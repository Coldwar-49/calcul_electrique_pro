// Valeurs de référence : onglet « Icc Max » (cellules P8, N11:P29).
import 'package:calcul_electrique_pro/core/calculs/ik_max.dart';
import 'package:flutter_test/flutter_test.dart';

LiaisonIkMax _cu(double l, double sp, double sn) => LiaisonIkMax(
      longueur: l,
      sectionPhase: sp,
      sectionNeutre: sn,
    );

void main() {
  // 500 MVA, Dyn 630 kVA, Ucc 4 %, U = 400 V, transfo récent.
  const reseau = ReseauAmont();
  final liaisons = [
    _cu(6, 25, 25),
    _cu(30, 35, 35),
    _cu(50, 120, 120),
    _cu(10, 120, 16),
    _cu(50, 10, 10),
    _cu(80, 2.5, 2.5),
    _cu(50, 1.5, 1.5),
  ];
  final r = calculerIkMax(reseau, liaisons);

  test('Ik3 au secondaire du transformateur (P8)', () {
    expect(r.ik3Transfo, closeTo(22.069746968331277, 1e-9));
  });

  test('Ik3 à chaque point (N11, N14, N17, N20, N23, N26, N29)', () {
    const attendu = [
      18.2439691824267,
      9.23861205367444,
      7.0258197442910015,
      6.7045694722982745,
      1.9946711902190286,
      0.3543616138186087,
      0.19067583514850778,
    ];
    for (var i = 0; i < attendu.length; i++) {
      expect(r.points[i].ik3, closeTo(attendu[i], 1e-9), reason: 'point $i');
    }
  });

  test('Ik2 = 0,866 × Ik3 (O11, O14)', () {
    expect(r.points[0].ik2, closeTo(15.799277311981522, 1e-9));
    expect(r.points[1].ik2, closeTo(8.000638038482066, 1e-9));
  });

  test('Ik1 à chaque point (P11, P14, P17, P20, P23, P26, P29)', () {
    const attendu = [
      14.78977156170844,
      5.394922299877799,
      3.9483551103785257,
      3.294319022696481,
      0.9791588009265123,
      0.17643030962802891,
      0.09511468234465695,
    ];
    for (var i = 0; i < attendu.length; i++) {
      expect(r.points[i].ik1, closeTo(attendu[i], 1e-9), reason: 'point $i');
    }
  });

  test('impédance cumulée Z triphasée au TGBT (W14)', () {
    expect(r.points[0].z3, closeTo(0.013956334561757574, 1e-12));
  });

  test('transfo avant juillet 2003 : tension sans le facteur 1,05', () {
    final ancien = calculerIkMax(
        reseau.copyWith(transfoAvant2003: true), [_cu(6, 25, 25)]);
    // I8 = 1 au lieu de 1,05 : Ik proportionnel à 1/1,05.
    expect(ancien.points[0].ik3, closeTo(r.points[0].ik3 / 1.05, 1e-9));
  });
}
