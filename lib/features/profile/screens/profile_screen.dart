import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/primary_button.dart';
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

  const ProfileScreen({super.key, this.locale = 'en'});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  /// Whether the OTP has been sent and we're now on the code-entry step.
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isDeletingAccount = false;
  String? _deleteErrorMessage;

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
      setState(() => _errorMessage = 'Could not send code. Please try again.');
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
        const SnackBar(
          content: Text('Account saved! Your scores will now be recorded.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Incorrect code. Please check your email and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    await auth.signInAnonymously();
    // No explicit ProfileProvider.refresh() needed — it reloads itself on
    // every Supabase auth state change.
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
        const SnackBar(
          content: Text('Your account and all saved data have been deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _deleteErrorMessage =
            'Could not delete your account. Please check your connection and try again.');
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
    final screenName = (profile.username ?? '').trim();

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
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              _ProfileHeader(
                avatar: avatar,
                screenName: screenName,
                placeholder: t('profile.screen_name_placeholder'),
                editLabel: t('profile.edit'),
                onEdit: profile.isLoading ? null : () => _openEditSheet(t),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              _BadgeRow(
                title: t('profile.badges_title'),
                stats: profile.stats,
                localizer: t,
              ),
              const SizedBox(height: AppSizes.spacingLarge * 1.5),
              _ProfileMenu(locale: widget.locale, localizer: t),
              const SizedBox(height: AppSizes.spacingLarge * 1.5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('profile.account_section').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
                      isLinked ? _buildLinkedView(auth) : _buildOtpFlow(),
                      const SizedBox(height: AppSizes.spacingLarge),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: AppSizes.spacingLarge),
                      _buildDeleteAccountSection(t),
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
        const Text(
          'Account linked',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          auth.currentUser?.email ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        PrimaryButton(
          label: 'Sign Out',
          icon: Icons.logout,
          expanded: true,
          backgroundColor: Colors.white24,
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
            : PrimaryButton(
                label: t('profile.delete_account_button'),
                icon: Icons.delete_forever,
                expanded: true,
                backgroundColor: AppColors.accentRed,
                onPressed: () => _confirmDeleteAccount(t),
              ),
      ],
    );
  }

  /// Two-step OTP flow for anonymous players.
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
          const Text(
            'Save your scores',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          const Text(
            'Enter your email and we\'ll send you a sign-in code. No password needed.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.email, color: Colors.white70),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
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
                  label: 'Send Code',
                  icon: Icons.send,
                  expanded: true,
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
          const Text(
            'Check your email',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            'We sent a 6-digit code to ${_emailController.text.trim()}.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _otpController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '6-digit code',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_open, color: Colors.white70),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) =>
                (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
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
                  label: 'Verify Code',
                  icon: Icons.check_circle,
                  expanded: true,
                  onPressed: _verifyOtp,
                ),

          const SizedBox(height: AppSizes.spacingMedium),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => setState(() {
                _otpSent = false;
                _otpController.clear();
                _errorMessage = null;
              }),
              child: const Text(
                'Use a different email',
                style: TextStyle(color: AppColors.catrinBlue),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text(
                'Resend code',
                style: TextStyle(color: AppColors.catrinBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header: avatar, screen name, edit button ─────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AvatarOption avatar;
  final String screenName;
  final String placeholder;
  final String editLabel;
  final VoidCallback? onEdit;

  const _ProfileHeader({
    required this.avatar,
    required this.screenName,
    required this.placeholder,
    required this.editLabel,
    required this.onEdit,
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
        const SizedBox(height: AppSizes.spacingMedium),
        PrimaryButton(
          label: editLabel,
          icon: Icons.edit,
          backgroundColor: Colors.white24,
          onPressed: onEdit,
        ),
      ],
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
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 12,
            fontWeight: FontWeight.bold,
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
              fontFamily: 'ComicRelief',
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
          _MenuItemRow(
            label: localizer('profile.menu.settings'),
            fontSize: fontSize,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profileSettings,
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
                  fontFamily: 'ComicRelief',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
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
    _nameController = TextEditingController(text: profile.username ?? '');
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
          username: _nameController.text,
          avatarId: _selectedAvatarId,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = widget.localizer('profile.name_taken');
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
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Text(
              t('profile.screen_name_label'),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 13,
                fontWeight: FontWeight.bold,
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
                fontFamily: 'ComicRelief',
                fontSize: 13,
                fontWeight: FontWeight.bold,
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
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      t('profile.cancel'),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
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
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
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
