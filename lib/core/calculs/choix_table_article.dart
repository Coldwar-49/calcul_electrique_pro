/// Aide au choix d'une table article (Opale Électricité) selon neuf critères,
/// d'après l'onglet « Choix table Article ».
library;

import '../donnees/choix_table_article.dart';
import '../donnees/choix_table_article_modele.dart';

/// Nombre de critères.
int get nbCriteresTable => libellesCriteresTable.length;

/// Valeurs possibles du critère [i], dans l'ordre d'apparition du classeur.
List<String> valeursCritere(int i) {
  final vus = <String>[];
  for (final l in choixTableArticle) {
    final v = l.criteres[i];
    if (!vus.contains(v)) vus.add(v);
  }
  return vus;
}

bool _correspond(LigneChoixTable l, List<String?> selection, {int? sauf}) {
  for (var j = 0; j < nbCriteresTable; j++) {
    if (j == sauf) continue;
    final s = selection[j];
    if (s != null && l.criteres[j] != s) return false;
  }
  return true;
}

/// Valeurs du critère [i] compatibles avec les autres critères déjà choisis
/// ([selection], `null` = pas de choix).
List<String> valeursCompatibles(int i, List<String?> selection) {
  final vus = <String>[];
  for (final l in choixTableArticle) {
    if (_correspond(l, selection, sauf: i) && !vus.contains(l.criteres[i])) {
      vus.add(l.criteres[i]);
    }
  }
  return vus;
}

/// Numéros de table pour une sélection complète (normalement un seul).
List<int> tablesArticle(List<String?> selection) => [
      for (final l in choixTableArticle)
        if (_correspond(l, selection)) l.table,
    ];

/// Applique le choix [valeur] au critère [i] et ajuste les autres critères
/// un par un (dans l'ordre du classeur) : l'ancienne valeur est conservée si
/// elle reste possible avec les critères déjà fixés, sinon la première valeur
/// possible est retenue. La sélection obtenue correspond toujours à une ligne
/// du classeur.
List<String> choisirCritere(List<String> selection, int i, String valeur) {
  final partielle = List<String?>.filled(nbCriteresTable, null)..[i] = valeur;
  for (var j = 0; j < nbCriteresTable; j++) {
    if (j == i) continue;
    final compatibles = valeursCompatibles(j, partielle);
    partielle[j] =
        compatibles.contains(selection[j]) ? selection[j] : compatibles.first;
  }
  return [for (final v in partielle) v!];
}

/// Sélection initiale : les critères de la première ligne du classeur.
List<String> selectionInitiale() => [...choixTableArticle.first.criteres];
