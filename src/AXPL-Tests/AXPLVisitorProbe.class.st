"
Double de test pour le protocole #acceptAXPLVisitor:. Chaque visitXxx:
renvoie un symbole distinct, ce qui permet de vérifier à la fois le bon
dispatch ET que la valeur de retour du visiteur est bien propagée —
c'est justement ce que le acceptSimpleReneVisitor: natif de SimpleRene
(sans ^) ne fait pas.
"
Class {
	#name : 'AXPLVisitorProbe',
	#superclass : 'Object',
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'visiting' }
AXPLVisitorProbe >> visitBooleanDescription: aDescription [
	^ #booleanVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitDateDescription: aDescription [
	^ #dateVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitDescription: aDescription [
	^ #genericVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitNumberDescription: aDescription [
	^ #numberVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitPriorityContainer: aContainer [
	^ #priorityContainerVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitSingleOptionDescription: aDescription [
	^ #singleOptionVisited
]

{ #category : 'visiting' }
AXPLVisitorProbe >> visitStringDescription: aDescription [
	^ #stringVisited
]
