import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/influences_externes.dart';
import '../../core/donnees/influences.dart';
import '../../core/donnees/types.dart';
import '../providers/donnees_reference_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _vert = Color(0xFF0B5B22);
const _vertFond = Color(0xFFD7F5DD);

class InfluencesExternesScreen extends StatelessWidget {
  const InfluencesExternesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Influences externes',
      sousTitre: 'Câbles, conduits et goulottes adaptés aux conditions d\'emploi',
      icone: Icons.water_drop_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final niveaux = ref.watch(niveauxInfluencesProvider);
    final n = ref.read(niveauxInfluencesProvider.notifier);

    return CarteSection(
      titre: 'Conditions d\'emploi',
      icone: Icons.thermostat_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Seuils du classeur (2013)'),
            subtitle: const Text(
                'Sinon : tableaux 52.3A et 52.4 de la NF C 15-100-1 (2024).'),
            value: ref.watch(editionInfluencesProvider) ==
                EditionNorme.norme2013,
            onChanged: (v) => ref.read(editionInfluencesProvider.notifier).choisir(
                v ? EditionNorme.norme2013 : EditionNorme.normeActuelle),
          ),
          GrilleChamps(
        largeurMin: 300,
        children: [
          for (final code in ordreSaisieInfluences)
            ListeDeroulante<int>(
              label: '$code — ${glossaireInfluences[code]!.titre}',
              valeur: niveaux[code]!,
              info: 'Influence externe $code : choisir le niveau qui décrit les '
                  'conditions du local ou de l\'emplacement.',
              options: {
                for (var i = 0; i < glossaireInfluences[code]!.niveaux.length; i++)
                  i + 1: '$code${i + 1} — ${glossaireInfluences[code]!.niveaux[i]}',
              },
              onChanged: (v) => n.definir(code, v),
            ),
        ],
          ),
        ],
      ),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cables = ref.watch(resultatsCablesProvider);
    final conduits = ref.watch(resultatsConduitsProvider);
    final nbCables = cables.where((r) => r.convient).length;
    final nbConduits = conduits.where((r) => r.convient).length;
    final texte = Theme.of(context).textTheme;

    return PanneauResultat(
      libelle: 'Câbles adaptés',
      valeur: '$nbCables / ${cables.length}',
      statut: nbCables == 0 ? StatutResultat.nonConforme : StatutResultat.neutre,
      details: [
        LigneDetail('Conduits et goulottes adaptés',
            '$nbConduits / ${conduits.length}'),
      ],
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Câbles',
              style: texte.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final r in cables) _Ligne(resultat: r),
          const SizedBox(height: 16),
          Text('Conduits, goulottes et moulures',
              style: texte.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final r in conduits) _Ligne(resultat: r),
        ],
      ),
      pied: 'Une influence est contraignante quand son niveau dépasse ce que le '
          'matériel tolère. Les indices IP / IK requis ne sont pas calculés '
          '(valeurs saisies par macro dans le classeur). Valeurs de l\'édition 2013.',
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.resultat});

  final ResultatInfluences resultat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final ok = resultat.convient;
    final couleur = ok ? _vert : cs.error;
    final fond = ok ? _vertFond : cs.errorContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resultat.type.nom,
                    style: texte.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (!resultat.type.usageCourant)
                  Text('Hors usage courant',
                      style: texte.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                for (final r in resultat.remarques)
                  Text(r,
                      style: texte.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 14, color: couleur),
                const SizedBox(width: 4),
                Text(ok ? 'Convient' : resultat.contraintes.join(' '),
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
