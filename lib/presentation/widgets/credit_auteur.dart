import 'package:flutter/material.dart';

/// Mention « Créé par … » affichée discrètement.
class CreditAuteur extends StatelessWidget {
  const CreditAuteur({super.key, this.etroit = false});

  /// true : texte sur trois lignes, pour le rail de navigation compact.
  final bool etroit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: cs.onSurfaceVariant, fontSize: etroit ? 10 : null);
    return Text(
      etroit ? 'Créé par\nDevismes\nFabrice' : 'Créé par Devismes Fabrice',
      textAlign: etroit ? TextAlign.center : TextAlign.start,
      style: style,
    );
  }
}
