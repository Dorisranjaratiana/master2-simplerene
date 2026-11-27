"
Tests de l'objectif 3 (S. Ducasse) : des commandes Commander2 générées
depuis les descriptions, et la barre de menus que Spec construit avec
elles dans la fenêtre AXPLFormApp. Aucun dialogue n'est ouvert : on
vérifie quelles commandes existent, quand elles sont exécutables, et ce
qu'elles produisent.
"
Class {
	#name : 'AXPLCommandsTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'app'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLCommandsTest >> setUp [
	super setUp.
	client := ClientHopital new.
	app := AXPLFormApp new.
	app targetObject: client
]

{ #category : 'private' }
AXPLCommandsTest >> menu [
	^ app rootCommandsGroup / 'Menu'
]

{ #category : 'private' }
AXPLCommandsTest >> namesIn: aCommandGroup [
	^ (aCommandGroup entries collect: [ :each | each name ]) asArray
]

{ #category : 'tests' }
AXPLCommandsTest >> testDesCommandesGenereesPourChaqueDescription [
	"« créer des commandes avec les descriptions »"
	| nom commands |
	nom := app psiEngine readDescription: 'Nom'.
	commands := AXPLFieldCommand commandsFor: nom.
	self
		assert: (commands collect: [ :each | each class ]) asArray
		equals: { AXPLExplainFieldCommand. AXPLRelabelFieldCommand. AXPLChangeLevelFieldCommand.
			AXPLEditExplanationFieldCommand. AXPLRemoveFieldCommand }.
	self assert: (commands allSatisfy: [ :each | each field == nom ]).
	self assert: (commands allSatisfy: [ :each | each isKindOf: CmCommand ]).
]

{ #category : 'tests' }
AXPLCommandsTest >> testLaBarreDeMenusEstConstruiteParSpecDepuisLesCommandes [
	"« et créer des menus avec les commandes (Spec fait déjà cela) »"
	app levelDropList selectItem: #expert.
	self assert: (self namesIn: self menu) equals: #( 'Dossier' 'Champs' 'Ψ' ).
	self assert: (app menuBar isKindOf: SpMenuBarPresenter).
	self
		assert: (app menuBar menuGroups first menuItems collect: [ :each | each name ]) asArray
		equals: #( 'Dossier' 'Champs' 'Ψ' ).
]

{ #category : 'tests' }
AXPLCommandsTest >> testLeMenuChampsSuitLesChampsAffiches [
	"Un sous-menu par champ affiché : il suit le niveau et le contexte."
	#( #simple #expert ) do: [ :lvl |
		app levelDropList selectItem: lvl.
		self
			assert: (self namesIn: self menu / 'Champs')
			equals: (((AXPLFramework for: client) visibleFieldsAt: lvl) collect: [ :d | d label ]) asArray ].
	app requiredOnlyCheckBox state: true.
	self assert: (self namesIn: self menu / 'Champs') equals: #( 'Nom' 'Prénom' 'Âge' ).
	self
		assert: (self namesIn: self menu / 'Champs' / 'Nom')
		equals: #( 'Pourquoi ce champ ?' 'Renommer… (Ψ)' 'Changer le niveau… (Ψ)'
			'Modifier l''explication… (Ψ)' 'Supprimer (Ψ)' ).
]

{ #category : 'tests' }
AXPLCommandsTest >> testLesCommandesPsiSeulementAuNiveauLePlusPrivilegie [
	app levelDropList selectItem: #simple.
	self deny: (self menu / 'Champs' / 'Nom' / 'Supprimer (Ψ)') canBeExecuted.
	self deny: (self menu / 'Ψ' / 'Créer un champ…') canBeExecuted.
	self assert: (self menu / 'Champs' / 'Nom' / 'Pourquoi ce champ ?') canBeExecuted.
	app levelDropList selectItem: #expert.
	self assert: (self menu / 'Champs' / 'Nom' / 'Supprimer (Ψ)') canBeExecuted.
	self assert: (self menu / 'Ψ' / 'Créer un champ…') canBeExecuted.
]

{ #category : 'tests' }
AXPLCommandsTest >> testAnnulerPsiExecutableSeulementSIlYAQuelqueChoseAAnnuler [
	app levelDropList selectItem: #expert.
	self deny: (self menu / 'Ψ' / 'Annuler la dernière modification Ψ') canBeExecuted.
	app psiEngine createField: 'Note interne' type: SRStringDescription level: #simple.
	app updateInterface.
	self assert: (self menu / 'Ψ' / 'Annuler la dernière modification Ψ') canBeExecuted.
	self assert: ((self namesIn: self menu / 'Champs') includes: 'Note interne').
]

{ #category : 'tests' }
AXPLCommandsTest >> testPourquoiCeChamp [
	| command text |
	app levelDropList selectItem: #simple.
	command := self menu / 'Champs' / 'Nom' / 'Pourquoi ce champ ?'.
	text := command innerCommand explanationText.
	self assert: (text includesSubstring: 'champ obligatoire').
	self assert: (text includesSubstring: 'Visible à partir du niveau Simple').
	self assert: (text includesSubstring: 'déclaré').
	self assert: (text includesSubstring: ((app psiEngine readDescription: 'Nom') commentFor: #simple)).
]

{ #category : 'tests' }
AXPLCommandsTest >> testReinitialiserParLaCommande [
	app levelDropList selectItem: #base.
	(self menu / 'Dossier' / 'Réinitialiser') execute.
	self assert: app levelDropList selectedItem isNil.
	self assert: app formPresenter isNil.
]

{ #category : 'tests' }
AXPLCommandsTest >> testLeContexteDesCommandesEstLaFenetre [
	app levelDropList selectItem: #expert.
	self assert: (self menu / 'Dossier' / 'Enregistrer') context identicalTo: app.
	self assert: (self menu / 'Champs' / 'Nom' / 'Supprimer (Ψ)') context identicalTo: app.
]
