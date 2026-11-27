"
Ψ ⑤② : changer l'explication de ce champ, pour un niveau ou pour tous.
"
Class {
	#name : 'AXPLEditExplanationFieldCommand',
	#superclass : 'AXPLFieldCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'accessing' }
AXPLEditExplanationFieldCommand class >> menuOrder [
	^ 40
]

{ #category : 'testing' }
AXPLEditExplanationFieldCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLEditExplanationFieldCommand >> execute [
	self app runPsiEditExplanation: self field label
]

{ #category : 'initialization' }
AXPLEditExplanationFieldCommand >> initialize [
	super initialize.
	self
		name: 'Modifier l''explication… (Ψ)';
		description: 'Ψ ⑤② : changer l''explication de ce champ, pour un niveau ou pour tous.'
]
