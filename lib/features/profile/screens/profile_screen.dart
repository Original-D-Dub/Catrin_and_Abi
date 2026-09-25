import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/button.dart';
import '../models/profile_catalog.dart';
import '../providers/profile_provider.dart';

/// Player profile: avatar, screen name, earned badges, a menu (Score,
/// Videos, Settings — each its own page), and (at the bottom) account
/// linking / sign-out / delete account.
///
/// The account-linking flow (previously the whole of this screen, under the
/// name "My Account") still uses a two-step OTP (one-time code) flow — no
/// password required:
/// 1. Player enters their email address.
/// 2. A 6-digit code is sent to that email; player enters the code to verify.
///
/// Reached from the profile icon on the home screen.
class ProfileScreen extends StatefulWidget {
  final String locale;

  /// When true, the screen scrolls to the account section (sign-in /
  /// account-linking) as soon as it's first laid out — used when arriving
  /// here via a "sign in to save your scores/videos" prompt elsewhere.
  final bool scrollToAccount;

  const ProfileScreen({
    super.key,
    this.locale = 'en',
    this.scrollToAccount = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _accountSectionKey = GlobalKey();

  /// Whether the OTP has been sent and we're now on the code-entry step.
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isDeletingAccount = false;
  String? _deleteErrorMessage;

  bool _isHwbLoading = false;
  String? _hwbErrorMessage;

  bool _isSigningOut = false;
  String? _signOutErrorMessage;

  AppLocalizations get _t => AppLocalizations(locale: widget.locale);

  @override
  void initState() {
    super.initState();
    if (widget.scrollToAccount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accountContext = _accountSectionKey.currentContext;
        if (accountContext != null) {
          Scrollable.ensureVisible(
            accountContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Step 1 — send the OTP to the entered email.
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().sendOtp(_emailController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _errorMessage = _t('profile.send_code_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Step 2 — verify the OTP code the player received.
  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().verifyOtp(
            email: _emailController.text.trim(),
            token: _otpController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('profile.otp_verified_snackbar')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = _t('profile.verify_code_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens the system browser for Hwb (Microsoft/Entra) sign-in. The actual
  /// session arrives later via deep link and [AuthProvider]'s auth-state
  /// listener, so there's nothing to await here beyond launching the flow.
  Future<void> _signInWithHwb() async {
    setState(() {
      _isHwbLoading = true;
      _hwbErrorMessage = null;
    });
    try {
      await context.read<AuthProvider>().signInWithHwb();
    } catch (e) {
      setState(() => _hwbErrorMessage = _t('profile.hwb_sign_in_error'));
    } finally {
      if (mounted) setState(() => _isHwbLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
      _signOutErrorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.signOut();
      await auth.signInAnonymously();
      // No explicit ProfileProvider.refresh() needed — it reloads itself on
      // every Supabase auth state change.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('profile.signed_out_snackbar')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _signOutErrorMessage = _t('profile.sign_out_error'));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Future<void> _confirmDeleteAccount(AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        message: t('profile.delete_account_confirm'),
        cancelLabel: t('profile.cancel'),
        yesLabel: t('profile.yes'),
      ),
    );
    if (confirmed == true) await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
      _deleteErrorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.deleteAccount();
      // Start a fresh anonymous session so the app keeps working.
      await auth.signInAnonymously();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('profile.account_deleted_snackbar')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _deleteErrorMessage = _t('profile.delete_account_error'));
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  void _openEditSheet(AppLocalizations t) {
    final profile = context.read<ProfileProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1250),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: profile,
        child: _EditProfileSheet(localizer: t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(locale: widget.locale);
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final isLinked = !auth.isAnonymous && auth.isLoggedIn;
    final avatar = avatarById(profile.avatarId);
    final screenName = (profile.screenName ?? '').trim();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1250),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('profile.title'),
          style: AppTheme.title.copyWith(fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: t('profile.menu.settings'),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.profileSettings,
              arguments: widget.locale,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _ProfileHeader(
                            avatar: avatar,
                            screenName: screenName,
                            placeholder: t('profile.screen_name_placeholder'),
                          ),
                          if (isLinked) ...[
                            const SizedBox(height: AppSizes.spacingLarge),
                            _BadgeRow(
                              title: t('profile.badges_title'),
                              stats: profile.stats,
                              localizer: t,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _EditProfileButton(
                        label: t('profile.edit'),
                        onEdit:
                            profile.isLoading ? null : () => _openEditSheet(t),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacingLarge * 1.5),
              _ProfileMenu(locale: widget.locale, localizer: t),
              const SizedBox(height: AppSizes.spacingLarge * 1.5),
              Align(
                key: _accountSectionKey,
                alignment: Alignment.centerLeft,
                child: Text(
                  t('profile.account_section').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isLinked ? _buildLinkedView(auth) : _buildSignInOptions(auth),
                      if (isLinked) ...[
                        const SizedBox(height: AppSizes.spacingLarge),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: AppSizes.spacingLarge),
                        _buildDeleteAccountSection(t),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when the player already has a verified (non-anonymous) account.
  Widget _buildLinkedView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user, size: 48, color: AppColors.success),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          _t('profile.account_linked'),
          style: AppTheme.heading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          auth.currentUser?.email ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        if (_signOutErrorMessage != null) ...[
          Text(
            _signOutErrorMessage!,
            style: const TextStyle(color: AppColors.accentRed),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
        ],
        _isSigningOut
            ? const Center(child: CircularProgressIndicator())
            : SecondaryButton(
                label: _t('profile.sign_out_button'),
                icon: Icons.logout,
                expanded: true,
                onPressed: _signOut,
              ),
      ],
    );
  }

  /// Delete-account message, button, and confirmation overlay — shown
  /// below the sign-out button (or the OTP form for anonymous players).
  Widget _buildDeleteAccountSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile.delete_account_message'),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        if (_deleteErrorMessage != null) ...[
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            _deleteErrorMessage!,
            style: const TextStyle(color: AppColors.accentRed),
          ),
        ],
        const SizedBox(height: AppSizes.spacingMedium),
        _isDeletingAccount
            ? const Center(child: CircularProgressIndicator())
            : WarningButton(
                label: t('profile.delete_account_button'),
                icon: Icons.delete_forever,
                expanded: true,
                onPressed: () => _confirmDeleteAccount(t),
              ),
      ],
    );
  }

  /// Sign-in options for anonymous players: Hwb (Microsoft/Entra) SSO, plus
  /// — while [AppConfig.hwbOnlyLogin] is false — the email/OTP flow used for
  /// testing before Hwb sign-in is fully wired up and verified.
  Widget _buildSignInOptions(AuthProvider auth) {
    final hwbError = _hwbErrorMessage ??
        (auth.hwbRejectionMessage != null ? _t(auth.hwbRejectionMessage!) : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('profile.save_scores_heading'),
          style: AppTheme.heading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          _t('profile.hwb_sign_in_message'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        if (hwbError != null) ...[
          Text(
            hwbError,
            style: const TextStyle(color: AppColors.accentRed),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
        ],
        _isHwbLoading
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                label: _t('profile.hwb_sign_in_button'),
                icon: Icons.school,
                expanded: true,
                backgroundColor: AppColors.success,
                onPressed: _signInWithHwb,
              ),
        if (!AppConfig.hwbOnlyLogin) ...[
          const SizedBox(height: AppSizes.spacingLarge),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: AppSizes.spacingLarge),
          _buildOtpFlow(),
        ],
      ],
    );
  }

  /// Two-step OTP flow — kept for testing with any email address until Hwb
  /// sign-in is verified end-to-end (see [AppConfig.hwbOnlyLogin]).
  Widget _buildOtpFlow() {
    return _otpSent ? _buildOtpEntry() : _buildEmailEntry();
  }

  /// Step 1 — email address entry.
  Widget _buildEmailEntry() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('profile.email_sign_in_heading'),
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            _t('profile.email_sign_in_message'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: _t('profile.email_label'),
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.email, color: Colors.white70),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) => (v == null || !v.contains('@'))
                ? _t('profile.email_invalid')
                : null,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.accentRed),
            ),
          ],

          const SizedBox(height: AppSizes.spacingLarge),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(
                  label: _t('profile.send_code_button'),
                  icon: Icons.send,
                  expanded: true,
                  backgroundColor: AppColors.success,
                  onPressed: _sendOtp,
                ),
        ],
      ),
    );
  }

  /// Step 2 — OTP code entry.
  Widget _buildOtpEntry() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('profile.check_email_heading'),
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            _t('profile.otp_sent_message')
                .replaceAll('{email}', _emailController.text.trim()),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _otpController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: _t('profile.otp_code_label'),
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_open, color: Colors.white70),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) => (v == null || v.trim().length != 6)
                ? _t('profile.otp_invalid')
                : null,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.accentRed),
            ),
          ],

          const SizedBox(height: AppSizes.spacingLarge),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(
                  label: _t('profile.verify_code_button'),
                  icon: Icons.check_circle,
                  expanded: true,
                  backgroundColor: AppColors.success,
                  onPressed: _verifyOtp,
                ),

          const SizedBox(height: AppSizes.spacingMedium),
          _buildOtpEntrySecondaryActions(),
        ],
      ),
    );
  }

  /// "Use a different email" / "Resend code" — full-width and stacked on
  /// narrow screens, side by side (each sharing half the width) on wide ones.
  Widget _buildOtpEntrySecondaryActions() {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final useDifferentEmailButton = SecondaryButton(
      label: _t('profile.use_different_email'),
      onPressed: _isLoading ? null : () => setState(() {
        _otpSent = false;
        _otpController.clear();
        _errorMessage = null;
      }),
      expanded: true,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
    );
    final resendCodeButton = TertiaryButton(
      label: _t('profile.resend_code'),
      onPressed: _isLoading ? null : _sendOtp,
      expanded: true,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
    );

    if (isWideScreen) {
      return Row(
        children: [
          Expanded(child: useDifferentEmailButton),
          const SizedBox(width: AppSizes.spacingMedium),
          Expanded(child: resendCodeButton),
        ],
      );
    }
    return Column(
      children: [
        useDifferentEmailButton,
        const SizedBox(height: AppSizes.spacingMedium),
        resendCodeButton,
      ],
    );
  }
}

// ── Header: avatar, screen name ───────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AvatarOption avatar;
  final String screenName;
  final String placeholder;

  const _ProfileHeader({
    required this.avatar,
    required this.screenName,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatar.color,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(avatar.emoji, style: const TextStyle(fontSize: 92)),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          screenName.isEmpty ? placeholder : screenName,
          style: const TextStyle(
            fontFamily: 'LuckiestGuy',
            fontSize: 28,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Edit button — responsive: shrinks its label on mobile, then drops to a
// bare pencil icon below [_kIconOnlyBreakpoint] where there isn't room for
// both the avatar/name and the label without crowding. ─────────────────────

const double _kMobileBreakpoint = 600;
const double _kIconOnlyBreakpoint = 375;

class _EditProfileButton extends StatelessWidget {
  final String label;
  final VoidCallback? onEdit;

  const _EditProfileButton({required this.label, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final iconOnly = width < _kIconOnlyBreakpoint;
    final isMobile = width < _kMobileBreakpoint;
    return PrimaryButton(
      label: label,
      icon: Icons.edit,
      backgroundColor: Colors.white24,
      onPressed: onEdit,
      iconOnly: iconOnly,
      fontSize: isMobile ? 14 : null,
    );
  }
}

// ── Badge row ──────────────────────────────────────────────────────────────

class _BadgeRow extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> stats;
  final AppLocalizations localizer;

  const _BadgeRow({
    required this.title,
    required this.stats,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTheme.heading.copyWith(
            fontSize: 12,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final badge in profileBadges)
              _BadgeCircle(
                badge: badge,
                earned: badge.isEarned(stats),
                label: localizer(badge.labelKey),
                lockedLabel: localizer('profile.badge.locked'),
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  final ProfileBadge badge;
  final bool earned;
  final String label;
  final String lockedLabel;

  const _BadgeCircle({
    required this.badge,
    required this.earned,
    required this.label,
    required this.lockedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Opacity(
            opacity: earned ? 1.0 : 0.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.color,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(badge.emoji, style: const TextStyle(fontSize: 30)),
                ),
                if (!earned)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.lock, color: Colors.white70, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: earned ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu: Score / Videos / Settings ──────────────────────────────────────────

class _ProfileMenu extends StatelessWidget {
  final String locale;
  final AppLocalizations localizer;

  const _ProfileMenu({required this.locale, required this.localizer});

  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _MenuItemRow(
            label: localizer('profile.menu.score'),
            fontSize: fontSize,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profileScores,
              arguments: locale,
            ),
          ),
          _MenuItemRow(
            label: localizer('profile.menu.videos'),
            fontSize: fontSize,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profileVideos,
              arguments: locale,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final String label;
  final double fontSize;
  final VoidCallback onTap;

  const _MenuItemRow({
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ── Edit sheet: screen name + avatar grid ─────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final AppLocalizations localizer;

  const _EditProfileSheet({required this.localizer});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late String _selectedAvatarId;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameController = TextEditingController(text: profile.screenName ?? '');
    _selectedAvatarId = avatarById(profile.avatarId).id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final ok = await context.read<ProfileProvider>().updateProfile(
          screenName: _nameController.text,
          avatarId: _selectedAvatarId,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = widget.localizer('profile.save_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.localizer;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.paddingLarge,
        right: AppSizes.paddingLarge,
        top: AppSizes.paddingLarge,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingLarge,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              t('profile.edit_title'),
              style: AppTheme.title.copyWith(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Text(
              t('profile.screen_name_label'),
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            TextField(
              controller: _nameController,
              maxLength: 24,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: t('profile.screen_name_placeholder'),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              t('profile.choose_avatar'),
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingSmall,
              crossAxisSpacing: AppSizes.spacingSmall,
              children: [
                for (final avatar in avatarCatalog)
                  _AvatarChoice(
                    avatar: avatar,
                    isSelected: avatar.id == _selectedAvatarId,
                    onTap: () => setState(() => _selectedAvatarId = avatar.id),
                  ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.spacingSmall),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.accentRed),
              ),
            ],
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    label: t('profile.cancel'),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(
                  child: PrimaryButton(
                    label: t('profile.save'),
                    expanded: true,
                    backgroundColor: AppColors.success,
                    onPressed: _isSaving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete-account confirmation overlay ───────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String message;
  final String cancelLabel;
  final String yesLabel;

  const _DeleteConfirmDialog({
    required this.message,
    required this.cancelLabel,
    required this.yesLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    label: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(
                  child: PrimaryButton(
                    label: yesLabel,
                    backgroundColor: AppColors.accentRed,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  final AvatarOption avatar;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarChoice({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatar.color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        alignment: Alignment.center,
        child: Text(avatar.emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
