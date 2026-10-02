// Valeurs de référence : onglets « Pdc 1 pole IT », « PDC Fusibles » et
// « PDC DM Schneider » (docs/modules/04_filiation_pouvoir_de_coupure.md).
import 'package:calcul_electrique_pro/core/calculs/pouvoir_de_coupure.dart';
import 'package:calcul_electrique_pro/core/donnees/fusibles.dart';
import 'package:calcul_electrique_pro/core/donnees/pouvoir_de_coupure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pdc sous un pôle en schéma IT', () {
    GammeIt gamme(String nom) =>
        gammesIt.firstWhere((g) => g.libelle == nom);

    test('valeurs du classeur (C7:C20)', () {
      expect(gamme('DT 40').pdcKa, 2);
      expect(gamme('C60N').pdcKa, 3);
      expect(gamme('C60L (≤ 25 A)').pdcKa, 6);
      expect(gamme('C60L (≤ 40 A)').pdcKa, 5);
      expect(gamme('C60L (≤ 63 A)').pdcKa, 4);
      expect(gamme('C120H').pdcKa, 4.5);
      expect(gamme('NG125L').pdcKa, 12.5);
      expect(gamme('NG125LMA').pdcKa, 12.5);
      expect(gammesIt.length, 14);
    });
  });

  group('Pdc des fusibles cylindriques', () {
    test('tailles et Pdc gG / aM (D11:J17)', () {
      final t = {for (final x in taillesFusibles) x.libelle: x};
      expect(t['8,5 x 31,5']!.gg.pdcKa, 20);
      expect(t['8,5 x 31,5']!.am.pdcKa, 20);
      expect(t['10 x 38']!.gg.pdcKa, 120);
      expect(t['10 x 38']!.am.pdcKa, 100);
      expect(t['22 x 58']!.gg.calibreMin, 4);
      expect(t['22 x 58']!.am.calibreMin, 16);
      expect(t['22 x 58']!.am.calibreMax, 125);
      expect(pdcFusiblesCouteauxKa, 120);
    });

    test('gG 12 A : les 4 tailles conviennent', () {
      final tailles = taillesPourCalibre(TypeFusible.gg, 12);
      expect(tailles.map((t) => t.libelle).toList(),
          ['8,5 x 31,5', '10 x 38', '14 x 51', '22 x 58']);
    });

    test('aM 12 A : 8,5 x 31,5 (1 à 10 A) et 22 x 58 (16 à 125 A) exclus', () {
      final tailles = taillesPourCalibre(TypeFusible.am, 12);
      expect(tailles.map((t) => t.libelle).toList(), ['10 x 38', '14 x 51']);
    });

    test('calibre hors de toutes les plages', () {
      expect(taillesPourCalibre(TypeFusible.gg, 200), isEmpty);
      expect(taillesPourCalibre(TypeFusible.gg, 0.1), isEmpty);
    });

    test('bornes incluses : gG 125 A et 0,25 A', () {
      expect(taillesPourCalibre(TypeFusible.gg, 125).length, 1);
      expect(taillesPourCalibre(TypeFusible.gg, 0.25).length, 1);
    });
  });

  group('Pdc des disjoncteurs moteurs Schneider', () {
    DisjoncteurMoteur ref(String debut) => disjoncteursMoteurs
        .firstWhere((d) => d.reference.startsWith(debut));

    test('valeurs du classeur (E5:O23)', () {
      expect(ref('GV2 ME 01').pdcKa, 100);
      expect(ref('GV2 ME 16').pdcKa, 15);
      expect(ref('GV2 ME 32').pdcKa, 10);
      expect(ref('GV2 P 20').pdcKa, 50);
      expect(ref('GV2 P 32').pdcKa, 35);
      expect(ref('GV3 ME 80').pdcKa, 15);
      expect(ref('GV2LE 16').pdcKa, 15);
      expect(ref('GV2L 16').pdcKa, 50);
      expect(ref('GV3 L 25').pdcKa, 100);
      expect(ref('GK3 EF 80').pdcKa, 35);
      expect(ref('P25M 14 à 25A').pdcKa, 15);
      expect(ref('P25M 23').pdcKa, 50);
    });

    test('Pdc infini pour le P25M 0,16 à 10 A', () {
      expect(ref('P25M 0,16').pdcKa, double.infinity);
    });
  });

  group('Comparaison Pdc / Ik', () {
    test('Pdc au moins égal au courant', () {
      expect(pdcSuffisant(6, 6), isTrue);
      expect(pdcSuffisant(6, 6.1), isFalse);
      expect(pdcSuffisant(double.infinity, 100000), isTrue);
    });
  });
}
