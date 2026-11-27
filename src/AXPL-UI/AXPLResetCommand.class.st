"
Tout effacer : nouvel objet, formulaire d'origine, écran neutre.
"
Class {
	#name : 'AXPLResetCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLResetCommand >> canBeExecuted [
	^ self app notNil
]

{ #category : 'executing' }
AXPLResetCommand >> execute [
	self app resetInterface
]

{ #category : 'initialization' }
AXPLResetCommand >> initialize [
	super initialize.
	self
		name: 'Réinitialiser';
		description: 'Tout effacer : nouvel objet, formulaire d''origine, écran neutre.'
]
