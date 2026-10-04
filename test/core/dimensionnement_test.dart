// L'assistant n'ajoute aucune règle : ses résultats sont ceux des onglets
// Surcharges et Chute de tension appliqués à chaque section.
import 'package:calcul_electrique_pro/core/calculs/chute_tension.dart';
import 'package:calcul_electrique_pro/core/calculs/dimensionnement.dart';
import 'package:calcul_electrique_pro/core/calculs/surcharges.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

ResultatDimensionnement _calcul({
  double ib = 32,
  double longueur = 20,
  Tarif tarif = Tarif.bleu,
}) =>
    dimensionnerCircuit(
      ib: ib,
      isolant: Isolant.pr,
      circuit: Circuit.triphase,
      mode: ModePose.c,
      ame: Ame.cuivre,
      coefficientK: 1,
      longueur: longueur,
      u0: 230,
      cosPhi: 0.8,
      tarif: tarif,
      usage: UsageCircuit.force,
    );

void main() {
  test('chaque candidat reprend les onglets Surcharges et Chute de tension',
      () {
    final r = _calcul();
    for (final c in r.candidats) {
      final s = calculerSurcharge(
        isolant: Isolant.pr,
        circuit: Circuit.triphase,
        mode: ModePose.c,
        ame: Ame.cuivre,
        section: c.section,
        coefficientK: 1,
      );
      expect(c.iz, s.i);
      expect(c.calibre, s.calibre);
      final du = chuteTensionTroncon(LigneChuteTension(
        u0: 230,
        section: c.section,
        longueur: 20,
        cosPhi: 0.8,
        ib: 32,
        usage: UsageCircuit.force,
      ));
      expect(c.chute.deltaU, closeTo(du, 1e-12));
    }
  });

  test('la section retenue est la première conforme et aucune plus petite ne '
      'l\'est', () {
    final r = _calcul();
    final retenu = r.retenu!;
    expect(retenu.conforme, isTrue);
    expect(retenu.calibre, greaterThanOrEqualTo(32));
    for (final c in r.candidats.takeWhile((c) => c != retenu)) {
      expect(c.conforme, isFalse);
    }
  });

  test('une longueur très grande impose une section plus forte', () {
    final court = _calcul(longueur: 10).retenu!;
    final long = _calcul(longueur: 150).retenu!;
    expect(long.section, greaterThan(court.section));
  });

  test('courant démesuré : aucune section ne convient', () {
    expect(_calcul(ib: 5000).retenu, isNull);
  });

  test('aluminium : sections de moins de 10 mm² écartées (tableau 52.19)', () {
    final r = dimensionnerCircuit(
      ib: 5,
      isolant: Isolant.pr,
      circuit: Circuit.triphase,
      mode: ModePose.c,
      ame: Ame.aluminium,
      coefficientK: 1,
      longueur: 10,
      u0: 230,
      cosPhi: 0.8,
      tarif: Tarif.bleu,
      usage: UsageCircuit.force,
    );
    expect(r.candidats.first.section, 10);
    expect(r.candidats.every((c) => c.section >= 10), isTrue);
  });
}
