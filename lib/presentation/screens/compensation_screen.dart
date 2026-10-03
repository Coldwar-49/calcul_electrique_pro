import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../formats.dart';
import '../providers/compensation_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class CompensationScreen extends StatelessWidget {
  const CompensationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Compensation réactive',
      sousTitre: 'Puissance de la batterie de condensateurs',
      icone: Icons.battery_charging_full_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(compensationEntreeProvider);
    final n = ref.read(compensationEntreeProvider.notifier);
    return CarteSection(
      titre: 'Installation',
      icone: Icons.factory_outlined,
      child: GrilleChamps(children: [
        ChampNombre(
          key: const ValueKey('cr-p'),
          label: 'Puissance active P',
          suffixe: 'kW',
          valeurInitiale: fmtCompact(e.puissanceKw),
          minimum: 0,
          onValide: (v) => n.modifier((x) => x.copyWith(puissanceKw: v)),
        ),
        ChampNombre(
          key: const ValueKey('cr-c1'),
          label: 'cos φ actuel',
          valeurInitiale: fmtCompact(e.cosPhiActuel),
          minimum: 0.01,
          maximum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(cosPhiActuel: v)),
        ),
        ChampNombre(
          key: const ValueKey('cr-c2'),
          label: 'cos φ visé',
          valeurInitiale: fmtCompact(e.cosPhiVise),
          minimum: 0.01,
          maximum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(cosPhiVise: v)),
        ),
      ]),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(compensationResultatProvider);
    final negatif = r.puissanceBatterie < 0;
    return PanneauResultat(
      libelle: 'Puissance de la batterie Qc',
      valeur: fmt(r.puissanceBatterie / 1000),
      unite: 'kvar',
      messageStatut: negatif
          ? 'Le cos φ visé est inférieur au cos φ actuel : pas de compensation.'
          : null,
      details: [
        LigneDetail('Réactif avant', '${fmt(r.reactifAvant / 1000)} kvar'),
        LigneDetail('Réactif après', '${fmt(r.reactifApres / 1000)} kvar'),
        LigneDetail('Apparente avant', '${fmt(r.apparenteAvant / 1000)} kVA'),
        LigneDetail('Apparente après', '${fmt(r.apparenteApres / 1000)} kVA'),
      ],
      pied: 'Qc = P × (tan φ1 − tan φ2)',
    );
  }
}
