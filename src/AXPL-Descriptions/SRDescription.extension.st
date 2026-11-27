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
SRDescription >> axplExplanation [
	"② Le décorateur d'explicabilité, ou nil s'il n'a jamais été posé."

	^ self propertyAt: #axplExplanation ifAbsent: [ nil ]
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> axplExplanation: anExplanationOrNil [
	"nil retire la propriété (retour au #comment de SimpleRene)."

	self propertyAt: #axplExplanation putRemovingNil: anExplanationOrNil
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> commentFor: aLevel [
	"② Explicabilité (X) : le texte à montrer à ce niveau. Ordre de
	recherche : l'explication AXPL du niveau, puis l'explication AXPL
	commune (AXPLExplanation, rangée dans les propriétés), puis le
	#comment de SimpleRene. Un #comment Dictionary (ancien format AXPL)
	reste lu, pour ne pas casser une application existante."

	| raw |
	self axplExplanation ifNotNil: [ :explanation |
		(explanation textFor: aLevel) ifNotNil: [ :text | ^ text ] ].
	raw := self comment.
	raw ifNil: [ ^ '' ].
	raw isString ifTrue: [ ^ raw ].
	(raw isKindOf: Dictionary) ifTrue: [
		^ raw at: aLevel ifAbsent: [ raw at: #base ifAbsent: [ '' ] ] ].
	^ ''
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> explanation [
	"② Le décorateur d'explicabilité, créé au premier besoin (en reprenant
	un éventuel #comment existant, pour ne rien perdre)."

	^ self
		propertyAt: #axplExplanation
		ifAbsentPut: [ AXPLExplanation fromLegacyComment: self comment ]
]

{ #category : '*AXPL-Descriptions' }
SRDescription >> explanation: aStringOrDictionary [
	"② Déclare l'explication : une String (la même à tous les niveaux) ou
	un Dictionary niveau → texte. N'écrit jamais dans #comment."

	self axplExplanation: ((aStringOrDictionary isKindOf: Dictionary)
		ifTrue: [ AXPLExplanation perLevel: aStringOrDictionary ]
		ifFalse: [ AXPLExplanation common: aStringOrDictionary ])
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
