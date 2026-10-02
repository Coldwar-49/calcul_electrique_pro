import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../widgets/credit_auteur.dart';
import 'chute_tension_screen.dart';
import 'contacts_indirects_screen.dart';
import 'contrainte_thermique_screen.dart';
import 'filiation_screen.dart';
import 'ik_max_screen.dart';
import 'ik_min_screen.dart';
import 'pouvoir_de_coupure_screen.dart';
import 'regle_triangle_screen.dart';
import 'resistance_pe_screen.dart';
import 'surcharges_screen.dart';

class _Destination {
  const _Destination(this.libelle, this.icone, this.iconeActive);
  final String libelle;
  final IconData icone;
  final IconData iconeActive;
}

const _destinations = [
  _Destination('Surcharges', Icons.shield_outlined, Icons.shield),
  _Destination(
      'Chute de tension', Icons.trending_down_rounded, Icons.trending_down),
  _Destination(
      'Contrainte thermique', Icons.whatshot_outlined, Icons.whatshot),
  _Destination('Ik max', Icons.flash_on_outlined, Icons.flash_on),
  _Destination('Ik min', Icons.flash_off_outlined, Icons.flash_off),
  _Destination(
      'Règle du triangle', Icons.change_history_outlined, Icons.change_history),
  _Destination('Résistance du PE', Icons.vertical_align_bottom_outlined,
      Icons.vertical_align_bottom),
  _Destination('Contacts indirects', Icons.back_hand_outlined, Icons.back_hand),
  _Destination('Pouvoir de coupure', Icons.shield_moon_outlined,
      Icons.shield_moon),
  _Destination('Filiation', Icons.account_tree_outlined, Icons.account_tree),
];

const _pages = <Widget>[
  SurchargesScreen(),
  ChuteTensionScreen(),
  ContrainteThermiqueScreen(),
  IkMaxScreen(),
  IkMinScreen(),
  RegleTriangleScreen(),
  ResistancePeScreen(),
  ContactsIndirectsScreen(),
  PouvoirDeCoupureScreen(),
  FiliationScreen(),
];

/// Coque de l'application : rail latéral sur grand écran, barre en bas sinon.
class AccueilShell extends ConsumerWidget {
  const AccueilShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationProvider);
    final nav = ref.read(navigationProvider.notifier);
    final large = MediaQuery.sizeOf(context).width >= 900;
    final etendu = MediaQuery.sizeOf(context).width >= 1200;
    final page = IndexedStack(index: index, children: _pages);

    if (!large) {
      // Neuf écrans : menu latéral coulissant (ouvert par le bouton du bandeau).
      return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Marque(toujoursEtendue: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final (i, d) in _destinations.indexed)
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          selected: i == index,
                          selectedTileColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          leading: Icon(i == index ? d.iconeActive : d.icone),
                          title: Text(d.libelle,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            nav.aller(i);
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 12, 16, 16),
                  child: CreditAuteur(),
                ),
              ],
            ),
          ),
        ),
        body: page,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Le rail défile si la fenêtre est trop basse pour tout afficher.
          LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    extended: etendu,
                    selectedIndex: index,
                    onDestinationSelected: nav.aller,
                    labelType: etendu
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: const _Marque(),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding:
                              EdgeInsets.fromLTRB(etendu ? 16 : 4, 0, 8, 16),
                          child: CreditAuteur(etroit: !etendu),
                        ),
                      ),
                    ),
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icone),
                          selectedIcon: Icon(d.iconeActive),
                          label: Text(d.libelle),
                        ),
                    ],
                  ),
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

class _Marque extends StatelessWidget {
  const _Marque({this.toujoursEtendue = false});

  /// true : logo et nom, quelle que soit la largeur (menu latéral).
  final bool toujoursEtendue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final etendu = toujoursEtendue || MediaQuery.sizeOf(context).width >= 1200;
    final logo = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.bolt_rounded, color: cs.tertiaryContainer, size: 26),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: etendu
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
          : logo,
    );
  }
}
