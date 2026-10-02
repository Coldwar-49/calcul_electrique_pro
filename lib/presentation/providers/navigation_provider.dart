import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'écran de calcul affiché ; `null` tant que l'utilisateur n'a rien
/// choisi (l'application affiche alors son écran d'accueil).
class NavigationNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void aller(int index) => state = index;
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, int?>(NavigationNotifier.new);
