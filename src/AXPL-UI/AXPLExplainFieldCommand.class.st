"
② « Pourquoi ce champ ? » : ce que le méta-modèle dit du champ — type,
obligatoire ou non, niveau requis, origine (déclaré ou créé par Ψ) et
explication au niveau affiché.
"
Class {
	#name : 'AXPLExplainFieldCommand',
	#superclass : 'AXPLFieldCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'accessing' }
AXPLExplainFieldCommand class >> menuOrder [
	^ 10
]

{ #category : 'testing' }
AXPLExplainFieldCommand >> canBeExecuted [
	^ self app notNil
]

{ #category : 'executing' }
AXPLExplainFieldCommand >> execute [
	self app inform: self explanationText
]

{ #category : 'accessing' }
AXPLExplainFieldCommand >> explanationText [
	| level explanation |
	level := self app currentContext
		ifNil: [ AXPLFormBuilder requiredLevelFor: self field ]
		ifNotNil: [ :context | context explanationLevel ifNil: [ AXPLFormBuilder requiredLevelFor: self field ] ].
	explanation := self field commentFor: level.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self field label;
			nextPutAll: ' — ';
			nextPutAll: (self field isRequired ifTrue: [ 'champ obligatoire' ] ifFalse: [ 'champ facultatif' ]);
			nextPutAll: ' (';
			nextPutAll: self field class name;
			nextPutAll: ')';
			cr;
			nextPutAll: 'Visible à partir du niveau ';
			nextPutAll: (AXPLFormBuilder requiredLevelFor: self field) asString capitalized;
			cr;
			nextPutAll: ((self field axplExplanation notNil and: [ self field axplExplanation isPsiCreated ])
				ifTrue: [ 'Champ créé par Ψ pendant l''exécution' ]
				ifFalse: [ 'Champ déclaré dans descriptionForAXPL' ]).
		explanation isEmpty ifFalse: [
			stream
				cr;
				nextPutAll: 'Explication (';
				nextPutAll: level asString capitalized;
				nextPutAll: ') : ';
				nextPutAll: explanation ] ]
]

{ #category : 'initialization' }
AXPLExplainFieldCommand >> initialize [
	super initialize.
	self
		name: 'Pourquoi ce champ ?';
		description: '② Ce que le méta-modèle dit de ce champ, et son explication.'
]
