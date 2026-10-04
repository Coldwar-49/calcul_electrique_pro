import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/influences_externes.dart';
import '../../core/donnees/influences.dart';
import '../../core/donnees/types.dart';

/// Niveau choisi pour chaque influence externe (code -> niveau, 1 = premier).
class NiveauxNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {...niveauxParDefaut};

  void definir(String code, int niveau) =>
      state = {...state, code: niveau};
}

final niveauxInfluencesProvider =
    NotifierProvider<NiveauxNotifier, Map<String, int>>(NiveauxNotifier.new);

/// Édition des seuils : 2024 (tableaux 52.3A / 52.4) ou classeur 2013.
class EditionInfluencesNotifier extends Notifier<EditionNorme> {
  @override
  EditionNorme build() => EditionNorme.normeActuelle;

  void choisir(EditionNorme e) => state = e;
}

final editionInfluencesProvider =
    NotifierProvider<EditionInfluencesNotifier, EditionNorme>(
        EditionInfluencesNotifier.new);

final resultatsCablesProvider = Provider<List<ResultatInfluences>>((ref) =>
    evaluerCables(ref.watch(niveauxInfluencesProvider),
        edition: ref.watch(editionInfluencesProvider)));

final resultatsConduitsProvider = Provider<List<ResultatInfluences>>((ref) =>
    evaluerConduits(ref.watch(niveauxInfluencesProvider),
        edition: ref.watch(editionInfluencesProvider)));
