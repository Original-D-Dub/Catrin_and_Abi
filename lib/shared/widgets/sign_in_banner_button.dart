import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../services/auth_provider.dart';

/// Shows a "Sign in to save your scores" button for anonymous users.
/// Renders nothing for signed-in users.
class SignInBannerButton extends StatelessWidget {
  const SignInBannerButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAnonymous) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.linkAccount),
      icon: const Icon(Icons.person_add, size: 18),
      label: const Text('Sign in to save your scores'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.catrinBlue,
        side: const BorderSide(color: AppColors.catrinBlue),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingSmall,
        ),
      ),
    );
  }
}
