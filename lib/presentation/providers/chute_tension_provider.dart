import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';
import 'tarif_provider.dart';

/// Tronçon avec un identifiant stable (clés des champs de saisie).
class TronconUi {
  const TronconUi(this.id, this.ligne);
  final int id;
  final LigneChuteTension ligne;
}

class TronconsNotifier extends Notifier<List<TronconUi>> {
  int _prochainId = 1;

  @override
  List<TronconUi> build() => [TronconUi(_prochainId++, const LigneChuteTension())];

  /// Ajoute un tronçon en reprenant les réglages du dernier.
  void ajouter() {
    final modele = state.isEmpty ? const LigneChuteTension() : state.last.ligne;
    state = [...state, TronconUi(_prochainId++, modele)];
  }

  void supprimer(int id) {
    if (state.length <= 1) return;
    state = [for (final t in state) if (t.id != id) t];
  }

  void modifier(int id, LigneChuteTension Function(LigneChuteTension) f) {
    state = [
      for (final t in state) t.id == id ? TronconUi(t.id, f(t.ligne)) : t,
    ];
  }
}

final tronconsProvider =
    NotifierProvider<TronconsNotifier, List<TronconUi>>(TronconsNotifier.new);

/// Majoration du seuil au-delà de 100 m de canalisations principales
/// (tableau 52.23 de la NF C 15-100-1 : 2024) : désactivée au départ.
class MajorationLongueurNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void choisir(bool v) => state = v;
}

final majorationLongueurProvider =
    NotifierProvider<MajorationLongueurNotifier, bool>(
        MajorationLongueurNotifier.new);

final chuteTensionResultatsProvider =
    Provider<List<ResultatChuteTension>>((ref) {
  final troncons = ref.watch(tronconsProvider);
  final tarif = ref.watch(tarifProvider);
  return calculerChuteTension(
    [for (final t in troncons) t.ligne.copyWith(tarif: tarif)],
    majorerSeuilLongueur: ref.watch(majorationLongueurProvider),
  );
});
