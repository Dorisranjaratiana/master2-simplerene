"
""Contrat abstrait de génération (⑦) : indépendant de tout toolkit UI.
AXPLSpecVisitor (Spec2, desktop) en est la seule implémentation concrète
aujourd'hui, mais un futur visiteur web (Seaside, export JSON pour un
frontend séparé, etc.) n'a qu'à hériter d'ici — sans dépendre de Spec2
ni d'AXPL-UI — pour rejouer exactement la même adaptation (①), la même
explicabilité graduée (②) et la même réflexivité (Ψ) sur une cible
différente.

visit: et visitPriorityContainer: parcourent le meta-modèle de façon
générique et délèguent à acceptAXPLVisitor: pour le double-dispatch ;
seule la construction d'un widget par type de champ (visitXxxDescription:)
et l'assemblage d'un conteneur (assembleContainer:) sont laissés à la
responsabilité de chaque sous-classe concrète.""
"
Class {
	#name : 'AXPLVisitor',
	#superclass : 'Object',
	#instVars : [
		'targetObject',
		'level',
		'validationHandler'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'instance creation' }
AXPLVisitor class >> on: aTargetObject level: aLevel [
	"Contrat de construction commun à tous les visiteurs concrets : l'objet
	métier à lire/écrire, et le niveau courant (qui choisit l'explication
	② à afficher). Un visiteur ne va jamais chercher ce niveau dans une
	fenêtre ou une requête — on le lui donne."
	^ self new
		targetObject: aTargetObject;
		level: aLevel;
		yourself
]

{ #category : 'accessing' }
AXPLVisitor >> level [
	^ level
]

{ #category : 'accessing' }
AXPLVisitor >> level: aSymbol [
	level := aSymbol
]

{ #category : 'building' }
AXPLVisitor >> assembleContainer: aCollectionOfItems [
	"Assemble les éléments déjà construits (un par champ visible) en un
	conteneur propre à la cible : SpBoxLayout pour Spec2, balise HTML pour
	le web, Array pour un export JSON, etc."
	^ self subclassResponsibility
]

{ #category : 'accessing' }
AXPLVisitor >> targetObject [
	^ targetObject
]

{ #category : 'accessing' }
AXPLVisitor >> targetObject: anObject [
	"Cette méthode permet d'injecter n'importe quel objet de l'extérieur"
	targetObject := anObject
]

{ #category : 'visiting' }
AXPLVisitor >> visit: aCollection [
	| items |
	items := aCollection collect: [ :desc | desc acceptAXPLVisitor: self ].
	^ self assembleContainer: items
]

{ #category : 'visiting' }
AXPLVisitor >> visitBooleanDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'visiting' }
AXPLVisitor >> visitDateDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'visiting' }
AXPLVisitor >> visitDescription: aDescription [
	"Atteint pour tout type SimpleRene qu'AXPL ne sait pas rendre (Time,
	DateAndTime, MultipleOption, relations, fichiers...). Avant, il
	retombait sur un champ texte : la saisie était ensuite refusée par la
	validation de type, ou écrite dans le mauvais type, sans aucun
	message. Un framework doit refuser clairement ce qu'il ne gère pas."
	^ Error signal: 'Type de description non supporté par AXPL : ' ,
		aDescription class name , ' (champ "' , aDescription label asString ,
		'"). Types supportés : String, Number, Boolean, Date, SingleOption, Password.'
]

{ #category : 'visiting' }
AXPLVisitor >> visitPasswordDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'visiting' }
AXPLVisitor >> visitNumberDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'visiting' }
AXPLVisitor >> visitPriorityContainer: aContainer [
	^ self visit: aContainer children
]

{ #category : 'visiting' }
AXPLVisitor >> visitSingleOptionDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'visiting' }
AXPLVisitor >> visitStringDescription: aDescription [
	^ self subclassResponsibility
]

{ #category : 'writing' }
AXPLVisitor >> commit: aValue for: aDescription [
	"Passage unique de toute saisie vers l'objet métier, quel que soit le
	type de champ : on n'écrit que ce que les règles de la description
	acceptent, et on prévient toujours (validationHandler) — message
	d'erreur ou nil — pour que l'interface puisse l'afficher. Avant,
	seuls texte et nombre étaient validés, et un refus était silencieux :
	l'écran montrait une valeur que l'objet n'avait pas."
	| message |
	message := aDescription validationMessageFor: aValue.
	message ifNil: [ aDescription write: aValue to: targetObject ].
	self validationHandler value: aDescription value: message.
	^ message
]

{ #category : 'accessing' }
AXPLVisitor >> validationHandler [
	^ validationHandler ifNil: [ [ :description :messageOrNil | ] ]
]

{ #category : 'accessing' }
AXPLVisitor >> whenValidationChangedDo: aBlock [
	"aBlock reçoit la description et le message d'erreur (nil si la
	saisie est valide et a été écrite)."
	validationHandler := aBlock
]
