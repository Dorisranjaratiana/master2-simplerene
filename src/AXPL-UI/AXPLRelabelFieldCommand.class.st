"
Ψ ④ : donner un autre label à ce champ.
"
Class {
	#name : 'AXPLRelabelFieldCommand',
	#superclass : 'AXPLFieldCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'accessing' }
AXPLRelabelFieldCommand class >> menuOrder [
	^ 20
]

{ #category : 'testing' }
AXPLRelabelFieldCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLRelabelFieldCommand >> execute [
	self app runPsiRelabel: self field label
]

{ #category : 'initialization' }
AXPLRelabelFieldCommand >> initialize [
	super initialize.
	self
		name: 'Renommer… (Ψ)';
		description: 'Ψ ④ : donner un autre label à ce champ.'
]
