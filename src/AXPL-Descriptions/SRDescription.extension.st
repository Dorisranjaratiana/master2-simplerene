Extension { #name : 'SRDescription' }

{ #category : '*AXPL-Descriptions' }
SRDescription >> commentFor: aLevel [
	"② Explicabilité (X) : le vrai SRDescription>>#comment stocke soit une
	String simple, soit un Dictionary #simple/#base/#expert (posé par AXPL).
	On extrait ici le texte adapté au niveau demandé."

	| raw |
	raw := self comment.
	raw ifNil: [ ^ '' ].
	raw isString ifTrue: [ ^ raw ].
	^ raw at: aLevel ifAbsent: [ raw at: #base ifAbsent: [ '' ] ]
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> level [
	"① Adaptation (A) : niveau d'utilisateur pouvant voir ce champ."

	^ self propertyAt: #axplLevel ifAbsent: [ #simple ]
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> level: aSymbol [
	self propertyAt: #axplLevel put: aSymbol
]
