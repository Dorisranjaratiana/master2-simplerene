"
""Visiteur Spec2 (implémentation concrète d'AXPLVisitor) qui génère les
widgets UI desktop depuis les descriptions.
Implémente les relations ⑦ (Méta → L) et ⑧ (L → Utilisateur).
Chaque visitXxx: génère le widget approprié avec label, tooltip (②) et binding.
assembleContainer: empile les widgets déjà construits dans un SpBoxLayout vertical.
withLabel:for: assemble label + widget en ligne horizontale.
Travaille toujours sur le metaContainer partagé via les descriptions filtrées.""
"
Class {
	#name : 'AXPLSpecVisitor',
	#superclass : 'AXPLVisitor',
	#instVars : [
		'presenter'
	],
	#category : 'AXPL-UI',
	#package : 'AXPL-UI'
}

{ #category : 'building' }
AXPLSpecVisitor >> assembleContainer: aCollectionOfItems [
    | mainLayout |
    mainLayout := SpBoxLayout newVertical spacing: 8.
    aCollectionOfItems do: [ :item | mainLayout add: item expand: false ].
    ^ mainLayout
]

{ #category : 'private' }
AXPLSpecVisitor >> labelTextFor: aDescription [
	"Marque visuellement les champs obligatoires (beRequired), pour que
	l'utilisateur sache avant de valider pourquoi Enregistrer peut échouer."
	^ aDescription isRequired
		ifTrue: [ aDescription label , ' *' ]
		ifFalse: [ aDescription label ]
]

{ #category : 'accessing' }
AXPLSpecVisitor >> presenter: aPresenter [
	presenter := aPresenter
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitBooleanDescription: aDesc [
    | checkbox currentLevel explicabilityText |
    
    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDesc commentFor: currentLevel.

    checkbox := presenter newCheckBox.
    checkbox label: (self labelTextFor: aDesc).
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
    input whenDateChanged: [ :aDate |
        aDescription write: aDate to: targetObject ].

    label := presenter newLabel label: (self labelTextFor: aDescription).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    ^ self withLabel: label for: input
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
        (aDescription isSatisfiedBy: num)
            ifTrue: [ aDescription write: num to: targetObject ] ].

    label := presenter newLabel label: (self labelTextFor: aDescription).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    ^ self withLabel: label for: input
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitSingleOptionDescription: aDesc [
    | drop row label currentLevel explicabilityText |

    currentLevel := presenter levelDropList selectedItem.
    explicabilityText := aDesc commentFor: currentLevel.

    label := presenter newLabel label: (self labelTextFor: aDesc).
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

    label := presenter newLabel label: (self labelTextFor: aDesc).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    input := presenter newTextInput.
    value := aDesc read: targetObject.
    input text: (value ifNil: [ '' ] ifNotNil: [ value asString ]).
    input whenTextChangedDo: [ :txt |
        (aDesc isSatisfiedBy: txt)
            ifTrue: [ aDesc write: txt to: targetObject ] ].

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
