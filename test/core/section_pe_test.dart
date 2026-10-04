// Valeurs de référence : NF C 15-100-1 (2024-08) tableau 54.3 et 54A.x ;
// minima hors canalisation et formule thermique : guide UTE C 15-106 (2003).
import 'package:calcul_electrique_pro/core/calculs/section_pe.dart';
import 'package:calcul_electrique_pro/core/donnees/k_conducteurs_protection.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

ResultatSectionPe _meme(double s) =>
    calculerSectionPe(sectionPhase: s, amePhase: Ame.cuivre, amePe: Ame.cuivre);

void main() {
  group('Tableau 3, même métal', () {
    test('S ≤ 16 : PE = S', () {
      expect(_meme(2.5).retenue, 2.5);
      expect(_meme(16).retenue, 16);
    });
    test('16 < S ≤ 35 : PE = 16', () {
      expect(_meme(25).retenue, 16);
      expect(_meme(35).retenue, 16);
    });
    test('S > 35 : PE = S/2, arrondi à la section normalisée supérieure', () {
      expect(_meme(70).retenue, 35);
      final r = _meme(95);
      expect(r.calculee, 47.5);
      expect(r.retenue, 50);
      expect(_meme(120).retenue, 70);
    });
  });

  test('métaux différents : multiplié par k1 / k2 (tableaux 2024)', () {
    // Phase aluminium PR/EPR dans le câble (54A.4 : 93), PE cuivre dans le
    // câble PR/EPR (54A.4 : 138) : 35 × 93 / 138 = 23,59 -> 25.
    final k1 = lignesKPhase()[2].k(Ame.aluminium);
    final k2 = ligneK(SituationPe.incorpore, 2).k(Ame.cuivre);
    expect((k1, k2), (93, 138));
    final r = calculerSectionPe(
        sectionPhase: 70,
        amePhase: Ame.aluminium,
        amePe: Ame.cuivre,
        k1: k1,
        k2: k2);
    expect(r.tableau3, closeTo(35 * 93 / 138, 1e-12));
    expect(r.retenue, 25);
  });

  test('k réduit au-delà de 300 mm² (PVC isolé)', () {
    final l = ligneK(SituationPe.incorpore, 0); // PVC 70 °C : 111 / 99
    expect(l.k(Ame.cuivre), 111);
    expect(l.k(Ame.cuivre, gros: true), 99);
    expect(l.k(Ame.aluminium, gros: true), 67);
    // Ligne sans valeur réduite : la même valeur.
    expect(ligneK(SituationPe.incorpore, 2).k(Ame.cuivre, gros: true), 138);
    // Thermique : 100 kA, 1 s -> 100000/111 = 900 mm² > 300 -> k = 99.
    final r = calculerSectionPe(
        sectionPhase: 6,
        amePhase: Ame.cuivre,
        amePe: Ame.cuivre,
        k2: 111,
        k2Gros: 99,
        ikA: 100000,
        temps: 1);
    expect(r.k2Utilise, 99);
    expect(r.thermique, closeTo(100000 / 99, 1e-9));
  });

  test('tableaux de k 2024 : valeurs lues dans la norme', () {
    // 54A.2A, 54A.2B, 54A.3A, 54A.3B, 54A.6A, 54A.6B (cuivre / aluminium).
    expect(ligneK(SituationPe.isoleSepare, 2).k(Ame.cuivre), 169);
    expect(ligneK(SituationPe.isoleSepare, 2).k(Ame.aluminium), 114);
    expect(ligneK(SituationPe.isoleSepareEnterre, 2).k(Ame.cuivre), 175);
    expect(ligneK(SituationPe.nuSurGaine, 1).k(Ame.cuivre), 133);
    expect(ligneK(SituationPe.nuSurGaineEnterre, 1).k(Ame.aluminium), 94);
    expect(ligneK(SituationPe.nuNonEnterre, 0).k(Ame.cuivre), 220);
    expect(ligneK(SituationPe.nuEnterre, 2).k(Ame.cuivre), 140);
    // 54A.5 : gaine métallique (cuivre / aluminium).
    expect(ligneK(SituationPe.gaineMetallique, 0).k(Ame.cuivre), 136);
    expect(ligneK(SituationPe.gaineMetallique, 1).k(Ame.aluminium), 83);
    expect(ligneK(SituationPe.gaineMetallique, 3).k(Ame.cuivre), 139);
    expect(ligneK(SituationPe.gaineMetallique, 4).k(Ame.aluminium), 91);
    // Recoupements entre tableaux (mêmes températures finales).
    expect(ligneK(SituationPe.nuSurGaine, 0).k(Ame.cuivre),
        ligneK(SituationPe.nuNonEnterre, 1).k(Ame.cuivre));
    expect(ligneK(SituationPe.nuSurGaineEnterre, 2).k(Ame.cuivre),
        ligneK(SituationPe.isoleSepareEnterre, 4).k(Ame.cuivre));
  });

  test('PE hors canalisation : minimum mécanique', () {
    final nonProtege = calculerSectionPe(
      sectionPhase: 1.5,
      amePhase: Ame.cuivre,
      amePe: Ame.cuivre,
      horsCanalisation: true,
      protegeMecaniquement: false,
    );
    expect(nonProtege.retenue, 4);
    final protege = calculerSectionPe(
      sectionPhase: 1.5,
      amePhase: Ame.cuivre,
      amePe: Ame.cuivre,
      horsCanalisation: true,
    );
    expect(protege.retenue, 2.5);
    final alu = calculerSectionPe(
      sectionPhase: 10,
      amePhase: Ame.aluminium,
      amePe: Ame.aluminium,
      horsCanalisation: true,
    );
    expect(alu.retenue, 16);
  });

  test('contrainte thermique : √(I²t)/k', () {
    // 10 kA, 0,2 s, k = 143 : 4472,1 / 143 = 31,27 mm² -> 35.
    final r = calculerSectionPe(
      sectionPhase: 6,
      amePhase: Ame.cuivre,
      amePe: Ame.cuivre,
      k2: 143,
      ikA: 10000,
      temps: 0.2,
    );
    expect(r.thermique, closeTo(31.2736, 1e-3));
    expect(r.retenue, 35);
  });

  test('conducteur de terre enterré (tableau 54.2, NF C 15-100-1 2024)', () {
    expect(sectionConducteurTerre(NatureTerre.enterreIsole, 6), 16);
    expect(sectionConducteurTerre(NatureTerre.enterreNuCuivre, 6), 25);
    expect(sectionConducteurTerre(NatureTerre.enterreNuAcier, 6), 50);
    // L'exigence de l'art. 543.1 l'emporte si elle est plus forte.
    expect(sectionConducteurTerre(NatureTerre.enterreNuCuivre, 35), 35);
    // Non enterré : mêmes règles que le PE.
    expect(sectionConducteurTerre(NatureTerre.nonEnterre, 10), 10);
  });
}
