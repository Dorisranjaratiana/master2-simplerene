"
② Décorateur d'explicabilité attaché à une description SimpleRene, sans
la sous-classer ni détourner un de ses champs : il est rangé dans le
dictionnaire de propriétés de la description (propertyAt: #axplExplanation),
le mécanisme d'extension prévu par SimpleRene (SRTPropertyOwner).

Il porte :
- texts : une explication par niveau (Dictionary niveau → String) ;
- commonText : l'explication commune, utilisée pour les niveaux sans texte propre ;
- origin : #declared (champ déclaré dans descriptionForAXPL) ou #psi
  (champ créé à l'exécution par le moteur Ψ).

Le #comment de SimpleRene reste une String d'aide, comme son contrat le
prévoit (et comme Spec-Form l'affiche) ; il sert de dernier repli.

Usage :
	desc explanation: 'Même aide à tous les niveaux'.
	desc explanation: (Dictionary new at: #simple put: '...'; at: #expert put: '...'; yourself).
	desc explanation text: '...' forLevel: #base.
	desc commentFor: #base.
"
Class {
	#name : 'AXPLExplanation',
	#superclass : 'Object',
	#instVars : [
		'texts',
		'commonText',
		'origin'
	],
	#category : 'AXPL-Descriptions',
	#package : 'AXPL-Descriptions'
}

{ #category : 'instance creation' }
AXPLExplanation class >> common: aStringOrNil [
	^ self new commonText: aStringOrNil; yourself
]

{ #category : 'instance creation' }
AXPLExplanation class >> fromLegacyComment: anObject [
	"Reprend un ancien #comment : une String devient l'explication commune,
	un Dictionary (ancien format AXPL v1) les explications par niveau."

	(anObject isKindOf: Dictionary) ifTrue: [ ^ self perLevel: anObject ].
	(anObject isString and: [ anObject notEmpty ]) ifTrue: [ ^ self common: anObject ].
	^ self new
]

{ #category : 'instance creation' }
AXPLExplanation class >> perLevel: aDictionary [
	| explanation |
	explanation := self new.
	aDictionary keysAndValuesDo: [ :level :text | explanation text: text forLevel: level ].
	^ explanation
]

{ #category : 'modifying' }
AXPLExplanation >> beCommon: aStringOrNil [
	"La même explication à tous les niveaux : les textes par niveau sont oubliés."

	texts removeAll.
	self commonText: aStringOrNil
]

{ #category : 'accessing' }
AXPLExplanation >> commonText [
	^ commonText
]

{ #category : 'accessing' }
AXPLExplanation >> commonText: aStringOrNil [
	commonText := (aStringOrNil notNil and: [ aStringOrNil isEmpty ])
		ifTrue: [ nil ]
		ifFalse: [ aStringOrNil ]
]

{ #category : 'testing' }
AXPLExplanation >> hasTextFor: aLevel [
	^ (self textFor: aLevel) notNil
]

{ #category : 'initialization' }
AXPLExplanation >> initialize [
	super initialize.
	texts := Dictionary new.
	origin := #declared
]

{ #category : 'testing' }
AXPLExplanation >> isEmpty [
	^ texts isEmpty and: [ commonText isNil ]
]

{ #category : 'testing' }
AXPLExplanation >> isPsiCreated [
	^ origin = #psi
]

{ #category : 'accessing' }
AXPLExplanation >> levels [
	"Les niveaux qui ont une explication propre."
	^ texts keys
]

{ #category : 'accessing' }
AXPLExplanation >> origin [
	^ origin
]

{ #category : 'accessing' }
AXPLExplanation >> origin: aSymbol [
	origin := aSymbol
]

{ #category : 'copying' }
AXPLExplanation >> postCopy [
	super postCopy.
	texts := texts copy
]

{ #category : 'printing' }
AXPLExplanation >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $(.
	commonText ifNotNil: [ aStream print: commonText ].
	texts keysAndValuesDo: [ :level :text |
		aStream space; print: level; nextPutAll: ': '; print: text ].
	aStream nextPut: $)
]

{ #category : 'modifying' }
AXPLExplanation >> text: aString forLevel: aLevel [
	texts at: aLevel put: aString
]

{ #category : 'accessing' }
AXPLExplanation >> textFor: aLevel [
	"L'explication propre au niveau, sinon l'explication commune, sinon nil."
	^ texts at: aLevel ifAbsent: [ commonText ]
]
