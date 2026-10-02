import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';

/// Tarif du projet, partagé entre les écrans (Ik max, Chute de tension).
class TarifNotifier extends Notifier<Tarif> {
  @override
  Tarif build() => Tarif.bleu;

  void choisir(Tarif t) => state = t;
}

final tarifProvider = NotifierProvider<TarifNotifier, Tarif>(TarifNotifier.new);
