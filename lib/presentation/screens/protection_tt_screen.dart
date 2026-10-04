import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/protection_tt.dart';
import '../../core/donnees/temps_coupure.dart';
import '../formats.dart';
import '../providers/protection_tt_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class ProtectionTTScreen extends StatelessWidget {
  const ProtectionTTScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Protection TT par DDR',
      sousTitre: 'Résistance de prise de terre maximale',
      icone: Icons.electrical_services_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(protectionTTEntreeProvider);
    final n = ref.read(protectionTTEntreeProvider.notifier);
    return CarteSection(
      titre: 'Schéma TT',
      icone: Icons.vertical_align_bottom_outlined,
      child: GrilleChamps(children: [
        ChampNombre(
          key: const ValueKey('tt-idn'),
          label: 'Sensibilité du DDR IΔn',
          suffixe: 'mA',
          valeurInitiale: fmtCompact(e.sensibiliteMa),
          minimum: 0.1,
          onValide: (v) => n.modifier((x) => x.copyWith(sensibiliteMa: v)),
        ),
        ListeDeroulante<TensionLimite>(
          label: 'Tension limite UL',
          valeur: e.limite,
          options: {for (final t in TensionLimite.values) t: t.libelle},
          onChanged: (v) => n.modifier((x) => x.copyWith(limite: v)),
        ),
        ChampNombre(
          key: const ValueKey('tt-u0'),
          label: 'Tension simple U0',
          suffixe: 'V',
          valeurInitiale: fmtCompact(e.u0),
          minimum: 1,
          aide: 'Sert au temps de coupure maximal (tableau 41.1).',
          onValide: (v) => n.modifier((x) => x.copyWith(u0: v)),
        ),
        _ChampResistance(valeur: e.resistanceTerre, notifier: n),
      ]),
    );
  }
}

/// Champ facultatif : vide = pas de vérification, seulement la valeur maximale.
class _ChampResistance extends StatelessWidget {
  const _ChampResistance({required this.valeur, required this.notifier});

  final double? valeur;
  final ProtectionTTNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('tt-ra'),
      initialValue: valeur == null ? '' : fmtCompact(valeur!),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Résistance mesurée Ra (facultatif)',
        suffixText: 'Ω',
        helperText: 'Vide : seule la valeur maximale est calculée.',
      ),
      onChanged: (t) {
        final v = double.tryParse(t.trim().replaceAll(',', '.'));
        notifier.modifier((x) => v != null && v >= 0
            ? x.copyWith(resistanceTerre: v)
            : x.copyWith(effacerResistance: true));
      },
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(protectionTTResultatProvider);
    final e = ref.watch(protectionTTEntreeProvider);
    final c = r.conforme;
    final tCoupure = tempsCoupureMax(e.u0, SchemaTemps.tt);
    return PanneauResultat(
      libelle: 'Résistance de terre maximale Ra',
      valeur: fmt(r.resistanceMax),
      unite: 'Ω',
      statut: c == null
          ? StatutResultat.neutre
          : c
              ? StatutResultat.conforme
              : StatutResultat.nonConforme,
      messageStatut: c == null
          ? null
          : c
              ? 'Conforme : Ra × IΔn = ${fmt(r.tensionDeContact!)} V'
              : 'Non conforme : Ra × IΔn = ${fmt(r.tensionDeContact!)} V '
                  '> ${fmtCompact(e.limite.volts)} V',
      details: [
        if (tCoupure != null)
          LigneDetail('Temps de coupure maximal (tableau 41.1, TT)',
              '${fmtCompact(tCoupure)} s'),
      ],
      pied: 'Ra × IΔn ≤ UL (NF C 15-100-1 2024, art. 411.5.3 : UL = 50 V). '
          'Valeur de 25 V pour les locaux particuliers : à confirmer dans la '
          'partie concernée. Si Ra est inconnue, elle peut être remplacée par '
          'l\'impédance de boucle Zs.',
    );
  }
}
