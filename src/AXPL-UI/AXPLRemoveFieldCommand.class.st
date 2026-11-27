"
Ψ ⑥ : retirer ce champ du formulaire (annulable).
"
Class {
	#name : 'AXPLRemoveFieldCommand',
	#superclass : 'AXPLFieldCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'accessing' }
AXPLRemoveFieldCommand class >> menuOrder [
	^ 50
]

{ #category : 'testing' }
AXPLRemoveFieldCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLRemoveFieldCommand >> execute [
	self app runPsiRemoveField: self field label
]

{ #category : 'initialization' }
AXPLRemoveFieldCommand >> initialize [
	super initialize.
	self
		name: 'Supprimer (Ψ)';
		description: 'Ψ ⑥ : retirer ce champ du formulaire (annulable).'
]
