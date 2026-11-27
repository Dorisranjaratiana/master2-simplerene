"
Ouvrir un dossier enregistré (valeurs et modifications Ψ).
"
Class {
	#name : 'AXPLOpenDossierCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLOpenDossierCommand >> canBeExecuted [
	^ self app notNil
]

{ #category : 'executing' }
AXPLOpenDossierCommand >> execute [
	self app runOpenDossier
]

{ #category : 'initialization' }
AXPLOpenDossierCommand >> initialize [
	super initialize.
	self
		name: 'Ouvrir…';
		description: 'Ouvrir un dossier enregistré (valeurs et modifications Ψ).'
]
