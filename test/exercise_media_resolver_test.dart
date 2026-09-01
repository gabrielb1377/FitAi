import 'package:fitai/widgets/exercicio_gif_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical ID resolves a verified media path', () {
    const manifest = <String, String>{
      'peito_001': 'assets/exercises/gifs/peito_001.gif',
    };

    expect(
      ExerciseMediaResolver.pathFor('peito_001', manifest),
      'assets/exercises/gifs/peito_001.gif',
    );
  });

  test('display names never participate in media resolution', () {
    const manifest = <String, String>{
      'peito_001': 'assets/exercises/gifs/peito_001.gif',
    };

    expect(ExerciseMediaResolver.pathFor('supino reto', manifest), isNull);
    expect(ExerciseMediaResolver.pathFor('', manifest), isNull);
  });

  test('an unknown canonical ID fails closed', () {
    const manifest = <String, String>{
      'peito_001': 'assets/exercises/gifs/peito_001.gif',
    };

    expect(ExerciseMediaResolver.pathFor('costas_031', manifest), isNull);
  });

  testWidgets('a verified canonical exercise renders its v2 asset', (
    tester,
  ) async {
    ExerciseMediaResolver.setManifestForTest(const {
      'abdomen_001': 'assets/exercises/gifs/abdomen_001.gif',
    });
    addTearDown(ExerciseMediaResolver.resetForTest);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 120,
            child: ExercicioGifImage(
              canonicalExerciseId: 'abdomen_001',
              titulo: 'Abdominal crunch',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/exercises/gifs/abdomen_001.gif',
    );
  });
}
