import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/influences_externes.dart';
import '../../core/donnees/influences.dart';

/// Niveau choisi pour chaque influence externe (code -> niveau, 1 = premier).
class NiveauxNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {...niveauxParDefaut};

  void definir(String code, int niveau) =>
      state = {...state, code: niveau};
}

final niveauxInfluencesProvider =
    NotifierProvider<NiveauxNotifier, Map<String, int>>(NiveauxNotifier.new);

final resultatsCablesProvider = Provider<List<ResultatInfluences>>(
    (ref) => evaluerCables(ref.watch(niveauxInfluencesProvider)));

final resultatsConduitsProvider = Provider<List<ResultatInfluences>>(
    (ref) => evaluerConduits(ref.watch(niveauxInfluencesProvider)));
