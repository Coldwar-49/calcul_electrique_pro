// Valeurs de référence : NF C 15-100-1 (2024-08), tableau 52.24.
import 'package:calcul_electrique_pro/core/calculs/chute_tension.dart';
import 'package:calcul_electrique_pro/core/donnees/sections_resistivites.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('résistivités du tableau 52.24', () {
    expect(ResistiviteService.caoutchouc60.pour(Ame.cuivre), 0.0215);
    expect(ResistiviteService.pvc70.pour(Ame.cuivre), 0.0222);
    expect(ResistiviteService.pvc90.pour(Ame.cuivre), 0.0237);
    expect(ResistiviteService.pr90.pour(Ame.cuivre), 0.0237);
    expect(ResistiviteService.pr120.pour(Ame.cuivre), 0.0259);
    expect(ResistiviteService.caoutchouc60.pour(Ame.aluminium), 0.0341);
    expect(ResistiviteService.pvc70.pour(Ame.aluminium), 0.0353);
    expect(ResistiviteService.pr90.pour(Ame.aluminium), 0.0376);
    expect(ResistiviteService.pr120.pour(Ame.aluminium), 0.0412);
  });

  test('ΔU : la valeur du classeur reste le défaut, ρ 2024 en option', () {
    const l = LigneChuteTension(
        section: 10, longueur: 50, cosPhi: 1, ib: 20, usage: UsageCircuit.force);
    final classeur = chuteTensionTroncon(l);
    // 1 × 20 × 0,023 × 50 / 10 = 2,3 V (triphasé équilibré, b = 1, cos φ = 1)
    expect(classeur, closeTo(2.3, 1e-9));
    final pr =
        chuteTensionTroncon(l.copyWith(resistivite: ResistiviteService.pr90));
    expect(pr, closeTo(20 * 0.0237 * 50 / 10, 1e-9));
    expect(pr, greaterThan(classeur));
  });
}
