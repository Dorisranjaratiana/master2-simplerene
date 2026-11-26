Extension { #name : 'SRDescription' }

{ #category : '*AXPL-Descriptions' }
SRDescription >> acceptAXPLVisitor: aVisitor [
	"Protocole de double-dispatch propre à AXPL : contrairement à
	#acceptSimpleReneVisitor: (natif, sans ^, pensé pour des visiteurs à
	effet de bord), celui-ci renvoie le résultat du visiteur — nécessaire
	pour qu'AXPLSpecVisitor puisse construire et retourner un widget."

	^ aVisitor visitDescription: self
]

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

{ #category : '*AXPL-Descriptions' }
SRDescription >> validationMessageFor: anObject [
	"nil si anObject respecte les règles de la description (requis, type,
	conditions comme bePositive ou addCondition:labelled:), sinon le
	message d'erreur de SimpleRene — pour l'afficher à l'utilisateur au
	lieu de refuser la saisie en silence (isSatisfiedBy: ne dit que
	true/false)."

	[ self validate: anObject ]
		on: SRValidationError
		do: [ :err | ^ err messageText ].
	^ nil
]
