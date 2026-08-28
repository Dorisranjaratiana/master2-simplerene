"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: — modifie un label à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: — synchronise l'explication après intercession.
[t] traceLog — historique horodaté de toutes les intercessions (DateAndTime).
Instance unique créée dans targetObject: — jamais recréée entre les re-rendus.
Étend aussi ④ à la création/suppression de champs (AXPLDynamicField) : ces champs
n'ont pas de variable d'instance associée sur le targetObject, ils portent leur
propre valeur, ce qui permet de les ajouter/retirer sans toucher à la classe métier.""
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog',
		'dynamicFields'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aTypeSymbol level: aLevelSymbol help: aHelpString options: anOptionsCollection [
	| field |
	((self readDescription: aLabel) notNil or: [ (self dynamicFieldNamed: aLabel) notNil ])
		ifTrue: [ Error signal: 'Un champ nommé "' , aLabel , '" existe déjà.' ].
	field := AXPLDynamicField new
		label: aLabel;
		type: aTypeSymbol;
		level: aLevelSymbol;
		help: aHelpString;
		options: anOptionsCollection;
		yourself.
	dynamicFields add: field.
	traceLog add: (Association
		key: DateAndTime now
		value: 'Create: ' , aLabel , ' (' , aTypeSymbol asString , ', #' , aLevelSymbol asString , ')').
	^ field
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> dynamicFieldNamed: aLabel [
	^ dynamicFields detect: [ :f | f label = aLabel ] ifNone: [ nil ]
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> dynamicFields [
	^ dynamicFields
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
    super initialize.
    traceLog := OrderedCollection new.
    dynamicFields := OrderedCollection new.
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
	| desc dynField |
	desc := self readDescription: oldLabel.
	desc ifNotNil: [
		desc label: newLabel.
		desc comment: (
			'Champ : ' , newLabel
			, ' | Niveau : ' , desc level asString
			, ' | Modifié par Ψ le : ' , DateAndTime now printString
			, ' | Ancien label : ' , oldLabel).
		traceLog add: (Association
			key: DateAndTime now
			value: ('Rename: ' , oldLabel , ' → ' , newLabel)).
		^ self ].
	dynField := self dynamicFieldNamed: oldLabel.
	dynField ifNotNil: [
		dynField label: newLabel.
		traceLog add: (Association
			key: DateAndTime now
			value: ('Rename: ' , oldLabel , ' → ' , newLabel)).
		^ self ].
	Error signal: 'Champ introuvable : "' , oldLabel , '".'
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> removeField: aLabel [
	| field |
	field := self dynamicFieldNamed: aLabel.
	field ifNil: [
		(self readDescription: aLabel)
			ifNotNil: [ Error signal: 'Impossible de supprimer un champ natif du dossier : "' , aLabel , '".' ]
			ifNil: [ Error signal: 'Champ introuvable : "' , aLabel , '".' ] ].
	dynamicFields remove: field.
	traceLog add: (Association
		key: DateAndTime now
		value: 'Remove: ' , aLabel).
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
	| desc dynField |
	desc := self readDescription: aLabel.
	desc ifNotNil: [
		desc level: aNewLevel.
		traceLog add: (Association
			key: DateAndTime now
			value: 'Level: ' , aLabel , ' → ' , aNewLevel asString).
		^ self ].
	dynField := self dynamicFieldNamed: aLabel.
	dynField ifNotNil: [
		dynField level: aNewLevel.
		traceLog add: (Association
			key: DateAndTime now
			value: 'Level: ' , aLabel , ' → ' , aNewLevel asString).
		^ self ].
	Error signal: 'Champ introuvable : "' , aLabel , '".'
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> traceLog [
    ^ traceLog
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
