// Valeurs de référence : onglet « Règle du triangle » (cellules N7:R7, J7, K7).
import 'package:calcul_electrique_pro/core/calculs/regle_triangle.dart';
import 'package:calcul_electrique_pro/core/donnees/courbes_disjoncteurs.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

ResultatTriangle _calcul({double longueurDistribuee = 10}) =>
    calculerRegleTriangle(
      reglage: const ReglageMagnetique.courbe(CourbeDisjoncteur.c),
      ir: 63,
      sectionS1: 10,
      ameS1: Ame.cuivre,
      distancePS2: 30,
      sectionS2: 4,
      ameS2: Ame.cuivre,
      longueurDistribuee: longueurDistribuee,
    );

void main() {
  test('cas du classeur : courbe C, 63 A, S1 10 mm², S2 4 mm² à 30 m', () {
    final r = _calcul();
    expect(r.longueurMaxS1, closeTo(63.492063492063494, 1e-9)); // P7
    expect(r.longueurMaxS2Seul, closeTo(25.396825396825395, 1e-9)); // R7
    expect(r.longueurMaxS2, closeTo(13.396825396825397, 1e-9)); // J7
    expect(r.conforme, isTrue); // K7 : 10 m <= 13,4 m
  });

  test('longueur distribuée trop grande -> non conforme', () {
    expect(_calcul(longueurDistribuee: 14).conforme, isFalse);
    expect(_calcul(longueurDistribuee: 13.396825396825397).conforme, isTrue);
  });

  test('valeurs de courbe (N7)', () {
    const attendu = {
      CourbeDisjoncteur.b: 5.0,
      CourbeDisjoncteur.c: 10.0,
      CourbeDisjoncteur.d: 20.0,
      CourbeDisjoncteur.k: 14.0,
      CourbeDisjoncteur.ma: 12.0,
      CourbeDisjoncteur.z: 3.6,
    };
    attendu.forEach((courbe, m) {
      expect(ReglageMagnetique.courbe(courbe).multiple, m);
    });
  });

  test('multiple de Ir saisi : 1,2 × la valeur (N7)', () {
    expect(const ReglageMagnetique.multipleIr(8).multiple, closeTo(9.6, 1e-12));
  });

  test('âme aluminium : résistivité 0,037', () {
    final cu = longueurMaxProtegee(
        section: 10, ame: Ame.cuivre, ir: 63, multiple: 10);
    final al = longueurMaxProtegee(
        section: 10, ame: Ame.aluminium, ir: 63, multiple: 10);
    expect(al, closeTo(cu * 0.023 / 0.037, 1e-9));
  });
}
