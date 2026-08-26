"
""Backend web minimal pour AXPL, prêt à être appelé par un frontend
séparé (React ou autre). Ne réimplémente rien : réutilise tel quel
AXPLJsonVisitor (⑦ pour le web), AXPLFormBuilder (①) et
AXPLReflexivityEngine (Ψ) — la même logique que SRFormApp côté desktop,
juste exposée en HTTP via Teapot au lieu de Spec2.

Routes :
  GET  /form?level=simple|base|expert   → champs visibles à ce niveau (JSON)
  POST /field        {label, value}     → écrit une valeur (validée avant écriture)
  POST /psi/rename       {oldLabel, newLabel}
  POST /psi/set-level    {label, level}
  POST /psi/create-field {label, type, level, options?}
  POST /psi/remove-field {label}
  GET  /psi/trace                       → historique horodaté Ψ

CORS ouvert (Access-Control-Allow-Origin/Methods/Headers) — pratique
pour un frontend en développement local (Vite/CRA sur un autre port),
à resserrer avant tout déploiement réel. Les trois en-têtes sont
nécessaires : Origin seul ne suffit pas dès qu'une requête POST envoie
un corps JSON (Content-Type: application/json déclenche un preflight
OPTIONS que le navigateur bloque sans Allow-Methods/Allow-Headers).

Les champs Date reçus du web arrivent en String JSON (format ISO
8601 'AAAA-MM-JJ', celui de <input type=date> et de
Date#asString côté JSON) — #writeField: les convertit explicitement
en Date Pharo avant validation/écriture, plutôt que de les stocker
tels quels et casser l'affichage desktop (qui attend un vrai Date).""
"
Class {
	#name : 'AXPLWebServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'targetObject',
		'metaContainer',
		'psiEngine'
	],
	#category : 'AXPL-Web',
	#package : 'AXPL-Web'
}

{ #category : 'instance creation' }
AXPLWebServer class >> onPort: aPort forTargetObject: anObject [
	^ self new
		targetObject: anObject;
		start: aPort;
		yourself
]

{ #category : 'building' }
AXPLWebServer >> formJsonFor: aLevelSymbol [
	"① + ⑦ : mêmes AXPLFormBuilder et AXPLJsonVisitor que le desktop,
	juste appelés directement plutôt que depuis un SRFormApp Spec2."
	| builder visitor visible |
	builder := AXPLFormBuilder new
		targetObject: targetObject;
		userLevel: aLevelSymbol;
		metaContainer: metaContainer;
		yourself.
	visible := builder build.
	visitor := AXPLJsonVisitor on: targetObject level: aLevelSymbol.
	^ visitor visit: visible
]

{ #category : 'private' }
AXPLWebServer >> coerceValue: aValue for: aDescription [
	"Le JSON n'a pas de type Date natif : un champ SRDateDescription arrive
	du web en String ISO 8601 ('AAAA-MM-JJ', tronquée si un timestamp
	complet est envoyé). On la convertit explicitement en Date Pharo avant
	toute validation/écriture — sinon la valeur brute finirait stockée en
	String et casserait l'affichage desktop, qui attend un vrai Date."
	(aDescription isKindOf: SRDateDescription) ifFalse: [ ^ aValue ].
	(aValue isKindOf: String) ifFalse: [ ^ aValue ].
	^ self dateFromIso: aValue
]

{ #category : 'private' }
AXPLWebServer >> dateFromIso: aString [
	| datePart parts year month day |
	datePart := aString copyFrom: 1 to: (10 min: aString size).
	parts := datePart tokenize: '-'.
	(parts size = 3
		and: [ (year := (parts at: 1) asInteger) notNil
		and: [ (month := (parts at: 2) asInteger) notNil
		and: [ (day := (parts at: 3) asInteger) notNil ] ] ])
		ifFalse: [
			Error signal: 'Date invalide (attendu AAAA-MM-JJ) : ' , aString printString ].
	^ Date year: year month: month day: day
]

{ #category : 'private' }
AXPLWebServer >> jsonBodyOf: aRequest [
	"NeoJSONReader class >> fromString: parse les clés d'objet JSON en
	String (propertyNamesAsSymbols vaut false par défaut, vérifié dans la
	source de NeoJSON) — alors que toutes les routes ci-dessous lisent le
	corps avec des Symbol (body at: #label, #value...). Sans ce réglage,
	CHAQUE route POST échouerait avec 'key not found' sur une vraie
	requête HTTP, masqué en {error: ...} propre par safely: mais jamais
	fonctionnel."
	^ (NeoJSONReader on: aRequest entity contents readStream)
		propertyNamesAsSymbols: true;
		next
]

{ #category : 'private' }
AXPLWebServer >> ok [
	^ Dictionary new at: #ok put: true; yourself
]

{ #category : 'private' }
AXPLWebServer >> safely: aBlock [
	"Toutes les routes passent par ici : une requête malformée (JSON
	invalide, clé manquante, label inconnu, type de champ inconnu,
	niveau invalide...) ne doit jamais renvoyer une trace Smalltalk brute
	à un client HTTP externe — toujours du JSON propre avec un message
	clair, même en cas d'erreur."
	^ [ aBlock value ]
		on: Error
		do: [ :err | Dictionary new at: #error put: err messageText; yourself ]
]

{ #category : 'psi' }
AXPLWebServer >> psiCreateField: aRequest [
	"⑥ — les mêmes classes de description que côté desktop, choisies
	depuis le type texte reçu du frontend."
	| body typeClasses type level label |
	body := self jsonBodyOf: aRequest.
	label := body at: #label.
	level := (body at: #level) asSymbol.
	type := body at: #type.
	type = 'select'
		ifTrue: [
			psiEngine
				createSelectionField: label
				options: (body at: #options)
				level: level ]
		ifFalse: [
			typeClasses := Dictionary new
				at: 'string' put: SRStringDescription;
				at: 'number' put: SRNumberDescription;
				at: 'boolean' put: SRBooleanDescription;
				at: 'date' put: SRDateDescription;
				yourself.
			psiEngine
				createField: label
				type: (typeClasses at: type)
				level: level ].
	^ self ok
]

{ #category : 'psi' }
AXPLWebServer >> psiRemoveField: aRequest [
	"⑥"
	| body |
	body := self jsonBodyOf: aRequest.
	psiEngine removeField: (body at: #label).
	^ self ok
]

{ #category : 'psi' }
AXPLWebServer >> psiRename: aRequest [
	"④"
	| body |
	body := self jsonBodyOf: aRequest.
	psiEngine relabelDescription: (body at: #oldLabel) to: (body at: #newLabel).
	^ self ok
]

{ #category : 'psi' }
AXPLWebServer >> psiSetLevel: aRequest [
	"⑨"
	| body |
	body := self jsonBodyOf: aRequest.
	psiEngine setLevel: (body at: #level) asSymbol ofDescription: (body at: #label).
	^ self ok
]

{ #category : 'initialization' }
AXPLWebServer >> start: aPort [
	teapot := Teapot configure: {
		(#defaultOutput -> #json).
		(#port -> aPort).
		(#debugMode -> true) }.
	teapot
		after: '*' -> [ :req :resp |
			"Access-Control-Allow-Origin seul suffit pour une requête CORS
			'simple' (GET sans en-tête custom), comme /form. Mais POST /field
			et /psi/* envoient un corps JSON avec Content-Type: application/json,
			ce qui déclenche un preflight OPTIONS que le navigateur bloque
			silencieusement sans Allow-Methods/Allow-Headers explicites — le
			POST semble alors ne rien faire, sans erreur visible côté serveur."
			resp headers
				at: 'Access-Control-Allow-Origin' put: '*';
				at: 'Access-Control-Allow-Methods' put: 'GET, POST, OPTIONS';
				at: 'Access-Control-Allow-Headers' put: 'Content-Type' ];
		OPTIONS: '/*' -> [ :req | '' ];
		GET: '/form' -> [ :req |
			self safely: [ self formJsonFor: (req at: #level ifAbsent: [ 'simple' ]) asSymbol ] ];
		POST: '/field' -> [ :req | self safely: [ self writeField: req ] ];
		POST: '/psi/rename' -> [ :req | self safely: [ self psiRename: req ] ];
		POST: '/psi/set-level' -> [ :req | self safely: [ self psiSetLevel: req ] ];
		POST: '/psi/create-field' -> [ :req | self safely: [ self psiCreateField: req ] ];
		POST: '/psi/remove-field' -> [ :req | self safely: [ self psiRemoveField: req ] ];
		GET: '/psi/trace' -> [ :req | self safely: [ self traceJson ] ].
	teapot start.
]

{ #category : 'accessing' }
AXPLWebServer >> stop [
	teapot ifNotNil: [ teapot stop ]
]

{ #category : 'accessing' }
AXPLWebServer >> targetObject: anObject [
	targetObject := anObject.
	metaContainer := anObject class descriptionForAXPL.
	psiEngine := AXPLReflexivityEngine new
		metaContainer: metaContainer;
		yourself.
]

{ #category : 'accessing' }
AXPLWebServer >> traceJson [
	"[t]"
	^ psiEngine traceLog collect: [ :assoc |
		Dictionary new
			at: #timestamp put: assoc key printString;
			at: #action put: assoc value;
			yourself ]
]

{ #category : 'private' }
AXPLWebServer >> writeField: aRequest [
	"Comme AXPLSpecVisitor : jamais d'écriture sans validation passée
	(isSatisfiedBy:) — et jamais sans coercion du type JSON reçu vers le
	type Pharo attendu par la description (voir coerceValue:for:)."
	| body desc value |
	body := self jsonBodyOf: aRequest.
	desc := metaContainer children
		detect: [ :d | d label = (body at: #label) ]
		ifNone: [ ^ Dictionary new at: #error put: 'Champ inconnu'; yourself ].
	value := self coerceValue: (body at: #value) for: desc.
	(desc isSatisfiedBy: value)
		ifTrue: [
			desc write: value to: targetObject.
			^ self ok ]
		ifFalse: [ ^ Dictionary new at: #error put: 'Valeur invalide'; yourself ]
]
