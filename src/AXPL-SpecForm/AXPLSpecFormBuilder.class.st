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
Chaque saisie est validée par SimpleRene avant d'être écrite (write:description:) :
une valeur refusée n'est pas écrite, l'infobulle du champ affiche ⚠ et le
message, et le presenter prévient l'application.
Le filtrage par niveau ① est fait avant (AXPLSpecFormPresenter ne lui
donne que les champs visibles).
"
Class {
	#name : 'AXPLSpecFormBuilder',
	#superclass : 'SFGridPresenterBuilder',
	#instVars : [
		'level',
		'widgets'
	],
	#category : 'AXPL-SpecForm',
	#package : 'AXPL-SpecForm'
}

{ #category : 'private' }
AXPLSpecFormBuilder >> appendWidget: aWidget description: aDescription [
	"SpDatePresenter (composite, pas un widget simple) n'a pas d'infobulle :
	vérifié par la CI, help: y lève doesNotUnderstand."
	self widgets at: aDescription put: aWidget.
	self mark: aWidget for: aDescription with: nil.
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
	"newDropList du trait SpTPresenterBuilder passe par #application, que
	ce constructeur n'a pas : on le demande au presenter du formulaire."
	| dropList |
	dropList := self presenter newDropList.
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

{ #category : 'private' }
AXPLSpecFormBuilder >> mark: aWidget for: aDescription with: aMessageOrNil [
	"② L'infobulle donne l'explication du niveau ; tant qu'une saisie est
	refusée, elle donne le message de SimpleRene."
	(aWidget respondsTo: #help:) ifFalse: [ ^ self ].
	aWidget help: (aMessageOrNil
		ifNil: [ aDescription commentFor: level ]
		ifNotNil: [ '⚠ ' , aMessageOrNil asString ])
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitBooleanDescription: aDescription [
	"Comme Spec-Form, mais une valeur nil est une case décochée."
	| checkbox |
	checkbox := self newCheckBox
		state: (self read: aDescription) == true;
		enabled: aDescription isReadOnly not;
		whenChangedDo: [ :aValue | self write: aValue description: aDescription ];
		yourself.
	self appendWidget: checkbox description: aDescription
]

{ #category : 'visiting' }
AXPLSpecFormBuilder >> visitContainer: aContainer [
	"Mêmes espacements que la fenêtre AXΨL : 33 pixels par ligne, sur
	lesquels est calculée la hauteur de la fenêtre (AXPLFormApp)."
	super visitContainer: aContainer.
	gridLayout
		rowSpacing: 8;
		columnSpacing: 15
]

{ #category : 'accessing' }
AXPLSpecFormBuilder >> widgetFor: aLabel [
	^ self widgets keys
		detect: [ :each | each label = aLabel ]
		ifFound: [ :description | self widgets at: description ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AXPLSpecFormBuilder >> widgets [
	"description → widget de saisie"
	^ widgets ifNil: [ widgets := IdentityDictionary new ]
]

{ #category : 'private' }
AXPLSpecFormBuilder >> write: anObject description: aDescription [
	"Validée avant d'être écrite (règles de SimpleRene : requis, type,
	conditions) ; une valeur refusée n'est pas écrite."
	| message |
	message := aDescription validationMessageFor: anObject.
	message ifNil: [ super write: anObject description: aDescription ].
	(self widgets at: aDescription ifAbsent: [ nil ]) ifNotNil: [ :widget |
		self mark: widget for: aDescription with: message ].
	presenter notifyValidationOf: aDescription message: message.
	^ message
]
