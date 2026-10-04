/// Glossaire des bulles d'aide : libellé d'un champ -> explication.
///
/// [ChampNombre] et [ListeDeroulante] y cherchent automatiquement le texte
/// correspondant à leur libellé (survol à la souris, appui long au doigt).
/// Les textes définissent les grandeurs ; ils ne contiennent aucune valeur
/// normative qui ne soit déjà dans les calculs.
library;

const Map<String, String> _aides = {
  // --- Réseau amont, transformateur, groupe ---
  'Tension entre phases':
      'Tension composée du réseau (entre deux phases), ex. 400 V en '
      'triphasé. C\'est la tension à vide du secondaire du transformateur '
      'ou de l\'alternateur.',
  'Pcc amont':
      'Puissance de court-circuit du réseau en amont du transformateur '
      '(en MVA), donnée par le distributeur d\'énergie. Plus elle est '
      'grande, plus le réseau amont est « rigide » et plus le courant de '
      'court-circuit est élevé.',
  'Couplage':
      'Mode de raccordement des enroulements du transformateur (ex. Dyn11 : '
      'primaire en triangle, secondaire en étoile avec neutre sorti). Il '
      'détermine notamment le comportement du neutre et le courant de '
      'défaut phase-neutre.',
  'Puissance du transformateur':
      'Puissance apparente nominale du transformateur (kVA), lue sur sa '
      'plaque signalétique.',
  'Tension de court-circuit Ucc':
      'Tension (en % de la tension nominale) à appliquer au primaire, '
      'secondaire en court-circuit, pour y faire circuler le courant '
      'nominal. Plus Ucc est faible, plus le courant de court-circuit '
      'du transformateur est fort. Valeur de la plaque signalétique.',
  'Transformateurs en parallèle':
      'Nombre de transformateurs identiques couplés sur le même jeu de '
      'barres. Les courants de court-circuit s\'additionnent.',
  'Groupes en parallèle':
      'Nombre de groupes électrogènes identiques couplés sur le même jeu de '
      'barres.',
  'Puissance':
      'Puissance nominale de la source ou du récepteur (voir l\'unité '
      'affichée à droite du champ).',
  'Réactance transitoire x\'d':
      'Réactance de l\'alternateur juste après l\'apparition du défaut (en '
      '%), donnée par le constructeur. Elle fixe le courant de '
      'court-circuit du groupe pendant les premières périodes.',
  'Réactance homopolaire x0':
      'Réactance de l\'alternateur vis-à-vis des courants homopolaires (en '
      '%), donnée par le constructeur. Elle intervient dans le défaut '
      'phase-terre ou phase-neutre.',
  'Régime de neutre':
      'Schéma de liaison à la terre de l\'installation : TN (masses reliées '
      'au neutre), TT (masses à une prise de terre distincte) ou IT '
      '(neutre isolé ou impédant).',

  // --- Conducteurs ---
  'Âme':
      'Matière du conducteur : cuivre ou aluminium. Elle fixe la '
      'résistivité utilisée dans les calculs.',
  'Âme S1': 'Matière du conducteur du câble S1 (cuivre ou aluminium).',
  'Âme S2': 'Matière du conducteur du câble S2 (cuivre ou aluminium).',
  'Longueur': 'Longueur de la liaison ou du tronçon, en mètres.',
  'Section phase (mm²)': 'Section d\'un conducteur de phase, en mm².',
  'Section de phase (mm²)': 'Section d\'un conducteur de phase, en mm².',
  'Section (mm²)': 'Section d\'un conducteur, en mm².',
  'Section neutre (mm²)': 'Section du conducteur neutre, en mm².',
  'Section PE (mm²)': 'Section du conducteur de protection (PE), en mm².',
  'Section du PE (mm²)': 'Section du conducteur de protection (PE), en mm².',
  'Phases par pôle':
      'Nombre de conducteurs en parallèle pour chaque phase. Le courant se '
      'répartit entre eux et l\'impédance de la liaison diminue.',
  'Conducteurs par phase':
      'Nombre de conducteurs en parallèle pour chaque phase.',
  'Conducteurs par pôle':
      'Nombre de conducteurs en parallèle pour chaque pôle (phase ou '
      'neutre).',
  'Conducteurs de phase par pôle':
      'Nombre de conducteurs de phase en parallèle pour chaque pôle.',
  'Conducteurs en parallèle par phase':
      'Nombre de conducteurs montés en parallèle pour chaque phase (lettre L '
      'dans le classeur).',
  'Neutres par pôle': 'Nombre de conducteurs neutres en parallèle.',
  'PE par pôle': 'Nombre de conducteurs de protection (PE) en parallèle.',
  'Conducteurs de PE par pôle':
      'Nombre de conducteurs de protection (PE) en parallèle.',
  'Position du PE':
      'Le conducteur de protection (PE) est-il dans la même canalisation '
      'que les phases, ou dans une canalisation différente ? Ce choix '
      'détermine les isolants proposés pour le coefficient k.',
  'Isolant':
      'Nature de l\'isolant du conducteur (PVC, PR…), qui fixe la '
      'température limite admissible et donc le coefficient k.',
  'Type de câble':
      'Désignation du câble. Elle détermine son isolant (PVC ou PR), donc '
      'les formules de courant admissible.',

  // --- Surcharges et coefficient K ---
  'Circuit':
      'Monophasé ou triphasé : nombre de conducteurs chargés, qui '
      'change le courant admissible et la chute de tension.',
  'Mode de pose':
      'Méthode de référence de pose du câble (B, C, D, E ou F). Elle fixe '
      'la formule du courant admissible et les coefficients de '
      'correction applicables.',
  'Coefficient K':
      'Coefficient global M = K1 × … × K7 qui corrige le courant admissible '
      '(température, groupement, nature du sol, etc.). 1 si aucune '
      'correction ne s\'applique.',
  'Coefficient K (M)':
      'Coefficient global M = K1 × … × K7. Le calculer avec l\'assistant de '
      'l\'écran Surcharges.',
  'Circuits ou câbles multiconducteurs groupés':
      'Nombre de circuits (ou de câbles multiconducteurs) posés ensemble '
      'dans le même cheminement. Le groupement réduit le courant '
      'admissible.',
  'Nombre de couches':
      'Nombre de couches de câbles superposées sur le support (chemin de '
      'câbles, tablette).',
  'Distance entre câbles':
      'Espacement entre les câbles : des câbles espacés s\'échauffent moins '
      'que des câbles jointifs.',
  'Coefficient complémentaire K7':
      'Coefficient supplémentaire laissé à votre appréciation (1 par '
      'défaut) pour une correction non prévue par les autres.',
  'Température ambiante':
      'Température de l\'air autour du câble. Au-dessus de la valeur de '
      'référence, le courant admissible diminue.',
  'Température du sol':
      'Température du terrain où le câble est enterré. Au-dessus de la '
      'valeur de référence, le courant admissible diminue.',

  // --- Chute de tension, courant d'emploi, puissance ---
  'Tension U0':
      'Tension simple (phase-neutre), ex. 230 V. En triphasé 400 V, '
      'U0 = 400 / √3.',
  'Tension simple U0':
      'Tension simple (phase-neutre), ex. 230 V. En triphasé 400 V, '
      'U0 = 400 / √3.',
  'Tension phase / neutre (TN, ITAN)':
      'Tension simple U0 entre phase et neutre, utilisée en régime TN et '
      'IT avec neutre distribué.',
  'Tension entre phases (ITSN)':
      'Tension composée entre phases, utilisée en régime IT sans neutre '
      'distribué.',
  'Tension': 'Tension d\'alimentation du récepteur ou du circuit, en volts.',
  'Conducteur de terre':
      'Conducteur reliant la borne principale de terre à la prise de terre. '
          'Enterré, sa section minimale dépend de sa nature (tableau 54.2) ; '
          'l\'aluminium est interdit. Dans tous les cas il doit aussi '
          'respecter l\'art. 543.1 (comme le PE).',
  'Alimentation du moteur':
      'Moteur monophasé 230 V ou triphasé 400 V : les limites du tableau '
          'dépendent du type d\'alimentation.',
  'Type de local':
      'Habitation (branchement à puissance limitée) ou autres locaux '
          '(tertiaire, industriel, agricole… avec branchement à puissance '
          'surveillée) : les limites ne sont pas les mêmes.',
  'Réseau de distribution':
      'Réseau public aérien ou souterrain : un réseau souterrain, plus '
          'robuste, admet des moteurs plus puissants et un courant de '
          'démarrage plus élevé.',
  'Mode de démarrage':
      'Démarrage direct à pleine puissance, ou autre mode (étoile-triangle, '
          'démarreur progressif, variateur…) qui limite le courant d\'appel.',
  'Puissance du moteur (facultatif)':
      'Puissance apparente du moteur en kVA. Vide : seule la limite est '
          'affichée.',
  'Intensité de démarrage (facultatif)':
      'Courant d\'appel du moteur au démarrage, en ampères. Vide : seule la '
          'limite est affichée.',
  'Résistivité thermique du sol':
      'Capacité du terrain à évacuer la chaleur du câble enterré, en K·m/W. '
          'Les courants admissibles du tableau 52.8H sont établis pour '
          '2,5 K·m/W ; un sol plus conducteur (plus humide, plus faible '
          'valeur) augmente le courant admissible (tableau 52.11). Un sol sec '
          'est généralement plus proche de 1 K·m/W en France.',
  'Taux d\'harmoniques de rang 3':
      'Part des harmoniques de rang 3 (et multiples de 3) dans le courant '
          'de phase, en %. Elles s\'additionnent dans le neutre. Au-delà de '
          '15 %, le tableau 52.20 impose un coefficient ; au-delà de 33 %, '
          'le neutre dimensionne le câble.',
  'Câbles du circuit triphasé':
      'Câble multiconducteur (phases et neutre dans le même câble) ou câbles '
          'monoconducteurs : le tableau 52.20 distingue les deux cas.',
  'Résistivité ρ (isolant et température)':
      'Résistivité de l\'âme à la température de service normale, selon '
          'l\'isolant (tableau 52.24 de la NF C 15-100-1, 2024). « Valeur du '
          'classeur » garde les valeurs 0,023 (Cu) et 0,037 (Al).',
  'cos φ':
      'Facteur de puissance du récepteur : rapport entre puissance active '
      'et puissance apparente.',
  'cos φ moyen': 'Facteur de puissance moyen de l\'ensemble des récepteurs.',
  'Facteur de puissance cos φ':
      'Rapport entre la puissance active (kW) et la puissance apparente '
      '(kVA). 1 pour une charge purement résistive.',
  'Courant d\'emploi Ib':
      'Courant que le circuit doit réellement transporter en service '
      'normal. Il sert de base au choix du calibre de la protection.',
  'Usage':
      'Éclairage ou force : le seuil de chute de tension admissible '
      'n\'est pas le même.',
  'Alimentation': 'Monophasée ou triphasée : change la formule du courant.',
  'Rendement':
      'Rapport entre la puissance utile (mécanique) et la puissance '
      'absorbée. 1 si la puissance saisie est déjà la puissance '
      'absorbée.',
  'Puissance Pn': 'Puissance nominale du récepteur.',
  'Ku (utilisation)':
      'Facteur d\'utilisation : fraction de la puissance nominale '
      'réellement appelée par le récepteur en fonctionnement.',
  'Ks (simultanéité)':
      'Facteur de simultanéité : fraction des récepteurs d\'un groupe '
      'susceptibles de fonctionner en même temps.',
  'Ks global':
      'Facteur de simultanéité appliqué à l\'ensemble de l\'installation.',
  'Puissance active P': 'Puissance active de l\'installation, en kW.',
  'cos φ actuel': 'Facteur de puissance avant compensation.',
  'cos φ visé':
      'Facteur de puissance que l\'on veut atteindre après '
      'compensation.',

  // --- Protections ---
  'Calibre': 'Courant assigné In de l\'appareil de protection, en ampères.',
  'Calibre In':
      'Courant assigné In de l\'appareil de protection, en '
      'ampères.',
  'Calibre du fusible': 'Courant assigné du fusible, en ampères.',
  'Type de fusible':
      'Famille du fusible : gG (usage général) ou aM (accompagnement '
      'moteur). Elle fixe le courant de fusion garanti.',
  'Type de disjoncteur':
      'Catégorie du disjoncteur : petit disjoncteur (courbe de '
      'déclenchement fixe) ou disjoncteur industriel (déclencheur '
      'réglable).',
  'Courbe':
      'Courbe de déclenchement magnétique du disjoncteur (B, C, D…) : elle '
      'fixe le multiple de In à partir duquel il déclenche '
      'instantanément.',
  'Réglage magnétique':
      'Choix du seuil du déclencheur magnétique (déclenchement '
      'instantané) du disjoncteur de protection P.',
  'Multiple de Ir':
      'Seuil du déclencheur magnétique exprimé en multiple du réglage '
      'thermique Ir.',
  'Réglage du magnétique (multiple de Ir)':
      'Seuil du déclencheur magnétique exprimé en multiple du réglage '
      'thermique Ir.',
  'Réglage thermique Ir':
      'Courant de réglage du déclencheur thermique (long retard), en '
      'ampères. Il est compris entre une fraction de In et In.',
  'Facteur de réglage':
      'Premier facteur de la calculatrice : Ir = In × facteur de réglage × '
      'facteur de correction.',
  'Facteur de correction':
      'Second facteur de la calculatrice : Ir = In × facteur de réglage × '
      'facteur de correction.',
  'Rapport Sph / Spe':
      'Rapport entre la section du conducteur de phase et celle du '
      'conducteur de protection (1, 2 ou 3 dans le classeur). Il '
      'intervient dans le coefficient k2 de la résistance maximale.',
  'Ik maximal (Ik3, Ik2 ou Ik1)':
      'Plus grand courant de court-circuit au point considéré (triphasé, '
      'biphasé ou monophasé), en kA. Il sert à vérifier la tenue '
      'thermique des conducteurs.',
  'Courant de court-circuit Ik':
      'Courant de court-circuit présumé au point d\'installation de '
      'l\'appareil, en kA.',
  'Courant de double défaut Id2 sur un pôle':
      'En régime IT, courant circulant lorsque deux défauts d\'isolement '
      'surviennent sur des phases différentes, ramené à un pôle (kA).',
  'Gamme de disjoncteur':
      'Famille de disjoncteurs dont on consulte le pouvoir de coupure.',
  'Taille': 'Dimension (taille) du fusible, qui dépend de son calibre.',
  'Référence': 'Référence commerciale de l\'appareil.',
  'Sensibilité du DDR IΔn':
      'Courant différentiel résiduel assigné du dispositif différentiel '
      '(DDR) : seuil de déclenchement nominal.',
  'Tension limite UL':
      'Tension de contact maximale admissible (50 V en général, 25 V dans '
      'certains locaux : à confirmer dans l\'article de la norme).',

  // --- Section du PE ---
  'Âme de la phase': 'Matière du conducteur de phase : cuivre ou aluminium.',
  'Âme du PE':
      'Matière du conducteur de protection. Si elle diffère de celle de la '
          'phase, la section du tableau 3 est multipliée par k1 / k2.',
  'Isolant de la phase':
      'Isolant du conducteur de phase : il fixe le coefficient k1.',
  'Situation du PE':
      'Façon dont le conducteur de protection est installé (dans le câble, '
          'séparé, nu, enterré ou non). Elle sélectionne le tableau 54A.x de '
          'la norme donnant le coefficient k2.',
  'Isolant ou conditions du PE':
      'Isolant du PE (ou nature de la gaine, conditions d\'installation pour '
          'un PE nu) : il fixe le coefficient k2.',
  'Isolant du PE':
      'Isolant (ou PE nu) du conducteur de protection : il fixe le '
          'coefficient k2 utilisé si les métaux diffèrent ou pour la '
          'vérification thermique.',
  'Protection mécanique du PE':
      'Un PE hors canalisation protégé mécaniquement (conduit, goulotte…) '
          'peut descendre à 2,5 mm² Cu ; sinon 4 mm² Cu. En aluminium : '
          '16 mm² dans les deux cas.',
  'Courant de défaut Ik':
      'Courant de défaut que le PE doit pouvoir supporter, en kA (valeur '
          'maximale au point considéré).',
  'Durée de coupure t':
      'Temps de fonctionnement de la protection pour ce courant, en '
          'secondes (la formule n\'est valable que jusqu\'à 5 s).',

  // --- Règle du triangle ---
  'Section S1 (mm²)':
      'Section du câble principal S1, protégé par le '
      'disjoncteur P.',
  'Section S2 (mm²)': 'Section du câble dérivé S2, plus petit que S1.',
  'Distance entre P et S2':
      'Distance, en mètres, entre le disjoncteur P et le point de '
      'dérivation du câble S2.',
  'Longueur distribuée de S2':
      'Longueur du câble S2 le long de laquelle le courant est distribué.',

  // --- Filiation ---
  'Catalogue':
      'Année d\'édition du catalogue constructeur utilisé pour les '
      'tableaux de filiation.',
  'Réseau': 'Tension du réseau pour laquelle le tableau est établi.',
  'Familles d\'appareils':
      'Famille de disjoncteurs (amont/aval) couverte par le tableau de '
      'filiation affiché.',
  'Disjoncteur amont':
      'Disjoncteur placé en tête, qui assiste le disjoncteur aval pour '
      'couper un fort courant de court-circuit.',
  'Disjoncteur aval':
      'Disjoncteur situé en aval, dont le pouvoir de coupure propre est '
      'insuffisant et qui est renforcé par la filiation.',
};

/// Texte d'aide associé à [libelle], ou `null` s'il n'y en a pas.
String? aidePourLibelle(String libelle) => _aides[libelle];
