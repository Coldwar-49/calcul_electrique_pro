import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/protection_tt.dart';

class ProtectionTTEntree {
  const ProtectionTTEntree({
    this.sensibiliteMa = 30,
    this.limite = TensionLimite.v50,
    this.resistanceTerre,
  });

  final double sensibiliteMa;
  final TensionLimite limite;
  final double? resistanceTerre;

  ProtectionTTEntree copyWith({
    double? sensibiliteMa,
    TensionLimite? limite,
    double? resistanceTerre,
    bool effacerResistance = false,
  }) =>
      ProtectionTTEntree(
        sensibiliteMa: sensibiliteMa ?? this.sensibiliteMa,
        limite: limite ?? this.limite,
        resistanceTerre:
            effacerResistance ? null : (resistanceTerre ?? this.resistanceTerre),
      );
}

class ProtectionTTNotifier extends Notifier<ProtectionTTEntree> {
  @override
  ProtectionTTEntree build() => const ProtectionTTEntree();

  void modifier(ProtectionTTEntree Function(ProtectionTTEntree) f) =>
      state = f(state);
}

final protectionTTEntreeProvider =
    NotifierProvider<ProtectionTTNotifier, ProtectionTTEntree>(
        ProtectionTTNotifier.new);

final protectionTTResultatProvider = Provider<ResultatTT>((ref) {
  final e = ref.watch(protectionTTEntreeProvider);
  return calculerProtectionTT(
    sensibilite: e.sensibiliteMa / 1000,
    tensionLimite: e.limite.volts,
    resistanceTerre: e.resistanceTerre,
  );
});
