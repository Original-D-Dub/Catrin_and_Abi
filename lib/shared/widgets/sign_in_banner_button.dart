import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import '../services/auth_provider.dart';

/// Shows a "Sign in to save your scores" button for anonymous users.
/// Renders nothing for signed-in users.
class SignInBannerButton extends StatelessWidget {
  /// UI locale ('en' or 'cy') used for the button label.
  final String locale;

  const SignInBannerButton({super.key, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAnonymous) {
      return const SizedBox.shrink();
    }
    final localizer = AppLocalizations(locale: locale);
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
      icon: const Icon(Icons.person_add, size: 18),
      label: Text(localizer('general.sign_in_to_save_scores')),
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
