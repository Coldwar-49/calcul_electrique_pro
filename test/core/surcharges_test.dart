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
          nbCouches: 1,
          edition: EditionNorme.norme2013);
      expect(k, closeTo(0.77, 1e-12));
    });

    test('méthode E en 2024 : même cas, tableau 52.13 -> 0,79', () {
      final k = coefficientMethodeEF(
          isolant: Isolant.pr,
          temperature: 30,
          nbCircuits: 4,
          tablettePerforee: true,
          nbCouches: 1);
      expect(k, closeTo(0.79, 1e-12));
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
      // K5 : 0,86 au lieu de 0,84 ; K2 (2 circuits, échelles) : 0,87 au lieu de 0,88.
      expect(k, closeTo(0.37557273599999996 / 0.84 * 0.86 * 0.87 / 0.88, 1e-12));
    });

    test('température hors tableau -> ArgumentError', () {
      expect(() => k1Temperature(Isolant.pr, 32), throwsArgumentError);
    });
  });

  group('Surcharges (I = a × S^b, cellules U6:AD25 pour S = 240)', () {
    double? i240(Isolant iso, Circuit c, ModePose m, Ame a) =>
        courantFormule(
            isolant: iso,
            circuit: c,
            mode: m,
            ame: a,
            section: 240,
            edition: EditionNorme.norme2013);

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
          section: 50,
          edition: EditionNorme.norme2013);
      final b = courantFormule(
          isolant: Isolant.pr,
          circuit: Circuit.triphase,
          mode: ModePose.d,
          ame: Ame.cuivre,
          section: 47.5,
          edition: EditionNorme.norme2013);
      expect(a, b);
    });

    test('cas du classeur : U1000R2V alu 240 mm² triphasé mode D', () {
      final r = calculerSurcharge(
          isolant: Isolant.pr,
          circuit: Circuit.triphase,
          mode: ModePose.d,
          ame: Ame.aluminium,
          section: 240,
          coefficientK: 1,
          edition: EditionNorme.norme2013);
      expect(r.i, closeTo(408.7326153680451, 1e-9));
      expect(r.calibre, 315);
    });

    test('modes B, C, E, F en 2024 : tableaux 52.8C, 52.8E, 52.8F (valeurs exactes)', () {
      double? iz(ModePose m, Ame a, Isolant i, Circuit c, double s) =>
          courantFormule(isolant: i, circuit: c, mode: m, ame: a, section: s);
      // B1 (52.8C)
      expect(iz(ModePose.b, Ame.cuivre, Isolant.pvc, Circuit.triphase, 1.5), 15.5);
      expect(iz(ModePose.b, Ame.cuivre, Isolant.pr, Circuit.monophase, 300), 603);
      expect(iz(ModePose.b, Ame.aluminium, Isolant.pr, Circuit.triphase, 120), 251);
      expect(iz(ModePose.b, Ame.cuivre, Isolant.pr, Circuit.monophase, 630), 995);
      // Cases vides : 400 à 630 mm² n'existent que pour PR 2 en B1.
      expect(iz(ModePose.b, Ame.cuivre, Isolant.pvc, Circuit.triphase, 400), isNull);
      expect(iz(ModePose.b, Ame.cuivre, Isolant.pr, Circuit.triphase, 500), isNull);
      // C (52.8E)
      expect(iz(ModePose.c, Ame.cuivre, Isolant.pvc, Circuit.triphase, 16), 76);
      expect(iz(ModePose.c, Ame.cuivre, Isolant.pr, Circuit.triphase, 630), 923);
      expect(iz(ModePose.c, Ame.aluminium, Isolant.pr, Circuit.monophase, 300), 508);
      expect(iz(ModePose.c, Ame.cuivre, Isolant.pvc, Circuit.triphase, 400), isNull);
      // E (52.8F, multiconducteurs)
      expect(iz(ModePose.e, Ame.cuivre, Isolant.pvc, Circuit.triphase, 25), 101);
      expect(iz(ModePose.e, Ame.cuivre, Isolant.pr, Circuit.monophase, 300), 741);
      expect(iz(ModePose.e, Ame.aluminium, Isolant.pr, Circuit.triphase, 240), 409);
      expect(iz(ModePose.e, Ame.cuivre, Isolant.pr, Circuit.triphase, 400), isNull);
      // F (52.8F, monoconducteurs : 3 conducteurs en trèfle)
      expect(iz(ModePose.f, Ame.cuivre, Isolant.pr, Circuit.triphase, 25), 135);
      expect(iz(ModePose.f, Ame.cuivre, Isolant.pvc, Circuit.monophase, 630), 1005);
      expect(iz(ModePose.f, Ame.aluminium, Isolant.pr, Circuit.triphase, 630), 899);
      expect(iz(ModePose.f, Ame.cuivre, Isolant.pr, Circuit.monophase, 10), isNull);
      // Le classeur 2013 donne toujours une valeur par formule.
      expect(
          courantFormule(
              isolant: Isolant.pr,
              circuit: Circuit.triphase,
              mode: ModePose.b,
              ame: Ame.cuivre,
              section: 500,
              edition: EditionNorme.norme2013),
          isNotNull);
    });

    test('formule du classeur : écart avec les tableaux 2024 au plus 12 %', () {
      // Les formules a x S^b du classeur ajustent les tableaux 2024 ; le pire
      // écart relevé (B1, aluminium) est de -11,2 %, le pire excès de +8,2 %
      // (300 mm², PVC 3). Les modes C, E et F sont à moins de 6 %.
      for (final (mode, ame, iso, circ) in [
        (ModePose.c, Ame.cuivre, Isolant.pr, Circuit.triphase),
        (ModePose.e, Ame.cuivre, Isolant.pvc, Circuit.monophase),
        (ModePose.b, Ame.aluminium, Isolant.pvc, Circuit.triphase),
      ]) {
        for (final s in [10.0, 35.0, 120.0, 240.0]) {
          final f = courantFormule(
              isolant: iso, circuit: circ, mode: mode, ame: ame, section: s,
              edition: EditionNorme.norme2013)!;
          final t = courantFormule(
              isolant: iso, circuit: circ, mode: mode, ame: ame, section: s)!;
          expect((f - t).abs() / t, lessThan(0.12), reason: '$mode $ame $s');
        }
      }
    });

    test('mode D en 2024 : tableau 52.8H.2 (D2), sol à 2,5 K·m/W', () {
      double? iz(Ame a, Isolant i, Circuit c, double s) =>
          courantFormule(
              isolant: i, circuit: c, mode: ModePose.d, ame: a, section: s);
      expect(iz(Ame.cuivre, Isolant.pvc, Circuit.triphase, 16), 70);
      expect(iz(Ame.cuivre, Isolant.pvc, Circuit.monophase, 16), 83);
      expect(iz(Ame.cuivre, Isolant.pr, Circuit.triphase, 25), 107);
      expect(iz(Ame.cuivre, Isolant.pr, Circuit.monophase, 300), 502);
      expect(iz(Ame.aluminium, Isolant.pr, Circuit.triphase, 240), 290);
      expect(iz(Ame.aluminium, Isolant.pvc, Circuit.monophase, 16), 63);
      // Sections absentes du tableau : aluminium < 16 mm², plus de 300 mm².
      expect(iz(Ame.aluminium, Isolant.pr, Circuit.triphase, 10), isNull);
      expect(iz(Ame.cuivre, Isolant.pr, Circuit.triphase, 400), isNull);
      // La section 50 n'est pas remplacée par 47,5 dans le tableau 2024.
      expect(iz(Ame.cuivre, Isolant.pvc, Circuit.triphase, 50), 130);
    });

    test('mode D en 2024 : K = K1(sol) x groupement 52.16 x résistivité 52.11', () {
      // 3 circuits à 0,25 m, sol à 1 K.m/W, PR, 20 °C : 1 x 0,80 x 1,5.
      final k = coefficientPourMode(
          ModePose.d,
          Isolant.pr,
          const ParamsK(
              temperature: 20,
              nbCircuits: 3,
              distanceEnterre: DistanceEnterre.m025,
              resistiviteSol: 1.0));
      expect(k, closeTo(0.80 * 1.5, 1e-12));
      // Même cas avec le classeur 2013 : tableau 52R, sans résistivité.
      final k13 = coefficientPourMode(
          ModePose.d,
          Isolant.pr,
          const ParamsK(
              temperature: 20,
              nbCircuits: 3,
              edition: EditionNorme.norme2013,
              distance: DistanceCables.cm25));
      expect(k13, closeTo(0.74, 1e-12));
    });

    test('tableaux 52.16 et 52.11', () {
      expect(k5216(1, DistanceEnterre.nulle), 1);
      expect(k5216(2, DistanceEnterre.nulle), 0.75);
      expect(k5216(6, DistanceEnterre.m05), 0.80);
      expect(k5216(12, DistanceEnterre.m0125), 0.51);
      expect(k5216(20, DistanceEnterre.m025), 0.53);
      expect(k5216(10, DistanceEnterre.nulle), 0.36); // ligne 12 (sécurité)
      expect(k5216(30, DistanceEnterre.nulle), 0.29);
      expect(kResistiviteSol(2.5), 1);
      expect(kResistiviteSol(1.0), 1.5);
      expect(kResistiviteSol(1.0, conduit: true), 1.18);
      expect(kResistiviteSol(0.4), 2.31);
      expect(kResistiviteSol(3.0), 0.9);
      expect(() => kResistiviteSol(1.2), throwsArgumentError);
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

    test('K2 méthodes E et F : tableau 52.13 (un étage, jointifs)', () {
      const ech = {1: 1.0, 2: 0.87, 3: 0.82, 4: 0.80, 6: 0.79, 9: 0.78};
      const per = {1: 1.0, 2: 0.88, 3: 0.82, 4: 0.79, 6: 0.76, 9: 0.73};
      ech.forEach((n, k) =>
          expect(k2MethodesEF(n, tablettePerforee: false), k, reason: 'échelles $n'));
      per.forEach((n, k) =>
          expect(k2MethodesEF(n, tablettePerforee: true), k, reason: 'perforées $n'));
      // Entre deux colonnes : colonne supérieure ; au-delà de 9 : colonne 9.
      expect(k2MethodesEF(5, tablettePerforee: true), 0.76);
      expect(k2MethodesEF(8, tablettePerforee: false), 0.78);
      // Classeur 2013.
      expect(k2MethodesEF(2, tablettePerforee: false, edition: EditionNorme.norme2013), 0.88);
      expect(k2MethodesEF(4, tablettePerforee: true, edition: EditionNorme.norme2013), 0.77);
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
