import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/donnees/calibres.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/triangle_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/choix_ou_autre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _ames = {Ame.cuivre: 'Cuivre', Ame.aluminium: 'Aluminium'};

class RegleTriangleScreen extends StatelessWidget {
  const RegleTriangleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Règle du triangle',
      sousTitre: 'Longueur maximale d\'un câble dérivé protégé en court-circuit',
      icone: Icons.change_history_rounded,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(triangleEntreeProvider);
    final n = ref.read(triangleEntreeProvider.notifier);
    final sections = {for (final s in sectionsUsuelles) s: fmtCompact(s)};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Disjoncteur de protection P',
          icone: Icons.electrical_services_rounded,
          child: GrilleChamps(children: [
            ListeDeroulante<ChoixReglage>(
              label: 'Réglage magnétique',
              valeur: e.choixReglage,
              options: {for (final c in ChoixReglage.values) c: c.libelle},
              onChanged: (v) => n.modifier((x) => x.copyWith(choixReglage: v)),
            ),
            if (e.choixReglage == ChoixReglage.multipleIr)
              ChampNombre(
                key: const ValueKey('tri-mult'),
                label: 'Multiple de Ir',
                valeurInitiale: fmtCompact(e.multipleIr),
                minimum: 0.1,
                aide: 'Le calcul applique 1,2 × la valeur saisie.',
                onValide: (v) => n.modifier((x) => x.copyWith(multipleIr: v)),
              ),
            ChoixOuAutre(
              label: 'Réglage thermique Ir',
              valeur: e.ir,
              choix: calibresNormalises,
              unite: 'A',
              minimum: 0.1,
              onChanged: (v) => n.modifier((x) => x.copyWith(ir: v)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Câble S1 (protégé par P)',
          icone: Icons.cable_outlined,
          child: GrilleChamps(children: [
            ListeDeroulante<double>(
              label: 'Section S1 (mm²)',
              valeur: e.sectionS1,
              options: sections,
              onChanged: (v) => n.modifier((x) => x.copyWith(sectionS1: v)),
            ),
            ListeDeroulante<Ame>(
              label: 'Âme S1',
              valeur: e.ameS1,
              options: _ames,
              onChanged: (v) => n.modifier((x) => x.copyWith(ameS1: v)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Câble S2 (dérivation)',
          icone: Icons.call_split_rounded,
          child: GrilleChamps(children: [
            ChampNombre(
              key: const ValueKey('tri-dist'),
              label: 'Distance entre P et S2',
              suffixe: 'm',
              valeurInitiale: fmtCompact(e.distancePS2),
              minimum: 0,
              onValide: (v) => n.modifier((x) => x.copyWith(distancePS2: v)),
            ),
            ListeDeroulante<double>(
              label: 'Section S2 (mm²)',
              valeur: e.sectionS2,
              options: sections,
              onChanged: (v) => n.modifier((x) => x.copyWith(sectionS2: v)),
            ),
            ListeDeroulante<Ame>(
              label: 'Âme S2',
              valeur: e.ameS2,
              options: _ames,
              onChanged: (v) => n.modifier((x) => x.copyWith(ameS2: v)),
            ),
            ChampNombre(
              key: const ValueKey('tri-long'),
              label: 'Longueur distribuée de S2',
              suffixe: 'm',
              valeurInitiale: fmtCompact(e.longueurDistribuee),
              minimum: 0,
              onValide: (v) =>
                  n.modifier((x) => x.copyWith(longueurDistribuee: v)),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(triangleResultatProvider);
    final e = ref.watch(triangleEntreeProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

    final max = r.longueurMaxS2;
    final taux = max > 0 ? e.longueurDistribuee / max : double.infinity;
    final couleur = r.conforme ? const Color(0xFF1E8E3E) : cs.error;

    return PanneauResultat(
      libelle: 'Longueur maximale de S2 protégée par P',
      valeur: max < 0 ? '0' : fmt(max),
      unite: 'm',
      statut:
          r.conforme ? StatutResultat.conforme : StatutResultat.nonConforme,
      messageStatut: r.conforme
          ? 'Conforme : ${fmtCompact(e.longueurDistribuee)} m distribués'
          : max < 0
              ? 'Non conforme : S2 part au-delà de la longueur protégée de S1'
              : 'Non conforme : ${fmtCompact(e.longueurDistribuee)} m distribués',
      details: [
        LigneDetail('Longueur max. de S1 seul', '${fmt(r.longueurMaxS1)} m'),
        LigneDetail('Longueur max. de S2 seul', '${fmt(r.longueurMaxS2Seul)} m'),
        LigneDetail('Im / Ir retenu', fmtCompact(e.reglage.multiple)),
      ],
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Longueur distribuée',
                    overflow: TextOverflow.ellipsis,
                    style: texte.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  max > 0 ? '${fmt(taux * 100, 0)} % du maximum' : '—',
                  overflow: TextOverflow.ellipsis,
                  style: texte.labelMedium?.copyWith(
                      color: couleur, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: max > 0 ? (taux > 1 ? 1 : taux) : 1,
              minHeight: 10,
              color: couleur,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
      pied: 'L(S2) = (Lmax S1 − distance) × Lmax S2 / Lmax S1, avec '
          'Lmax = 0,8 × 230 × S / (2 × Ir × Im/Ir × ρ). '
          'Valeurs de l\'édition 2013.',
    );
  }
}
