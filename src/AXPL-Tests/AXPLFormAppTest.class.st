"
Tests de la fenêtre AXPLFormApp sans l'ouvrir. Couvre ce qui n'avait
aucun test jusqu'ici et où se cachaient de vrais plantages (parsing des
options d'un champ Choix créé par Ψ) : rendu par niveau, accès Ψ réservé
au niveau le plus privilégié, Annuler, validation à l'enregistrement,
explication des champs masqués. Les dialogues (UIManager) ne sont pas
testés ; la logique qu'ils utilisent en est extraite et testée ici.
"
Class {
	#name : 'AXPLFormAppTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'app'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLFormAppTest >> setUp [
    super setUp.
    client := ClientHopital new.
    app := AXPLFormApp new.
    app targetObject: client.
]

{ #category : 'tests' }
AXPLFormAppTest >> testRenduParNiveau [
    "Un élément par champ visible, plus un bouton groupé s'il reste des
    champs masqués ; Ψ et la trace seulement au niveau le plus privilégié."
    | framework |
    framework := AXPLFramework for: client.
    AXPLFormBuilder levels do: [ :lvl |
        | visible hidden |
        app levelDropList selectItem: lvl.
        app updateInterface.
        visible := framework visibleFieldsAt: lvl.
        hidden := framework hiddenFieldsAt: lvl.
        self
            assert: app formContainer layout presenters size
            equals: visible size + (hidden isEmpty ifTrue: [ 0 ] ifFalse: [ 1 ]).
        self
            assert: app psiButton isEnabled
            equals: lvl = AXPLFormBuilder mostPrivilegedLevel ].
]

{ #category : 'tests' }
AXPLFormAppTest >> testAnnulerRepartDUnObjetEtDUnMoteurNeufs [
    | ancienMeta |
    client nom: 'Ranjaratiana'.
    ancienMeta := app metaContainer.
    app psiEngine createField: 'Note interne' type: SRStringDescription level: #expert.
    app resetInterface.
    self deny: app targetObject == client.
    self assert: app targetObject nom equals: ''.
    self deny: app metaContainer == ancienMeta.
    self assert: (app psiEngine readDescription: 'Note interne') isNil.
]

{ #category : 'tests' }
AXPLFormAppTest >> testChampsInvalidesAvantEnregistrement [
    client age: -5.
    self assert: (app invalidFields anySatisfy: [ :d | d label = 'Âge' ]).
    client age: 30.
    self deny: (app invalidFields anySatisfy: [ :d | d label = 'Âge' ]).
]

{ #category : 'tests' }
AXPLFormAppTest >> testParseOptionsDUnChampChoix [
    "Régression : utilisait tokenize:/trimSeparators, absents de Pharo 13
    — créer un champ Choix depuis le menu Ψ plantait."
    self assert: (app parseOptions: ' A, B ,AB,  O ') equals: #('A' 'B' 'AB' 'O').
    self assert: (app parseOptions: 'A, , B') equals: #('A' 'B').
]

{ #category : 'tests' }
AXPLFormAppTest >> testExplicationDesChampsMasquesDonneLeNiveauRequis [
    "② Dire pourquoi un champ est masqué = dire quel niveau le débloque."
    | hidden text |
    app levelDropList selectItem: #simple.
    hidden := (AXPLFramework for: client) hiddenFieldsAt: #simple.
    text := app hiddenFieldsExplanationText: hidden.
    self assert: (text includesSubstring: 'Allergies — visible à partir du niveau Expert').
    self assert: (text includesSubstring: 'Médecin Référent — visible à partir du niveau Base').
]
