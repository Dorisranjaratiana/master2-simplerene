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
		'targetObject'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

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
	"Si on ne connaît pas le type spécifique, on affiche un champ texte par défaut"
	^ self visitStringDescription: aDescription
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
