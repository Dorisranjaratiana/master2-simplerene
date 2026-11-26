"
Tests d'AXPLSpecVisitor (⑦ desktop) sans ouvrir de fenêtre : les widgets
Spec2 sont construits par un SpPresenter quelconque, puis inspectés.
Vérifie ce que l'utilisateur voit (label, étoile des champs requis, aide
② selon le niveau, masquage des mots de passe) et surtout que la saisie
arrive bien dans l'objet métier — une liaison jusqu'ici jamais testée.
"
Class {
	#name : 'AXPLSpecVisitorTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container',
		'presenter'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLSpecVisitorTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
    presenter := SpPresenter new.
]

{ #category : 'private' }
AXPLSpecVisitorTest >> descriptionLabelled: aLabel [
    ^ container children detect: [ :d | d label = aLabel ]
]

{ #category : 'private' }
AXPLSpecVisitorTest >> visitorAt: aLevel [
    ^ (AXPLSpecVisitor on: client level: aLevel)
        presenter: presenter;
        yourself
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testSaisieTexteEcriteDansLObjetMetier [
    | row input |
    row := (self visitorAt: #simple) visitStringDescription: (self descriptionLabelled: 'Nom').
    input := row presenters last.
    input text: 'Ranjaratiana'.
    self assert: client nom equals: 'Ranjaratiana'.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testCaseACocherEcriteDansLObjetMetier [
    | checkbox |
    checkbox := (self visitorAt: #simple) visitBooleanDescription: (self descriptionLabelled: 'Urgent').
    checkbox state: true.
    self assert: client isUrgent.
    checkbox state: false.
    self deny: client isUrgent.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testChampRequisMarqueParUneEtoile [
    | row |
    row := (self visitorAt: #simple) visitStringDescription: (self descriptionLabelled: 'Nom').
    self assert: row presenters first label equals: 'Nom *'.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testAideSuitLeNiveauDuVisiteur [
    "② L'aide affichée est celle du niveau donné au visiteur — pas celle
    d'une liste déroulante quelconque."
    | desc helpSimple helpExpert |
    desc := self descriptionLabelled: 'Nom'.
    helpSimple := ((self visitorAt: #simple) visitStringDescription: desc) presenters first help.
    helpExpert := ((self visitorAt: #expert) visitStringDescription: desc) presenters first help.
    self assert: helpSimple equals: (desc commentFor: #simple).
    self assert: helpExpert equals: (desc commentFor: #expert).
    self deny: helpSimple equals: helpExpert.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testMotDePasseMasque [
    | desc row |
    desc := SRPasswordDescription new label: 'Mot de passe'; accessor: #nom; yourself.
    row := (self visitorAt: #simple) visitPasswordDescription: desc.
    self assert: row presenters last isPassword.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testUnElementParChampVisible [
    | visible layout |
    visible := (AXPLFramework for: client) visibleFieldsAt: #base.
    layout := (self visitorAt: #base) visit: visible.
    self assert: layout presenters size equals: visible size.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testSaisieRefuseeSignaleeSurLeChamp [
    "-5 dans l'Âge : refusé, signalé par l'infobulle du champ, l'objet
    garde sa valeur ; une saisie corrigée rétablit l'explication."
    | desc row label input |
    desc := self descriptionLabelled: 'Âge'.
    client age: 30.
    row := (self visitorAt: #simple) visitNumberDescription: desc.
    label := row presenters first.
    input := row presenters last.
    input number: -5.
    self assert: client age equals: 30.
    self assert: label help equals: '⚠ ' , (desc validationMessageFor: -5) asString.
    input number: 33.
    self assert: client age equals: 33.
    self assert: label help equals: (desc commentFor: #simple).
    "Régression : le texte du label changeait, et Morphic lui faisait
    alors perdre sa largeur fixe — le champ se décalait."
    self assert: label label equals: 'Âge *'.
]

{ #category : 'tests' }
AXPLSpecVisitorTest >> testChampCreeParPsiAfficheSonExplication [
    "② Le champ créé par Ψ montre son aide au survol, comme les autres,
    et sa saisie va dans l'objet (dictionnaire #properties)."
    | engine desc row |
    engine := AXPLReflexivityEngine new metaContainer: container; yourself.
    desc := engine
        createField: 'Note interne'
        type: SRStringDescription
        level: #simple
        explanation: 'Remarque libre du soignant.'.
    row := (self visitorAt: #simple) visitStringDescription: desc.
    self assert: row presenters first help equals: 'Remarque libre du soignant.'.
    row presenters last text: 'RAS'.
    self assert: (desc read: client) equals: 'RAS'.
]
