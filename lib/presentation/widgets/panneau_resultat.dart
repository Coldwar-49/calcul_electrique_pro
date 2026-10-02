import 'package:flutter/material.dart';

/// Panneau de résultat : valeur principale mise en avant + lignes de détail.
class PanneauResultat extends StatelessWidget {
  const PanneauResultat({
    super.key,
    required this.libelle,
    required this.valeur,
    this.unite,
    this.statut = StatutResultat.neutre,
    this.messageStatut,
    this.details = const [],
    this.extra,
    this.pied,
  });

  final String libelle;
  final String valeur;
  final String? unite;
  final StatutResultat statut;
  final String? messageStatut;
  final List<LigneDetail> details;

  /// Contenu libre affiché sous les détails (tableau, etc.).
  final Widget? extra;
  final String? pied;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final (fond, premierPlan, icone) = switch (statut) {
      StatutResultat.neutre => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          Icons.bolt_rounded
        ),
      StatutResultat.conforme => (
          const Color(0xFFD7F5DD),
          const Color(0xFF0B5B22),
          Icons.check_circle_rounded
        ),
      StatutResultat.nonConforme => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.error_rounded
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icone, color: premierPlan, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(libelle,
                            style: texte.labelLarge?.copyWith(
                                color: premierPlan,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(valeur,
                              style: texte.displayMedium?.copyWith(
                                  color: premierPlan,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      if (unite != null) ...[
                        const SizedBox(width: 6),
                        Text(unite!,
                            style: texte.titleLarge?.copyWith(
                                color: premierPlan.withValues(alpha: 0.8))),
                      ],
                    ],
                  ),
                  if (messageStatut != null) ...[
                    const SizedBox(height: 8),
                    Text(messageStatut!,
                        style: texte.bodyMedium
                            ?.copyWith(color: premierPlan)),
                  ],
                ],
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (var i = 0; i < details.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(details[i].libelle,
                            style: texte.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant)),
                      ),
                      Text(details[i].valeur,
                          style: texte.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
            if (extra != null) ...[
              const SizedBox(height: 16),
              extra!,
            ],
            if (pied != null) ...[
              const SizedBox(height: 12),
              Text(pied!,
                  style: texte.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

enum StatutResultat { neutre, conforme, nonConforme }

class LigneDetail {
  const LigneDetail(this.libelle, this.valeur);
  final String libelle;
  final String valeur;
}
