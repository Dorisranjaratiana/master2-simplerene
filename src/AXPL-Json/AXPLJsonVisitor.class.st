"
""Implémentation concrète d'AXPLVisitor qui produit une structure de
données pure (Dictionary/Array/String/Number/Boolean, pas d'objet Spec)
au lieu de widgets desktop. Ne dépend que d'AXPL-Core — aucune trace de
Spec2. C'est la preuve que le portage web (Seaside, ou un frontend
JS séparé consommant cette structure) n'a pas besoin de dupliquer la
logique d'adaptation (①), d'explicabilité (②) ou de réflexivité (Ψ).

Le résultat de visit:/acceptAXPLVisitor: est directement sérialisable en
JSON par n'importe quel writer (NeoJSON, STON, etc.) — AXPL-Json ne
prend pas parti sur lequel utiliser.""
"
Class {
	#name : 'AXPLJsonVisitor',
	#superclass : 'AXPLVisitor',
	#instVars : [
		'level'
	],
	#category : 'AXPL-Json',
	#package : 'AXPL-Json'
}

{ #category : 'instance creation' }
AXPLJsonVisitor class >> on: aTargetObject level: aLevel [
	^ self new
		targetObject: aTargetObject;
		level: aLevel;
		yourself
]

{ #category : 'building' }
AXPLJsonVisitor >> assembleContainer: aCollectionOfItems [
	^ Dictionary new
		at: #type put: 'group';
		at: #fields put: aCollectionOfItems asArray;
		yourself
]

{ #category : 'private' }
AXPLJsonVisitor >> jsonFor: aDescription type: aTypeString [
	^ Dictionary new
		at: #label put: aDescription label;
		at: #type put: aTypeString;
		at: #level put: aDescription level asString;
		at: #help put: (aDescription commentFor: level);
		at: #value put: (aDescription read: self targetObject);
		yourself
]

{ #category : 'accessing' }
AXPLJsonVisitor >> level [
	^ level
]

{ #category : 'accessing' }
AXPLJsonVisitor >> level: aSymbol [
	level := aSymbol
]

{ #category : 'visiting' }
AXPLJsonVisitor >> visitBooleanDescription: aDescription [
	^ self jsonFor: aDescription type: 'boolean'
]

{ #category : 'visiting' }
AXPLJsonVisitor >> visitDateDescription: aDescription [
	| json |
	json := self jsonFor: aDescription type: 'date'.
	json at: #value put: ((json at: #value) ifNotNil: [ :d | d asString ]).
	^ json
]

{ #category : 'visiting' }
AXPLJsonVisitor >> visitNumberDescription: aDescription [
	^ self jsonFor: aDescription type: 'number'
]

{ #category : 'visiting' }
AXPLJsonVisitor >> visitSingleOptionDescription: aDescription [
	| json |
	json := self jsonFor: aDescription type: 'select'.
	json at: #options put: aDescription options asArray.
	^ json
]

{ #category : 'visiting' }
AXPLJsonVisitor >> visitStringDescription: aDescription [
	^ self jsonFor: aDescription type: 'string'
]
