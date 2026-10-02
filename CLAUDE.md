# Calcul Électrique Pro (nom provisoire) — projet Flutter Android + Windows

App de calculs électriques BT issue du classeur Excel **CLAUREG V3.6 (2013)**.
Marque : DevisApps. Langue de l'UI et du code métier : français. Dart/Flutter, VS Code.

## Objectif V1 : calculs de câbles
Porter en Dart, de façon fidèle, les calculs du classeur :
1. Protection contre les surcharges (Iz, coefficient K selon modes de pose B/C/D/E/F, choix du calibre In)
2. Chute de tension (circuit, section, longueur, cos φ, ame cuivre/alu)
3. Contrainte thermique
4. Ik max (Icc Max) et Ik min (CI, CI GE)
5. Règle du triangle
6. Résistance maximum du PE (disjoncteurs, fusibles)

Hors V1 : contacts indirects TN/IT, filiation constructeurs, clausier Opale, checklists BE2/BE3, HT, ERP, RICT.

## Source de vérité
`docs/claureg_extraction.md` : formules et valeurs de chaque cellule des onglets de calcul
(Surcharges, K pour methode B..F, Chute de tension, Contrainte Thermique, Icc Max, Ik min CI, Ik min CI GE,
Règle du triangle, Résistance PE DJ/Fusibles, Surintensités). Le classeur original est `CLAUREG V3.6 rev 1.xlsm`
(à copier dans `docs/` si besoin).

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
