import 'package:flutter/material.dart';

/// Carte avec titre, icône et contenu, pour regrouper des champs.
class CarteSection extends StatelessWidget {
  const CarteSection({
    super.key,
    required this.titre,
    required this.icone,
    required this.child,
    this.action,
  });

  final String titre;
  final IconData icone;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, size: 20, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titre,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// Disposition en colonnes qui s'adaptent à la largeur disponible.
class GrilleChamps extends StatelessWidget {
  const GrilleChamps({
    super.key,
    required this.children,
    this.largeurMin = 240,
  });

  final List<Widget> children;
  final double largeurMin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const espace = 14.0;
        final colonnes = ((c.maxWidth + espace) / (largeurMin + espace))
            .floor()
            .clamp(1, 4);
        final largeur = (c.maxWidth - espace * (colonnes - 1)) / colonnes;
        return Wrap(
          spacing: espace,
          runSpacing: espace,
          children: [
            for (final w in children) SizedBox(width: largeur, child: w),
          ],
        );
      },
    );
  }
}
