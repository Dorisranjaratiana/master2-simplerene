"
Objectif 3 (S. Ducasse) : les actions de la fenêtre AXΨL sont des
commandes Commander2 (CmCommand), dont Spec construit les menus
(AXPLFormApp class >> buildCommandsGroupWith:forRoot:). Le contexte d'une
commande est la fenêtre AXPLFormApp.

	AXPLCommand                      abstrait
	 ├─ AXPLOpenDossierCommand, AXPLSaveCommand, AXPLResetCommand     (menu Dossier)
	 ├─ AXPLPsiCreateFieldCommand, AXPLPsiUndoCommand, AXPLTraceCommand (menu Ψ)
	 └─ AXPLFieldCommand              abstrait : générées depuis une description
	     ├─ AXPLExplainFieldCommand          Pourquoi ce champ ?
	     ├─ AXPLRelabelFieldCommand          Renommer… (Ψ)
	     ├─ AXPLChangeLevelFieldCommand      Changer le niveau… (Ψ)
	     ├─ AXPLEditExplanationFieldCommand  Modifier l'explication… (Ψ)
	     └─ AXPLRemoveFieldCommand           Supprimer (Ψ)
"
Class {
	#name : 'AXPLCommand',
	#superclass : 'CmCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLCommand class >> isAbstract [
	^ self == AXPLCommand
]

{ #category : 'accessing' }
AXPLCommand >> app [
	"La fenêtre AXPLFormApp sur laquelle agit la commande."
	^ self context
]

{ #category : 'testing' }
AXPLCommand >> isPsiAvailable [
	^ self app notNil and: [ self app isPsiAvailable ]
]
