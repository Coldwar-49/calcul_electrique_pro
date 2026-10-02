#!/usr/bin/env python3
"""Génère les données du module « Données de référence » depuis son extraction.

Usage : python tools/generer_influences.py docs/modules/03_donnees_reference.md

Produit :
  - lib/core/donnees/influences_cables_conduits.dart : pour chaque type de câble
    ou de conduit, les seuils d'influences externes (formules `IF($G$8>8,"AA/","")`
    des colonnes Z:AF) et les remarques « Toléré si… » affichées en colonne F ;
  - lib/core/donnees/choix_table_article.dart : tableau « Choix table Article ».

Le script ne devine rien : une formule hors des motifs connus est signalée.
"""
import re
import sys

FORMULE_CODE = re.compile(r'"([A-Z]{2})/"')


# ----------------------------------------------------------------- lecture

def lire_sections(chemin):
    """{nom d'onglet: [lignes]} depuis les titres « ### Onglet « X » »."""
    sections, courant = {}, None
    for ligne in open(chemin, encoding='utf-8'):
        m = re.match(r'^### Onglet « (.*) »', ligne)
        if m:
            courant = m.group(1)
            sections[courant] = []
        elif courant is not None:
            sections[courant].append(ligne.rstrip('\n'))
    return sections


def cellules(lignes):
    """{adresse: valeur} depuis les lignes « - A1: x | B1: y »."""
    d = {}
    for ligne in lignes:
        if not ligne.startswith('- '):
            continue
        for morceau in ligne[2:].split(' | '):
            m = re.match(r'^([A-Z]+\d+): ?(.*)$', morceau)
            if m:
                d[m.group(1)] = m.group(2).strip()
    return d


# ---------------------------------------------------------- mini-formules

def decouper_args(s):
    """Découpe « a,b,c » au premier niveau (guillemets et parenthèses)."""
    args, prof, cour, guill = [], 0, '', False
    for ch in s:
        if ch == '"':
            guill = not guill
        if not guill:
            if ch == '(':
                prof += 1
            elif ch == ')':
                prof -= 1
            elif ch == ',' and prof == 0:
                args.append(cour)
                cour = ''
                continue
        cour += ch
    args.append(cour)
    return args


def sans_dollar(s):
    return s.replace('$', '').strip()


def condition(expr, e_val, codes_par_cellule, avertir):
    """Évalue/convertit une condition.

    Retourne True/False (si elle ne dépend que de la colonne E) ou un tuple
    ('niv', code, op, valeur) si elle porte sur un niveau d'influence, ou
    ('et', [conditions]).
    """
    expr = sans_dollar(expr)
    while expr.startswith('(') and expr.endswith(')') and decouper_args(expr[1:-1]) == [expr[1:-1]]:
        expr = expr[1:-1]
    m = re.match(r'^AND\((.*)\)$', expr)
    if m:
        parts = [condition(a, e_val, codes_par_cellule, avertir) for a in decouper_args(m.group(1))]
        return ('et', parts)
    m = re.match(r'^E\d+="(OUI|NON)"$', expr)
    if m:
        return e_val == m.group(1)
    m = re.match(r'^([A-Z]+8)(<|>|=)(\d+)$', expr)
    if m:
        cell = m.group(1)
        if cell not in codes_par_cellule:
            avertir(f'cellule de niveau inconnue {cell} dans {expr}')
            return None
        return ('niv', codes_par_cellule[cell], m.group(2), int(m.group(3)))
    avertir(f'condition non reconnue : {expr}')
    return None


def evaluer_si(formule, e_val, codes_par_cellule, avertir):
    """Transforme =IF(...) en liste d'alternatives [(conditions ou None, texte)].

    Chaque alternative correspond à une branche renvoyant un texte non vide.
    `conditions` est None si la branche est toujours vraie, sinon une liste de
    conditions qui doivent TOUTES être vraies (ET).
    """
    f = sans_dollar(formule.lstrip('='))
    m = re.match(r'^IF\((.*)\)$', f)
    if not m:
        txt = f.strip('"')
        return [(None, txt)] if txt else []
    args = decouper_args(m.group(1))
    if len(args) != 3:
        avertir(f'IF à {len(args)} arguments : {f}')
        return []
    cond = condition(args[0], e_val, codes_par_cellule, avertir)
    alors = evaluer_si('=' + args[1], e_val, codes_par_cellule, avertir) if args[1].strip() else []
    sinon = evaluer_si('=' + args[2], e_val, codes_par_cellule, avertir) if args[2].strip() else []
    # texte direct entre guillemets
    def texte_si_litteral(a):
        a = a.strip()
        return a[1:-1] if a.startswith('"') and a.endswith('"') else None
    alors_lit, sinon_lit = texte_si_litteral(args[1]), texte_si_litteral(args[2])
    if alors_lit is not None:
        alors = [(None, alors_lit)] if alors_lit else []
    if sinon_lit is not None:
        sinon = [(None, sinon_lit)] if sinon_lit else []

    if cond is True:
        return alors
    if cond is False:
        return sinon
    if cond is None:
        return []
    conds = cond[1] if cond[0] == 'et' else [cond]
    sortie = []
    for c_alors, texte in alors:
        sortie.append((conds + (c_alors or []), texte))
    # branche « sinon » : conservée telle quelle (conditions propres)
    sortie.extend(sinon)
    return sortie


# ----------------------------------------------------------------- feuilles

CODES_ORDRE = ['AA', 'AD', 'AE', 'AF', 'AG', 'AH', 'AK', 'AL', 'BB', 'BC', 'BD', 'BE', 'CA', 'CB']
COLS_Z_AF = ['Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF']


def regle_depuis_formule(f, codes_par_cellule, avertir):
    """('code', max, min, exclus) pour une formule de seuil, ou ('code','toujours')."""
    f = sans_dollar(f)
    if f == '' :
        return None
    if re.fullmatch(r'[A-Z]{2}/', f):
        return (f[:-1], 'toujours')
    # =IF(G8>8,"AA/","")
    m = re.match(r'^=IF\(([A-Z]+8)(>|<|=)(\d+),"([A-Z]{2})/",""\)$', f)
    if m:
        cell, op, n, code = m.group(1), m.group(2), int(m.group(3)), m.group(4)
        if codes_par_cellule.get(cell) != code:
            avertir(f'incohérence : {cell} ({codes_par_cellule.get(cell)}) pour le code {code} dans {f}')
        return (code, op, n)
    # =IF(G8<3,"AA/",IF(G8>5,"AA/",""))
    m = re.match(r'^=IF\(([A-Z]+8)<(\d+),"([A-Z]{2})/",IF\(([A-Z]+8)>(\d+),"([A-Z]{2})/",""\)\)$', f)
    if m and m.group(1) == m.group(4) and m.group(3) == m.group(6):
        code = m.group(3)
        if codes_par_cellule.get(m.group(1)) != code:
            avertir(f'incohérence : {m.group(1)} pour le code {code} dans {f}')
        return (code, '<>', int(m.group(2)), int(m.group(5)))
    avertir(f'formule de seuil non reconnue : {f}')
    return None


def lire_types(cell, lignes_types, avertir, codes_par_cellule):
    """lignes_types : [ligne de nom, ...] ; chaque type occupe deux lignes r et r+1."""
    types = []
    for r in lignes_types:
        nom = cell.get(f'D{r}')
        e_val = cell.get(f'E{r}')
        if not nom or e_val not in ('OUI', 'NON'):
            avertir(f'ligne {r} : nom/E introuvables ({nom!r}, {e_val!r})')
            continue
        regles = {}
        for rr in (r, r + 1):
            for col in COLS_Z_AF:
                f = cell.get(f'{col}{rr}')
                if f is None:
                    continue
                res = regle_depuis_formule(f, codes_par_cellule, avertir)
                if res is None:
                    continue
                code = res[0]
                if code in regles:
                    avertir(f'{nom} : code {code} défini deux fois')
                regles[code] = res[1:]
        # Contraintes affichées (colonne J) : formule SUBSTITUTE ou texte fixe.
        j = cell.get(f'J{r}')
        fixes = None
        if j is not None and not j.startswith('='):
            fixes = [c for c in j.split() if c]
        elif j is None:
            fixes = []
        # Remarques affichées (colonne F).
        f_col = cell.get(f'F{r}', '')
        notes = []
        if f_col.startswith('='):
            ref = re.fullmatch(r'=T(\d+)', f_col)
            if ref:
                t_formule = cell.get(f'T{ref.group(1)}', '')
                if t_formule:
                    notes = evaluer_si(t_formule, e_val, codes_par_cellule, avertir)
            else:
                avertir(f'{nom} : colonne F inattendue {f_col!r}')
        else:
            t = f_col.strip().strip(',').strip()
            if t:
                notes = [(None, t)]
        types.append(dict(nom=nom, usage_courant=(e_val == 'OUI'), regles=regles,
                          fixes=fixes, notes=notes))
    return types


def niveaux_cellules(cell):
    """{cellule de niveau (ex. 'G8'): code} depuis la ligne d'en-tête 6."""
    d = {}
    for col in ['B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'R']:
        code = cell.get(f'{col}6')
        if code:
            d[f'{col}8'] = code
    return d


# --------------------------------------------------------------- sorties Dart

def q(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def dart_regle(r):
    if r[0] == 'toujours':
        return 'RegleInfluence.toujours()'
    if r[0] == '>':
        return f'RegleInfluence(max: {r[1]})'
    if r[0] == '<':
        return f'RegleInfluence(min: {r[1]})'
    if r[0] == '=':
        return f'RegleInfluence(exclus: {{{r[1]}}})'
    if r[0] == '<>':
        return f'RegleInfluence(min: {r[1]}, max: {r[2]})'
    raise ValueError(r)


def dart_note(cond, texte):
    if cond is None:
        conds = 'const []'
    else:
        conds = '[' + ', '.join(f"ConditionNiveau({q(c[1])}, {q(c[2])}, {c[3]})" for c in cond) + ']'
        conds = 'const ' + conds if False else conds
    return f'NoteInfluence({q(texte)}, {conds if cond is not None else "[]"})'


def ecrire_types(nom_var, types):
    out = [f'const List<TypeInfluence> {nom_var} = [']
    for t in types:
        out.append('  TypeInfluence(')
        out.append(f"    nom: {q(t['nom'])},")
        out.append(f"    usageCourant: {'true' if t['usage_courant'] else 'false'},")
        if t['fixes'] is not None and t['fixes'] != []:
            out.append('    contraintesFixes: [' + ', '.join(q(c) for c in t['fixes']) + '],')
        out.append('    regles: {')
        for code in CODES_ORDRE:
            if code in t['regles']:
                out.append(f"      {q(code)}: {dart_regle(t['regles'][code])},")
        out.append('    },')
        if t['notes']:
            out.append('    notes: [')
            for cond, texte in t['notes']:
                out.append('      ' + dart_note(cond, texte) + ',')
            out.append('    ],')
        out.append('  ),')
    out.append('];')
    return out


def ecrire_influences(sections):
    avertissements = []

    def avertir_f(feuille):
        return lambda m: avertissements.append(f'[{feuille}] {m}')

    out = ["/// Influences externes : seuils par type de câble et de conduit.",
           "///",
           "/// FICHIER GÉNÉRÉ par tools/generer_influences.py depuis",
           "/// docs/modules/03_donnees_reference.md : ne pas modifier à la main.",
           "library;",
           "",
           "import 'influences.dart';",
           ""]
    resume = []
    for feuille, var, lignes_types in (
        ('IP-IK Cables', 'typesCables', [14, 16, 18, 20, 22, 24, 26, 28]),
        ('IP-IK Conduits', 'typesConduits', [13, 15, 17, 19, 21, 23, 25, 27, 29]),
    ):
        cell = cellules(sections[feuille])
        codes = niveaux_cellules(cell)
        types = lire_types(cell, lignes_types, avertir_f(feuille), codes)
        out.extend(ecrire_types(var, types))
        out.append('')
        resume.append((feuille, types))
    return out, resume, avertissements


def ecrire_table_article(sections):
    cell_lignes = sections['Choix table Article']
    lignes = []
    for ligne in cell_lignes:
        if not ligne.startswith('- A'):
            continue
        d = {}
        for morceau in ligne[2:].split(' | '):
            m = re.match(r'^([A-J])(\d+): ?(.*)$', morceau)
            if m:
                d[m.group(1)] = m.group(3).strip()
        if len(d) == 10 and d['A'] not in ('Régime du neutre principal',):
            lignes.append(d)
    out = ["/// Tableau d'aide au choix d'une table article (Opale Électricité).",
           "///",
           "/// FICHIER GÉNÉRÉ par tools/generer_influences.py depuis",
           "/// docs/modules/03_donnees_reference.md : ne pas modifier à la main.",
           "library;",
           "",
           "import 'choix_table_article_modele.dart';",
           "",
           "const List<LigneChoixTable> choixTableArticle = ["]
    for d in lignes:
        champs = ', '.join(q(d[c]) for c in 'ABCDEFGHI')
        out.append(f"  LigneChoixTable({champs}, {int(d['J'])}),")
    out.append('];')
    out.append('')
    return out, len(lignes)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sections = lire_sections(sys.argv[1])
    sortie, resume, avertissements = ecrire_influences(sections)
    chemin = 'lib/core/donnees/influences_cables_conduits.dart'
    open(chemin, 'w', encoding='utf-8', newline='\n').write('\n'.join(sortie))
    print(f'Écrit : {chemin}', file=sys.stderr)

    sortie2, n = ecrire_table_article(sections)
    chemin2 = 'lib/core/donnees/choix_table_article.dart'
    open(chemin2, 'w', encoding='utf-8', newline='\n').write('\n'.join(sortie2))
    print(f'Écrit : {chemin2} ({n} lignes)', file=sys.stderr)

    # Résumé lisible pour relecture.
    for feuille, types in resume:
        print(f'\n== {feuille}', file=sys.stderr)
        for t in types:
            print(f"  {t['nom']} (usage courant: {t['usage_courant']}) fixes={t['fixes']}", file=sys.stderr)
            print('    seuils:', {c: t['regles'][c] for c in CODES_ORDRE if c in t['regles']}, file=sys.stderr)
            for cond, texte in t['notes']:
                print(f'    note: {texte!r} si {cond}', file=sys.stderr)
    if avertissements:
        print('\nAVERTISSEMENTS :', file=sys.stderr)
        for a in avertissements:
            print('  ', a, file=sys.stderr)


if __name__ == '__main__':
    main()
