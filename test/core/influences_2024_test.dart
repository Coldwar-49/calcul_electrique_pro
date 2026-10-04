// Valeurs de référence : NF C 15-100-1 (2024-08), tableaux 52.3A et 52.4.
import 'package:calcul_electrique_pro/core/calculs/influences_externes.dart';
import 'package:calcul_electrique_pro/core/donnees/influences.dart';
import 'package:calcul_electrique_pro/core/donnees/types.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, int> _niveaux([Map<String, int> surcharge = const {}]) =>
    {...niveauxParDefaut, ...surcharge};

ResultatInfluences _cable(String nom, Map<String, int> n,
        {EditionNorme edition = EditionNorme.normeActuelle}) =>
    evaluerCables(n, edition: edition).firstWhere((r) => r.type.nom == nom);

void main() {
  test('niveaux par défaut (AA4) : seul H05VV-F (AA5 à 6) ne convient plus', () {
    for (final r in evaluerCables(_niveaux())) {
      if (r.type.nom == 'H05VVF') {
        expect(r.contraintes, ['AA']);
      } else {
        expect(r.convient, isTrue, reason: r.type.nom);
      }
    }
  });

  test('température AA : 4 à 6 seulement pour U1000R2V (2013 : tout niveau)', () {
    final hors = _niveaux({'AA': 8});
    expect(_cable('U1000R2V', hors).contraintes, ['AA']);
    expect(_cable('U1000R2V', hors, edition: EditionNorme.norme2013).convient,
        isTrue);
    expect(_cable('U1000R2V', _niveaux({'AA': 3})).contraintes, ['AA']);
    expect(_cable('U1000R2V', _niveaux({'AA': 6})).convient, isTrue);
    // Note (a) : toléré hors plage sans effort mécanique.
    expect(_cable('U1000R2V', hors).remarques.single, contains('mécanique'));
  });

  test('H05VV-F : AA 5 à 6, AH au plus 2', () {
    expect(_cable('H05VVF', _niveaux({'AA': 4})).contraintes, ['AA']);
    expect(_cable('H05VVF', _niveaux({'AA': 5})).convient, isTrue);
    expect(_cable('H05VVF', _niveaux({'AA': 5, 'AH': 3})).contraintes, ['AH']);
    expect(_cable('H05VVF', _niveaux({'AA': 5, 'AH': 3}),
            edition: EditionNorme.norme2013)
        .convient, isTrue);
  });

  test('chocs AG et vibrations AH des câbles H07 RN-F / BN4-F', () {
    expect(_cable('H07RNF', _niveaux({'AG': 4})).contraintes, ['AG']);
    expect(_cable('H07RNF', _niveaux({'AG': 3})).convient, isTrue);
    expect(_cable('H07BN4F', _niveaux({'AH': 3})).contraintes, ['AH']);
  });

  test('U1000RVFV : flore AK2 non admise ; CR1 : eau AD au plus 3', () {
    expect(_cable('U1000RVFV', _niveaux({'AK': 2})).contraintes, ['AK']);
    expect(_cable('CR1', _niveaux({'AD': 4})).contraintes, ['AD']);
    expect(_cable('CR1', _niveaux({'AD': 3})).convient, isTrue);
  });

  test('immersion AD7 : note de durée limitée', () {
    final r = _cable('U1000R2V', _niveaux({'AD': 7}));
    expect(r.convient, isTrue);
    expect(r.remarques.single, contains('deux mois'));
  });

  test('conduits : inchangés (identiques au classeur)', () {
    final a = evaluerConduits(_niveaux());
    final b = evaluerConduits(_niveaux(), edition: EditionNorme.norme2013);
    expect([for (final r in a) r.contraintes], [for (final r in b) r.contraintes]);
  });
}
