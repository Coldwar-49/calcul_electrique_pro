import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/chute_tension_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';
import '../widgets/selecteur_tarif.dart';

class ChuteTensionScreen extends StatelessWidget {
  const ChuteTensionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Chute de tension',
      sousTitre: 'Tronçons en série, chute cumulée et conformité',
      icone: Icons.trending_down_rounded,
      formulaire: _ListeTroncons(),
      resultat: _Synthese(),
    );
  }
}

class _ListeTroncons extends ConsumerWidget {
  const _ListeTroncons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final troncons = ref.watch(tronconsProvider);
    final resultats = ref.watch(chuteTensionResultatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CarteSection(
          titre: 'Alimentation',
          icone: Icons.receipt_long_outlined,
          child: GrilleChamps(children: [SelecteurTarif()]),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < troncons.length; i++) ...[
          _CarteTroncon(
            numero: i + 1,
            troncon: troncons[i],
            resultat: resultats[i],
            supprimable: troncons.length > 1,
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => ref.read(tronconsProvider.notifier).ajouter(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un tronçon'),
          ),
        ),
      ],
    );
  }
}

class _CarteTroncon extends ConsumerWidget {
  const _CarteTroncon({
    required this.numero,
    required this.troncon,
    required this.resultat,
    required this.supprimable,
  });

  final int numero;
  final TronconUi troncon;
  final ResultatChuteTension resultat;
  final bool supprimable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = troncon.ligne;
    final id = troncon.id;
    final n = ref.read(tronconsProvider.notifier);
    void maj(LigneChuteTension Function(LigneChuteTension) f) =>
        n.modifier(id, f);

    return CarteSection(
      titre: 'Tronçon $numero',
      icone: Icons.timeline_rounded,
      action: supprimable
          ? IconButton(
              tooltip: 'Supprimer ce tronçon',
              onPressed: () => n.supprimer(id),
              icon: const Icon(Icons.delete_outline_rounded),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(largeurMin: 200, children: [
            ListeDeroulante<SchemaCircuit>(
              label: 'Circuit',
              valeur: l.circuit,
              options: {for (final c in SchemaCircuit.values) c: c.libelle},
              onChanged: (v) => maj((x) => x.copyWith(circuit: v)),
            ),
            ChampNombre(
              key: ValueKey('u0-$id'),
              label: 'Tension U0',
              suffixe: 'V',
              valeurInitiale: fmtCompact(l.u0),
              minimum: 1,
              onValide: (v) => maj((x) => x.copyWith(u0: v)),
            ),
            ListeDeroulante<double>(
              label: 'Section (mm²)',
              valeur: l.section,
              options: {for (final s in sectionsUsuelles) s: fmtCompact(s)},
              onChanged: (v) => maj((x) => x.copyWith(section: v)),
            ),
            ChampNombre(
              key: ValueKey('nb-$id'),
              label: 'Conducteurs par pôle',
              valeurInitiale: l.nbConducteursParPole.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) =>
                  maj((x) => x.copyWith(nbConducteursParPole: v.toInt())),
            ),
            ChampNombre(
              key: ValueKey('long-$id'),
              label: 'Longueur',
              suffixe: 'm',
              valeurInitiale: fmtCompact(l.longueur),
              minimum: 0,
              onValide: (v) => maj((x) => x.copyWith(longueur: v)),
            ),
            ListeDeroulante<Ame>(
              label: 'Âme',
              valeur: l.ame,
              options: const {
                Ame.cuivre: 'Cuivre',
                Ame.aluminium: 'Aluminium',
              },
              onChanged: (v) => maj((x) => x.copyWith(ame: v)),
            ),
            ChampNombre(
              key: ValueKey('cos-$id'),
              label: 'cos φ',
              valeurInitiale: fmtCompact(l.cosPhi),
              minimum: 0.01,
              maximum: 1,
              onValide: (v) => maj((x) => x.copyWith(cosPhi: v)),
            ),
            ChampNombre(
              key: ValueKey('ib-$id'),
              label: 'Courant d\'emploi Ib',
              suffixe: 'A',
              valeurInitiale: fmtCompact(l.ib),
              minimum: 0,
              onValide: (v) => maj((x) => x.copyWith(ib: v)),
            ),
            ListeDeroulante<UsageCircuit>(
              label: 'Usage',
              valeur: l.usage,
              options: {for (final u in UsageCircuit.values) u: u.libelle},
              onChanged: (v) => maj((x) => x.copyWith(usage: v)),
            ),
          ]),
          const SizedBox(height: 18),
          _BandeauResultat(resultat: resultat),
        ],
      ),
    );
  }
}

class _BandeauResultat extends StatelessWidget {
  const _BandeauResultat({required this.resultat});

  final ResultatChuteTension resultat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final ok = resultat.conforme;
    final couleur = ok ? const Color(0xFF0B5B22) : cs.error;
    final fond = ok ? const Color(0xFFD7F5DD) : cs.errorContainer;

    Widget valeur(String libelle, String v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle,
                  style: texte.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(v,
                  style: texte.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          valeur('ΔU tronçon', '${fmt(resultat.deltaU, 3)} V'),
          valeur('ΔU cumulée', '${fmt(resultat.cumulV, 3)} V'),
          valeur('Cumul', '${fmt(resultat.pourcent)} %'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 16, color: couleur),
                const SizedBox(width: 4),
                Text(ok ? 'Conforme' : 'Non conforme',
                    style: texte.labelMedium?.copyWith(
                        color: couleur, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Synthese extends ConsumerWidget {
  const _Synthese();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultats = ref.watch(chuteTensionResultatsProvider);
    final dernier = resultats.last;
    final nonConformes = resultats.where((r) => !r.conforme).length;
    final seuil = fmtCompact(dernier.seuil * 100);

    return PanneauResultat(
      libelle: 'Chute de tension cumulée',
      valeur: fmt(dernier.pourcent),
      unite: '%',
      statut: dernier.conforme
          ? StatutResultat.conforme
          : StatutResultat.nonConforme,
      messageStatut: dernier.conforme
          ? 'Conforme (seuil $seuil %)'
          : 'Non conforme (seuil $seuil %)',
      details: [
        LigneDetail('ΔU cumulée', '${fmt(dernier.cumulV, 3)} V'),
        LigneDetail('Tronçons', '${resultats.length}'),
        LigneDetail('Tronçons non conformes', '$nonConformes'),
      ],
      pied: 'ΔU = (b/n) × Ib × (ρ·L·cos φ / S + 0,08·10⁻³ · L · sin φ). '
          'Seuils : 3 % / 5 % (Bleu et Jaune), 6 % / 8 % (Vert), '
          'éclairage / force.',
    );
  }
}
