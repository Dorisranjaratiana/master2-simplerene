"
""Descripteur léger d'un domaine métier enregistré : sa clé d'adressage, son
libellé lisible (tiré du label de sa méta-description) et la classe métier
elle-même. Ne contient aucune logique — c'est une fiche d'identité.""
"
Class {
	#name : 'AXPLDomain',
	#superclass : 'Object',
	#instVars : [
		'key',
		'label',
		'domainClass'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLDomain >> domainClass [
	^ domainClass
]

{ #category : 'accessing' }
AXPLDomain >> domainClass: aClass [
	domainClass := aClass
]

{ #category : 'accessing' }
AXPLDomain >> key [
	^ key
]

{ #category : 'accessing' }
AXPLDomain >> key: aString [
	key := aString
]

{ #category : 'accessing' }
AXPLDomain >> label [
	^ label
]

{ #category : 'accessing' }
AXPLDomain >> label: aString [
	label := aString
]
