"
Plusieurs contextes à la fois : un champ n'est montré que si TOUS
l'acceptent ; s'il est masqué, la raison donnée est celle du premier
contexte qui le refuse. Se construit avec & :

	(AXPLContext level: #expert) & AXPLContext requiredOnly.
"
Class {
	#name : 'AXPLCompositeContext',
	#superclass : 'AXPLContext',
	#instVars : [
		'contexts'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'instance creation' }
AXPLCompositeContext class >> with: aCollectionOfContexts [
	^ self new setContexts: aCollectionOfContexts
]

{ #category : 'testing' }
AXPLCompositeContext >> accepts: aDescription [
	^ contexts allSatisfy: [ :each | each accepts: aDescription ]
]

{ #category : 'accessing' }
AXPLCompositeContext >> contexts [
	^ contexts
]

{ #category : 'accessing' }
AXPLCompositeContext >> explanationLevel [
	contexts do: [ :each | each explanationLevel ifNotNil: [ :lvl | ^ lvl ] ].
	^ nil
]

{ #category : 'accessing' }
AXPLCompositeContext >> label [
	^ ' + ' join: (contexts collect: [ :each | each label ])
]

{ #category : 'explaining' }
AXPLCompositeContext >> reasonForHiding: aDescription [
	^ contexts
		detect: [ :each | (each accepts: aDescription) not ]
		ifFound: [ :each | each reasonForHiding: aDescription ]
		ifNone: [ '' ]
]

{ #category : 'initialization' }
AXPLCompositeContext >> setContexts: aCollectionOfContexts [
	contexts := aCollectionOfContexts asArray
]
