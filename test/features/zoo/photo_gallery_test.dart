import 'package:catrin_abi_bsl/features/zoo/widgets/photo_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ScatteredPhotoGallery lays every photo out (none dropped) at distinct
/// positions, so they read as a scattered pile rather than a stack.
void main() {
  testWidgets('renders every photo at a distinct, scattered position',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ScatteredPhotoGallery(
            photos: [
              MiniPhotoCard(photoAssetPath: 'a.png', animalName: 'Lion'),
              MiniPhotoCard(photoAssetPath: 'b.png', animalName: 'Tiger'),
              MiniPhotoCard(photoAssetPath: 'c.png', animalName: 'Bear'),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Lion'), findsOneWidget);
    expect(find.text('Tiger'), findsOneWidget);
    expect(find.text('Bear'), findsOneWidget);

    final positions = [
      tester.getTopLeft(find.byType(MiniPhotoCard).at(0)),
      tester.getTopLeft(find.byType(MiniPhotoCard).at(1)),
      tester.getTopLeft(find.byType(MiniPhotoCard).at(2)),
    ];
    expect(positions.toSet().length, 3, reason: 'photos should not overlap exactly');
  });
}
