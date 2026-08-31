"
""Registre ouvert des types de champs (Open/Closed). Associe un symbole de type
(#string, #number, ...) à la classe SRDescription qui le matérialise. Ajouter un
nouveau type de champ au framework ne nécessite plus de modifier un dispatch
if/else existant (AXPLReflexivityEngine, AXPLHttpServer) : il suffit d'appeler
#register:as: sur le registre partagé. Symétrique de la table type→composant
prévue côté frontend.""
"
Class {
	#name : 'AXPLFieldTypeRegistry',
	#superclass : 'Object',
	#instVars : [
		'mappings'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLFieldTypeRegistry class >> default [
	^ default ifNil: [ default := self new registerDefaults; yourself ]
]

{ #category : 'querying' }
AXPLFieldTypeRegistry >> descriptionClassFor: aTypeSymbol [
	^ mappings
		at: aTypeSymbol
		ifAbsent: [ AXPLInvalidPayloadError signal: 'Type de champ inconnu : "' , aTypeSymbol asString , '".' ]
]

{ #category : 'initialization' }
AXPLFieldTypeRegistry >> initialize [
	super initialize.
	mappings := Dictionary new.
]

{ #category : 'testing' }
AXPLFieldTypeRegistry >> includesType: aTypeSymbol [
	^ mappings includesKey: aTypeSymbol
]

{ #category : 'registering' }
AXPLFieldTypeRegistry >> register: aTypeSymbol as: aDescriptionClass [
	mappings at: aTypeSymbol put: aDescriptionClass
]

{ #category : 'initialization' }
AXPLFieldTypeRegistry >> registerDefaults [
	self register: #string as: SRStringDescription.
	self register: #number as: SRNumberDescription.
	self register: #boolean as: SRBooleanDescription.
	self register: #date as: SRDateDescription.
	self register: #select as: SRSingleOptionDescription.
]

{ #category : 'querying' }
AXPLFieldTypeRegistry >> typeNameFor: aDescription [
	^ (mappings associations
		detect: [ :assoc | aDescription isKindOf: assoc value ]
		ifNone: [ nil ])
		ifNil: [ 'string' ]
		ifNotNil: [ :assoc | assoc key asString ]
]
