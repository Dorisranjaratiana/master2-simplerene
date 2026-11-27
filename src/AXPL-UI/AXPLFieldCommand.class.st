"
Commande générée depuis une description (objectif 3 : « créer des
commandes avec les descriptions ») : commandsFor: crée, pour un champ,
une instance de chaque sous-classe concrète. Ajouter une commande à tous
les champs = ajouter une sous-classe ; les menus la montrent aussitôt.
"
Class {
	#name : 'AXPLFieldCommand',
	#superclass : 'AXPLCommand',
	#instVars : [
		'field'
	],
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
AXPLFieldCommand class >> commandsFor: aDescription [
	"Une commande de chaque sorte pour ce champ, dans l'ordre du menu."
	^ ((self allSubclasses reject: [ :each | each isAbstract ])
		asSortedCollection: [ :a :b | a menuOrder <= b menuOrder ])
			asArray collect: [ :each | each on: aDescription ]
]

{ #category : 'testing' }
AXPLFieldCommand class >> isAbstract [
	^ self == AXPLFieldCommand
]

{ #category : 'accessing' }
AXPLFieldCommand class >> menuOrder [
	^ 100
]

{ #category : 'instance creation' }
AXPLFieldCommand class >> on: aDescription [
	^ self new setField: aDescription
]

{ #category : 'accessing' }
AXPLFieldCommand >> field [
	"La description SimpleRene du champ visé."
	^ field
]

{ #category : 'initialization' }
AXPLFieldCommand >> setField: aDescription [
	field := aDescription
]
