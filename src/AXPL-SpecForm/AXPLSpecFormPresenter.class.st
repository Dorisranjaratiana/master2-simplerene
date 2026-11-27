"
Formulaire AXΨL dessiné par Spec-Form : un SFContainerPresenter de
Spec-Form, alimenté par AXΨL.
- ① il ne reçoit que les champs visibles au niveau demandé
  (AXPLFramework >> visibleFieldsAt:), y compris ceux créés par Ψ ;
- ② chaque champ montre l'explication de ce niveau (AXPLSpecFormBuilder) ;
- la saisie passe par le memento de SimpleRene (SRCheckedMemento) : rien
  n'est écrit dans l'objet avant #save, qui valide d'abord avec les règles
  de SimpleRene.

	(AXPLFramework for: ClientHopital new) specFormPresenterAt: #base.
	((AXPLFramework for: ClientHopital new) specFormPresenterAt: #base) open.
"
Class {
	#name : 'AXPLSpecFormPresenter',
	#superclass : 'SFContainerPresenter',
	#instVars : [
		'level'
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
	| container memento |
	container := SRPriorityContainer new.
	container label: anAXPLFramework metaContainer label.
	container initialExtent: 520 @ 640.
	(anAXPLFramework visibleFieldsAt: aLevel) do: [ :each | container add: each ].
	memento := anAXPLFramework targetObject simpleReneMementoClass
		model: anAXPLFramework targetObject
		description: container.
	^ self basicNew
		setLevel: aLevel;
		initializeMemento: memento description: container parent: nil;
		yourself
]

{ #category : 'building' }
AXPLSpecFormPresenter >> build [
	self presenterBuilderClass new
		presenter: self;
		level: level;
		visit: self description
]

{ #category : 'accessing' }
AXPLSpecFormPresenter >> level [
	^ level
]

{ #category : 'actions' }
AXPLSpecFormPresenter >> save [
	"Valide la saisie avec les règles de SimpleRene, puis l'écrit dans
	l'objet. Renvoie nil, ou le message d'erreur (rien n'est écrit)."
	[ self memento validate ]
		on: SRValidationError
		do: [ :error | ^ error messageText ].
	self memento commit.
	^ nil
]

{ #category : 'private' }
AXPLSpecFormPresenter >> setLevel: aLevel [
	level := aLevel
]
