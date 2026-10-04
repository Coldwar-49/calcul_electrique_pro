import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../widgets/credit_auteur.dart';
import 'bilan_puissance_screen.dart';
import 'chute_tension_screen.dart';
import 'compensation_screen.dart';
import 'contacts_indirects_screen.dart';
import 'contrainte_thermique_screen.dart';
import 'courant_emploi_screen.dart';
import 'dimensionnement_screen.dart';
import 'filiation_screen.dart';
import 'ik_max_screen.dart';
import 'ik_min_screen.dart';
import 'influences_externes_screen.dart';
import 'pouvoir_de_coupure_screen.dart';
import 'protection_tt_screen.dart';
import 'regle_triangle_screen.dart';
import 'resistance_pe_screen.dart';
import 'surcharges_screen.dart';

class _Destination {
  const _Destination(this.libelle, this.icone, this.iconeActive, this.page);
  final String libelle;
  final IconData icone;
  final IconData iconeActive;
  final Widget page;
}

class _Groupe {
  const _Groupe(this.titre, this.entrees);
  final String titre;
  final List<_Destination> entrees;
}

/// Rubriques du menu, par ordre alphabétique, et entrées classées par ordre
/// alphabétique dans chaque rubrique. Pour ajouter un calcul : une ligne ici.
const _groupes = [
  _Groupe('Circuits', [
    _Destination('Bilan de puissance', Icons.calculate_outlined,
        Icons.calculate, BilanPuissanceScreen()),
    _Destination('Chute de tension', Icons.trending_down_rounded,
        Icons.trending_down, ChuteTensionScreen()),
    _Destination('Compensation réactive', Icons.battery_charging_full_outlined,
        Icons.battery_charging_full, CompensationScreen()),
    _Destination('Contrainte thermique', Icons.whatshot_outlined,
        Icons.whatshot, ContrainteThermiqueScreen()),
    _Destination('Courant d\'emploi', Icons.electric_meter_outlined,
        Icons.electric_meter, CourantEmploiScreen()),
    _Destination('Dimensionnement', Icons.auto_fix_high_outlined,
        Icons.auto_fix_high, DimensionnementScreen()),
    _Destination(
        'Surcharges', Icons.shield_outlined, Icons.shield, SurchargesScreen()),
  ]),
  _Groupe('Court-circuit', [
    _Destination(
        'Ik max', Icons.flash_on_outlined, Icons.flash_on, IkMaxScreen()),
    _Destination(
        'Ik min', Icons.flash_off_outlined, Icons.flash_off, IkMinScreen()),
    _Destination('Règle du triangle', Icons.change_history_outlined,
        Icons.change_history, RegleTriangleScreen()),
  ]),
  _Groupe('Protection', [
    _Destination('Contacts indirects', Icons.back_hand_outlined,
        Icons.back_hand, ContactsIndirectsScreen()),
    _Destination('Filiation', Icons.account_tree_outlined,
        Icons.account_tree, FiliationScreen()),
    _Destination('Pouvoir de coupure', Icons.shield_moon_outlined,
        Icons.shield_moon, PouvoirDeCoupureScreen()),
    _Destination('Protection TT par DDR', Icons.electrical_services_outlined,
        Icons.electrical_services, ProtectionTTScreen()),
    _Destination('Résistance du PE', Icons.vertical_align_bottom_outlined,
        Icons.vertical_align_bottom, ResistancePeScreen()),
  ]),
  _Groupe('Références', [
    _Destination('Influences externes', Icons.water_drop_outlined,
        Icons.water_drop, InfluencesExternesScreen()),
  ]),
];

/// Toutes les entrées dans l'ordre du menu (l'indice sert à la navigation).
final _destinations = <_Destination>[
  for (final g in _groupes) ...g.entrees,
];

final _pages = <Widget>[for (final d in _destinations) d.page];

/// L'application s'ouvre sur « Surcharges », le calcul principal.
final int _indexAccueil =
    _destinations.indexWhere((d) => d.libelle == 'Surcharges');

/// Coque de l'application : menu fixe à gauche dès 600 px de large (icônes
/// seules sous 900 px, avec les libellés au-delà), menu coulissant sur
/// téléphone.
class AccueilShell extends ConsumerWidget {
  const AccueilShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationProvider) ?? _indexAccueil;
    final nav = ref.read(navigationProvider.notifier);
    final largeur = MediaQuery.sizeOf(context).width;
    final page = IndexedStack(index: index, children: _pages);

    if (largeur < 600) {
      return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: _MenuLateral(
              index: index,
              compact: false,
              onSelect: (i) {
                nav.aller(i);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        body: page,
      );
    }

    final compact = largeur < 900;
    return Scaffold(
      body: Row(
        children: [
          // Material (et non Container coloré) : les entrées ListTile y dessinent
          // leur surbrillance de sélection.
          Material(
            key: const ValueKey('menu-lateral'),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: SizedBox(
              width: compact ? 80 : 264,
              child: SafeArea(
                child: _MenuLateral(
                  index: index,
                  compact: compact,
                  onSelect: nav.aller,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: page),
        ],
      ),
    );
  }
}

/// Menu à rubriques : marque en haut, entrées défilantes, crédit toujours
/// visible en bas.
class _MenuLateral extends StatelessWidget {
  const _MenuLateral({
    required this.index,
    required this.compact,
    required this.onSelect,
  });

  final int index;

  /// true : icônes seules (info-bulle avec le libellé).
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

    final elements = <Widget>[];
    var i = 0;
    for (var g = 0; g < _groupes.length; g++) {
      final groupe = _groupes[g];
      if (compact) {
        if (g > 0) {
          elements.add(const Divider(indent: 16, endIndent: 16, height: 16));
        }
      } else {
        elements.add(Padding(
          padding: EdgeInsets.fromLTRB(16, g == 0 ? 4 : 20, 16, 6),
          child: Text(
            groupe.titre.toUpperCase(),
            style: texte.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ));
      }
      for (final d in groupe.entrees) {
        final indice = i++;
        final actif = indice == index;
        elements.add(compact
            ? _EntreeCompacte(
                destination: d, actif: actif, onTap: () => onSelect(indice))
            : ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                selected: actif,
                selectedTileColor: cs.primaryContainer,
                leading: Icon(actif ? d.iconeActive : d.icone),
                title: Text(d.libelle,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => onSelect(indice),
              ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Marque(toujoursEtendue: !compact),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
            children: elements,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 4 : 24, 8, 8, 16),
          child: CreditAuteur(etroit: compact),
        ),
      ],
    );
  }
}

class _EntreeCompacte extends StatelessWidget {
  const _EntreeCompacte({
    required this.destination,
    required this.actif,
    required this.onTap,
  });

  final _Destination destination;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: destination.libelle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: actif ? cs.primaryContainer : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              actif ? destination.iconeActive : destination.icone,
              color: actif ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Marque extends StatelessWidget {
  const _Marque({this.toujoursEtendue = false});

  /// true : logo et nom ; false : logo seul.
  final bool toujoursEtendue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logo = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.bolt_rounded, color: cs.tertiaryContainer, size: 26),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: toujoursEtendue
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                logo,
                const SizedBox(width: 12),
                Flexible(
                  child: Text('Calcul Électrique Pro',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            )
          : Center(child: logo),
    );
  }
}
