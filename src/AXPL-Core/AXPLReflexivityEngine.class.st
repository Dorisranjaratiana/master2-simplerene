"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: — modifie un label à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: — synchronise l'explication après intercession.
[t] traceLog — historique horodaté de toutes les intercessions (DateAndTime).
Instance unique créée dans targetObject: — jamais recréée entre les re-rendus.

Étend ④ à une véritable intercession STRUCTURELLE (Maes, 1987) au sens plein du terme :
createField:type:level:help:options: ajoute réellement une variable d'instance à la
classe métier (targetClass) via #subclass:instanceVariableNames:classVariableNames:package:,
puis compile ses accesseur/mutateur via #compile: — exploitant la réflexivité native de
Pharo (redéfinition de classe à chaud, migration automatique des instances existantes,
programmation live) plutôt que de simuler le champ dans une structure annexe.
removeField: effectue l'opération inverse : #removeSelector: puis retrait de la variable
d'instance. Seuls les champs ainsi créés par Ψ (psiCreatedAccessors) peuvent être retirés ;
les champs natifs déclarés dans descriptionForAXPL restent protégés.""
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog',
		'targetClass',
		'psiCreatedAccessors'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

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

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aTypeSymbol level: aLevelSymbol help: aHelpString options: anOptionsCollection [
	"① Intercession STRUCTURELLE : ajoute une véritable variable d'instance à targetClass
	et compile ses accesseur/mutateur, puis enregistre la description dans la méta-description.
	La migration des instances existantes (dont targetObject) est gérée nativement par Pharo."
	| accessorName newVarNames descClass description priority |
	(self readDescription: aLabel) ifNotNil: [
		Error signal: 'Un champ nommé "' , aLabel , '" existe déjà.' ].

	accessorName := self uniqueInstVarNameFor: aLabel.

	newVarNames := targetClass instVarNames asOrderedCollection.
	newVarNames add: accessorName.
	targetClass superclass
		subclass: targetClass name asSymbol
		instanceVariableNames: (String streamContents: [ :s |
			newVarNames
				do: [ :each | s nextPutAll: each ]
				separatedBy: [ s nextPut: $  ] ])
		classVariableNames: ''
		package: targetClass package name.

	targetClass compile: accessorName , String lf , '^ ' , accessorName.
	targetClass compile: accessorName , ': aValue' , String lf , accessorName , ' := aValue'.

	descClass := self descriptionClassFor: aTypeSymbol.
	priority := metaContainer isEmpty
		ifTrue: [ 10 ]
		ifFalse: [ (metaContainer children collect: [ :d | d priority ]) max + 10 ].
	description := descClass new
		label: aLabel;
		accessor: accessorName asSymbol;
		priority: priority;
		level: aLevelSymbol;
		comment: (Dictionary new
			at: #simple put: aHelpString;
			at: #base put: aHelpString;
			at: #expert put: aHelpString;
			yourself);
		yourself.
	aTypeSymbol = #select ifTrue: [ description options: anOptionsCollection asArray ].

	metaContainer add: description.
	psiCreatedAccessors add: accessorName asSymbol.

	traceLog add: (Association
		key: DateAndTime now
		value: 'Create (Ψ intercession structurelle) : "' , aLabel
			, '" → nouvelle variable d''instance #' , accessorName
			, ' sur ' , targetClass name
			, ' (' , aTypeSymbol asString , ', niveau #' , aLevelSymbol asString , ')').
]

{ #category : 'private' }
AXPLReflexivityEngine >> descriptionClassFor: aTypeSymbol [
	aTypeSymbol = #string ifTrue: [ ^ SRStringDescription ].
	aTypeSymbol = #number ifTrue: [ ^ SRNumberDescription ].
	aTypeSymbol = #boolean ifTrue: [ ^ SRBooleanDescription ].
	aTypeSymbol = #date ifTrue: [ ^ SRDateDescription ].
	aTypeSymbol = #select ifTrue: [ ^ SRSingleOptionDescription ].
	^ SRStringDescription
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
    super initialize.
    traceLog := OrderedCollection new.
    psiCreatedAccessors := Set new.
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

{ #category : 'accessing' }
AXPLReflexivityEngine >> metaContainer: aContainer [
    metaContainer := aContainer
]

{ #category : 'querying' }
AXPLReflexivityEngine >> readDescription: aLabel [
    ^ metaContainer children
        detect: [ :d | d label = aLabel ]
        ifNone: [ nil ]
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> relabelDescription: oldLabel to: newLabel [
	| desc |
	desc := self readDescription: oldLabel.
	desc ifNil: [ Error signal: 'Champ introuvable : "' , oldLabel , '".' ].
	desc label: newLabel.
	desc comment: (
		'Champ : ' , newLabel
		, ' | Niveau : ' , desc level asString
		, ' | Modifié par Ψ le : ' , DateAndTime now printString
		, ' | Ancien label : ' , oldLabel).
	traceLog add: (Association
		key: DateAndTime now
		value: ('Rename: ' , oldLabel , ' → ' , newLabel)).
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> removeField: aLabel [
	"Intercession STRUCTURELLE inverse de createField: : retire les accesseurs compilés
	puis la variable d'instance elle-même. Seuls les champs créés par Ψ sont éligibles ;
	les champs natifs (déclarés dans descriptionForAXPL) restent protégés."
	| desc accessorSym remainingVars |
	desc := self readDescription: aLabel.
	desc ifNil: [ Error signal: 'Champ introuvable : "' , aLabel , '".' ].
	accessorSym := desc accessor.
	(psiCreatedAccessors includes: accessorSym) ifFalse: [
		Error signal: 'Impossible de supprimer un champ natif du dossier : "' , aLabel , '".' ].

	metaContainer remove: desc.

	remainingVars := targetClass instVarNames reject: [ :each | each = accessorSym asString ].
	targetClass superclass
		subclass: targetClass name asSymbol
		instanceVariableNames: (String streamContents: [ :s |
			remainingVars
				do: [ :each | s nextPutAll: each ]
				separatedBy: [ s nextPut: $  ] ])
		classVariableNames: ''
		package: targetClass package name.

	targetClass removeSelector: accessorSym.
	targetClass removeSelector: accessorSym asMutator.
	psiCreatedAccessors remove: accessorSym.

	traceLog add: (Association
		key: DateAndTime now
		value: 'Remove (Ψ intercession structurelle) : "' , aLabel
			, '" → suppression de la variable d''instance #' , accessorSym
			, ' et de ses accesseurs sur ' , targetClass name).
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
	| desc |
	desc := self readDescription: aLabel.
	desc ifNil: [ Error signal: 'Champ introuvable : "' , aLabel , '".' ].
	desc level: aNewLevel.
	traceLog add: (Association
		key: DateAndTime now
		value: 'Level: ' , aLabel , ' → ' , aNewLevel asString).
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
    | desc raw |
    desc := self readDescription: aLabel.
    desc ifNotNil: [
        raw := desc comment.
        (raw isKindOf: Dictionary)
            ifTrue: [ raw at: aLevel put: aText ]
            ifFalse: [
                desc comment: (Dictionary new
                    at: aLevel put: aText;
                    yourself) ] ]
]
