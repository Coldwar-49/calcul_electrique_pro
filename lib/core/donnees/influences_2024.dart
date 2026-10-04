/// Influences externes : corrections apportées aux seuils du classeur (2013) par
/// les tableaux 52.3A (câbles) et 52.4 (conduits) de la NF C 15-100-1 (2024-08).
///
/// Seules les cases qui diffèrent sont reprises. Non repris :
/// - la colonne AN (rayonnement solaire), nouvelle : l'application n'a pas
///   cette influence ;
/// - H05RN-F : câble absent du tableau 2024 (le plus proche, H05RR-F, est trop
///   différent pour être substitué) ;
/// - MRL et CSA, influence BC : le classeur la déclare toujours contraignante
///   (texte fixe), alors que le tableau 52.4 admet BC1 et BC2 ;
/// - les cellules à niveaux listés (« 2,3 » pour BB / BC de H05VV-F…), dont le
///   niveau 1 est sans contrainte.
library;

import 'influences.dart';
import 'influences_cables_conduits.dart';
import 'types.dart';

const _noteAaBas = NoteInfluence(
  'Toléré hors de la plage AA indiquée si le câble n\'est soumis à aucun '
  'effort mécanique (tableau 52.3A, note a)',
  [ConditionNiveau('AA', '<', 4)],
);
const _noteAaHaut = NoteInfluence(
  'Toléré hors de la plage AA indiquée si le câble n\'est soumis à aucun '
  'effort mécanique (tableau 52.3A, note a)',
  [ConditionNiveau('AA', '>', 6)],
);
const _noteAd7 = NoteInfluence(
  'AD7 : durée d\'immersion cumulée limitée à deux mois par an '
  '(tableau 52.3A, note d)',
  [ConditionNiveau('AD', '=', 7)],
);

class _Correction {
  const _Correction(this.regles, [this.notes = const []]);
  final Map<String, RegleInfluence> regles;
  final List<NoteInfluence> notes;
}

const Map<String, _Correction> _corrections = {
  'U1000R2V': _Correction(
    {'AA': RegleInfluence(min: 4, max: 6)},
    [_noteAaBas, _noteAaHaut, _noteAd7],
  ),
  'U1000RVFV': _Correction(
    {'AA': RegleInfluence(min: 4, max: 6), 'AK': RegleInfluence(max: 1)},
    [_noteAaBas, _noteAaHaut, _noteAd7],
  ),
  'H07BN4F': _Correction(
    {
      'AA': RegleInfluence(min: 4, max: 6),
      'AG': RegleInfluence(max: 3),
      'AH': RegleInfluence(max: 2),
    },
    [_noteAaBas, _noteAaHaut, _noteAd7],
  ),
  'H07RNF': _Correction(
    {'AG': RegleInfluence(max: 3), 'AH': RegleInfluence(max: 2)},
    [_noteAd7],
  ),
  'H07RN8F': _Correction(
    {
      'AA': RegleInfluence(min: 4, max: 6),
      'AG': RegleInfluence(max: 3),
      'AH': RegleInfluence(max: 2),
    },
    [_noteAaBas, _noteAaHaut],
  ),
  'H05VVF': _Correction(
    {'AA': RegleInfluence(min: 5, max: 6), 'AH': RegleInfluence(max: 2)},
    [_noteAaBas, _noteAaHaut],
  ),
  'CR1': _Correction(
    {'AA': RegleInfluence(min: 4, max: 6), 'AD': RegleInfluence(max: 3)},
    [_noteAaBas, _noteAaHaut],
  ),
};

TypeInfluence _appliquer(TypeInfluence t, EditionNorme edition) {
  final c = _corrections[t.nom];
  if (edition == EditionNorme.norme2013 || c == null) return t;
  // Les notes AA « hors plage » dépendent des bornes propres au câble : on
  // adapte les conditions aux nouvelles règles AA.
  final aa = c.regles['AA'];
  final notes = [
    for (final n in c.notes)
      if (aa != null && n.conditions.length == 1 && n.conditions.first.code == 'AA')
        NoteInfluence(
          n.texte,
          [
            n.conditions.first.operateur == '<'
                ? ConditionNiveau('AA', '<', aa.min ?? 1)
                : ConditionNiveau('AA', '>', aa.max ?? 8),
          ],
        )
      else
        n,
  ];
  return TypeInfluence(
    nom: t.nom,
    usageCourant: t.usageCourant,
    regles: {...t.regles, ...c.regles},
    contraintesFixes: t.contraintesFixes,
    notes: [...t.notes, ...notes],
  );
}

/// Câbles selon l'édition : 2013 = classeur, actuelle = corrections 2024.
List<TypeInfluence> cablesPourEdition(EditionNorme edition) =>
    [for (final t in typesCables) _appliquer(t, edition)];

/// Conduits selon l'édition (aucune correction n'est reprise en 2024).
List<TypeInfluence> conduitsPourEdition(EditionNorme edition) => typesConduits;
