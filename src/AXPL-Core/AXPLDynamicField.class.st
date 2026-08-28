"
""Champ créé dynamiquement à l'exécution par le moteur Ψ (relation ④ étendue).
Contrairement aux SRDescription statiques de descriptionForAXPL (variables d'instance
fixes de l'objet métier), un AXPLDynamicField porte sa propre valeur : il n'est
adossé à aucun accesseur du targetObject. Cela permet d'ajouter/retirer des champs
sans jamais modifier la classe métier (ClientHopital, Etudiant, ...).""
"
Class {
	#name : 'AXPLDynamicField',
	#superclass : 'Object',
	#instVars : [
		'label',
		'type',
		'level',
		'help',
		'value',
		'options'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLDynamicField >> help [
	^ help
]

{ #category : 'accessing' }
AXPLDynamicField >> help: aString [
	help := aString
]

{ #category : 'initialization' }
AXPLDynamicField >> initialize [
	super initialize.
	options := #().
	value := nil.
]

{ #category : 'accessing' }
AXPLDynamicField >> label [
	^ label
]

{ #category : 'accessing' }
AXPLDynamicField >> label: aString [
	label := aString
]

{ #category : 'accessing' }
AXPLDynamicField >> level [
	^ level
]

{ #category : 'accessing' }
AXPLDynamicField >> level: aSymbol [
	level := aSymbol
]

{ #category : 'accessing' }
AXPLDynamicField >> options [
	^ options
]

{ #category : 'accessing' }
AXPLDynamicField >> options: aCollection [
	options := aCollection ifNil: [ #() ]
]

{ #category : 'accessing' }
AXPLDynamicField >> type [
	^ type
]

{ #category : 'accessing' }
AXPLDynamicField >> type: aSymbol [
	type := aSymbol
]

{ #category : 'accessing' }
AXPLDynamicField >> value [
	^ value
]

{ #category : 'accessing' }
AXPLDynamicField >> value: anObject [
	value := anObject
]
