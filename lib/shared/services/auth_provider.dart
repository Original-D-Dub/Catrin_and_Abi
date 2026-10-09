import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Manages authentication state for the app.
///
/// Wraps Supabase auth so the rest of the app stays decoupled from it.
/// Provided at the root of the widget tree (see app.dart) so any screen
/// can access the current user without importing Supabase directly.
class AuthProvider extends ChangeNotifier {
  /// Localization key set when a signed-in account is rejected by
  /// [_enforceHwbOnlyIfNeeded] because it isn't a Hwb account, or when a Hwb
  /// sign-in fails after returning from the browser — resolve with an
  /// [AppLocalizations] at the display site, since this provider has no
  /// locale/context of its own. Cleared on the next successful sign-in.
  String? hwbRejectionMessage;

  /// True between launching a Hwb browser flow and it completing, so that
  /// unrelated auth errors (e.g. a token refresh failing) aren't reported as
  /// a failed Hwb sign-in.
  bool _hwbFlowPending = false;

  static const String _hwbRedirect = 'catrinabi://login-callback';
  static const String _hwbScopes = 'email openid profile';

  AuthProvider() {
    // Listen to auth state changes (sign-in, sign-out, token refresh).
    // Errors from the OAuth deep link (e.g. a failed Hwb link) arrive on the
    // same stream.
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.userUpdated) {
          _hwbFlowPending = false;
        }
        _enforceHwbOnlyIfNeeded(data.session?.user);
        notifyListeners();
      },
      onError: _onAuthStreamError,
    );
  }

  /// Handles errors from the auth stream. If an anonymous player tried to
  /// link a Hwb account that already belongs to another player (e.g. they
  /// signed in on a different device first), falls back to a normal Hwb
  /// sign-in to that existing account. This session's anonymous progress is
  /// not merged in that case.
  void _onAuthStreamError(Object error) {
    if (error is AuthException && _isIdentityAlreadyLinked(error)) {
      _startHwbSignIn().catchError((Object e) {
        debugPrint('Hwb sign-in fallback error: $e');
        _reportHwbFailure();
      });
      return;
    }
    debugPrint('Auth stream error: $error');
    if (_hwbFlowPending) _reportHwbFailure();
  }

  void _reportHwbFailure() {
    _hwbFlowPending = false;
    hwbRejectionMessage = 'auth.hwb_sign_in_failed';
    notifyListeners();
  }

  /// Errors parsed from the redirect URL carry the `error_code` value in
  /// [AuthException.statusCode]; errors from API calls carry it in
  /// [AuthException.code]. Check both.
  bool _isIdentityAlreadyLinked(AuthException error) {
    const code = 'identity_already_exists';
    return error.code == code || error.statusCode == code;
  }

  /// When [AppConfig.hwbOnlyLogin] is true, signs out any non-anonymous
  /// account whose email isn't on a Hwb domain. Lets AppConfig.hwbOnlyLogin
  /// be the single switch that enforces Hwb-only sign-in, independent of
  /// which screen/flow a session came from.
  Future<void> _enforceHwbOnlyIfNeeded(User? user) async {
    if (!AppConfig.hwbOnlyLogin) return;
    if (user == null || user.isAnonymous) return;
    if (_accountEmails(user).any(_isHwbEmail)) {
      hwbRejectionMessage = null;
      return;
    }
    hwbRejectionMessage = 'auth.hwb_rejection_message';
    await Supabase.instance.client.auth.signOut();
  }

  /// The account email plus any email on its linked identities. An
  /// anonymous account converted by linking a Hwb identity may carry the
  /// address only on that identity.
  Iterable<String?> _accountEmails(User user) sync* {
    yield user.email;
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      yield identity.identityData?['email'] as String?;
    }
  }

  bool _isHwbEmail(String? email) {
    if (email == null || !email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase();
    return AppConfig.hwbEmailDomains
        .any((d) => domain == d || domain.endsWith('.$d'));
  }

  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;

  /// True when the player is signed in but has no email (anonymous session).
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Sign up with email + password.
  /// [username] is stored in user metadata and copied to the profiles table
  /// by the database trigger created in Step 4.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    notifyListeners();
    return response;
  }

  /// Sign in with email + password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return response;
  }

  /// Sign in anonymously — lets children play without an account.
  /// They can link an email later via [linkEmail].
  Future<AuthResponse> signInAnonymously() async {
    final response = await Supabase.instance.client.auth.signInAnonymously();
    notifyListeners();
    return response;
  }

  /// Link an email + password to an existing anonymous account,
  /// preserving all saved stats.
  Future<UserResponse> linkEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: {'username': username},
      ),
    );
    notifyListeners();
    return response;
  }

  /// Starts Hwb sign-in via Microsoft/Entra OAuth. Opens the system browser;
  /// the resulting session arrives asynchronously through
  /// [onAuthStateChange] once the app is redirected back via the
  /// 'catrinabi://login-callback' deep link, at which point
  /// [_enforceHwbOnlyIfNeeded] verifies it's actually a Hwb account.
  ///
  /// When the current player is anonymous, the Hwb identity is linked to
  /// their existing account instead, so the same user ID — and all stats
  /// and collections saved against it — carry over. If that Hwb account is
  /// already in use, [_onAuthStreamError] falls back to a plain sign-in.
  ///
  /// Requires, in the Supabase dashboard: the Azure provider configured
  /// (client ID/secret from an Entra app registration) and, for linking,
  /// Authentication → "Allow manual linking" enabled.
  Future<void> signInWithHwb() async {
    hwbRejectionMessage = null;
    _hwbFlowPending = true;
    try {
      if (currentUser?.isAnonymous ?? false) {
        await Supabase.instance.client.auth.linkIdentity(
          OAuthProvider.azure,
          redirectTo: _hwbRedirect,
          scopes: _hwbScopes,
        );
      } else {
        await _startHwbSignIn();
      }
    } catch (_) {
      // Browser never opened — the caller reports this failure itself.
      _hwbFlowPending = false;
      rethrow;
    }
  }

  Future<void> _startHwbSignIn() {
    _hwbFlowPending = true;
    return Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.azure,
      redirectTo: _hwbRedirect,
      scopes: _hwbScopes,
    );
  }

  /// Sends a 6-digit OTP to [email].
  /// Creates a new account if the email is not yet registered.
  Future<void> sendOtp(String email) async {
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  /// Verifies the 6-digit OTP code the user received by email.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    final response = await Supabase.instance.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    notifyListeners();
    return response;
  }

  /// Sends a password-reset email. Does not require the user to be signed in.
  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }

  /// Permanently deletes the current account and all of its data
  /// (profile, game stats, bingo collection). Cannot be undone.
  ///
  /// Calls the `delete_account` Postgres function, which removes the
  /// auth.users row; every per-user table has an ON DELETE CASCADE foreign
  /// key to auth.users, so all player data goes with it. New per-user tables
  /// must reference auth.users with ON DELETE CASCADE to be covered.
  ///
  /// Required by App Store guideline 5.1.1(v) and the Play Store data-deletion
  /// policy for apps that offer account creation.
  Future<void> deleteAccount() async {
    await Supabase.instance.client.rpc('delete_account');
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // The server session died with the account; signOut has already
      // cleared the local session, which is all that matters here.
    }
    notifyListeners();
  }
}
