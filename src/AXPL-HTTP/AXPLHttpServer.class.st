"
""Sert le framework AXPL en HTTP/JSON via Teapot, pour un frontend web (ex: React)
qui ne peut pas piloter directement les objets Pharo comme le fait SRFormApp.

Neutre par construction : ne référence AUCUNE classe métier concrète. Les domaines
disponibles sont découverts par réflexion (AXPLDomainRegistry discover) au démarrage
— toute classe qui implémente #descriptionForAXPL devient automatiquement adressable,
sans modifier ce fichier.

Contrat v1 (voir README) :
  GET    /health
  GET    /api/v1/domains
  GET    /api/v1/domains/<domain>/form?level=simple|base|expert
  GET    /api/v1/domains/<domain>/trace
  GET    /api/v1/domains/<domain>/fields/<label>
  POST   /api/v1/domains/<domain>/fields                    {label,type,level,help,options}
  POST   /api/v1/domains/<domain>/fields/<label>/value      {value}
  POST   /api/v1/domains/<domain>/fields/<label>/rename     {newLabel}
  POST   /api/v1/domains/<domain>/fields/<label>/level      {level}
  DELETE /api/v1/domains/<domain>/fields/<label>
  POST   /api/v1/domains/<domain>/reset

Toute erreur applicative (AXPLApiError et sous-classes) produit un statut HTTP
et un corps {error:{code,message}} cohérents, plutôt qu'un systématique 200.
Une AXPLDomainSession par domaine découvert, créée à la demande et mise en cache
— chaque domaine a son propre targetObject/metaContainer/psiEngine, isolé des autres.""
"
Class {
	#name : 'AXPLHttpServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'registry',
		'sessions',
		'fieldTypes'
	],
	#classInstVars : [
		'default',
		'allowedOrigin'
	],
	#category : 'AXPL-HTTP',
	#package : 'AXPL-HTTP'
}

{ #category : 'accessing' }
AXPLHttpServer class >> allowedOrigin [
	"Origine CORS autorisée. '*' convient en développement local ; restreindre à
	l'origine exacte du frontend (#allowedOrigin:) avant tout déploiement public."
	^ allowedOrigin ifNil: [ '*' ]
]

{ #category : 'accessing' }
AXPLHttpServer class >> allowedOrigin: aString [
	allowedOrigin := aString
]

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
AXPLHttpServer >> apiErrorResponse: ex [
	^ TeaResponse new
		code: (self httpStatusFor: ex class);
		body: (Dictionary new
			at: #error put: (Dictionary new
				at: #code put: ex class code asString;
				at: #message put: ex messageText;
				yourself);
			yourself);
		yourself
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
AXPLHttpServer >> createFieldFor: aDomainKey from: req [
	| session body |
	session := self sessionFor: aDomainKey.
	body := self jsonBodyOf: req.
	session psiEngine
		createField: (body at: 'label' ifAbsent: [ nil ])
		type: (body at: 'type' ifAbsent: [ AXPLInvalidPayloadError signal: 'Le type est requis.' ]) asSymbol
		level: (body at: 'level' ifAbsent: [ AXPLInvalidPayloadError signal: 'Le niveau est requis.' ]) asSymbol
		help: (body at: 'help' ifAbsent: [ '' ])
		options: (body at: 'options' ifAbsent: [ #() ]).
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'private' }
AXPLHttpServer >> dateFromISOString: aString [
	| parts |
	parts := aString tokenize: '-'.
	^ Date year: parts first asNumber month: parts second asNumber day: parts third asNumber
]

{ #category : 'http-handlers' }
AXPLHttpServer >> domainsJson [
	^ Dictionary new
		at: #domains put: (registry domains collect: [ :d |
			Dictionary new at: #key put: d key; at: #label put: d label; yourself ]) asArray;
		yourself
]

{ #category : 'http-handlers' }
AXPLHttpServer >> fieldJsonFor: aDomainKey label: aLabel [
	| session desc |
	session := self sessionFor: aDomainKey.
	desc := session metaContainer children
		detect: [ :d | d label = aLabel ]
		ifNone: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	^ self jsonForDescription: desc level: #expert targetObject: session targetObject
]

{ #category : 'http-handlers' }
AXPLHttpServer >> formResponseFor: aDomainKey level: aLevelString [
	| session level builder visible |
	session := self sessionFor: aDomainKey.
	level := aLevelString asSymbol.
	builder := AXPLFormBuilder new
		targetObject: session targetObject;
		userLevel: level;
		metaContainer: session metaContainer;
		yourself.
	visible := builder build.
	^ Dictionary new
		at: #type put: 'group';
		at: #label put: session metaContainer label;
		at: #fields put: (visible collect: [ :d | self jsonForDescription: d level: level targetObject: session targetObject ]) asArray;
		yourself
]

{ #category : 'private' }
AXPLHttpServer >> httpStatusFor: anExceptionClass [
	anExceptionClass = AXPLFieldNotFoundError ifTrue: [ ^ 404 ].
	anExceptionClass = AXPLDomainNotFoundError ifTrue: [ ^ 404 ].
	anExceptionClass = AXPLFieldAlreadyExistsError ifTrue: [ ^ 409 ].
	anExceptionClass = AXPLFieldProtectedError ifTrue: [ ^ 403 ].
	anExceptionClass = AXPLInvalidPayloadError ifTrue: [ ^ 400 ].
	^ 500
]

{ #category : 'initialization' }
AXPLHttpServer >> initialize [
	super initialize.
	registry := AXPLDomainRegistry discover.
	fieldTypes := AXPLFieldTypeRegistry default.
	sessions := Dictionary new.
]

{ #category : 'private' }
AXPLHttpServer >> jsonBodyOf: req [
	^ NeoJSONReader fromString: req entity contents asString
]

{ #category : 'private' }
AXPLHttpServer >> jsonForDescription: aDescription level: aLevel targetObject: aTargetObject [
	^ Dictionary new
		at: #label put: aDescription label;
		at: #type put: (fieldTypes typeNameFor: aDescription);
		at: #level put: aDescription level asString;
		at: #help put: (aDescription commentFor: aLevel);
		at: #value put: (self jsonValue: (aDescription read: aTargetObject));
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
AXPLHttpServer >> removeFieldFor: aDomainKey label: aLabel [
	(self sessionFor: aDomainKey) psiEngine removeField: aLabel.
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'http-handlers' }
AXPLHttpServer >> renameFieldFor: aDomainKey label: aLabel from: req [
	| session body |
	session := self sessionFor: aDomainKey.
	body := self jsonBodyOf: req.
	session psiEngine relabelDescription: aLabel to: (body at: 'newLabel' ifAbsent: [ nil ]).
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'private' }
AXPLHttpServer >> sessionFor: aDomainKey [
	^ sessions at: aDomainKey ifAbsentPut: [
		AXPLDomainSession new initializeFor: (registry at: aDomainKey); yourself ]
]

{ #category : 'http-handlers' }
AXPLHttpServer >> resetDomain: aDomainKey [
	"Rejette la session en cache pour ce domaine ; le prochain accès en recrée une
	fraîche via #sessionFor:. Utile pour rejouer une démo sans redémarrer le serveur.
	Vérifie d'abord que le domaine existe, pour renvoyer DOMAIN_NOT_FOUND plutôt
	que de réinitialiser silencieusement une clé inconnue."
	registry at: aDomainKey.
	sessions removeKey: aDomainKey ifAbsent: [ nil ].
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'http-handlers' }
AXPLHttpServer >> setLevelFor: aDomainKey label: aLabel from: req [
	| session body |
	session := self sessionFor: aDomainKey.
	body := self jsonBodyOf: req.
	session psiEngine setLevel: (body at: 'level' ifAbsent: [ AXPLInvalidPayloadError signal: 'Le niveau est requis.' ]) asSymbol ofDescription: aLabel.
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'starting' }
AXPLHttpServer >> start [
	teapot := Teapot configure: {
		#port -> 8080.
		#defaultOutput -> #json }.
	teapot
		GET: '/health' -> [ :req | Dictionary new at: #status put: 'ok'; yourself ];
		GET: '/api/v1/domains' -> [ :req | self domainsJson ];
		GET: '/api/v1/domains/<domain>/form' -> [ :req | self formResponseFor: (req at: #domain) level: (req at: #level ifAbsent: [ 'simple' ]) ];
		GET: '/api/v1/domains/<domain>/trace' -> [ :req | self traceLogJsonFor: (req at: #domain) ];
		GET: '/api/v1/domains/<domain>/fields/<label>' -> [ :req | self fieldJsonFor: (req at: #domain) label: (req at: #label) ];
		POST: '/api/v1/domains/<domain>/fields' -> [ :req | self createFieldFor: (req at: #domain) from: req ];
		POST: '/api/v1/domains/<domain>/fields/<label>/value' -> [ :req | self writeFieldFor: (req at: #domain) label: (req at: #label) from: req ];
		POST: '/api/v1/domains/<domain>/fields/<label>/rename' -> [ :req | self renameFieldFor: (req at: #domain) label: (req at: #label) from: req ];
		POST: '/api/v1/domains/<domain>/fields/<label>/level' -> [ :req | self setLevelFor: (req at: #domain) label: (req at: #label) from: req ];
		DELETE: '/api/v1/domains/<domain>/fields/<label>' -> [ :req | self removeFieldFor: (req at: #domain) label: (req at: #label) ];
		POST: '/api/v1/domains/<domain>/reset' -> [ :req | self resetDomain: (req at: #domain) ];
		OPTIONS: '/*' -> [ :req | TeaResponse ok ];
		after: '/*' -> [ :req :resp |
			resp headers
				at: 'Access-Control-Allow-Origin' put: self class allowedOrigin;
				at: 'Access-Control-Allow-Methods' put: 'GET, POST, DELETE, OPTIONS';
				at: 'Access-Control-Allow-Headers' put: 'Content-Type' ];
		exception: AXPLApiError -> [ :ex :req | self apiErrorResponse: ex ];
		exception: Error -> [ :ex :req |
			Transcript showCr: 'AXPL-HTTP erreur interne : ' , ex messageText.
			TeaResponse new code: 500; body: (Dictionary new
				at: #error put: (Dictionary new at: #code put: 'INTERNAL_ERROR'; at: #message put: ex messageText; yourself);
				yourself); yourself ];
		start.
]

{ #category : 'starting' }
AXPLHttpServer >> stop [
	teapot ifNotNil: [ teapot stop ]
]

{ #category : 'http-handlers' }
AXPLHttpServer >> traceLogJsonFor: aDomainKey [
	^ ((self sessionFor: aDomainKey) psiEngine traceLog collect: [ :assoc |
		Dictionary new
			at: #timestamp put: assoc key asString;
			at: #message put: assoc value;
			yourself ]) asArray
]

{ #category : 'http-handlers' }
AXPLHttpServer >> writeFieldFor: aDomainKey label: aLabel from: req [
	| session body desc |
	session := self sessionFor: aDomainKey.
	body := self jsonBodyOf: req.
	desc := session metaContainer children
		detect: [ :d | d label = aLabel ]
		ifNone: [ AXPLFieldNotFoundError signal: 'Champ introuvable : "' , aLabel , '".' ].
	desc write: (self coerceValue: (body at: 'value' ifAbsent: [ nil ]) for: desc) to: session targetObject.
	^ Dictionary new at: #ok put: true; yourself
]
