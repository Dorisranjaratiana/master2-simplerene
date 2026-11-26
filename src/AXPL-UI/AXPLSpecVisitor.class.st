"
""Visiteur Spec2 (implémentation concrète d'AXPLVisitor) qui génère les
widgets UI desktop depuis les descriptions.
Implémente les relations ⑦ (Méta → L) et ⑧ (L → Utilisateur).
Chaque visitXxx: génère le widget approprié avec label, tooltip (②) et binding.
assembleContainer: empile les widgets déjà construits dans un SpBoxLayout vertical.
withLabel:for: assemble label + widget en ligne horizontale.
Travaille toujours sur le metaContainer partagé via les descriptions filtrées.
Construction : (AXPLSpecVisitor on: anObject level: aLevel) presenter: unSpPresenter.
Le niveau lui est donné (comme à AXPLJsonVisitor) ; presenter ne sert
qu'aux fabriques de widgets Spec2 (newLabel, newTextInput...) — n'importe
quel SpPresenter convient, pas seulement la fenêtre AXPLFormApp.""
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
    
    currentLevel := level.
    explicabilityText := aDesc commentFor: currentLevel.

    checkbox := presenter newCheckBox.
    checkbox label: (self labelTextFor: aDesc).
    "CORRECTION : On passe la String extraite, pas le dictionnaire"
    checkbox help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).
    
    checkbox state: (aDesc read: targetObject).
    checkbox whenActivatedDo: [
        self mark: checkbox for: aDesc with: (self commit: true for: aDesc) ].
    checkbox whenDeactivatedDo: [
        self mark: checkbox for: aDesc with: (self commit: false for: aDesc) ].

    ^ checkbox
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitDateDescription: aDescription [
    | input dateValue currentLevel explicabilityText label |
    
    currentLevel := level.
    explicabilityText := aDescription commentFor: currentLevel.

    input := SpDatePresenter new.
    dateValue := aDescription read: targetObject.
    input date: (dateValue ifNil: [ Date today ] ifNotNil: [ dateValue ]).
    label := presenter newLabel label: (self labelTextFor: aDescription).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).
    input whenDateChanged: [ :aDate |
        self mark: label for: aDescription with: (self commit: aDate for: aDescription) ].

    ^ self withLabel: label for: input
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitNumberDescription: aDescription [
    | input numValue currentLevel explicabilityText label |
    
    currentLevel := level.
    explicabilityText := aDescription commentFor: currentLevel.

    input := presenter newNumberInput.
    numValue := aDescription read: targetObject.
    input number: (numValue ifNil: [ 0 ]).

    label := presenter newLabel label: (self labelTextFor: aDescription).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).
    input whenNumberChangedDo: [ :num |
        self mark: label for: aDescription with: (self commit: num for: aDescription) ].

    ^ self withLabel: label for: input
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitSingleOptionDescription: aDesc [
    | drop row label currentLevel explicabilityText |

    currentLevel := level.
    explicabilityText := aDesc commentFor: currentLevel.

    label := presenter newLabel label: (self labelTextFor: aDesc).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    drop := presenter newDropList.
    drop items: aDesc options.
    drop selectItem: (aDesc read: targetObject).
    drop whenSelectedItemChangedDo: [ :item |
        self mark: label for: aDesc with: (self commit: item for: aDesc) ].

    row := SpBoxLayout newHorizontal spacing: 15.
    row add: label width: 140.
    row add: drop expand: true.
    ^ row
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitPasswordDescription: aDesc [
    ^ self textRowFor: aDesc password: true
]

{ #category : 'visiting' }
AXPLSpecVisitor >> visitStringDescription: aDesc [
    ^ self textRowFor: aDesc password: false
]

{ #category : 'private' }
AXPLSpecVisitor >> textRowFor: aDesc password: isPassword [
    | input row label currentLevel explicabilityText value |

    currentLevel := level.
    explicabilityText := aDesc commentFor: currentLevel.

    label := presenter newLabel label: (self labelTextFor: aDesc).
    label help: (explicabilityText isString ifTrue: [ explicabilityText ] ifFalse: [ '' ]).

    input := presenter newTextInput.
    isPassword ifTrue: [ input bePassword ].
    value := aDesc read: targetObject.
    input text: (value ifNil: [ '' ] ifNotNil: [ value asString ]).
    input whenTextChangedDo: [ :txt |
        self mark: label for: aDesc with: (self commit: txt for: aDesc) ].

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

{ #category : 'private' }
AXPLSpecVisitor >> mark: aLabelledPresenter for: aDescription with: messageOrNil [
    "Signale une saisie refusée sur le champ lui-même : ⚠ devant le label,
    et le message de SimpleRene en infobulle à la place de l'explication
    ②. Une saisie valide rétablit label et explication."
    | explanation |
    explanation := aDescription commentFor: level.
    messageOrNil
        ifNil: [
            aLabelledPresenter label: (self labelTextFor: aDescription).
            aLabelledPresenter help: (explanation isString ifTrue: [ explanation ] ifFalse: [ '' ]) ]
        ifNotNil: [
            aLabelledPresenter label: '⚠ ' , (self labelTextFor: aDescription).
            aLabelledPresenter help: messageOrNil asString ]
]
