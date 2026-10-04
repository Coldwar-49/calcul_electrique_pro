// Valeurs de référence : NF C 15-100-1 (2024-08), tableau 52.20 et 524.2.3.
import 'package:calcul_electrique_pro/core/calculs/section_neutre.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:calcul_electrique_pro/core/donnees/coefficients_k.dart';
import 'package:flutter_test/flutter_test.dart';

ResultatNeutre _n(double th3,
        {double ib = 100,
        bool tri = true,
        CableNeutre cable = CableNeutre.multiconducteur,
        double s = 35,
        Ame ame = Ame.cuivre,
        bool protege = false}) =>
    calculerNeutre(
        ib: ib,
        th3Pourcent: th3,
        triphase: tri,
        cable: cable,
        sectionPhase: s,
        ame: ame,
        neutreProtege: protege);

void main() {
  test('cas selon TH3', () {
    expect(<double>[0, 15, 15.1, 33, 33.1, 45, 45.1].map(casHarmoniques),
        [1, 1, 2, 2, 3, 3, 4]);
  });

  test('cas 1 (TH3 ≤ 15 %) : neutre réductible si 524.2.3 satisfait', () {
    final r = _n(10, s: 35, protege: true);
    expect(r.cas, 1);
    expect(r.neutreReductibleAdmis, isTrue);
    expect(r.sectionNeutreMinimale, 16);
    expect(r.courantNeutre, 50);
    // Section de phase trop petite, ou neutre non protégé : neutre = phase.
    expect(_n(10, s: 16, protege: true).neutreReductibleAdmis, isFalse);
    expect(_n(10, s: 35).neutreReductibleAdmis, isFalse);
    // Aluminium : seuil 25 mm².
    expect(_n(10, s: 25, ame: Ame.aluminium, protege: true)
        .neutreReductibleAdmis, isFalse);
    expect(_n(10, s: 35, ame: Ame.aluminium, protege: true)
        .sectionNeutreMinimale, 25);
  });

  test('cas 2 (15 à 33 %) : IB de phase = IB / 0,86, neutre = phase', () {
    final r = _n(20);
    expect(r.cas, 2);
    expect(r.courantPhase, closeTo(100 / 0.86, 1e-9));
    expect(r.neutreEgalPhase, isTrue);
  });

  test('cas 3 (33 à 45 %) : IB neutre = IB × TH3 × 3 / 0,86', () {
    final r = _n(40);
    expect(r.cas, 3);
    expect(r.courantNeutre, closeTo(100 * 0.4 * 3 / 0.86, 1e-9));
    expect(r.neutreEgalPhase, isTrue);
    final m = _n(40, cable: CableNeutre.monoconducteur);
    expect(m.neutreSuperieurPhase, isTrue);
    expect(m.courantPhase, 100);
  });

  test('cas 4 (> 45 %) : multiconducteur IB × TH3 × 3, mono ÷ 0,86', () {
    final r = _n(60);
    expect(r.cas, 4);
    expect(r.courantNeutre, closeTo(100 * 0.6 * 3, 1e-9));
    final m = _n(60, cable: CableNeutre.monoconducteur);
    expect(m.courantNeutre, closeTo(100 * 0.6 * 3 / 0.86, 1e-9));
    expect(m.neutreSuperieurPhase, isTrue);
  });

  test('monophasé : le neutre porte le courant de la phase', () {
    final r = _n(60, tri: false);
    expect(r.courantNeutre, 100);
    expect(r.courantPhase, 100);
  });

  test('K5 : 0,86 (2024) ou 0,84 (classeur 2013)', () {
    expect(kHarmoniques(true), 0.86);
    expect(kHarmoniques(true, edition: EditionNorme.norme2013), 0.84);
    expect(kHarmoniques(false), 1);
  });
}
