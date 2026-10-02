// Valeurs de référence : onglets « Ik min CI » (régime ITAN) et
// « Ik min CI GE » (régime TN), cellules M, W, S et R de
// docs/claureg_extraction.md.
import 'package:calcul_electrique_pro/core/calculs/ik_max.dart' show Couplage;
import 'package:calcul_electrique_pro/core/calculs/ik_min.dart';
import 'package:calcul_electrique_pro/core/donnees/courbes_disjoncteurs.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

ProtectionIk _dj(CourbeDisjoncteur c, double ir) =>
    ProtectionIk(reglage: ReglageMagnetique.courbe(c), ir: ir);

void main() {
  group('Ik min CI — source transformateur, régime ITAN', () {
    // 400 V, 500 MVA, 1 transfo Dyn 40 kVA Ucc 5,7 %.
    final source = sourceTransformateur(
      u0: 400,
      pccMva: 500,
      couplage: Couplage.dyn,
      puissanceKva: 40,
      uccPourcent: 5.7,
    );
    final liaisons = [
      const LiaisonIkMin(
          longueur: 1e-06, sectionPhase: 10, sectionPe: 10),
      LiaisonIkMin(
          longueur: 1,
          sectionPhase: 10,
          sectionPe: 10,
          protection: _dj(CourbeDisjoncteur.ma, 40)),
      LiaisonIkMin(
          longueur: 40,
          sectionPhase: 70,
          nbPhasesParPole: 3,
          sectionPe: 70,
          nbPeParPole: 2,
          protection: _dj(CourbeDisjoncteur.b, 200000)),
      LiaisonIkMin(
          ame: Ame.aluminium,
          longueur: 70,
          sectionPhase: 50,
          sectionPe: 25,
          protection: _dj(CourbeDisjoncteur.b, 1)),
      LiaisonIkMin(
          longueur: 10,
          sectionPhase: 16,
          sectionPe: 16,
          protection: _dj(CourbeDisjoncteur.b, 1)),
      LiaisonIkMin(
          longueur: 10,
          sectionPhase: 4,
          sectionPe: 4,
          protection: _dj(CourbeDisjoncteur.b, 20000)),
    ];
    final r = calculerIkMin(source, RegimeNeutre.itan, liaisons);

    test('If à chaque point (M9, M12, M15, M18, M21, M24)', () {
      const attendu = [
        0.45792080239564636,
        0.45499995772278007,
        0.44400967741693115,
        0.32268100956888696,
        0.30403489661335426,
        0.24443170180526816,
      ];
      for (var i = 0; i < attendu.length; i++) {
        expect(r[i].ifKa, closeTo(attendu[i], 1e-9), reason: 'point $i');
      }
    });

    test('impédance cumulée au TGBT (AD12)', () {
      expect(r[0].z, closeTo(0.25153859991329536, 1e-12));
    });

    test('protection assurée ou non (S12, S15, S18, S21, S24)', () {
      // Pas de protection sur la première liaison : sans objet.
      expect(r[0].statut, StatutProtection.nonApplicable);
      expect(r[1].statut, StatutProtection.nonAssuree); // S12
      expect(r[2].statut, StatutProtection.nonAssuree); // S15
      expect(r[3].statut, StatutProtection.assuree); // S18
      expect(r[3].protecteur, 3); // DJ TD3
      expect(r[4].protecteur, 4); // S21 : DJ TD4
      expect(r[5].statut, StatutProtection.assuree); // S24
      expect(r[5].protecteur, 4); // DJ TD4 (celle de TD5 ne déclenche pas)
    });

    test('régime TN : If non réduit (W9)', () {
      final tn = calculerIkMin(source, RegimeNeutre.tn, liaisons);
      expect(tn[0].ifKa, closeTo(0.9158416047912927, 1e-9));
    });
  });

  group('Ik min CI GE — source groupe électrogène, régime TN', () {
    // 230 V, 1 GE de 2500 kVA, x\'d 30 %, x0 6 %.
    final source = sourceGroupe(
        u0: 230, puissanceKva: 2500, xdPourcent: 30, x0Pourcent: 6);
    final liaisons = [
      LiaisonIkMin(
          longueur: 10,
          sectionPhase: 240,
          nbPhasesParPole: 2,
          sectionPe: 120,
          nbPeParPole: 2,
          protection: _dj(CourbeDisjoncteur.c, 2348)),
      LiaisonIkMin(
          ame: Ame.aluminium,
          longueur: 20,
          sectionPhase: 70,
          nbPhasesParPole: 3,
          sectionPe: 50,
          nbPeParPole: 3,
          protection: _dj(CourbeDisjoncteur.c, 1097)),
      LiaisonIkMin(
          longueur: 50,
          sectionPhase: 35,
          sectionPe: 35,
          protection: _dj(CourbeDisjoncteur.c, 171)),
      LiaisonIkMin(
          ame: Ame.aluminium,
          longueur: 30,
          sectionPhase: 25,
          sectionPe: 25,
          protection: _dj(CourbeDisjoncteur.c, 79)),
      LiaisonIkMin(
          longueur: 200,
          sectionPhase: 16,
          sectionPe: 16,
          protection: _dj(CourbeDisjoncteur.c, 17)),
    ];
    final r = calculerIkMin(source, RegimeNeutre.tn, liaisons);

    test('réactance du groupe Xs (Y8)', () {
      expect(source.x, closeTo(0.004655200000000001, 1e-12));
    });

    test('If à chaque point (U11, U14, U17, U20, U23)', () {
      const attendu = [
        23.48034436317482,
        10.976047342480301,
        1.714816043076428,
        0.7989374691736896,
        0.17865401705631911,
      ];
      for (var i = 0; i < attendu.length; i++) {
        expect(r[i].ifKa, closeTo(attendu[i], 1e-9), reason: 'point $i');
      }
    });

    test('impédance cumulée au TGBT (AA11)', () {
      expect(r[0].z, closeTo(0.005641419439290082, 1e-12));
    });

    test('chaque point protégé par la protection de sa liaison (R11…R23)', () {
      for (var i = 0; i < r.length; i++) {
        expect(r[i].statut, StatutProtection.assuree, reason: 'point $i');
        expect(r[i].protecteur, i, reason: 'point $i');
      }
    });
  });

  test('régimes de neutre : facteurs 1 / 0,5 / 0,866', () {
    expect(RegimeNeutre.tn.facteur, 1);
    expect(RegimeNeutre.itan.facteur, 0.5);
    expect(RegimeNeutre.itsn.facteur, 0.8660254038);
  });
}
