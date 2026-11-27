"
Constructeur de formulaire Spec-Form (pharo-spec/Spec-Form, E. Lorenzano)
adapté à AXΨL. Spec-Form dessine la grille label / widget à partir des
descriptions SimpleRene ; AXΨL n'y ajoute que ce qui lui est propre :
- ② l'aide de chaque champ est l'explication du NIVEAU courant
  (commentFor:), pas le #comment unique de SimpleRene ;
- les champs obligatoires sont marqués d'une étoile ;
- deux types que Spec-Form n'affiche pas encore : Date (il n'a pas de
  visitDateDescription:, le champ disparaissait) et mot de passe (affiché
  en clair, comme un texte ordinaire) ;
- un texte nil ne fait pas planter le champ texte ;
- le champ à choix utilise newDropList : le newDropDown de Spec-Form
  (SpDropDownPresenter) n'a pas d'adaptateur Morphic dans Pharo 13
  (« No binding for DropDownAdapter found » à l'ouverture de la fenêtre).
Le filtrage par niveau ① est fait avant (AXPLSpecFormPresenter ne lui
donne que les champs visibles).
"
Class {
	#name : 'AXPLSpecFormBuilder',
	#superclass : 'SFGridPresenterBuilder',
	#instVars : [
		'level'
	],
	#category : 'AXPL-SpecForm',
	#package : 'AXPL-SpecForm'
}

{ #category : 'private' }
AXPLSpecFormBuilder >> appendWidget: aWidget description: aDescription [
	"SpDatePresenter (composite, pas un widget simple) n'a pas d'infobulle :
	vérifié par la CI, help: y lève doesNotUnderstand."
	(aWidget respondsTo: #help:) ifTrue: [
		aWidget help: (aDescription commentFor: level) ].
	builder
		add: (self labelTextFor: aDescription);
		add: aWidget;
		nextRow
]

{ #category : 'private' }
AXPLSpecFormBuilder >> labelTextFor: aDescription [
	^ aDescription isRequired
		ifTrue: [ aDescription label , ' *' ]
		ifFalse: [ aDescription label ]
]

{ #category : 'accessing' }
AXPLSpecFormBuilder >> level [
	^ level
]

{ #category : 'accessing' }
AXPLSpecFormBuilder >> level: aLevel [
	level := aLevel
]

{ #category : 'private' }
AXPLSpecFormBuilder >> textRowFor: aDescription password: isPassword [
	| textInput |
	textInput := self newTextInput.
	isPassword ifTrue: [ textInput bePassword ].
	textInput
		text: ((self read: aDescription) ifNil: [ '' ] ifNotNil: [ :value | value asString ]);
		editable: aDescription isReadOnly not;
		whenTextChangedDo: [ :aString | self write: aString description: aDescription ].
	self appendWidget: textInput description: aDescription
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitDateDescription: aDescription [
	| input |
	input := self instantiate: SpDatePresenter.
	input date: ((self read: aDescription) ifNil: [ Date today ]).
	input whenDateChanged: [ :aDate | self write: aDate description: aDescription ].
	self appendWidget: input description: aDescription
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitPasswordDescription: aDescription [
	self textRowFor: aDescription password: true
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitStringDescription: aDescription [
	self textRowFor: aDescription password: false
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitSingleOptionDescription: aDescription [
	| dropList |
	dropList := self newDropList.
	dropList
		startWithoutSelection;
		items: aDescription options;
		display: [ :each |
			each
				ifNil: [ '' ]
				ifNotNil: [ aDescription reference toString: each ] ].
	(self read: aDescription) ifNotNil: [ :value | dropList selectItem: value ].
	dropList
		enabled: aDescription isReadOnly not;
		whenSelectedItemChangedDo: [ :each | self write: each description: aDescription ].
	self appendWidget: dropList description: aDescription
]
