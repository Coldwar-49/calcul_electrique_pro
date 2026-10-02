# Calcul Électrique Pro (nom provisoire) — projet Flutter Android + Windows

App de calculs électriques BT issue du classeur Excel **CLAUREG V3.6 (2013)**.
Marque : DevisApps. Langue de l'UI et du code métier : français. Dart/Flutter, VS Code.

## Objectif V1 : toutes les feuilles de calcul du classeur
Porter en Dart, de façon fidèle, les 38 onglets de calcul/référence, répartis en 4 fichiers :
1. `docs/claureg_extraction.md` : surcharges (Iz, K, calibre In), K méthodes B/C/D/E/F, chute de tension, contrainte thermique, Icc max, Ik min (CI, CI GE), règle du triangle, résistance PE (disjoncteurs, fusibles)
2. `docs/modules/02_contacts_indirects_TN_IT.md` : conditions d'utilisation, TN/IT avec M=1 et M>1, fusibles m=1 et m>1
3. `docs/modules/03_donnees_reference.md` : IP/IK câbles et conduits, valeurs IP-IK, choix table article
4. `docs/modules/04_filiation_pouvoir_de_coupure.md` : Merlin Gerin (98-99 à 2012, Italien), PDC 1 pôle IT, coordination interrupteurs, PDC fusibles et disjoncteurs moteurs, Legrand, Hager

Hors V1 (à ajouter plus tard, ne pas lire ni implémenter sans demande de Fabrice) :
- `docs/modules/05_clausier_opale.md` : clausier Opale et feuilles 1 à 63
- `docs/modules/06_checklists_installation.md` : Armoires et coffrets BTA, BE2/BE3-Q18, HT, ERP, éclairage de sécurité, récepteurs, RICT, Surintensités, Contacts indirects

## Source de vérité
Les 4 fichiers V1 ci-dessus donnent, pour chaque onglet, la formule et la valeur calculée de chaque cellule.
Le classeur original est `CLAUREG V3.6 rev 1.xlsm` (à copier dans `docs/` si besoin).

Exemple de logique vue dans le classeur : K = M × L × (somme des coefficients selon type d'isolant/mode de pose) × 1,05 ;
section 50 mm² remplacée par 47,5 ; table de calibres normalisés (0,5 … 800 A et plus).

## Mise à jour NF C 15-100
Appliquer la **dernière édition/amendement en vigueur** (à rechercher sur le web, sources officielles AFNOR/Promotelec/
Legrand-Schneider-Hager). Règle de travail :
- Ne jamais inventer une valeur normative. Chaque valeur modifiée par rapport au classeur est listée dans
  `docs/changements_nfc15100.md` avec : ancienne valeur, nouvelle valeur, article/tableau, source.
- Valeur incertaine = la signaler, ne pas la figer.
- Garder les anciennes valeurs accessibles (option « norme 2013 / norme actuelle »).

## Architecture proposée
```
lib/
  core/calculs/        # moteur pur Dart, sans Flutter, 100 % testable
  core/donnees/        # tables normatives (K, calibres, résistivités, sections)
  presentation/screens/  # un écran par calcul
  presentation/widgets/
test/                  # tests unitaires : comparer aux valeurs calculées du classeur
```
- Moteur séparé de l'UI ; état avec Riverpod ou Provider (cohérent avec les autres apps DevisApps).
- Écrans adaptatifs : téléphone Android et fenêtre Windows large.

## Vérification
Pour chaque calcul : au moins 3 cas de test tirés du classeur (valeur formule Excel = valeur Dart).
Lancer `flutter analyze` et `flutter test` avant chaque commit.
