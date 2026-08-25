"
""Visiteur Spec2 qui génère les widgets UI depuis les descriptions. 
Implémente les relations ⑦ (Méta → L) et ⑧ (L → Utilisateur).
Chaque visitXxx: génère le widget approprié avec label, tooltip (②) et binding.
visit: parcourt une collection de descriptions et retourne un SpBoxLayout vertical.
withLabel:for: assemble label + widget en ligne horizontale.
Travaille toujours sur le metaContainer partagé via les descriptions filtrées.""
"
Class {
	#name : 'AXPLSpecVisitor',
	#superclass : 'Object',
	#instVars : [
		'presenter',
		'targetObject'
	],
	#category : 'AXPL-UI',
	#package : 'AXPL-UI'
}

{ #category : 'accessing' }
AXPLSpecVisitor >> presenter: aPresenter [
	presenter := aPresenter
]

{ #category : 'accessing' }
AXPLSpecVisitor >> targetObject: anObject [
	"Cette méthode permet d'injecter n'importe quel objet de l'extérieur"
	targetObject := anObject.
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visit: aCollection [
    | mainLayout |
    mainLayout := SpBoxLayout newVertical spacing: 8.
    aCollection do: [ :desc |
        mainLayout add: (desc acceptAXPLVisitor: self) expand: false ].
    ^ mainLayout
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitBooleanDescription: aDesc [
    | checkbox currentLevel explicabilityText |
    
    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDesc commentFor: currentLevel.

    checkbox := presenter newCheckBox.
    checkbox label: aDesc label.
    "CORRECTION : On passe la String extraite, pas le dictionnaire"
    checkbox help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).
    
    checkbox state: (aDesc read: targetObject).
    checkbox whenActivatedDo: [ aDesc write: true to: targetObject ].
    checkbox whenDeactivatedDo: [ aDesc write: false to: targetObject ].

    ^ checkbox
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitDateDescription: aDescription [
    | input dateValue currentLevel explicabilityText label |
    
    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDescription commentFor: currentLevel.

    input := SpDatePresenter new.
    dateValue := aDescription read: targetObject.
    input date: (dateValue ifNil: [ Date today ] ifNotNil: [ dateValue ]).
    input whenDateChangedDo: [ :aDate |
        aDescription write: aDate to: targetObject ].

    label := presenter newLabel label: aDescription label.
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    ^ self withLabel: label for: input
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitDescription: aDescription [
	"Si on ne connaît pas le type spécifique, on affiche un champ texte par défaut"
	^ self visitStringDescription: aDescription
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitNumberDescription: aDescription [
    | input numValue currentLevel explicabilityText label |
    
    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDescription commentFor: currentLevel.

    input := presenter newNumberInput.
    numValue := aDescription read: targetObject.
    input number: (numValue ifNil: [ 0 ]).

    input whenNumberChangedDo: [ :num |
        aDescription write: num to: targetObject ].

    label := presenter newLabel label: aDescription label.
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    ^ self withLabel: label for: input
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitPriorityContainer: aContainer [
	| vLayout |
	vLayout := SpBoxLayout newVertical.
	vLayout spacing: 10.
	aContainer children do: [ :each |
		vLayout add: (each acceptAXPLVisitor: self) expand: false ].
	^ vLayout
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitSingleOptionDescription: aDesc [
    | drop row label currentLevel explicabilityText |

    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDesc commentFor: currentLevel.

    label := presenter newLabel label: aDesc label.
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    drop := presenter newDropList.
    drop items: aDesc options.
    drop selectItem: (aDesc read: targetObject).
    drop whenSelectedItemChangedDo: [ :item |
        aDesc write: item to: targetObject ].

    row := SpBoxLayout newHorizontal spacing: 15.
    row add: label width: 140.
    row add: drop expand: true.
    ^ row
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitStringDescription: aDesc [
    | input row label currentLevel explicabilityText value |
    
    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDesc commentFor: currentLevel.

    label := presenter newLabel label: aDesc label.
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    input := presenter newTextInput.
    value := aDesc read: targetObject.
    input text: (value ifNil: [ '' ] ifNotNil: [ value asString ]).
    input whenTextChangedDo: [ :txt |
        aDesc write: txt to: targetObject ].

    row := SpBoxLayout newHorizontal spacing: 15.
    row add: label width: 140.
    row add: input expand: true.
    ^ row
]

{ #category : 'label' }
AXPLSpecVisitor >> withLabel: aLabel for: aWidget [
    "Si aLabel est déjà un Presenter (objet), on l'ajoute directement.
     Si c'est une String, on crée un nouveau label."
    | row labelPresenter |
    
    labelPresenter := (aLabel isString) 
        ifTrue: [ presenter newLabel label: aLabel ] 
        ifFalse: [ aLabel ]. "On garde l'objet label avec son .help"

    row := SpBoxLayout newHorizontal spacing: 15.
    row add: labelPresenter width: 140.
    row add: aWidget expand: true.
    ^ row
]
