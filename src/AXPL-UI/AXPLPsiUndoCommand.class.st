"
Ψ : défaire la dernière intercession.
"
Class {
	#name : 'AXPLPsiUndoCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLPsiUndoCommand >> canBeExecuted [
	^ self isPsiAvailable and: [ self app psiEngine canUndo ]
]

{ #category : 'executing' }
AXPLPsiUndoCommand >> execute [
	self app runPsiUndo
]

{ #category : 'initialization' }
AXPLPsiUndoCommand >> initialize [
	super initialize.
	self
		name: 'Annuler la dernière modification Ψ';
		description: 'Ψ : défaire la dernière intercession.'
]
