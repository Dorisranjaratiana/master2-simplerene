"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: / setLevel: / setType: / setOptions: / setHelp: —
   modifient une description à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: — synchronise l'explication après intercession.
[t] traceLog — historique horodaté de toutes les intercessions (DateAndTime),
borné à maxTraceEntries pour ne pas croître indéfiniment sur un serveur qui
tourne longtemps.
Instance unique créée dans targetObject: — jamais recréée entre les re-rendus.

INTERCESSION STRUCTURELLE (Maes, 1987) au sens plein du terme :
createField:... ajoute réellement une variable d'instance à la classe métier
(targetClass) via #addInstVarNamed: (repli sur l'API à slots), puis
compile ses accesseur/mutateur via #compile: — exploitant la réflexivité native de
Pharo (redéfinition de classe à chaud, migration automatique des instances
existantes, programmation live) plutôt que de simuler le champ dans une structure
annexe. removeField: effectue l'opération inverse : #removeSelector: sur les
accesseurs, puis retrait de la variable d'instance elle-même — mais UNIQUEMENT si
plus aucune méthode de la classe ne l'utilise (#whichSelectorsAccess:). Un champ
natif dont la variable est encore lue par du code métier (typiquement #initialize)
disparaît donc de la méta-description et perd ses accesseurs, sans qu'on corrompe
la classe en supprimant une variable encore référencée.

N'IMPORTE QUEL CHAMP est modifiable et supprimable : la protection des champs
natifs est désactivée par défaut (protectNativeFields), le mécanisme restant
disponible pour un projet qui voudrait réintroduire une politique de protection.

Toute intercession STRUCTURELLE modifie targetClass, un objet global et partagé : les
opérations sont sérialisées via un Mutex pour rester sûres si le serveur HTTP traite
plusieurs requêtes en parallèle (un process Zn par connexion).""
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog',
		'targetClass',
		'psiCreatedAccessors',
		'mutex',
		'protectNativeFields'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLReflexivityEngine class >> maxTraceEntries [
	^ 500
]

{ #category : 'private' }
AXPLReflexivityEngine >> axplTranslit: aCharacter [
	"Traduit un caractère accentué français vers son équivalent ASCII, conserve
	lettres/chiffres, transforme les séparateurs usuels, ignore le reste."
	| accented ascii index |
	accented := 'éèêëàâäùûüôöîïçÉÈÊËÀÂÄÙÛÜÔÖÎÏÇ'.
	ascii := 'eeeeaaaauuuooiicEEEEAAAAUUUOOIIC'.
	index := accented indexOf: aCharacter.
	index > 0 ifTrue: [ ^ (ascii at: index) asString ].
	(aCharacter isLetter or: [ aCharacter isDigit ]) ifTrue: [ ^ aCharacter asString ].
	(' -''_.,;:()[]{}/\@#' includes: aCharacter) ifTrue: [ ^ aCharacter asString ].
	^ ''
]

{ #category : 'private' }
AXPLReflexivityEngine >> checkValidLevel: aLevelSymbol [
	(#(#simple #base #expert) includes: aLevelSymbol) ifFalse: [
		AXPLInvalidPayloadError signal: 'Niveau inconnu : "' , aLevelSymbol asString , '".' ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> commentDictionaryFrom: aHelp [
	"Construit le dictionnaire d'explications graduées (X) à partir soit d'une String
	unique appliquée aux trois niveaux, soit d'un dictionnaire déjà gradué."
	| dict |
	dict := Dictionary new.
	(aHelp isKindOf: Dictionary)
		ifTrue: [
			#( #simple #base #expert ) do: [ :lvl |
				dict at: lvl put: (aHelp
					at: lvl asString
					ifAbsent: [ aHelp at: lvl ifAbsent: [ '' ] ]) ] ]
		ifFalse: [
			#( #simple #base #expert ) do: [ :lvl |
				dict at: lvl put: (aHelp ifNil: [ '' ]) ] ].
	^ dict
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aTypeSymbol level: aLevelSymbol help: aHelp options: anOptionsCollection [
	"④ Intercession STRUCTURELLE : ajoute une véritable variable d'instance à targetClass
	et compile ses accesseur/mutateur, puis enregistre la description dans la méta-description.
	La migration des instances existantes (dont targetObject) est gérée nativement par Pharo."
	^ mutex critical: [
		| accessorName descClass description priority |
		(aLabel isNil or: [ aLabel isEmpty ]) ifTrue: [
			AXPLInvalidPayloadError signal: 'Le label est requis.' ].
		self checkValidLevel: aLevelSymbol.
		(self readDescription: aLabel) ifNotNil: [
			AXPLFieldAlreadyExistsError signal: 'Un champ nommé "' , aLabel , '" existe déjà.' ].

		descClass := AXPLFieldTypeRegistry default descriptionClassFor: aTypeSymbol.
		accessorName := self uniqueInstVarNameFor: aLabel.

		self addInstanceVariableNamed: accessorName.

		targetClass compile: accessorName , String lf , '^ ' , accessorName.
		targetClass compile: accessorName , ': aValue' , String lf , accessorName , ' := aValue'.

		priority := metaContainer isEmpty
			ifTrue: [ 10 ]
			ifFalse: [ (metaContainer children collect: [ :d | d priority ]) max + 10 ].
		description := descClass new
			label: aLabel;
			accessor: accessorName asSymbol;
			priority: priority;
			level: aLevelSymbol;
			comment: (self commentDictionaryFrom: aHelp);
			yourself.
		aTypeSymbol = #select ifTrue: [ description options: anOptionsCollection asArray ].

		metaContainer add: description.
		psiCreatedAccessors add: accessorName asSymbol.

		self logIntercession: 'Create (Ψ intercession structurelle) : "' , aLabel
			, '" → nouvelle variable d''instance #' , accessorName
			, ' sur ' , targetClass name
			, ' (' , aTypeSymbol asString , ', niveau #' , aLevelSymbol asString , ')' ]
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
	super initialize.
	traceLog := OrderedCollection new.
	psiCreatedAccessors := Set new.
	mutex := Mutex new.
	protectNativeFields := false.
]

{ #category : 'private' }
AXPLReflexivityEngine >> instVarNameFrom: aLabel [
	"Dérive un identifiant Pharo valide (camelCase, sans accents) à partir d'un label."
	| ascii separators words current result |
	separators := ' -''_.,;:()[]{}/\@#'.
	ascii := String streamContents: [ :s |
		aLabel do: [ :ch | s nextPutAll: (self axplTranslit: ch) ] ].
	words := OrderedCollection new.
	current := WriteStream on: String new.
	ascii do: [ :ch |
		(separators includes: ch)
			ifTrue: [
				current contents isEmpty ifFalse: [
					words add: current contents.
					current := WriteStream on: String new ] ]
			ifFalse: [ current nextPut: ch ] ].
	current contents isEmpty ifFalse: [ words add: current contents ].

	result := WriteStream on: String new.
	words doWithIndex: [ :word :index |
		| w |
		w := word asLowercase.
		index = 1
			ifTrue: [ result nextPutAll: w ]
			ifFalse: [
				result nextPut: w first asUppercase.
				w size > 1 ifTrue: [ result nextPutAll: (w copyFrom: 2 to: w size) ] ] ].
	^ result contents
]

{ #category : 'testing' }
AXPLReflexivityEngine >> isPsiCreated: aDescription [
	"Vrai si ce champ a été ajouté à l'exécution par Ψ (et non déclaré dans
	descriptionForAXPL). Permet à un client de distinguer visuellement les
	champs natifs des ajouts structurels."
	^ psiCreatedAccessors includes: (self readSelectorOf: aDescription)
]

{ #category : 'private' }
AXPLReflexivityEngine >> logIntercession: aString [
	traceLog add: (Association key: DateAndTime now value: aString).
	[ traceLog size > self class maxTraceEntries ] whileTrue: [ traceLog removeFirst ].
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> metaContainer: aContainer [
	metaContainer := aContainer
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> protectNativeFields [
	^ protectNativeFields
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> protectNativeFields: aBoolean [
	"false (défaut) : n'importe quel champ peut être supprimé.
	true : seuls les champs créés par Ψ le peuvent."
	protectNativeFields := aBoolean
]

{ #category : 'querying' }
AXPLReflexivityEngine >> readDescription: aLabel [
	^ metaContainer children
		detect: [ :d | d label = aLabel ]
		ifNone: [ nil ]
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> restoreMissingAccessors [
	"Après la suppression d'un champ natif, ses accesseurs n'existent plus alors que
	#descriptionForAXPL continue de le déclarer : une session recréée (POST .../reset)
	planterait donc à la première lecture. On recompile ici les accesseurs manquants
	dont la variable d'instance subsiste — ce qui rend le reset réellement
	restaurateur, sans jamais toucher aux champs que Ψ a supprimés intégralement."
	metaContainer children do: [ :desc |
		| readSel varName |
		readSel := self readSelectorOf: desc.
		varName := readSel asString.
		((targetClass instVarNames includes: varName)
			and: [ (targetClass includesSelector: readSel) not ]) ifTrue: [
				targetClass compile: varName , String lf , '^ ' , varName.
				targetClass compile: varName , ': aValue' , String lf , varName , ' := aValue' ] ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> readSelectorOf: aDescription [
	"SRDescription>>accessor: convertit le symbole reçu en SRSelectorAccessor :
	#accessor ne renvoie donc PAS un Symbol mais un objet accesseur. On récupère
	ici le sélecteur de lecture, qui est aussi le nom de la variable d'instance."
	| acc |
	acc := aDescription accessor.
	^ (acc respondsTo: #readSelector)
		ifTrue: [ acc readSelector ]
		ifFalse: [ acc name asSymbol ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> addInstanceVariableNamed: aName [
	"Ajoute une variable d'instance à targetClass. On passe par l'API dédiée plutôt
	que de reconstruire la définition complète de la classe : c'est plus sûr (ni le
	package, ni les variables de classe, ni les traits ne risquent d'être perdus) et
	Pharo migre de lui-même les instances existantes vers la nouvelle forme
	(programmation live). Repli sur l'API à slots si l'image ne fournit pas
	#addInstVarNamed:."
	(targetClass respondsTo: #addInstVarNamed:)
		ifTrue: [ targetClass addInstVarNamed: aName ]
		ifFalse: [ targetClass addSlot: (InstanceVariableSlot named: aName asSymbol) ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> removeInstanceVariableNamed: aName [
	"Opération inverse de #addInstanceVariableNamed:."
	(targetClass respondsTo: #removeInstVarNamed:)
		ifTrue: [ targetClass removeInstVarNamed: aName ]
		ifFalse: [ targetClass removeSlot: (targetClass slotNamed: aName asSymbol) ]
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> relabelDescription: oldLabel to: newLabel [
	"④ Renomme un champ. Contrairement à la version initiale du mémoire, l'explication
	graduée (dimension X) n'est plus écrasée par une String de traçabilité : le
	dictionnaire #simple/#base/#expert est préservé, ce qui satisfait pleinement le
	critère 2 (l'historique de l'intercession vit dans le traceLog, sa vraie place)."
	| desc |
	(newLabel isNil or: [ newLabel isEmpty ]) ifTrue: [
		AXPLInvalidPayloadError signal: 'Le nouveau label est requis.' ].
	desc := self readDescription: oldLabel.
	desc ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , oldLabel , '".' ].
	(oldLabel = newLabel) ifFalse: [
		(self readDescription: newLabel) ifNotNil: [
			AXPLFieldAlreadyExistsError signal: 'Un champ nommé "' , newLabel , '" existe déjà.' ] ].
	desc label: newLabel.
	self logIntercession: 'Rename: ' , oldLabel , ' → ' , newLabel.
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> removeField: aLabel [
	"④ Intercession STRUCTURELLE inverse de createField: — applicable à N'IMPORTE QUEL
	champ. Retire la description, puis les accesseurs compilés, puis la variable
	d'instance elle-même si et seulement si plus aucune méthode de la classe ne
	l'utilise (sinon on corromprait du code métier tel que #initialize)."
	^ mutex critical: [
		| desc readSel writeSel varName varRemoved |
		desc := self readDescription: aLabel.
		desc ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
		readSel := self readSelectorOf: desc.
		writeSel := self writeSelectorOf: desc.
		varName := readSel asString.

		(protectNativeFields and: [ (psiCreatedAccessors includes: readSel) not ]) ifTrue: [
			AXPLFieldProtectedError signal: 'Champ natif protégé : "' , aLabel , '".' ].

		metaContainer remove: desc.

		(targetClass includesSelector: readSel) ifTrue: [ targetClass removeSelector: readSel ].
		(writeSel notNil and: [ targetClass includesSelector: writeSel ]) ifTrue: [
			targetClass removeSelector: writeSel ].

		varRemoved := false.
		((targetClass instVarNames includes: varName)
			and: [ (targetClass whichSelectorsAccess: varName) isEmpty ]) ifTrue: [
				self removeInstanceVariableNamed: varName.
				varRemoved := true ].

		psiCreatedAccessors remove: readSel ifAbsent: [ nil ].

		self logIntercession: 'Remove (Ψ intercession structurelle) : "' , aLabel
			, '" → accesseurs retirés de ' , targetClass name
			, (varRemoved
				ifTrue: [ ' ; variable d''instance #' , varName , ' supprimée' ]
				ifFalse: [ ' ; variable d''instance #' , varName , ' conservée (encore utilisée par du code métier)' ]) ]
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setHelp: aText forLevel: aLevelSymbol ofDescription: aLabel [
	"④ Modifie l'explication (X) d'un champ pour un niveau donné."
	self checkValidLevel: aLevelSymbol.
	(self readDescription: aLabel)
		ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	self updateExplanation: aLabel forLevel: aLevelSymbol with: aText.
	self logIntercession: 'Help: ' , aLabel , ' (#' , aLevelSymbol asString , ')'.
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
	| desc |
	self checkValidLevel: aNewLevel.
	desc := self readDescription: aLabel.
	desc ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	desc level: aNewLevel.
	self logIntercession: 'Level: ' , aLabel , ' → ' , aNewLevel asString.
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setOptions: anOptionsCollection ofDescription: aLabel [
	"④ Modifie la liste de choix d'un champ de type #select."
	| desc |
	desc := self readDescription: aLabel.
	desc ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	(desc isKindOf: SRSingleOptionDescription) ifFalse: [
		AXPLInvalidPayloadError signal: 'Le champ "' , aLabel , '" n''est pas un champ à options.' ].
	desc options: anOptionsCollection asArray.
	self logIntercession: 'Options: ' , aLabel , ' → ' , anOptionsCollection size asString , ' valeur(s)'.
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setType: aTypeSymbol ofDescription: aLabel options: anOptionsCollection [
	"④ Change le type d'un champ existant. La classe de description étant porteuse du
	type, on construit une nouvelle description de la bonne classe en préservant label,
	accesseur, priorité, niveau et explications, puis on la substitue EN PLACE dans la
	méta-description pour ne pas perturber l'ordre d'affichage."
	| desc descClass newDesc index |
	desc := self readDescription: aLabel.
	desc ifNil: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	descClass := AXPLFieldTypeRegistry default descriptionClassFor: aTypeSymbol.
	desc class = descClass ifTrue: [
		aTypeSymbol = #select ifTrue: [ self setOptions: anOptionsCollection ofDescription: aLabel ].
		^ self ].

	newDesc := descClass new
		label: desc label;
		accessor: (self readSelectorOf: desc);
		priority: desc priority;
		level: desc level;
		comment: desc comment;
		yourself.
	aTypeSymbol = #select ifTrue: [ newDesc options: anOptionsCollection asArray ].

	index := metaContainer children indexOf: desc.
	metaContainer children at: index put: newDesc.

	self logIntercession: 'Type: ' , aLabel , ' → ' , aTypeSymbol asString.
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> targetClass [
	^ targetClass
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> targetClass: aClass [
	targetClass := aClass
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> traceLog [
	^ traceLog
]

{ #category : 'private' }
AXPLReflexivityEngine >> uniqueInstVarNameFor: aLabel [
	| base candidate suffix existing |
	base := self instVarNameFrom: aLabel.
	base isEmpty ifTrue: [ base := 'champ' ].
	base first isDigit ifTrue: [ base := 'v' , base ].
	existing := targetClass allInstVarNames asSet.
	candidate := base.
	suffix := 1.
	[ existing includes: candidate ] whileTrue: [
		suffix := suffix + 1.
		candidate := base , suffix asString ].
	^ candidate
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> updateExplanation: aLabel forLevel: aLevel with: aText [
	"⑤ Synchronise l'explication après intercession. Si le commentaire n'était pas
	encore gradué (String simple), on le convertit en dictionnaire en conservant le
	texte existant pour les autres niveaux plutôt que de les perdre."
	| desc raw dict |
	desc := self readDescription: aLabel.
	desc ifNil: [ ^ self ].
	raw := desc comment.
	(raw isKindOf: Dictionary)
		ifTrue: [ raw at: aLevel put: aText ]
		ifFalse: [
			dict := self commentDictionaryFrom: (raw isString ifTrue: [ raw ] ifFalse: [ '' ]).
			dict at: aLevel put: aText.
			desc comment: dict ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> writeSelectorOf: aDescription [
	"Sélecteur du mutateur associé (ex: #nom:), ou nil si l'accesseur n'en expose pas."
	| acc |
	acc := aDescription accessor.
	^ (acc respondsTo: #writeSelector)
		ifTrue: [ acc writeSelector ]
		ifFalse: [ nil ]
]
