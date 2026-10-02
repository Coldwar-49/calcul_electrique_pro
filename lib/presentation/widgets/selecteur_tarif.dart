import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';
import '../providers/tarif_provider.dart';
import 'liste_deroulante.dart';

/// Liste du tarif du projet (Bleu, Jaune, Vert), la même sur tous les écrans.
class SelecteurTarif extends ConsumerWidget {
  const SelecteurTarif({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarif = ref.watch(tarifProvider);
    return ListeDeroulante<Tarif>(
      label: 'Tarif (commun à tous les calculs)',
      valeur: tarif,
      options: {for (final t in Tarif.values) t: t.libelle},
      onChanged: ref.read(tarifProvider.notifier).choisir,
    );
  }
}
