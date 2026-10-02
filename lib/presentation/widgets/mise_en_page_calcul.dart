import 'package:flutter/material.dart';

import 'credit_auteur.dart';
import 'en_tete_page.dart';

/// Largeur à partir de laquelle formulaire et résultat passent côte à côte.
const double largeurEcranLarge = 900;

/// Page de calcul : bandeau, puis formulaire et panneau de résultat.
/// Large : deux colonnes, résultat fixe à droite. Étroit : résultat en haut.
class MiseEnPageCalcul extends StatelessWidget {
  const MiseEnPageCalcul({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.formulaire,
    required this.resultat,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;
  final Widget formulaire;
  final Widget resultat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EnTetePage(titre: titre, sousTitre: sousTitre, icone: icone),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            if (c.maxWidth >= largeurEcranLarge) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 12),
                            child: formulaire,
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 380,
                          child: SingleChildScrollView(child: resultat),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                resultat,
                const SizedBox(height: 16),
                formulaire,
                const SizedBox(height: 20),
                const Center(child: CreditAuteur()),
                const SizedBox(height: 8),
              ],
            );
          }),
        ),
      ],
    );
  }
}
