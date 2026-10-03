import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/courant_emploi.dart';
import '../formats.dart';
import '../providers/bilan_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class BilanPuissanceScreen extends StatelessWidget {
  const BilanPuissanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Bilan de puissance',
      sousTitre: 'Puissance d\'utilisation et courant d\'emploi',
      icone: Icons.calculate_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(bilanEntreeProvider);
    final n = ref.read(bilanEntreeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Circuits',
          icone: Icons.list_alt_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in e.lignes) ...[
                Column(
                  key: ValueKey('bil-${l.id}'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GrilleChamps(children: [
                      TextFormField(
                        initialValue: l.nom,
                        decoration:
                            const InputDecoration(labelText: 'Désignation'),
                        onChanged: (t) =>
                            n.modifierLigne(l.id, (x) => x.copyWith(nom: t)),
                      ),
                      ChampNombre(
                        label: 'Puissance Pn',
                        suffixe: 'kW',
                        valeurInitiale: fmtCompact(l.puissanceKw),
                        minimum: 0,
                        onValide: (v) => n.modifierLigne(
                            l.id, (x) => x.copyWith(puissanceKw: v)),
                      ),
                      ChampNombre(
                        label: 'Ku (utilisation)',
                        valeurInitiale: fmtCompact(l.ku),
                        minimum: 0,
                        maximum: 1,
                        onValide: (v) =>
                            n.modifierLigne(l.id, (x) => x.copyWith(ku: v)),
                      ),
                      ChampNombre(
                        label: 'Ks (simultanéité)',
                        valeurInitiale: fmtCompact(l.ks),
                        minimum: 0,
                        maximum: 1,
                        onValide: (v) =>
                            n.modifierLigne(l.id, (x) => x.copyWith(ks: v)),
                      ),
                    ]),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: e.lignes.length > 1
                            ? () => n.supprimer(l.id)
                            : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: n.ajouter,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un circuit'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Ensemble',
          icone: Icons.account_tree_outlined,
          child: GrilleChamps(children: [
            ChampNombre(
              key: const ValueKey('bil-ksg'),
              label: 'Ks global',
              valeurInitiale: fmtCompact(e.ksGlobal),
              minimum: 0,
              maximum: 1,
              aide: 'Coefficients à saisir d\'après le guide UTE C 15-105.',
              onValide: (v) => n.modifier((x) => x.copyWith(ksGlobal: v)),
            ),
            ListeDeroulante<Alimentation>(
              label: 'Alimentation',
              valeur: e.alimentation,
              options: {for (final a in Alimentation.values) a: a.libelle},
              onChanged: (v) => n.modifier((x) =>
                  x.copyWith(alimentation: v, tension: v.tensionUsuelle)),
            ),
            ChampNombre(
              key: ValueKey('bil-u-${e.alimentation.name}'),
              label: 'Tension',
              suffixe: 'V',
              valeurInitiale: fmtCompact(e.tension),
              minimum: 1,
              onValide: (v) => n.modifier((x) => x.copyWith(tension: v)),
            ),
            ChampNombre(
              key: const ValueKey('bil-cos'),
              label: 'cos φ moyen',
              valeurInitiale: fmtCompact(e.cosPhi),
              minimum: 0.01,
              maximum: 1,
              onValide: (v) => n.modifier((x) => x.copyWith(cosPhi: v)),
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
    final r = ref.watch(bilanResultatProvider);
    return PanneauResultat(
      libelle: 'Puissance d\'utilisation',
      valeur: fmt(r.puissanceUtilisee / 1000),
      unite: 'kW',
      details: [
        LigneDetail(
            'Puissance installée', '${fmt(r.puissanceInstallee / 1000)} kW'),
        LigneDetail(
            'Puissance apparente', '${fmt(r.puissanceApparente / 1000)} kVA'),
        LigneDetail('Courant d\'emploi Ib', '${fmt(r.courantEmploi)} A'),
      ],
      pied: 'P utilisée = Σ (Pn × Ku × Ks) × Ks global.',
    );
  }
}
