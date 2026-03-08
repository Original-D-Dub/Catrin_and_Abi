// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_sizes.dart';
// import '../providers/camera_vowels_provider.dart';
// import '../widgets/finger_cursor_overlay.dart';
// import '../widgets/fingertip_highlight.dart';
// import '../widgets/hand_guide_display.dart';

// /// Main screen for the BSL Camera Vowels game.
// ///
// /// The front camera runs invisibly to track the player's hands using
// /// MediaPipe's 21-point hand skeleton. The player physically touches
// /// their left hand's fingertips with their right index finger; the app
// /// detects the contact and speaks the corresponding BSL vowel (a/e/i/o/u).
// ///
// /// Level 1 – Practice: all fingertips active, TTS fires on any touch.
// /// Level 2 – Challenge: a target vowel is shown; only the matching
// ///   fingertip scores a point.
// class CameraVowelsScreen extends StatelessWidget {
//   const CameraVowelsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CameraVowelsProvider>(
//       builder: (context, provider, _) {
//         return Scaffold(
//           extendBodyBehindAppBar: true,
//           appBar: provider.showLevelSelect
//               ? AppBar(
//                   backgroundColor: Colors.transparent,
//                   elevation: 0,
//                   centerTitle: true,
//                   title: const Text(
//                     'Camera Vowels',
//                     style: TextStyle(
//                       fontFamily: 'ComicRelief',
//                       fontSize: AppSizes.fontSizeLarge,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.accentWhite,
//                     ),
//                   ),
//                   leading: IconButton(
//                     icon: const Icon(Icons.arrow_back,
//                         color: AppColors.accentWhite),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 )
//               : null,
//           body: Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage(
//                     'assets/backgrounds/math-background-1080x1920.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: SafeArea(
//               child: provider.showLevelSelect
//                   ? _buildLevelSelect(context, provider)
//                   : _buildGame(context, provider),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ── Level select ───────────────────────────────────────────────────────────

//   Widget _buildLevelSelect(
//       BuildContext context, CameraVowelsProvider provider) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(AppSizes.paddingLarge),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Choose a Level',
//               style: TextStyle(
//                 fontFamily: 'ComicRelief',
//                 fontSize: AppSizes.fontSizeTitle,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: AppSizes.spacingLarge),
//             GridView.count(
//               crossAxisCount: 2,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               mainAxisSpacing: AppSizes.spacingMedium,
//               crossAxisSpacing: AppSizes.spacingMedium,
//               childAspectRatio: 1.3,
//               children: CameraVowelsLevel.all.map((level) {
//                 final colors = [AppColors.abiPink, AppColors.accentPurple];
//                 final color = colors[(level.number - 1) % colors.length];
//                 return ElevatedButton(
//                   onPressed: () => provider.selectLevel(level.number),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: color,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.all(AppSizes.paddingMedium),
//                     shape: RoundedRectangleBorder(
//                       borderRadius:
//                           BorderRadius.circular(AppSizes.borderRadiusMedium),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Level ${level.number}',
//                         style: const TextStyle(
//                           fontFamily: 'ComicRelief',
//                           fontSize: AppSizes.fontSizeLarge,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: AppSizes.spacingXSmall),
//                       Text(
//                         level.name,
//                         style: const TextStyle(
//                           fontFamily: 'ComicRelief',
//                           fontSize: AppSizes.fontSizeBody,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Game screen ────────────────────────────────────────────────────────────

//   Widget _buildGame(BuildContext context, CameraVowelsProvider provider) {
//     if (provider.gameState == CameraVowelsGameState.permissionDenied) {
//       return _buildPermissionDenied(context, provider);
//     }

//     return Stack(
//       children: [
//         Column(
//           children: [
//             const SizedBox(height: 8),
//             _buildHeaderBar(provider),
//             const SizedBox(height: 12),
//             Expanded(child: _buildGameArea(provider)),
//             if (provider.currentLevel.number == 2 &&
//                 provider.targetVowel != null)
//               _buildTargetVowelBanner(provider.targetVowel!),
//             const SizedBox(height: AppSizes.spacingMedium),
//           ],
//         ),

//         // Back button overlay (top-left)
//         Positioned(
//           top: 4,
//           left: 4,
//           child: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => provider.showLevelSelection(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGameArea(CameraVowelsProvider provider) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final size = Size(constraints.maxWidth, constraints.maxHeight);
//         return Stack(
//           children: [
//             // Left-hand guide (SVG or Rive)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: AppSizes.paddingMedium),
//                 child: const HandGuideDisplay(),
//               ),
//             ),

//             // Fingertip highlight rings
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: AppSizes.paddingMedium),
//                 child: FingertipHighlight(
//                   handDisplaySize: size,
//                   activeFingertipIndex: provider.activeFingertipIndex,
//                   wrongFingertipIndex: provider.wrongFingertipIndex,
//                 ),
//               ),
//             ),

//             // Right-hand index finger cursor
//             FingerCursorOverlay(
//               containerSize: size,
//               cursorPosition: provider.cursorPosition,
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildTargetVowelBanner(String vowel) {
//     final vowelColors = <String, Color>{
//       'a': AppColors.accentRed,
//       'e': AppColors.accentNavyBlue,
//       'i': AppColors.accentLimeGreen,
//       'o': AppColors.accentOrange,
//       'u': AppColors.accentPurple,
//     };
//     final color = vowelColors[vowel] ?? AppColors.catrinBlue;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.paddingLarge,
//         vertical: AppSizes.paddingSmall,
//       ),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.15),
//         borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
//         border: Border.all(color: color, width: 2),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text(
//             'Touch: ',
//             style: TextStyle(
//               fontFamily: 'ComicRelief',
//               fontSize: AppSizes.fontSizeLarge,
//               fontWeight: FontWeight.bold,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           Text(
//             vowel.toUpperCase(),
//             style: TextStyle(
//               fontFamily: 'ComicRelief',
//               fontSize: AppSizes.fontSizeTitle,
//               fontWeight: FontWeight.w900,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPermissionDenied(
//       BuildContext context, CameraVowelsProvider provider) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(AppSizes.paddingLarge),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.camera_alt_outlined,
//                 size: 64, color: AppColors.textSecondary),
//             const SizedBox(height: AppSizes.spacingMedium),
//             const Text(
//               'Camera permission is needed to track your hands.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontFamily: 'ComicRelief',
//                 fontSize: AppSizes.fontSizeLarge,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: AppSizes.spacingLarge),
//             ElevatedButton(
//               onPressed: () => provider.showLevelSelection(),
//               child: const Text('Go Back'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Header bar (same style as BSL Maths) ─────────────────────────────────

//   Widget _buildHeaderBar(CameraVowelsProvider provider) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 16, right: 16),
//       child: SizedBox(
//         height: 88,
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             // Purple header rectangle
//             Positioned(
//               left: 40,
//               right: 0,
//               top: 8,
//               bottom: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: AppColors.headerBackgroundLight,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(
//                     color: AppColors.headerBorderDark,
//                     width: 2,
//                   ),
//                 ),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.headerBackground,
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(
//                       color: AppColors.headerBorderDark,
//                       width: 2,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const SizedBox(width: 48),

//                       // Level name (centre)
//                       if (provider.currentLevel.name.isNotEmpty)
//                         Expanded(
//                           child: Center(
//                             child: Text(
//                               provider.currentLevel.name,
//                               style: const TextStyle(
//                                 fontFamily: 'ComicRelief',
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         )
//                       else
//                         const Spacer(),

//                       // Level number (right)
//                       Padding(
//                         padding: const EdgeInsets.only(right: 16),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               'Level',
//                               style: TextStyle(
//                                 fontFamily: 'ComicRelief',
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Text(
//                               '${provider.currentLevel.number}',
//                               style: const TextStyle(
//                                 fontFamily: 'ComicRelief',
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Score circle (overlapping left edge)
//             Positioned(
//               left: 0,
//               top: 0,
//               bottom: 0,
//               child: Center(
//                 child: Container(
//                   width: 104,
//                   height: 104,
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColors.headerBackgroundLight,
//                     border: Border.all(
//                       color: AppColors.headerBorderDark,
//                       width: 2,
//                     ),
//                   ),
//                   child: Container(
//                     width: 96,
//                     height: 96,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppColors.headerBackground,
//                       border: Border.all(
//                         color: AppColors.headerBorderDark,
//                         width: 2,
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           'Score',
//                           style: TextStyle(
//                             fontFamily: 'ComicRelief',
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           '${provider.score}',
//                           style: const TextStyle(
//                             fontFamily: 'ComicRelief',
//                             fontSize: 44,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.white,
//                             height: 1.0,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
