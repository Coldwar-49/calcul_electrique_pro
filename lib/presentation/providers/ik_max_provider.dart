import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/ik_max.dart';

class ReseauNotifier extends Notifier<ReseauAmont> {
  @override
  ReseauAmont build() => const ReseauAmont();

  void modifier(ReseauAmont Function(ReseauAmont) f) => state = f(state);
}

final reseauAmontProvider =
    NotifierProvider<ReseauNotifier, ReseauAmont>(ReseauNotifier.new);

/// Liaison avec un identifiant stable (clés des champs de saisie).
class LiaisonUi {
  const LiaisonUi(this.id, this.liaison);
  final int id;
  final LiaisonIkMax liaison;
}

class LiaisonsNotifier extends Notifier<List<LiaisonUi>> {
  int _prochainId = 1;

  @override
  List<LiaisonUi> build() => [
        LiaisonUi(_prochainId++,
            const LiaisonIkMax(longueur: 6, sectionPhase: 25, sectionNeutre: 25)),
        LiaisonUi(_prochainId++,
            const LiaisonIkMax(longueur: 30, sectionPhase: 35, sectionNeutre: 35)),
      ];

  /// Ajoute une liaison en aval, en reprenant les réglages de la dernière.
  void ajouter() {
    final modele = state.isEmpty ? const LiaisonIkMax() : state.last.liaison;
    state = [...state, LiaisonUi(_prochainId++, modele)];
  }

  /// Supprime la dernière liaison (la chaîne reste continue).
  void supprimerDerniere() {
    if (state.length <= 1) return;
    state = state.sublist(0, state.length - 1);
  }

  void modifier(int id, LiaisonIkMax Function(LiaisonIkMax) f) {
    state = [
      for (final l in state) l.id == id ? LiaisonUi(l.id, f(l.liaison)) : l,
    ];
  }
}

final liaisonsProvider =
    NotifierProvider<LiaisonsNotifier, List<LiaisonUi>>(LiaisonsNotifier.new);

final ikMaxResultatProvider = Provider<ResultatIkMax>((ref) {
  final reseau = ref.watch(reseauAmontProvider);
  final liaisons = ref.watch(liaisonsProvider);
  return calculerIkMax(reseau, [for (final l in liaisons) l.liaison]);
});

/// Nom du point d'arrivée de la liaison [i] : TGBT, TD1, TD2…
String nomPoint(int i) => i == 0 ? 'TGBT' : 'TD$i';

/// Nom de la liaison [i] : « Source → TGBT », « TGBT → TD1 »…
String nomLiaison(int i) =>
    i == 0 ? 'Source → TGBT' : '${nomPoint(i - 1)} → ${nomPoint(i)}';
