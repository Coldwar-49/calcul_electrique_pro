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
          edition: EditionNorme.norme2013,
          symetrique: false);
      expect(k, closeTo(0.37557273599999996, 1e-12));
    });

    test('même cas avec K5 = 0,86 (norme 2024, tableau 52.20)', () {
      final k = coefficientMethodeEF(
          isolant: Isolant.pvc,
          temperature: 40,
          nbCircuits: 2,
          tablettePerforee: false,
          nbCouches: 3,
          harmoniquesSup15: true,
          symetrique: false);
      expect(k, closeTo(0.37557273599999996 / 0.84 * 0.86, 1e-12));
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

  group('K2 selon le tableau 52.12 (NF C 15-100-1, 2024)', () {
    test('méthode B : valeurs tabulées jusqu\'à 9, puis 12, 16, 20', () {
      const attendu = {
        1: 1.0, 2: 0.80, 3: 0.70, 4: 0.65, 5: 0.60, 6: 0.57, 7: 0.54,
        8: 0.52, 9: 0.50, 12: 0.45, 16: 0.41, 20: 0.38,
      };
      attendu.forEach((n, k) => expect(k2MethodeB(n), k, reason: 'n=$n'));
      // Entre deux colonnes : la colonne supérieure (côté sécurité).
      expect(k2MethodeB(10), 0.45);
      expect(k2MethodeB(13), 0.41);
      expect(k2MethodeB(18), 0.38);
      expect(k2MethodeB(30), 0.38);
    });

    test('méthode B : le classeur 2013 reste disponible', () {
      expect(k2MethodeB(6, edition: EditionNorme.norme2013), 0.55);
      expect(k2MethodeB(8, edition: EditionNorme.norme2013), 0.5);
      expect(k2MethodeB(13, edition: EditionNorme.norme2013), 0.4);
      expect(nombreMaxCircuits(ModePose.b), 20);
      expect(nombreMaxCircuits(ModePose.b, edition: EditionNorme.norme2013), 13);
    });

    test('méthode C sous plafond : 0,95 0,81 0,76 … (2013 : 1 0,85 0,76 …)', () {
      expect(k2MethodeC(1, plafond: true), 0.95);
      expect(k2MethodeC(2, plafond: true), 0.81);
      expect(k2MethodeC(3, plafond: true), 0.76);
      expect(k2MethodeC(9, plafond: true), 0.64);
      expect(k2MethodeC(1, plafond: true, edition: EditionNorme.norme2013), 1);
      expect(k2MethodeC(2, plafond: true, edition: EditionNorme.norme2013), 0.85);
      // Sur mur : inchangé.
      expect(k2MethodeC(2, plafond: false), 0.85);
    });

    test('K1 (tableaux 52.9 et 52.10) et K3 (52.15) : valeurs identiques', () {
      expect(k1Temperature(Isolant.pvc, 40), 0.87);
      expect(k1Temperature(Isolant.pr, 80), 0.41);
      expect(k1Temperature(Isolant.pvc, 30, sol: true), 0.89);
      expect(k1Temperature(Isolant.pr, 60, sol: true), 0.65);
      expect(k3Couches(4), 0.7);
      expect(k3Couches(9), 0.66);
    });
  });
}
