"
Tests de la façade AXPLFramework : dérivation du metaContainer, filtrage
① par niveau, et unicité de l'instance Ψ sur la durée de vie de la façade
(jamais recréée entre deux appels à visibleFieldsAt:, contrairement à
l'ancien code qui recréait un AXPLReflexivityEngine à chaque appelant).
"
Class {
	#name : 'AXPLFrameworkTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'framework'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLFrameworkTest >> setUp [
    super setUp.
    client := ClientHopital new.
    framework := AXPLFramework for: client.
]

{ #category : 'tests' }
AXPLFrameworkTest >> testForDeriveLeMetaContainerDepuisTargetObject [
    self assert: framework targetObject equals: client.
    self assert: framework metaContainer equals: client class descriptionForAXPL.
]

{ #category : 'tests' }
AXPLFrameworkTest >> testVisibleFieldsAtFiltreParNiveau [
    | resultSimple resultExpert |
    resultSimple := framework visibleFieldsAt: #simple.
    resultExpert := framework visibleFieldsAt: #expert.
    self assert: (resultSimple allSatisfy: [ :d | d level = #simple ]).
    self assert: resultExpert size > resultSimple size.
]

{ #category : 'tests' }
AXPLFrameworkTest >> testPsiEngineEstUneInstanceUniqueReutilisee [
    "Contrairement à l'ancien code (chaque appelant créait son propre
    AXPLReflexivityEngine), la façade garde LA MÊME instance entre deux
    appels — condition nécessaire pour que le traceLog Ψ accumule
    l'historique complet plutôt que d'en perdre une partie."
    | engineFirstCall engineSecondCall |
    engineFirstCall := framework psiEngine.
    framework visibleFieldsAt: #simple.
    engineSecondCall := framework psiEngine.
    self assert: engineFirstCall == engineSecondCall.
]

{ #category : 'tests' }
AXPLFrameworkTest >> testPsiEngineOpereSurLeMemeMetaContainer [
    | desc |
    framework psiEngine createField: 'Note interne' type: SRStringDescription level: #expert.
    desc := framework metaContainer children detect: [ :d | d label = 'Note interne' ] ifNone: [ nil ].
    self assert: desc notNil.
]
