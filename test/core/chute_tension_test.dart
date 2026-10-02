// Valeurs de référence : cellules R5:U10 de l'onglet « Chute de tension »
// (docs/claureg_extraction.md), tarif Vert.
import 'package:calcul_electrique_pro/core/calculs/chute_tension.dart';
import 'package:flutter_test/flutter_test.dart';

LigneChuteTension _ligne(double s, double l, double ib, UsageCircuit u) =>
    LigneChuteTension(
      circuit: SchemaCircuit.triphaseEquilibre,
      u0: 230,
      section: s,
      longueur: l,
      cosPhi: 0.8,
      ib: ib,
      tarif: Tarif.vert,
      usage: u,
    );

void main() {
  final lignes = [
    _ligne(1.5, 112, 10, UsageCircuit.eclairage),
    _ligne(2.5, 0.1, 10, UsageCircuit.eclairage),
    _ligne(4, 0.1, 25, UsageCircuit.eclairage),
    _ligne(6, 58, 25, UsageCircuit.force),
    _ligne(10, 0.54, 70, UsageCircuit.force),
    _ligne(16, 1, 10, UsageCircuit.force),
  ];
  final r = calculerChuteTension(lignes);

  test('ΔU par tronçon (R5:R10)', () {
    const attendu = [
      13.792426666666666,
      0.007408,
      0.01162,
      4.5162666666666675,
      0.07136640000000001,
      0.011980000000000001,
    ];
    for (var i = 0; i < attendu.length; i++) {
      expect(r[i].deltaU, closeTo(attendu[i], 1e-9), reason: 'ligne ${i + 5}');
    }
  });

  test('cumul en volts et en % (S5:T10)', () {
    expect(r[0].cumulV, closeTo(13.792426666666666, 1e-9));
    expect(r[3].cumulV, closeTo(18.327721333333333, 1e-9));
    expect(r[5].cumulV, closeTo(18.411067733333333, 1e-9));
    expect(r[3].ratio, closeTo(0.07968574492753623, 1e-12));
  });

  test('conformité (U5:U10)', () {
    expect(r.map((e) => e.conforme).toList(),
        [true, true, false, true, true, false]);
  });

  test('seuils tarif/usage', () {
    expect(seuilChuteTension(Tarif.bleu, UsageCircuit.eclairage), 0.03);
    expect(seuilChuteTension(Tarif.bleu, UsageCircuit.force), 0.05);
    expect(seuilChuteTension(Tarif.jaune, UsageCircuit.eclairage), 0.03);
    expect(seuilChuteTension(Tarif.jaune, UsageCircuit.force), 0.05);
    expect(seuilChuteTension(Tarif.vert, UsageCircuit.eclairage), 0.06);
    expect(seuilChuteTension(Tarif.vert, UsageCircuit.force), 0.08);
  });

  test('monophasé : coefficient b = 2', () {
    final mono = chuteTensionTroncon(
        _ligne(2.5, 20, 10, UsageCircuit.force)
            .copyWith(circuit: SchemaCircuit.monophase));
    final tri = chuteTensionTroncon(_ligne(2.5, 20, 10, UsageCircuit.force));
    expect(mono, closeTo(2 * tri, 1e-12));
  });
}
