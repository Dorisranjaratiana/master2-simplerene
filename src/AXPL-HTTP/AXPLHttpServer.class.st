"
""Sert le framework AXPL en HTTP/JSON via Teapot, pour un frontend web (ex: React)
qui ne peut pas piloter directement les objets Pharo comme le fait SRFormApp.
Expose la même logique que SRFormApp>>updateInterface (filtrage ①, explicabilité ②,
intercession Ψ ④, traçabilité [t]) sous forme de routes REST/JSON :

  GET    /form?level=simple|base|expert   -> AXPLForm { type, fields }
  POST   /field        {label, value}     -> AXPLResult
  POST   /field/rename {oldLabel,newLabel}-> AXPLResult
  POST   /field/level  {label, level}     -> AXPLResult
  POST   /field/create {label,type,level,help,options} -> AXPLResult
  DELETE /field/<label>                   -> AXPLResult
  GET    /trace                           -> [{timestamp, message}]

Un unique targetObject (ClientHopital) est gardé en mémoire pour toute la durée
de vie du serveur, comme SRFormApp>>targetObject: le fait pour la fenêtre desktop.""
"
Class {
	#name : 'AXPLHttpServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'targetObject',
		'metaContainer',
		'psiEngine'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AXPL-HTTP',
	#package : 'AXPL-HTTP'
}

{ #category : 'accessing' }
AXPLHttpServer class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'starting' }
AXPLHttpServer class >> start [
	^ self default start
]

{ #category : 'starting' }
AXPLHttpServer class >> stop [
	default ifNotNil: [ default stop ]
]

{ #category : 'private' }
AXPLHttpServer >> coerceValue: aValue for: aDescription [
	(aDescription isKindOf: SRDateDescription) ifTrue: [
		^ (aValue isString and: [ aValue isNotEmpty ])
			ifTrue: [ self dateFromISOString: aValue ]
			ifFalse: [ nil ] ].
	^ aValue
]

{ #category : 'http-handlers' }
AXPLHttpServer >> createFieldFrom: req [
	| body |
	body := self jsonBodyOf: req.
	^ [
		psiEngine
			createField: (body at: 'label')
			type: (body at: 'type') asSymbol
			level: (body at: 'level') asSymbol
			help: (body at: 'help' ifAbsent: [ '' ])
			options: (body at: 'options' ifAbsent: [ #() ]).
		Dictionary new at: #ok put: true; yourself ]
		on: Error
		do: [ :e | Dictionary new at: #error put: e messageText; yourself ]
]

{ #category : 'private' }
AXPLHttpServer >> dateFromISOString: aString [
	| parts |
	parts := aString tokenize: '-'.
	^ Date year: parts first asNumber month: parts second asNumber day: parts third asNumber
]

{ #category : 'private' }
AXPLHttpServer >> fieldTypeFor: aDescription [
	(aDescription isKindOf: SRBooleanDescription) ifTrue: [ ^ 'boolean' ].
	(aDescription isKindOf: SRNumberDescription) ifTrue: [ ^ 'number' ].
	(aDescription isKindOf: SRDateDescription) ifTrue: [ ^ 'date' ].
	(aDescription isKindOf: SRSingleOptionDescription) ifTrue: [ ^ 'select' ].
	^ 'string'
]

{ #category : 'http-handlers' }
AXPLHttpServer >> formResponseFor: aLevelString [
	| level builder visible |
	level := aLevelString asSymbol.
	builder := AXPLFormBuilder new
		targetObject: targetObject;
		userLevel: level;
		metaContainer: metaContainer;
		yourself.
	visible := builder build.
	^ Dictionary new
		at: #type put: 'group';
		at: #fields put: (visible collect: [ :d | self jsonForDescription: d level: level ]) asArray;
		yourself
]

{ #category : 'initialization' }
AXPLHttpServer >> initialize [
	super initialize.
	targetObject := ClientHopital new.
	metaContainer := targetObject class descriptionForAXPL.
	psiEngine := AXPLReflexivityEngine new
		metaContainer: metaContainer;
		targetClass: targetObject class;
		yourself.
]

{ #category : 'private' }
AXPLHttpServer >> jsonBodyOf: req [
	^ NeoJSONReader fromString: req entity contents asString
]

{ #category : 'private' }
AXPLHttpServer >> jsonForDescription: aDescription level: aLevel [
	^ Dictionary new
		at: #label put: aDescription label;
		at: #type put: (self fieldTypeFor: aDescription);
		at: #level put: aDescription level asString;
		at: #help put: (aDescription commentFor: aLevel);
		at: #value put: (self jsonValue: (aDescription read: targetObject));
		at: #options put: ((aDescription isKindOf: SRSingleOptionDescription)
			ifTrue: [ aDescription options asArray ]
			ifFalse: [ nil ]);
		yourself
]

{ #category : 'private' }
AXPLHttpServer >> jsonValue: aValue [
	aValue ifNil: [ ^ nil ].
	(aValue isKindOf: Date) ifTrue: [
		^ (aValue year printPaddedWith: $0 to: 4) , '-'
			, (aValue monthIndex printPaddedWith: $0 to: 2) , '-'
			, (aValue dayOfMonth printPaddedWith: $0 to: 2) ].
	^ aValue
]

{ #category : 'http-handlers' }
AXPLHttpServer >> removeFieldNamed: aLabel [
	^ [
		psiEngine removeField: aLabel.
		Dictionary new at: #ok put: true; yourself ]
		on: Error
		do: [ :e | Dictionary new at: #error put: e messageText; yourself ]
]

{ #category : 'http-handlers' }
AXPLHttpServer >> renameFieldFrom: req [
	| body |
	body := self jsonBodyOf: req.
	^ [
		psiEngine relabelDescription: (body at: 'oldLabel') to: (body at: 'newLabel').
		Dictionary new at: #ok put: true; yourself ]
		on: Error
		do: [ :e | Dictionary new at: #error put: e messageText; yourself ]
]

{ #category : 'http-handlers' }
AXPLHttpServer >> setLevelFrom: req [
	| body |
	body := self jsonBodyOf: req.
	^ [
		psiEngine setLevel: (body at: 'level') asSymbol ofDescription: (body at: 'label').
		Dictionary new at: #ok put: true; yourself ]
		on: Error
		do: [ :e | Dictionary new at: #error put: e messageText; yourself ]
]

{ #category : 'starting' }
AXPLHttpServer >> start [
	teapot := Teapot configure: {
		#port -> 8080.
		#defaultOutput -> #json }.
	teapot
		GET: '/form' -> [ :req | self formResponseFor: (req at: #level ifAbsent: [ 'simple' ]) ];
		POST: '/field' -> [ :req | self writeFieldFrom: req ];
		POST: '/field/rename' -> [ :req | self renameFieldFrom: req ];
		POST: '/field/level' -> [ :req | self setLevelFrom: req ];
		POST: '/field/create' -> [ :req | self createFieldFrom: req ];
		DELETE: '/field/<label>' -> [ :req | self removeFieldNamed: (req at: #label) ];
		GET: '/trace' -> [ :req | self traceLogJson ];
		OPTIONS: '/*' -> [ :req | TeaResponse ok ];
		after: '/*' -> [ :req :resp |
			resp headers
				at: 'Access-Control-Allow-Origin' put: '*';
				at: 'Access-Control-Allow-Methods' put: 'GET, POST, DELETE, OPTIONS';
				at: 'Access-Control-Allow-Headers' put: 'Content-Type' ];
		exception: Error -> [ :ex :req | Dictionary new at: #error put: ex messageText; yourself ];
		start.
]

{ #category : 'starting' }
AXPLHttpServer >> stop [
	teapot ifNotNil: [ teapot stop ]
]

{ #category : 'http-handlers' }
AXPLHttpServer >> traceLogJson [
	^ (psiEngine traceLog collect: [ :assoc |
		Dictionary new
			at: #timestamp put: assoc key asString;
			at: #message put: assoc value;
			yourself ]) asArray
]

{ #category : 'http-handlers' }
AXPLHttpServer >> writeFieldFrom: req [
	| body label value desc |
	body := self jsonBodyOf: req.
	label := body at: 'label'.
	value := body at: 'value'.
	desc := metaContainer children detect: [ :d | d label = label ] ifNone: [ nil ].
	desc ifNil: [ ^ Dictionary new at: #error put: 'Champ introuvable : ' , label; yourself ].
	desc write: (self coerceValue: value for: desc) to: targetObject.
	^ Dictionary new at: #ok put: true; yourself
]
