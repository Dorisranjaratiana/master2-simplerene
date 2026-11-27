"
Formulaire AXΨL dessiné par Spec-Form : un SFContainerPresenter de
Spec-Form (pharo-spec/Spec-Form, E. Lorenzano), alimenté par AXΨL. C'est
lui qui dessine le formulaire de la fenêtre AXPLFormApp.
- ① il ne reçoit que les champs visibles au niveau demandé
  (AXPLFramework >> visibleFieldsAt:), y compris ceux créés par Ψ ;
- ② chaque champ montre l'explication de ce niveau (AXPLSpecFormBuilder) ;
- la saisie passe par un memento SimpleRene direct (SRStraightMemento) :
  chaque valeur est validée par les règles de SimpleRene puis écrite tout
  de suite dans l'objet ; une valeur refusée n'est pas écrite, le champ
  l'indique (⚠ dans son infobulle) et validationHandler est prévenu
  (comme AXPLVisitor >> commit:for:).

	((AXPLFramework for: ClientHopital new) specFormPresenterAt: #base) open.
"
Class {
	#name : 'AXPLSpecFormPresenter',
	#superclass : 'SFContainerPresenter',
	#instVars : [
		'level',
		'validationHandler',
		'builder'
	],
	#category : 'AXPL-SpecForm',
	#package : 'AXPL-SpecForm'
}

{ #category : 'private' }
AXPLSpecFormPresenter class >> defaultPresenterBuilder [
	^ AXPLSpecFormBuilder
]

{ #category : 'instance creation' }
AXPLSpecFormPresenter class >> on: anAXPLFramework level: aLevel [
	^ self on: anAXPLFramework level: aLevel owner: nil validationHandler: nil
]

{ #category : 'instance creation' }
AXPLSpecFormPresenter class >> on: anAXPLFramework level: aLevel owner: aPresenterOrNil validationHandler: aBlockOrNil [
	"aBlockOrNil : [ :description :messageOrNil | ... ], appelé après chaque
	saisie (message de SimpleRene si elle est refusée, nil sinon)."
	^ self
		on: anAXPLFramework
		level: aLevel
		fields: (anAXPLFramework visibleFieldsAt: aLevel)
		owner: aPresenterOrNil
		validationHandler: aBlockOrNil
]

{ #category : 'instance creation' }
AXPLSpecFormPresenter class >> on: anAXPLFramework level: aLevel fields: aCollectionOfDescriptions owner: aPresenterOrNil validationHandler: aBlockOrNil [
	"aCollectionOfDescriptions : les champs à montrer (choisis par un
	contexte, cf. AXPLFramework >> visibleFieldsIn:) ; aLevel : le niveau
	dont on montre les explications ②."
	| container memento form |
	container := SRPriorityContainer new.
	container label: anAXPLFramework metaContainer label.
	container initialExtent: 520 @ 640.
	aCollectionOfDescriptions do: [ :each | container add: each ].
	memento := SRStraightMemento
		model: anAXPLFramework targetObject
		description: container.
	form := self basicNew.
	aPresenterOrNil ifNotNil: [ form owner: aPresenterOrNil ].
	^ form
		setLevel: aLevel validationHandler: aBlockOrNil;
		initializeMemento: memento description: container parent: nil;
		yourself
]

{ #category : 'building' }
AXPLSpecFormPresenter >> build [
	builder := self presenterBuilderClass new
		presenter: self;
		level: level;
		yourself.
	builder visit: self description
]

{ #category : 'accessing' }
AXPLSpecFormPresenter >> level [
	^ level
]

{ #category : 'private' }
AXPLSpecFormPresenter >> notifyValidationOf: aDescription message: aMessageOrNil [
	validationHandler ifNotNil: [ :handler |
		handler value: aDescription value: aMessageOrNil ]
]

{ #category : 'actions' }
AXPLSpecFormPresenter >> save [
	"Vérifie tout le formulaire avec les règles de SimpleRene (les valeurs
	sont déjà dans l'objet). Renvoie nil, ou le message d'erreur."
	[ self memento validate ]
		on: SRValidationError
		do: [ :error | ^ error messageText ].
	^ nil
]

{ #category : 'private' }
AXPLSpecFormPresenter >> setLevel: aLevel validationHandler: aBlockOrNil [
	level := aLevel.
	validationHandler := aBlockOrNil
]

{ #category : 'accessing' }
AXPLSpecFormPresenter >> labelFor: aLabel [
	"Le label (avec son infobulle ②) du champ de ce label, ou nil."
	^ builder labelFor: aLabel
]

{ #category : 'accessing' }
AXPLSpecFormPresenter >> widgetFor: aLabel [
	"Le widget de saisie du champ de ce label (nil s'il n'est pas affiché)."
	^ builder widgetFor: aLabel
]
