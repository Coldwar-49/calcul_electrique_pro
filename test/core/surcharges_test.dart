// Valeurs de référence : classeur CLAUREG V3.6, onglets Surcharges et K pour
// methode B..F (cellules citées dans docs/claureg_extraction.md).
import 'package:calcul_electrique_pro/core/calculs/coefficient_k.dart';
import 'package:calcul_electrique_pro/core/calculs/surcharges.dart';
import 'package:calcul_electrique_pro/core/donnees/calibres.dart';
import 'package:calcul_electrique_pro/core/donnees/coefficients_k.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coefficient K (cellules U5 / T5 / L11 / M5)', () {
    test('méthode B : PR 30 °C, 1 circuit, 1 couche -> 0,9', () {
      final k = coefficientMethodeB(
          isolant: Isolant.pr, temperature: 30, nbCircuits: 1, nbCouches: 1);
      expect(k, closeTo(0.9, 1e-12));
    });

    test('méthode C : PR 50 °C, 4 circuits plafond, 2 couches', () {
      final k = coefficientMethodeC(
          isolant: Isolant.pr,
          temperature: 50,
          nbCircuits: 4,
          plafond: true,
          nbCouches: 2);
      expect(k, closeTo(0.44870399999999994, 1e-12));
    });

    test('méthode D : PR 20 °C, tous facteurs à 1 -> 1', () {
      final k = coefficientMethodeD(isolant: Isolant.pr, temperatureSol: 20);
      expect(k, closeTo(1, 1e-12));
    });

    test('méthode E : PR 30 °C, 4 circuits tablette perforée -> 0,77', () {
      final k = coefficientMethodeEF(
          isolant: Isolant.pr,
          temperature: 30,
          nbCircuits: 4,
          tablettePerforee: true,
          nbCouches: 1);
      expect(k, closeTo(0.77, 1e-12));
    });

    test('méthode F : PVC 40 °C, 2 circuits, 3 couches, Th>15 %, asym.', () {
      final k = coefficientMethodeEF(
          isolant: Isolant.pvc,
          temperature: 40,
          nbCircuits: 2,
          tablettePerforee: false,
          nbCouches: 3,
          harmoniquesSup15: true,
          symetrique: false);
      expect(k, closeTo(0.37557273599999996, 1e-12));
    });

    test('température hors tableau -> ArgumentError', () {
      expect(() => k1Temperature(Isolant.pr, 32), throwsArgumentError);
    });
  });

  group('Surcharges (I = a × S^b, cellules U6:AD25 pour S = 240)', () {
    double? i240(Isolant iso, Circuit c, ModePose m, Ame a) =>
        courantFormule(
            isolant: iso, circuit: c, mode: m, ame: a, section: 240);

    test('PR 3 D alu (AD24)', () {
      expect(i240(Isolant.pr, Circuit.triphase, ModePose.d, Ame.aluminium),
          closeTo(389.26915749337627, 1e-9));
    });

    test('PR 2 E cuivre (AC20)', () {
      expect(i240(Isolant.pr, Circuit.monophase, ModePose.e, Ame.cuivre),
          closeTo(641.4006657344379, 1e-9));
    });

    test('PVC 3 B cuivre, toutes sections (U6)', () {
      expect(i240(Isolant.pvc, Circuit.triphase, ModePose.b, Ame.cuivre),
          closeTo(369.9340969101628, 1e-9));
    });

    test('section 50 remplacée par 47,5 (J6)', () {
      final a = courantFormule(
          isolant: Isolant.pr,
          circuit: Circuit.triphase,
          mode: ModePose.d,
          ame: Ame.cuivre,
          section: 50);
      final b = courantFormule(
          isolant: Isolant.pr,
          circuit: Circuit.triphase,
          mode: ModePose.d,
          ame: Ame.cuivre,
          section: 47.5);
      expect(a, b);
    });

    test('cas du classeur : U1000R2V alu 240 mm² triphasé mode D', () {
      final r = calculerSurcharge(
          isolant: Isolant.pr,
          circuit: Circuit.triphase,
          mode: ModePose.d,
          ame: Ame.aluminium,
          section: 240,
          coefficientK: 1);
      expect(r.i, closeTo(408.7326153680451, 1e-9));
      expect(r.calibre, 315);
    });
  });

  group('Calibres (T30:X30)', () {
    test('seuils', () {
      expect(calibrePourCourant(0.5), isNull);
      expect(calibrePourCourant(0.655), 0.5);
      expect(calibrePourCourant(17.59), 10);
      expect(calibrePourCourant(17.6), 16);
      expect(calibrePourCourant(1374), 1000);
      expect(calibrePourCourant(1375), 1250);
    });
  });
}
