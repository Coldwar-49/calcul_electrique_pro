import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/demarrage_moteur.dart';
import '../formats.dart';
import '../providers/demarrage_moteur_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class DemarrageMoteurScreen extends StatelessWidget {
  const DemarrageMoteurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Démarrage de moteur',
      sousTitre:
          'Intensité de démarrage et puissance maximales (tableaux 55.3 et 55.4)',
      icone: Icons.settings_suggest_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(demarrageEntreeProvider);
    final n = ref.read(demarrageEntreeProvider.notifier);
    final tri = e.alimentation == AlimentationMoteur.triphase;
    return CarteSection(
      titre: 'Moteur et alimentation',
      icone: Icons.settings_suggest_outlined,
      child: GrilleChamps(children: [
        ListeDeroulante<AlimentationMoteur>(
          label: 'Alimentation du moteur',
          valeur: e.alimentation,
          options: {for (final a in AlimentationMoteur.values) a: a.libelle},
          onChanged: (v) => n.modifier((x) => x.copyWith(alimentation: v)),
        ),
        ListeDeroulante<LocalMoteur>(
          label: 'Type de local',
          valeur: e.local,
          options: {for (final l in LocalMoteur.values) l: l.libelle},
          onChanged: (v) => n.modifier((x) => x.copyWith(local: v)),
        ),
        ListeDeroulante<ReseauMoteur>(
          label: 'Réseau de distribution',
          valeur: e.reseau,
          options: {for (final r in ReseauMoteur.values) r: r.libelle},
          onChanged: (v) => n.modifier((x) => x.copyWith(reseau: v)),
        ),
        if (tri)
          ListeDeroulante<ModeDemarrage>(
            label: 'Mode de démarrage',
            valeur: e.mode,
            options: {for (final m in ModeDemarrage.values) m: m.libelle},
            onChanged: (v) => n.modifier((x) => x.copyWith(mode: v)),
          ),
        _ChampFacultatif(
          cle: const ValueKey('dm-p'),
          label: 'Puissance du moteur (facultatif)',
          suffixe: 'kVA',
          valeur: e.puissanceKva,
          onChange: (v) => n.modifier((x) => v == null
              ? x.copyWith(effacerPuissance: true)
              : x.copyWith(puissanceKva: v)),
        ),
        _ChampFacultatif(
          cle: const ValueKey('dm-id'),
          label: 'Intensité de démarrage (facultatif)',
          suffixe: 'A',
          valeur: e.intensite,
          onChange: (v) => n.modifier((x) => v == null
              ? x.copyWith(effacerIntensite: true)
              : x.copyWith(intensite: v)),
        ),
      ]),
    );
  }
}

/// Champ numérique facultatif : vide = pas de vérification.
class _ChampFacultatif extends StatelessWidget {
  const _ChampFacultatif({
    required this.cle,
    required this.label,
    required this.suffixe,
    required this.valeur,
    required this.onChange,
  });

  final Key cle;
  final String label;
  final String suffixe;
  final double? valeur;
  final ValueChanged<double?> onChange;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: cle,
      initialValue: valeur == null ? '' : fmtCompact(valeur!),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixe,
        helperText: 'Vide : seules les limites sont affichées.',
      ),
      onChanged: (t) {
        final v = double.tryParse(t.trim().replaceAll(',', '.'));
        onChange(v != null && v >= 0 ? v : null);
      },
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(demarrageResultatProvider);
    final e = ref.watch(demarrageEntreeProvider);
    final ok = (r.intensiteConforme ?? true) && (r.puissanceConforme ?? true);
    final renseigne =
        r.intensiteConforme != null || r.puissanceConforme != null;
    final depasse = [
      if (r.intensiteConforme == false) 'intensité de démarrage',
      if (r.puissanceConforme == false) 'puissance du moteur',
    ].join(' et ');
    return PanneauResultat(
      libelle: 'Intensité de démarrage maximale',
      valeur: fmtCompact(r.intensiteMax),
      unite: 'A',
      statut: !renseigne
          ? StatutResultat.neutre
          : ok
              ? StatutResultat.conforme
              : StatutResultat.nonConforme,
      messageStatut: !renseigne
          ? null
          : ok
              ? 'Conforme aux limites du tableau'
              : 'Limite dépassée : $depasse',
      details: [
        LigneDetail('Puissance maximale du moteur',
            '${fmtCompact(r.puissanceMax)} kVA'),
        if (e.puissanceKva != null)
          LigneDetail(
              'Puissance saisie',
              '${fmtCompact(e.puissanceKva!)} kVA — '
                  '${r.puissanceConforme! ? 'conforme' : 'trop élevée'}'),
        if (e.intensite != null)
          LigneDetail(
              'Intensité saisie',
              '${fmtCompact(e.intensite!)} A — '
                  '${r.intensiteConforme! ? 'conforme' : 'trop élevée'}'),
      ],
      pied: 'NF C 15-100-1 (2024), tableaux 55.3 (intensité) et 55.4 '
          '(puissance des moteurs alimentés directement). Intitulé exact des '
          'lignes du tableau à relire dans la norme.',
    );
  }
}
