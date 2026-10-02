// Valeurs de référence : module « Données de référence » (docs/modules/03).
import 'package:calcul_electrique_pro/core/calculs/choix_table_article.dart';
import 'package:calcul_electrique_pro/core/calculs/influences_externes.dart';
import 'package:calcul_electrique_pro/core/donnees/choix_table_article.dart';
import 'package:calcul_electrique_pro/core/donnees/influences.dart';
import 'package:calcul_electrique_pro/core/donnees/influences_cables_conduits.dart';
import 'package:flutter_test/flutter_test.dart';

ResultatInfluences cable(String nom, Map<String, int> niveaux) => evaluerType(
    typesCables.firstWhere((t) => t.nom == nom), niveaux);

ResultatInfluences conduit(String nom, Map<String, int> niveaux) => evaluerType(
    typesConduits.firstWhere((t) => t.nom == nom), niveaux);

Map<String, int> niveaux([Map<String, int> changements = const {}]) =>
    {...niveauxParDefaut, ...changements};

void main() {
  group('Influences externes — données', () {
    test('8 câbles et 9 conduits, 14 influences chacun', () {
      expect(typesCables.length, 8);
      expect(typesConduits.length, 9);
      for (final t in [...typesCables, ...typesConduits]) {
        expect(t.regles.keys.toSet(), glossaireInfluences.keys.toSet(),
            reason: t.nom);
      }
    });

    test('glossaire : nombre de niveaux de chaque influence', () {
      const attendu = {
        'AA': 8, 'AD': 8, 'AE': 4, 'AF': 4, 'AG': 4, 'AH': 3, 'AK': 2,
        'AL': 2, 'BB': 3, 'BC': 4, 'BD': 4, 'BE': 4, 'CA': 2, 'CB': 4,
      };
      attendu.forEach((code, n) {
        expect(glossaireInfluences[code]!.niveaux.length, n, reason: code);
      });
      expect(glossaireInfluences['AA']!.niveaux[3], '-5 à +40°C'); // AA4
      expect(glossaireInfluences['AD']!.niveaux[6], 'Immersion'); // AD7
    });

    test('niveaux par défaut du classeur et ordre de saisie', () {
      expect(niveauxParDefaut['AA'], 4);
      expect(niveauxParDefaut['BC'], 3);
      expect(ordreSaisieInfluences.length, 14);
      expect(niveauxParDefaut.keys.toSet(), ordreSaisieInfluences.toSet());
    });
  });

  group('Influences externes — câbles (niveaux par défaut)', () {
    test('tous les câbles conviennent aux niveaux par défaut', () {
      for (final r in evaluerCables(niveaux())) {
        expect(r.convient, isTrue, reason: r.type.nom);
      }
    });

    test('conduits : seuls MRL, CSA et Moulures Bois restent contraints (BC)', () {
      for (final r in evaluerConduits(niveaux())) {
        if (['MRL', 'CSA', 'Moulures Bois'].contains(r.type.nom)) {
          expect(r.contraintes, ['BC'], reason: r.type.nom);
          expect(r.type.usageCourant, isFalse);
        } else {
          expect(r.convient, isTrue, reason: r.type.nom);
        }
      }
    });
  });

  group('Influences externes — scénarios', () {
    test('AA2 (-40 à +5°C) : H07RNF et H05RNF contraints, U1000R2V non', () {
      final n = niveaux({'AA': 2});
      expect(cable('U1000R2V', n).convient, isTrue);
      expect(cable('H07RNF', n).contraintes, ['AA']); // AA < 3
      expect(cable('H05RNF', n).contraintes, ['AA']);
      expect(conduit('ICTL', n).contraintes, ['AA']); // AA < 4
    });

    test('AA2 : remarque « absence d\'effort mécanique » du H07RN8F', () {
      final r = cable('H07RN8F', niveaux({'AA': 2}));
      expect(r.remarques, ['Toléré si absence d\'effort mécanique (AA)']);
      expect(r.convient, isTrue);
      expect(cable('H07RN8F', niveaux({'AA': 5})).remarques, isEmpty);
      expect(cable('H07RN8F', niveaux({'AA': 7})).remarques.length, 1);
    });

    test('AD7 (immersion) : H05VVF contraint, H07RNF toléré sous condition', () {
      final n = niveaux({'AD': 7});
      expect(cable('H05VVF', n).contraintes, ['AD']); // AD > 6
      expect(cable('U1000R2V', n).convient, isTrue); // AD > 7 seulement
      expect(cable('H07RNF', n).remarques,
          ['Toléré si immersion limitée à 2 mois par an (AD)']);
    });

    test('CB2 : égalité à 2 contraignante pour H07BN4F, pas pour CR1', () {
      final n = niveaux({'CB': 2});
      expect(cable('H07BN4F', n).contraintes, ['CB']); // = 2
      expect(cable('CR1', n).convient, isTrue); // > 2
      expect(cable('U1000R2V', n).contraintes, ['CB']); // > 1
      expect(cable('H07BN4F', niveaux({'CB': 3})).convient, isTrue); // ≠ 2
    });

    test('BC4 : U1000RVFV contraint, remarque 250 V pour H05RNF', () {
      final n = niveaux({'BC': 4});
      expect(cable('U1000RVFV', n).contraintes, ['BC']); // > 3
      expect(cable('H05RNF', n).remarques, [
        'Toléré si tension nominale d\'alimentation par rapport à la terre au plus égale à 250 V (BC)'
      ]);
      expect(cable('H05RNF', niveaux({'BC': 3})).remarques, isEmpty);
    });

    test('remarques constantes (U1000RVFV, H05VVF, CR1)', () {
      expect(cable('U1000RVFV', niveaux()).remarques,
          ['Toléré si revétements métalliques reliés à la terre (BC)']);
      expect(cable('H05VVF', niveaux()).remarques,
          ['Toléré si absence d\'effort mécanique (AA)']);
      expect(cable('CR1', niveaux()).remarques, ['Si AN>2 voir doc. fabr.']);
    });

    test('plusieurs contraintes, dans l\'ordre du classeur', () {
      final n = niveaux({'AE': 4, 'AD': 8, 'AG': 4, 'BE': 4});
      expect(conduit('Goulottes', n).contraintes, ['AD', 'AE', 'AG', 'BE']);
    });

    test('Goulottes : AA hors 4 à 6 contraignant', () {
      expect(conduit('Goulottes', niveaux({'AA': 3})).contraintes, ['AA']);
      expect(conduit('Goulottes', niveaux({'AA': 7})).contraintes, ['AA']);
      expect(conduit('Goulottes', niveaux({'AA': 6})).convient, isTrue);
    });
  });

  group('Choix de la table article', () {
    test('186 lignes, 126 tables, 9 critères', () {
      expect(choixTableArticle.length, 186);
      expect(choixTableArticle.map((l) => l.table).toSet().length, 126);
      expect(nbCriteresTable, 9);
    });

    test('lignes du classeur (A7, A8, A35, A192)', () {
      expect(tablesArticle(['TT', 'BAES', 'Non', 'Non', 'Non', 'Non', 'Non',
        'Oui', 'Non']), [1]);
      expect(tablesArticle(['TT', 'BAES', 'Non', 'Oui', 'Non', 'Non', 'Non',
        'Oui', 'Non']), [2]);
      expect(tablesArticle(['TN / IT', 'BAES', 'Oui', 'Non', 'Non', 'Non',
        'Non', 'Oui', 'NF C 13-100']), [29]);
      expect(tablesArticle(['TN / IT', 'Source Centrale (6h)', 'Oui', 'Oui',
        'Non', 'Oui', 'ERP 1 à 4', 'Non', 'NF C 13-200']), [126]);
    });

    test('combinaison sans table', () {
      expect(tablesArticle(['TT', 'BAES', 'Non', 'Non', 'Non', 'Non', 'Non',
        'Oui', 'NF C 13-100']), isEmpty);
    });

    test('chaque combinaison du classeur donne une seule table', () {
      for (final l in choixTableArticle) {
        expect(tablesArticle(l.criteres), [l.table]);
      }
    });

    test('valeurs possibles de chaque critère', () {
      expect(valeursCritere(0), ['TT', 'TN / IT']);
      expect(valeursCritere(4), ['Non', 'Sans DRPE']);
      expect(valeursCritere(6),
          ['Non', 'ERP 5', 'ERP 1 à 4', 'ERP 1 dans CC']);
      expect(valeursCritere(8), ['Non', 'NF C 13-100', 'NF C 13-200']);
    });

    test('valeurs compatibles : TT impose « Haute tension = Non »', () {
      final sel = <String?>['TT', null, null, null, null, null, null, null, null];
      expect(valeursCompatibles(8, sel), ['Non']);
    });

    test('choisir un critère ramène les autres à une valeur compatible', () {
      final depart = selectionInitiale();
      expect(depart, ['TT', 'BAES', 'Non', 'Non', 'Non', 'Non', 'Non', 'Oui',
        'Non']);
      final apres = choisirCritere(depart, 8, 'NF C 13-100');
      // La haute tension n'existe qu'avec TN / IT : le neutre suit.
      expect(apres[0], 'TN / IT');
      expect(apres[8], 'NF C 13-100');
      expect(tablesArticle(apres).length, 1);
      // L'éclairage « BAES » reste possible, il est donc conservé.
      expect(apres[1], 'BAES');
    });

    test('toute sélection obtenue par choisirCritere est une ligne valide', () {
      for (var i = 0; i < nbCriteresTable; i++) {
        for (final valeur in valeursCritere(i)) {
          final sel = choisirCritere(selectionInitiale(), i, valeur);
          expect(sel[i], valeur);
          expect(tablesArticle(sel).length, 1, reason: '$i=$valeur');
        }
      }
    });
  });
}
