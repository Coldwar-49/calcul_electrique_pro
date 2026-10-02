import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'écran de calcul affiché.
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void aller(int index) => state = index;
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);
