"
classe etudiant
"
Class {
	#name : 'Etudiant',
	#superclass : 'Object',
	#instVars : [
		'nom',
		'prenom',
		'matricule',
		'dateNaissance',
		'filiere',
		'moyenne',
		'email',
		'adresse',
		'boursier',
		'montantBourse',
		'remarques',
		'estDiplomable',
		'properties'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'description' }
Etudiant class >> descriptionForAXPL [
	| container |
	container := SRPriorityContainer new label: 'Dossier Académique AXPL'.

	"--- NIVEAU SIMPLE : Identité et Cursus ---"
	container add: (SRStringDescription new
		label: 'Nom';
		accessor: #nom;
		priority: 10;
		level: #simple;
		beRequired;
		comment: (Dictionary new
			at: #simple put: 'Votre nom de famille officiel.';
			at: #base   put: 'Identifiant civil pour les registres universitaires.';
			at: #expert put: 'Clé d''indexation pour la synchronisation des bases nationales.';
			yourself)).

	container add: (SRStringDescription new
		label: 'Prénom';
		accessor: #prenom;
		priority: 20;
		level: #simple;
		beRequired;
		comment: (Dictionary new
			at: #simple put: 'Votre prénom usuel.';
			at: #base   put: 'Prénom utilisé pour la personnalisation des diplômes.';
			at: #expert put: 'Attribut de désambiguïsation pour la gestion des homonymes.';
			yourself)).

	container add: (SRStringDescription new
		label: 'Matricule';
		accessor: #matricule;
		priority: 30;
		level: #simple;
		beRequired;
		comment: (Dictionary new
			at: #simple put: 'Votre numéro d''étudiant unique.';
			at: #base   put: 'Identifiant de session pour les examens et services numériques.';
			at: #expert put: 'Clé primaire liant le dossier pédagogique et financier.';
			yourself)).

	container add: (SRSingleOptionDescription new
		label: 'Filière';
		accessor: #filiere;
		options: #('Informatique' 'Médecine' 'Droit' 'Arts');
		priority: 40;
		level: #simple;
		comment: (Dictionary new
			at: #simple put: 'Votre domaine d''études principal.';
			at: #base   put: 'Parcours académique définissant vos unités d''enseignement.';
			at: #expert put: 'Code de nomenclature disciplinaire pour l''accréditation.';
			yourself)).

	"--- NIVEAU BASE : Suivi et Contact ---"
	container add: (SRNumberDescription new
		label: 'Moyenne';
		accessor: #moyenne;
		priority: 50;
		level: #base;
		addCondition: [ :v | v between: 0 and: 20 ] labelled: 'La moyenne doit être comprise entre 0 et 20.';
		comment: (Dictionary new
			at: #simple put: 'Votre résultat global actuel.';
			at: #base   put: 'Indicateur de performance pour le suivi pédagogique.';
			at: #expert put: 'Variable quantitative pour le calcul du classement et des mentions.';
			yourself)).

	container add: (SRDateDescription new
		label: 'Date Naissance';
		accessor: #dateNaissance;
		priority: 60;
		level: #base;
		comment: (Dictionary new
			at: #base   put: 'Votre date de naissance officielle.';
			at: #expert put: 'Vérification de l''âge légal pour les droits sociaux et assurances.';
			yourself)).

	container add: (SRStringDescription new
		label: 'E-mail';
		accessor: #email;
		priority: 70;
		level: #base;
		comment: (Dictionary new
			at: #simple put: 'Votre adresse de contact universitaire.';
			at: #base   put: 'Canal de communication pour les convocations officielles.';
			at: #expert put: 'Identifiant de sécurité pour l''authentification SSO.';
			yourself)).

	container add: (SRBooleanDescription new
		label: 'Boursier';
		accessor: #boursier;
		priority: 80;
		level: #base;
		comment: (Dictionary new
			at: #simple put: 'Indique si vous bénéficiez d''une aide financière.';
			at: #base   put: 'Statut utilisé pour l''exonération des frais d''inscription.';
			at: #expert put: 'Indicateur de profil social pour les statistiques ministérielles.';
			yourself)).

	"--- NIVEAU EXPERT : Administration et Jury ---"
	container add: (SRNumberDescription new
		label: 'Montant Bourse';
		accessor: #montantBourse;
		priority: 90;
		level: #expert;
		comment: (Dictionary new
			at: #base   put: 'Somme allouée pour l''année universitaire.';
			at: #expert put: 'Variable budgétaire soumise à vérification d''assiduité.';
			yourself)).

	container add: (SRStringDescription new
		label: 'Remarques';
		accessor: #remarques;
		priority: 100;
		level: #expert;
		comment: (Dictionary new
			at: #base   put: 'Commentaires du corps enseignant.';
			at: #expert put: 'Évaluations qualitatives confidentielles du jury de délibération.';
			yourself)).

	container add: (SRBooleanDescription new
		label: 'Éligible Diplôme';
		accessor: #estDiplomable;
		priority: 110;
		level: #expert;
		comment: (Dictionary new
			at: #base   put: 'Vérification des crédits ECTS requis.';
			at: #expert put: 'État logique final validant la fin du cycle universitaire.';
			yourself)).

	container add: (SRStringDescription new
		label: 'Adresse';
		accessor: #adresse;
		priority: 120;
		level: #expert;
		comment: (Dictionary new
			at: #base   put: 'Votre lieu de résidence actuel.';
			at: #expert put: 'Donnée géographique pour la gestion des zones de bourses.';
			yourself)).

	^ container
]

{ #category : 'accessing' }
Etudiant >> adresse [ ^ adresse
]

{ #category : 'accessing' }
Etudiant >> adresse: anObject [ adresse := anObject
]

{ #category : 'accessing' }
Etudiant >> boursier [ ^ boursier
]

{ #category : 'accessing' }
Etudiant >> boursier: anObject [ boursier := anObject
]

{ #category : 'accessing' }
Etudiant >> dateNaissance [ ^ dateNaissance
]

{ #category : 'accessing' }
Etudiant >> dateNaissance: anObject [ dateNaissance := anObject
]

{ #category : 'accessing' }
Etudiant >> email [ ^ email
]

{ #category : 'accessing' }
Etudiant >> email: anObject [ email := anObject
]

{ #category : 'accessing' }
Etudiant >> estDiplomable [ ^ estDiplomable
]

{ #category : 'accessing' }
Etudiant >> estDiplomable: anObject [ estDiplomable := anObject
]

{ #category : 'accessing' }
Etudiant >> filiere [ ^ filiere
]

{ #category : 'accessing' }
Etudiant >> filiere: anObject [ filiere := anObject
]

{ #category : 'initialization' }
Etudiant >> initialize [
	super initialize.
	nom := ''.
	prenom := ''.
	moyenne := 0.
	boursier := false.
	estDiplomable := false.
	filiere := 'Informatique'.
]

{ #category : 'accessing' }
Etudiant >> matricule [ ^ matricule
]

{ #category : 'accessing' }
Etudiant >> matricule: anObject [ matricule := anObject
]

{ #category : 'accessing' }
Etudiant >> montantBourse [ ^ montantBourse
]

{ #category : 'accessing' }
Etudiant >> montantBourse: anObject [ montantBourse := anObject
]

{ #category : 'accessing' }
Etudiant >> properties [
	"Dictionnaire des champs créés dynamiquement par Ψ (⑥)."
	^ properties ifNil: [ properties := Dictionary new ]
]

{ #category : 'accessing' }
Etudiant >> moyenne [ ^ moyenne
]

{ #category : 'accessing' }
Etudiant >> moyenne: anObject [ moyenne := anObject
]

{ #category : 'accessing' }
Etudiant >> nom [ ^ nom
]

{ #category : 'accessing' }
Etudiant >> nom: anObject [ nom := anObject
]

{ #category : 'accessing' }
Etudiant >> prenom [ ^ prenom
]

{ #category : 'accessing' }
Etudiant >> prenom: anObject [ prenom := anObject
]

{ #category : 'accessing' }
Etudiant >> remarques [ ^ remarques
]

{ #category : 'accessing' }
Etudiant >> remarques: anObject [ remarques := anObject
]
