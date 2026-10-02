import 'package:flutter/material.dart';

/// Bandeau de titre en dégradé, en haut de chaque écran de calcul.
class EnTetePage extends StatelessWidget {
  const EnTetePage({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.icone,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32, vertical: compact ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            Color.lerp(cs.primary, const Color(0xFF6A2BD9), 0.55)!,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Sur téléphone, le menu latéral s'ouvre depuis le bandeau.
            if (Scaffold.maybeOf(context)?.hasDrawer ?? false) ...[
              IconButton(
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu_rounded, color: cs.onPrimary),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: cs.tertiaryContainer, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: (compact
                              ? texte.titleLarge
                              : texte.headlineSmall)
                          ?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sousTitre,
                      style: texte.bodyMedium?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
