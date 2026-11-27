"
Vérifie le scénario réflexif AXPLReflexiveScenario étape par étape — ce
que voit l'infirmière, ce que contient le méta-modèle — et l'API
d'introspection d'AXPLReflexivityEngine qu'il utilise.
"
Class {
	#name : 'AXPLReflexiveScenarioTest',
	#superclass : 'TestCase',
	#instVars : [
		'scenario',
		'initialSimple'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLReflexiveScenarioTest >> setUp [
    super setUp.
    scenario := AXPLReflexiveScenario new.
    initialSimple := (scenario framework visibleFieldsAt: #simple) collect: [ :d | d label ].
]

{ #category : 'tests' }
AXPLReflexiveScenarioTest >> testPendantLEpidemieLInfirmiereVoitLeFormulaireModifie [
    | psi simple |
    scenario runEpidemic.
    psi := scenario psi.
    simple := (scenario framework visibleFieldsAt: #simple) collect: [ :d | d label ].
    self assert: simple size equals: initialSimple size + 2.
    self assert: (simple includes: 'Statut infectieux').
    self assert: (simple includes: 'Risques allergiques').
    self assert: (psi readDescription: 'Allergies') isNil.
    self assert: (psi typeOf: 'Statut infectieux') equals: SRSingleOptionDescription.
    self
        assert: (psi explanationOf: 'Statut infectieux' forLevel: #simple)
        equals: 'À renseigner à chaque admission pendant l''épidémie.'.
    self
        assert: ((psi explanationOf: 'Statut infectieux' forLevel: #expert) includesSubstring: 'PCR').
    self assert: psi psiCreatedLabels asArray equals: #( 'Statut infectieux' ).
    self
        assert: ((psi readDescription: 'Statut infectieux') read: scenario framework targetObject)
        equals: 'Positif'.
    self assert: psi traceLog size equals: 5.
]

{ #category : 'tests' }
AXPLReflexiveScenarioTest >> testFinDeLEpidemieToutEstAnnule [
    | psi |
    scenario run.
    psi := scenario psi.
    self
        assert: ((scenario framework visibleFieldsAt: #simple) collect: [ :d | d label ])
        equals: initialSimple.
    self assert: (psi levelOf: 'Allergies') equals: #expert.
    self assert: (psi readDescription: 'Statut infectieux') isNil.
    self assert: psi psiCreatedLabels isEmpty.
    self deny: psi canUndo.
    self assert: psi traceLog size equals: 10.
]

{ #category : 'tests' }
AXPLReflexiveScenarioTest >> testLeRecitRaconteLesHuitEtapes [
    scenario run.
    1 to: 8 do: [ :step |
        self assert: (scenario log anySatisfy: [ :line | line beginsWith: step printString , '. ' ]) ].
]

{ #category : 'tests' }
AXPLReflexiveScenarioTest >> testLaFenetreSOuvreSurLeFormulaireModifie [
    "Ce que montre AXPLReflexiveScenario demo, sans ouvrir de fenêtre."
    | app |
    scenario runEpidemic.
    app := AXPLFormApp new.
    app framework: scenario framework.
    app levelDropList selectItem: #simple.
    self assert: app targetObject identicalTo: scenario framework targetObject.
    self
        assert: app formContainer layout presenters size
        equals: (scenario framework visibleFieldsAt: #simple) size + 1.
]

{ #category : 'tests' }
AXPLReflexiveScenarioTest >> testIntrospectionSurUnChampInconnu [
    | psi |
    psi := scenario psi.
    self assert: (psi levelOf: 'Inconnu') isNil.
    self assert: (psi typeOf: 'Inconnu') isNil.
    self assert: (psi explanationOf: 'Inconnu' forLevel: #simple) isNil.
    self assert: psi labels equals: (psi fields collect: [ :d | d label ]).
    self assert: (psi labels includes: 'Nom').
]
