// Valeurs de référence : onglet « Contrainte Thermique »
// (cellules H9, L9, N9, L13, N13 de docs/claureg_extraction.md).
import 'package:calcul_electrique_pro/core/calculs/contrainte_thermique.dart';
import 'package:calcul_electrique_pro/core/donnees/contrainte_thermique.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fusible : 16/16 mm² cuivre, 230 V, 70 m, k = 143', () {
    final r = calculerContrainteFusible(
      sectionPh: 16,
      sectionN: 16,
      ame: Ame.cuivre,
      u0: 230,
      longueur: 70,
      k: 143,
    );
    expect(r.ikMin, closeTo(751.0204081632653, 1e-9));
    expect(r.temps, closeTo(9.281294706994329, 1e-9));
    expect(r.conforme, isFalse);
    expect(r.sectionRetenue, 16);
  });

  test('disjoncteur : 16/16 mm², 10 kA, k = 143', () {
    final r = calculerContrainteDisjoncteur(
        sectionPh: 16, sectionN: 16, ikKa: 10, k: 143);
    expect(r.temps, closeTo(0.05234944, 1e-12));
    expect(r.conforme, isTrue);
  });

  test('section retenue = la plus petite de Ph et N', () {
    final r = calculerContrainteDisjoncteur(
        sectionPh: 35, sectionN: 16, ikKa: 10, k: 143);
    expect(r.sectionRetenue, 16);
  });

  test('facteur de réactance (I9/J9)', () {
    expect(facteurReactance(16), 1);
    expect(facteurReactance(150), 1);
    expect(facteurReactance(185), 1.2);
    expect(facteurReactance(240), 1.25);
    expect(facteurReactance(300), 1.3);
    expect(facteurReactance(630), 1.3);
  });

  test('table des k (P7:S18, classeur 2013)', () {
    double k(Ame a, IsolantContrainte i, CanalisationPe c) =>
        kContrainteThermique(a, i, c, edition: EditionNorme.norme2013);
    expect(k(Ame.cuivre, IsolantContrainte.prEpr, CanalisationPe.meme), 143);
    expect(k(Ame.aluminium, IsolantContrainte.pvcJusqua300, CanalisationPe.meme), 76);
    expect(k(Ame.cuivre, IsolantContrainte.prEpr, CanalisationPe.differentes), 176);
    expect(k(Ame.aluminium, IsolantContrainte.peNuBe23, CanalisationPe.differentes), 91);
    expect(() => k(Ame.cuivre, IsolantContrainte.peNu, CanalisationPe.meme),
        throwsArgumentError);
  });

  test('table des k 2024 (tableaux 43.1, 54A.2A, 54A.6A)', () {
    double k(Ame a, IsolantContrainte i, CanalisationPe c) =>
        kContrainteThermique(a, i, c);
    expect(k(Ame.cuivre, IsolantContrainte.prEpr, CanalisationPe.meme), 138);
    expect(k(Ame.aluminium, IsolantContrainte.pvcJusqua300, CanalisationPe.meme), 75);
    expect(k(Ame.cuivre, IsolantContrainte.pvcAudessus300, CanalisationPe.meme), 99);
    expect(k(Ame.aluminium, IsolantContrainte.pvcAudessus300, CanalisationPe.meme), 67);
    expect(k(Ame.cuivre, IsolantContrainte.prEpr, CanalisationPe.differentes), 169);
    expect(k(Ame.aluminium, IsolantContrainte.pvcAudessus300, CanalisationPe.differentes), 87);
    expect(k(Ame.cuivre, IsolantContrainte.peNu, CanalisationPe.differentes), 153);
    expect(k(Ame.aluminium, IsolantContrainte.peNuBe23, CanalisationPe.differentes), 90);
    expect(() => k(Ame.cuivre, IsolantContrainte.peNu, CanalisationPe.meme),
        throwsArgumentError);
  });
}
