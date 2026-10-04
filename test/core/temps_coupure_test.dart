// Valeurs de référence : NF C 15-100-1 (2024-08), tableau 41.1.
import 'package:calcul_electrique_pro/core/calculs/protection_tt.dart';
import 'package:calcul_electrique_pro/core/donnees/tableau_53_1.dart';
import 'package:calcul_electrique_pro/core/donnees/temps_coupure.dart';
import 'package:calcul_electrique_pro/core/calculs/chute_tension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tableau 41.1, courant alternatif', () {
    expect(tempsCoupureMax(230, SchemaTemps.tn), 0.4);
    expect(tempsCoupureMax(230, SchemaTemps.tt), 0.2);
    expect(tempsCoupureMax(400, SchemaTemps.tn), 0.2);
    expect(tempsCoupureMax(400, SchemaTemps.tt), 0.07);
    expect(tempsCoupureMax(120, SchemaTemps.tn), 0.8);
    expect(tempsCoupureMax(120, SchemaTemps.tt), 0.3);
    expect(tempsCoupureMax(690, SchemaTemps.tn), 0.1);
    expect(tempsCoupureMax(690, SchemaTemps.tt), 0.04);
  });

  test('tableau 41.1, courant continu lissé', () {
    expect(tempsCoupureMax(230, SchemaTemps.tn, continu: true), 5);
    expect(tempsCoupureMax(230, SchemaTemps.tt, continu: true), 0.4);
    expect(tempsCoupureMax(400, SchemaTemps.tt, continu: true), 0.2);
    expect(tempsCoupureMax(500, SchemaTemps.tn, continu: true), 0.1);
  });

  test('U0 ≤ 50 V : hors tableau', () {
    expect(tempsCoupureMax(50, SchemaTemps.tn), isNull);
  });

  test('majoration du seuil de chute de tension (tableau 52.23)', () {
    expect(majorationSeuilLongueur(80), 0);
    expect(majorationSeuilLongueur(100), 0);
    expect(majorationSeuilLongueur(200), closeTo(0.005, 1e-12)); // 100 m -> 0,5 %
    expect(majorationSeuilLongueur(150), closeTo(0.0025, 1e-12));
    expect(majorationSeuilLongueur(500), closeTo(0.005, 1e-12)); // plafond
    const l = LigneChuteTension(longueur: 150);
    final sans = calculerChuteTension([l]).single.seuil;
    final avec =
        calculerChuteTension([l], majorerSeuilLongueur: true).single.seuil;
    expect(avec - sans, closeTo(0.0025, 1e-12));
    // Deux tronçons : la longueur totale compte.
    final deux = calculerChuteTension(
        [const LigneChuteTension(longueur: 75), const LigneChuteTension(longueur: 75)],
        majorerSeuilLongueur: true);
    expect(deux.last.seuil - sans, closeTo(0.0025, 1e-12));
  });

  test('tableau 53.1 : valeurs arrondies, cohérentes avec 50 V / IΔn', () {
    for (final (idn, r) in tableau531) {
      final calcule = calculerProtectionTT(sensibilite: idn, tensionLimite: 50)
          .resistanceMax;
      expect(r, closeTo(calcule, 0.5), reason: 'IΔn = $idn A');
    }
    expect(resistanceTableau531(0.3), 167);
    expect(resistanceTableau531(0.03), 500); // « > 500 »
    expect(resistanceTableau531(0.02), isNull);
  });
}
