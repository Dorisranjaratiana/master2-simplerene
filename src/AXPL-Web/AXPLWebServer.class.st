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

CORS ouvert (Access-Control-Allow-Origin: *) — pratique pour un
frontend en développement local (Vite/CRA sur un autre port), à
resserrer avant tout déploiement réel.

LIMITE CONNUE : les champs Date reçus du web arrivent en String JSON,
pas en Date Pharo — #writeField: les écrit tels quels. Un champ Date
modifié depuis le web casserait l'affichage desktop (qui attend un
vrai Date). Non résolu ici : à traiter avant d'exposer un vrai champ
Date en écriture depuis le frontend.""
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
AXPLWebServer >> jsonBodyOf: aRequest [
	^ NeoJSONReader fromString: aRequest entity contents
]

{ #category : 'private' }
AXPLWebServer >> ok [
	^ Dictionary new at: #ok put: true; yourself
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
			resp headers at: 'Access-Control-Allow-Origin' put: '*' ];
		OPTIONS: '/*' -> [ :req | '' ];
		GET: '/form' -> [ :req |
			self formJsonFor: (req at: #level ifAbsent: [ 'simple' ]) asSymbol ];
		POST: '/field' -> [ :req | self writeField: req ];
		POST: '/psi/rename' -> [ :req | self psiRename: req ];
		POST: '/psi/set-level' -> [ :req | self psiSetLevel: req ];
		POST: '/psi/create-field' -> [ :req | self psiCreateField: req ];
		POST: '/psi/remove-field' -> [ :req | self psiRemoveField: req ];
		GET: '/psi/trace' -> [ :req | self traceJson ].
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
	(isSatisfiedBy:) — voir la LIMITE CONNUE du commentaire de classe
	pour les champs Date."
	| body desc |
	body := self jsonBodyOf: aRequest.
	desc := metaContainer children
		detect: [ :d | d label = (body at: #label) ]
		ifNone: [ ^ Dictionary new at: #error put: 'Champ inconnu'; yourself ].
	(desc isSatisfiedBy: (body at: #value))
		ifTrue: [
			desc write: (body at: #value) to: targetObject.
			^ self ok ]
		ifFalse: [ ^ Dictionary new at: #error put: 'Valeur invalide'; yourself ]
]
