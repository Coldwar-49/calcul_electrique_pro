// Valeurs de référence : onglets « Résistance PE DJ » et
// « Résistance PE Fusibles » (cellules G9:I9, G16:I16, D9:L9, D16:L16, M16).
import 'package:calcul_electrique_pro/core/calculs/resistance_pe.dart';
import 'package:calcul_electrique_pro/core/donnees/courbes_disjoncteurs.dart';
import 'package:calcul_electrique_pro/core/donnees/fusibles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('petit disjoncteur : 230 V, courbe C, 10 A, Sph/Spe = 1', () {
    final r = resistanceMaxPetitDisjoncteur(
        u0: 230, courbe: CourbeDisjoncteur.c, ir: 10, rapportSphSpe: 1);
    expect(r.tn, closeTo(1150, 1e-9)); // G9
    expect(r.itan, closeTo(575, 1e-9)); // H9
    expect(r.itsn, closeTo(995.9, 1e-9)); // I9
  });

  test('disjoncteur industriel : 400 V, 5 × Ir, Ir 10 A, Sph/Spe = 1', () {
    final r = resistanceMaxDisjoncteurIndustriel(
        u0: 400, multipleIr: 5, ir: 10, rapportSphSpe: 1);
    expect(r.tn, closeTo(4000, 1e-9)); // G16
    expect(r.itan, closeTo(2000, 1e-9)); // H16
    expect(r.itsn, closeTo(3464, 1e-9)); // I16
  });

  test('fusible gG 10 A sous 127 V', () {
    final r = resistanceMaxFusible(
        u0: 127, type: TypeFusible.gg, calibre: 10, rapportSphSpe: 1);
    expect(r.ia, closeTo(83.94160583941606, 1e-12)); // D9
    expect(r.terminaux.tn, closeTo(756.4782608695652, 1e-9)); // G9
    expect(r.terminaux.itan, closeTo(378.2391304347826, 1e-9)); // H9
    expect(r.terminaux.itsn, closeTo(655.1101739130435, 1e-9)); // I9
    expect(r.divisionnaires.tn, closeTo(1422.1791304347826, 1e-9)); // J9
    expect(r.divisionnaires.itan, closeTo(711.0895652173913, 1e-9)); // K9
    expect(r.divisionnaires.itsn, closeTo(1231.6071269565216, 1e-9)); // L9
  });

  test('fusible aM 10 A sous 400 V', () {
    final r = resistanceMaxFusible(
        u0: 400, type: TypeFusible.am, calibre: 10, rapportSphSpe: 1);
    expect(r.ia, closeTo(129.2134831460674, 1e-12)); // D16
    expect(r.terminaux.tn, closeTo(1547.826086956522, 1e-9)); // G16
    expect(r.terminaux.itan, closeTo(773.913043478261, 1e-9)); // H16
    expect(r.terminaux.itsn, closeTo(1340.417391304348, 1e-9)); // I16
    expect(r.divisionnaires.tn, closeTo(2368.1739130434785, 1e-9)); // J16
    expect(r.divisionnaires.itan, closeTo(1184.0869565217392, 1e-9)); // K16
    expect(r.divisionnaires.itsn, closeTo(2050.8386086956525, 1e-9)); // L16
  });

  test('k2 selon Sph/Spe (F9)', () {
    expect(k2Rapport(1), 1);
    expect(k2Rapport(2), 1.33);
    expect(k2Rapport(3), 1.5);
    expect(() => k2Rapport(4), throwsArgumentError);
  });

  test('rapport Sph/Spe = 2 : Rmax × 1,33', () {
    final base = resistanceMaxPetitDisjoncteur(
        u0: 230, courbe: CourbeDisjoncteur.c, ir: 10, rapportSphSpe: 1);
    final r2 = resistanceMaxPetitDisjoncteur(
        u0: 230, courbe: CourbeDisjoncteur.c, ir: 10, rapportSphSpe: 2);
    expect(r2.tn, closeTo(base.tn * 1.33, 1e-9));
  });

  test('table des fusibles : RECHERCHE du plus grand calibre <= saisie', () {
    expect(courantIa(TypeFusible.gg, 63), closeTo(547.6190476190476, 1e-12));
    expect(courantIa(TypeFusible.gg, 70), closeTo(547.6190476190476, 1e-12));
    expect(courantIa(TypeFusible.am, 1000), closeTo(12777.77777777778, 1e-9));
    expect(() => courantIa(TypeFusible.gg, 6), throwsArgumentError);
    expect(calibresFusible(TypeFusible.gg).length, 20);
  });

  test('calculatrice Ir (M16) : 200 × 0,9 × 0,93', () {
    expect(
        calculerIr(courantNominal: 200, facteur1: 0.9, facteur2: 0.93),
        closeTo(167.4, 1e-9));
  });
}
