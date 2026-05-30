import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages authentication state for the app.
///
/// Wraps Supabase auth so the rest of the app stays decoupled from it.
/// Provided at the root of the widget tree (see app.dart) so any screen
/// can access the current user without importing Supabase directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Listen to auth state changes (sign-in, sign-out, token refresh)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
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
}
