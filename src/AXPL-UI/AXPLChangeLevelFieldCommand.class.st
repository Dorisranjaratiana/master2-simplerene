"
Ψ ⑨ : changer le niveau à partir duquel ce champ est visible.
"
Class {
	#name : 'AXPLChangeLevelFieldCommand',
	#superclass : 'AXPLFieldCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'accessing' }
AXPLChangeLevelFieldCommand class >> menuOrder [
	^ 30
]

{ #category : 'testing' }
AXPLChangeLevelFieldCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLChangeLevelFieldCommand >> execute [
	self app runPsiChangeLevel: self field label
]

{ #category : 'initialization' }
AXPLChangeLevelFieldCommand >> initialize [
	super initialize.
	self
		name: 'Changer le niveau… (Ψ)';
		description: 'Ψ ⑨ : changer le niveau à partir duquel ce champ est visible.'
]
