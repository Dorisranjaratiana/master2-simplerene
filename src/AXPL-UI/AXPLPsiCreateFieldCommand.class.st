"
Ψ : ajouter un champ au formulaire pendant l'exécution.
"
Class {
	#name : 'AXPLPsiCreateFieldCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLPsiCreateFieldCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLPsiCreateFieldCommand >> execute [
	self app runPsiCreateField
]

{ #category : 'initialization' }
AXPLPsiCreateFieldCommand >> initialize [
	super initialize.
	self
		name: 'Créer un champ…';
		description: 'Ψ : ajouter un champ au formulaire pendant l''exécution.'
]
