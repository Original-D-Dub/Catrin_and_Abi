import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

/// Allows a player to save their scores by linking an email to their account.
///
/// Uses a two-step OTP (one-time code) flow — no password required:
/// 1. Player enters their email address.
/// 2. A 6-digit code is sent to that email; player enters the code to verify.
///
/// Works for both new and existing accounts. Intended to be reached from the
/// profile icon on the home screen.
class LinkAccountScreen extends StatefulWidget {
  const LinkAccountScreen({super.key});

  @override
  State<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends State<LinkAccountScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  /// Whether the OTP has been sent and we're now on the code-entry step.
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

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
      Navigator.pop(context);
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
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Confirms and permanently deletes the account and all saved data.
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account and all saved data — your '
          'profile, game scores and streaks, and your bingo animal '
          'collection.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.deleteAccount();
      // Start a fresh anonymous session so the app keeps working.
      await auth.signInAnonymously();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account and all saved data have been deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'Could not delete your account. Please check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLinked = !auth.isAnonymous && auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: AppColors.catrinBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: isLinked ? _buildLinkedView(auth) : _buildOtpFlow(),
        ),
      ),
    );
  }

  /// Shown when the player already has a verified (non-anonymous) account.
  Widget _buildLinkedView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user, size: 64, color: AppColors.success),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          'Account linked',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          auth.currentUser?.email ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        PrimaryButton(
          label: 'Sign Out',
          icon: Icons.logout,
          expanded: true,
          backgroundColor: AppColors.textSecondary,
          onPressed: _isLoading ? null : _signOut,
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        const Divider(),
        const SizedBox(height: AppSizes.spacingLarge),
        Text(
          'Delete account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        const Text(
          'Permanently delete your account and all saved data, including your '
          'profile, game scores and streaks, and your bingo animal collection. '
          'This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.accentRed),
          ),
        ],
        const SizedBox(height: AppSizes.spacingMedium),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                label: 'Delete Account',
                icon: Icons.delete_forever,
                expanded: true,
                backgroundColor: AppColors.accentRed,
                onPressed: _deleteAccount,
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
          Text(
            'Save your scores',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          const Text(
            'Enter your email and we\'ll send you a sign-in code. No password needed.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
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
          Text(
            'Check your email',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            'We sent a 6-digit code to ${_emailController.text.trim()}.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingLarge),

          TextFormField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              prefixIcon: Icon(Icons.lock_open),
              border: OutlineInputBorder(),
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
                style: TextStyle(color: AppColors.accentNavyBlue),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text(
                'Resend code',
                style: TextStyle(color: AppColors.accentNavyBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
