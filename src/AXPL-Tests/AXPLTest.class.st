Class {
	#name : 'AXPLTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container',
		'engine',
		'builder'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
    engine := AXPLReflexivityEngine new
        metaContainer: container;
        targetClass: client class;
        yourself.
    builder := AXPLFormBuilder new
        targetObject: client;
        metaContainer: container;
        yourself.
]

{ #category : 'tests' }
AXPLTest >> testExplicationContextuelle [
    "② — Chaque champ porte une explication String selon le niveau"
    | desc |
    desc := container children first.
    self assert: (desc commentFor: #simple) isString.
    self assert: (desc commentFor: #base) isString.
    self assert: (desc commentFor: #expert) isString.
]

{ #category : 'tests' }
AXPLTest >> testFiltragExpert [
    "① — En mode expert, tous les champs sont visibles"
    | resultSimple resultExpert |
    builder userLevel: #simple.
    resultSimple := builder build.
    builder userLevel: #expert.
    resultExpert := builder build.
    self assert: resultExpert size > resultSimple size.
]

{ #category : 'tests' }
AXPLTest >> testFiltragSimple [
    "① — En mode simple, seuls les champs #simple sont visibles"
    | result |
    builder userLevel: #simple.
    result := builder build.
    self assert: result notEmpty.
    self assert: (result allSatisfy: [ :d | d level = #simple ]).
]

{ #category : 'tests' }
AXPLTest >> testGenericite [
    "Le framework fonctionne avec tout objet qui implémente descriptionForAXPL"
    self assert: (client class respondsTo: #descriptionForAXPL).
    self assert: container children notEmpty.
    self assert: (builder build isKindOf: Collection).
]

{ #category : 'tests' }
AXPLTest >> testIntercessionPsi [
    "④ — Ψ renomme un champ à l'exécution"
    engine relabelDescription: 'Allergies' to: 'Risques Anaphylactiques'.
    self assert: (engine readDescription: 'Risques Anaphylactiques') notNil.
    self assert: (engine readDescription: 'Allergies') isNil.
]

{ #category : 'tests' }
AXPLTest >> testLecturePsi [
	 "③ — Ψ peut lire n'importe quelle description par son label"

	 | desc |
	 desc := engine readDescription: 'Nom'.
	 self assert: desc notNil.
	 self assert: desc label equals: 'Nom'
]

{ #category : 'tests' }
AXPLTest >> testSuppressionChampNatif [
	"④ — N'IMPORTE QUEL champ est supprimable, y compris un champ natif déclaré dans
	descriptionForAXPL : il quitte la méta-description et perd ses accesseurs. Sa
	variable d'instance est en revanche conservée tant que du code métier l'utilise
	encore (ici #initialize), pour ne pas corrompre la classe."
	| avant |
	avant := ClientHopital instVarNames size.
	self assert: (engine readDescription: 'Nom') notNil.

	engine removeField: 'Nom'.

	self assert: (engine readDescription: 'Nom') isNil.
	self deny: (ClientHopital includesSelector: #nom).
	self assert: (ClientHopital instVarNames includes: 'nom').
	self assert: ClientHopital instVarNames size equals: avant.

	"Restauration : la variable d'instance ayant été préservée, recompiler les
	accesseurs suffit à rendre la classe à son état initial pour les autres tests."
	ClientHopital compile: 'nom' , String lf , '^ nom'.
	ClientHopital compile: 'nom: aValue' , String lf , 'nom := aValue'.
	self assert: (ClientHopital includesSelector: #nom).
]

{ #category : 'tests' }
AXPLTest >> testSynchronisationExplication [
	 "⑤ — Après intercession, l'explication est mise à jour"

	 | desc |
	 engine relabelDescription: 'Allergies' to: 'Risques Anaphylactiques'.
	 engine
		 updateExplanation: 'Risques Anaphylactiques'
		 forLevel: #expert
		 with: 'Terme clinique normalisé.'.
	 desc := engine readDescription: 'Risques Anaphylactiques'.
	 self
		 assert: (desc commentFor: #expert)
		 equals: 'Terme clinique normalisé.'
]

{ #category : 'tests' }
AXPLTest >> testCycleDeVieChampComplet [
	"④ — Cycle complet sur un champ créé à l'exécution : ajout structurel réel,
	modification de chaque attribut (type, niveau, explication, label), puis
	suppression structurelle réelle qui restitue la classe dans son état initial."
	| avant label |
	avant := ClientHopital instVarNames size.
	label := 'Champ Test AXPL'.

	engine createField: label type: #string level: #simple help: 'aide' options: #().
	self assert: (engine readDescription: label) notNil.
	self assert: ClientHopital instVarNames size equals: avant + 1.
	self assert: (engine isPsiCreated: (engine readDescription: label)).

	engine setType: #number ofDescription: label options: #().
	self assert: ((engine readDescription: label) isKindOf: SRNumberDescription).

	engine setLevel: #expert ofDescription: label.
	self assert: (engine readDescription: label) level equals: #expert.

	engine setHelp: 'aide experte' forLevel: #expert ofDescription: label.
	self assert: ((engine readDescription: label) commentFor: #expert) equals: 'aide experte'.
	self assert: ((engine readDescription: label) commentFor: #simple) equals: 'aide'.

	engine relabelDescription: label to: label , ' 2'.
	self assert: (engine readDescription: label) isNil.

	engine removeField: label , ' 2'.
	self assert: (engine readDescription: label , ' 2') isNil.
	self assert: ClientHopital instVarNames size equals: avant.
]

{ #category : 'tests' }
AXPLTest >> testDomainDiscovery [
	"Recommandation 2 — le registre de domaines découvre par réflexion toute classe
	qui implémente #descriptionForAXPL, sans qu'aucun nom de classe métier soit câblé
	en dur dans le framework."
	| discovered keys |
	discovered := AXPLDomainRegistry discover.
	keys := discovered domains collect: [ :d | d key ].
	self assert: (keys includes: 'ClientHopital').
	self assert: (keys includes: 'Etudiant').
	self assert: (discovered at: 'ClientHopital') label equals: container label.
]

{ #category : 'tests' }
AXPLTest >> testFieldTypeRegistryDefaults [
	"Recommandation 4 — les cinq types de champs de base sont enregistrés et
	résolubles dans les deux sens (symbole → classe, classe → symbole)."
	| registry |
	registry := AXPLFieldTypeRegistry default.
	self assert: (registry descriptionClassFor: #string) equals: SRStringDescription.
	self assert: (registry descriptionClassFor: #number) equals: SRNumberDescription.
	self assert: (registry descriptionClassFor: #boolean) equals: SRBooleanDescription.
	self assert: (registry descriptionClassFor: #date) equals: SRDateDescription.
	self assert: (registry descriptionClassFor: #select) equals: SRSingleOptionDescription.
	self assert: (registry typeNameFor: container children first) equals: 'string'.
	self should: [ registry descriptionClassFor: #inconnu ] raise: AXPLInvalidPayloadError.
]

{ #category : 'tests' }
AXPLTest >> testTracabilite [
	 "[t] — Chaque intercession est horodatée dans le traceLog"

	 engine relabelDescription: 'Nom' to: 'Identifiant'.
	 engine relabelDescription: 'Prénom' to: 'Alias'.
	 self assert: engine traceLog size equals: 2.
	 self assert: (engine traceLog first key isKindOf: DateAndTime).
	 self assert: (engine traceLog first value includesSubstring: 'Nom')
]
