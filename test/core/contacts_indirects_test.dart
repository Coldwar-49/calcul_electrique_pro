// Valeurs de référence : onglets « TN + IT avec M=1 », « TN + IT avec M>1 »,
// « TN et IT Fusibles m=1 » et « TN et IT Fusibles m>1 ».
import 'package:calcul_electrique_pro/core/calculs/contacts_indirects.dart';
import 'package:calcul_electrique_pro/core/calculs/ik_min.dart'
    show RegimeNeutre;
import 'package:calcul_electrique_pro/core/donnees/courbes_disjoncteurs.dart';
import 'package:calcul_electrique_pro/core/donnees/fusibles.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

const _courbeC = ReglageMagnetique.courbe(CourbeDisjoncteur.c);
const _industriel = ReglageMagnetique.multipleIr(10);

void main() {
  group('Disjoncteurs, Sph = Spe (m = 1)', () {
    test('petit disjoncteur C 10 A, 1,5 mm² cuivre (M11, N11, O11)', () {
      final r = longueurMaxDisjoncteurSphEgalSpe(
        reglage: _courbeC,
        ir: 10,
        section: 1.5,
        nbConducteurs: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.tn, closeTo(60.00000000000001, 1e-9));
      expect(r.itan, closeTo(30.000000000000004, 1e-9));
      expect(r.itsn, closeTo(51.60000000000001, 1e-9));
    });

    test('disjoncteur industriel 10 × Ir, 10 A (M16, N16, O16)', () {
      final r = longueurMaxDisjoncteurSphEgalSpe(
        reglage: _industriel,
        ir: 10,
        section: 1.5,
        nbConducteurs: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.tn, closeTo(49.99999999999999, 1e-9));
      expect(r.itan, closeTo(24.999999999999996, 1e-9));
      expect(r.itsn, closeTo(42.99999999999999, 1e-9));
    });
  });

  group('Disjoncteurs, Sph ≠ Spe (m > 1)', () {
    test('petit disjoncteur C 10 A, Sph = Spe = 1,5 mm² (O11, P11, Q11)', () {
      final r = longueurMaxDisjoncteurSphDiffSpe(
        reglage: _courbeC,
        ir: 10,
        sectionPh: 1.5,
        nbPh: 1,
        sectionPe: 1.5,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.tn, closeTo(60.00000000000001, 1e-9));
      expect(r.itan, closeTo(30.000000000000004, 1e-9));
      expect(r.itsn, closeTo(51.60000000000001, 1e-9));
    });

    test('industriel 10 × Ir (O16, P16, Q16)', () {
      final r = longueurMaxDisjoncteurSphDiffSpe(
        reglage: _industriel,
        ir: 10,
        sectionPh: 1.5,
        nbPh: 1,
        sectionPe: 1.5,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.tn, closeTo(50, 1e-9));
      expect(r.itan, closeTo(25, 1e-9));
      expect(r.itsn, closeTo(43, 1e-9));
    });

    test('PE plus petit que la phase : longueur réduite', () {
      final egal = longueurMaxDisjoncteurSphDiffSpe(
        reglage: _courbeC,
        ir: 10,
        sectionPh: 16,
        nbPh: 1,
        sectionPe: 16,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      final petit = longueurMaxDisjoncteurSphDiffSpe(
        reglage: _courbeC,
        ir: 10,
        sectionPh: 16,
        nbPh: 1,
        sectionPe: 10,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(petit.tn, lessThan(egal.tn));
    });
  });

  group('Fusibles, Sph = Spe (m = 1)', () {
    test('gG 16 A, 1,5 mm² (L13, N13, O13, J13)', () {
      final r = longueurMaxFusibleSphEgalSpe(
        type: TypeFusible.gg,
        calibre: 16,
        section: 1.5,
        nbConducteurs: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.terminaux.tn, closeTo(52.69565217391304, 1e-9));
      expect(r.terminaux.itan, closeTo(26.34782608695652, 1e-9));
      expect(r.terminaux.itsn, closeTo(45.318260869565215, 1e-9));
      expect(r.distribution(RegimeNeutre.tn), closeTo(99.06782608695652, 1e-9));
      expect(r.itsnNonFiable, isFalse);
    });

    test('aM 16 A, 1,5 mm² (L20, N20, O20, J20)', () {
      final r = longueurMaxFusibleSphEgalSpe(
        type: TypeFusible.am,
        calibre: 16,
        section: 1.5,
        nbConducteurs: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.terminaux.tn, closeTo(28.695652173913047, 1e-9));
      expect(r.terminaux.itan, closeTo(14.347826086956523, 1e-9));
      expect(r.terminaux.itsn, closeTo(24.678260869565218, 1e-9));
      expect(r.distribution(RegimeNeutre.tn), closeTo(43.90434782608696, 1e-9));
    });
  });

  group('Fusibles, Sph ≠ Spe (m > 1)', () {
    test('gG 16 A (O13, Q13, R13, M13)', () {
      final r = longueurMaxFusibleSphDiffSpe(
        type: TypeFusible.gg,
        calibre: 16,
        sectionPh: 1.5,
        nbPh: 1,
        sectionPe: 1.5,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.terminaux.tn, closeTo(52.69565217391305, 1e-9));
      expect(r.terminaux.itan, closeTo(26.347826086956523, 1e-9));
      // R13 du classeur (formule sans Ia, reproduite à l'identique).
      expect(r.terminaux.itsn, closeTo(5160, 1e-9));
      expect(r.distribution(RegimeNeutre.tn), closeTo(99.06782608695652, 1e-9));
      expect(r.itsnNonFiable, isTrue);
    });

    test('aM 16 A : coefficient 1,88 du classeur (M20)', () {
      final r = longueurMaxFusibleSphDiffSpe(
        type: TypeFusible.am,
        calibre: 16,
        sectionPh: 1.5,
        nbPh: 1,
        sectionPe: 1.5,
        nbPe: 1,
        ame: Ame.cuivre,
        tensionPhN: 230,
        tensionPhPh: 400,
      );
      expect(r.terminaux.tn, closeTo(28.695652173913047, 1e-9));
      expect(r.terminaux.itsn, closeTo(5160, 1e-9));
      expect(r.distribution(RegimeNeutre.tn), closeTo(53.947826086956525, 1e-9));
    });
  });

  group('Tables de facteurs (RECHERCHE)', () {
    test('ITSN disjoncteurs : 220 -> 0,47, 400 -> 0,86, 1000 -> 2,17', () {
      expect(rechercheFacteur(facteurItsnDisjoncteur, 220), 0.47);
      expect(rechercheFacteur(facteurItsnDisjoncteur, 410), 0.86);
      expect(rechercheFacteur(facteurItsnDisjoncteur, 690), 1.5);
      expect(rechercheFacteur(facteurItsnDisjoncteur, 1000), 2.17);
    });

    test('ITSN fusibles : 690 -> 1,25, 1000 -> 1,53', () {
      expect(rechercheFacteur(facteurItsnFusible, 690), 1.25);
      expect(rechercheFacteur(facteurItsnFusible, 1000), 1.53);
    });

    test('TN fusibles : 127 -> 0,55, 230 -> 1, 400 -> 1,45, 580 -> 1,78', () {
      expect(rechercheFacteur(facteurTnFusible, 127), 0.55);
      expect(rechercheFacteur(facteurTnFusible, 230), 1);
      expect(rechercheFacteur(facteurTnFusible, 400), 1.45);
      expect(rechercheFacteur(facteurTnFusible, 580), 1.78);
    });

    test('tension sous la table -> ArgumentError', () {
      expect(() => rechercheFacteur(facteurItsnDisjoncteur, 100),
          throwsArgumentError);
    });
  });
}
