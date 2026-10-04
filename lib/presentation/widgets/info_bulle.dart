import 'package:flutter/material.dart';

/// Bulle d'aide : apparaît au survol à la souris, à l'appui long au doigt.
/// Sans [message], n'ajoute rien autour de [child].
class InfoBulle extends StatelessWidget {
  const InfoBulle({super.key, required this.message, required this.child});

  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m == null || m.isEmpty) return child;
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: m,
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 12),
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: cs.onInverseSurface),
      child: child,
    );
  }
}
