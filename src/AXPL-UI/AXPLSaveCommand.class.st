"
Vérifier les valeurs et enregistrer le dossier.
"
Class {
	#name : 'AXPLSaveCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLSaveCommand >> canBeExecuted [
	^ self app notNil and: [ self app levelDropList selectedItem notNil ]
]

{ #category : 'executing' }
AXPLSaveCommand >> execute [
	self app save
]

{ #category : 'initialization' }
AXPLSaveCommand >> initialize [
	super initialize.
	self
		name: 'Enregistrer';
		description: 'Vérifier les valeurs et enregistrer le dossier.'
]
