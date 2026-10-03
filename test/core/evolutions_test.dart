import 'package:calcul_electrique_pro/core/calculs/bilan_puissance.dart';
import 'package:calcul_electrique_pro/core/calculs/compensation_reactive.dart';
import 'package:calcul_electrique_pro/core/calculs/courant_emploi.dart';
import 'package:calcul_electrique_pro/core/calculs/protection_tt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Courant d\'emploi', () {
    test('monophasé 2300 W, 230 V, cos φ 1 -> 10 A', () {
      expect(
          courantEmploi(
              alimentation: Alimentation.monophase,
              puissance: 2300,
              tension: 230,
              cosPhi: 1),
          closeTo(10, 1e-9));
    });
    test('triphasé 10 kW, 400 V, cos φ 0,8 -> 18,04 A', () {
      expect(
          courantEmploi(
              alimentation: Alimentation.triphase,
              puissance: 10000,
              tension: 400,
              cosPhi: 0.8),
          closeTo(18.0422, 1e-3));
    });
    test('moteur triphasé 5,5 kW, rendement 0,9, cos φ 0,85 -> 10,39 A', () {
      expect(
          courantEmploi(
              alimentation: Alimentation.triphase,
              puissance: 5500,
              tension: 400,
              cosPhi: 0.85,
              rendement: 0.9),
          closeTo(10.376, 1e-2));
    });
  });

  group('Bilan de puissance', () {
    test('Σ Pn × Ku × Ks avec Ks global', () {
      final r = calculerBilan(
        lignes: const [
          LigneBilan(nom: 'A', puissance: 10000, ku: 0.8, ks: 1),
          LigneBilan(nom: 'B', puissance: 5000, ku: 1, ks: 0.5),
        ],
        ksGlobal: 0.9,
        alimentation: Alimentation.triphase,
        tension: 400,
        cosPhi: 0.9,
      );
      expect(r.puissanceInstallee, 15000);
      expect(r.puissanceUtilisee, closeTo((8000 + 2500) * 0.9, 1e-9));
      expect(r.puissanceApparente, closeTo(9450 / 0.9, 1e-9));
      expect(r.courantEmploi, closeTo(9450 / (1.7320508 * 400 * 0.9), 1e-3));
    });
  });

  group('Compensation réactive', () {
    test('100 kW, cos φ 0,8 -> 0,95 : Qc ≈ 42,13 kvar', () {
      final r = calculerCompensation(
          puissance: 100000, cosPhiActuel: 0.8, cosPhiVise: 0.95);
      expect(r.puissanceBatterie / 1000, closeTo(42.13, 0.01));
      expect(r.reactifAvant / 1000, closeTo(75, 1e-6));
    });
    test('cos φ identiques -> 0', () {
      final r = calculerCompensation(
          puissance: 5000, cosPhiActuel: 0.9, cosPhiVise: 0.9);
      expect(r.puissanceBatterie, closeTo(0, 1e-9));
    });
  });

  group('Protection TT', () {
    test('30 mA, 50 V -> Ra max 1666,7 Ω', () {
      final r = calculerProtectionTT(sensibilite: 0.03, tensionLimite: 50);
      expect(r.resistanceMax, closeTo(1666.67, 0.01));
      expect(r.conforme, isNull);
    });
    test('300 mA, 25 V, Ra 100 Ω -> non conforme', () {
      final r = calculerProtectionTT(
          sensibilite: 0.3, tensionLimite: 25, resistanceTerre: 100);
      expect(r.resistanceMax, closeTo(83.33, 0.01));
      expect(r.conforme, isFalse);
    });
  });
}
