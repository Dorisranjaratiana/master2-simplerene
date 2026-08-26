"
Tests du moteur de réflexivité Ψ (AXPLReflexivityEngine) : lecture ③,
intercession ④⑥⑨, synchronisation de l'explication ⑤ et traçabilité [t].
"
Class {
	#name : 'AXPLReflexivityEngineTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container',
		'engine'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLReflexivityEngineTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
    engine := AXPLReflexivityEngine new
        metaContainer: container;
        yourself.
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testCreationChampSelectionPsi [
    "⑥ — Ψ peut créer un champ à choix (SRSingleOptionDescription)"
    | desc |
    desc := engine createSelectionField: 'Groupe sanguin' options: #('A' 'B' 'AB' 'O') level: #base.
    self assert: desc options equals: #('A' 'B' 'AB' 'O').
    self assert: (container children includes: desc).
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testCreationEtSuppressionChampPsi [
    "⑥ — Ψ peut créer un champ entièrement nouveau, l'utiliser, puis le retirer"
    | desc |
    desc := engine createField: 'Note interne' type: SRStringDescription level: #expert.
    self assert: (engine readDescription: 'Note interne') notNil.
    self assert: desc level equals: #expert.

    "Le champ créé n'a pas de variable d'instance dédiée : sa valeur vit
    dans #properties, accessible via l'accessor de la description."
    desc write: 'Suivi attentif' to: client.
    self assert: (desc read: client) equals: 'Suivi attentif'.

    engine removeField: 'Note interne'.
    self assert: (engine readDescription: 'Note interne') isNil.
    self deny: (container children includes: desc).
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testCreationChampDoublonRefusee [
    "⑥ — readDescription: ne renvoie que le premier champ trouvé par
    label ; un doublon rendrait le second inaccessible à Ψ. Créer un
    champ avec un label déjà pris doit être refusé, pas silencieux."
    engine createField: 'Note interne' type: SRStringDescription level: #expert.
    self
        should: [ engine createField: 'Note interne' type: SRStringDescription level: #base ]
        raise: Error.
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testRelabelChampInexistantNeFaitRien [
    "Ψ ne doit rien casser silencieusement quand on lui donne un label
    qui n'existe pas — ni modification, ni entrée fantôme dans la trace."
    engine relabelDescription: 'ChampInexistant' to: 'Nouveau'.
    self assert: engine traceLog isEmpty.
    self assert: (engine readDescription: 'Nouveau') isNil.
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testSupprimerChampInexistantNeFaitRien [
    | tailleAvant |
    tailleAvant := container children size.
    engine removeField: 'ChampInexistant'.
    self assert: container children size equals: tailleAvant.
    self assert: engine traceLog isEmpty.
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testChangementNiveauPsi [
    "④⑨ — Ψ change le niveau d'un champ existant à l'exécution"
    | desc |
    desc := engine readDescription: 'Allergies'.
    self assert: desc level equals: #expert.

    engine setLevel: #simple ofDescription: 'Allergies'.
    self assert: desc level equals: #simple.
    self assert: (engine traceLog last value includesSubstring: 'Allergies').
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testIntercessionPsi [
    "④ — Ψ renomme un champ à l'exécution"
    engine relabelDescription: 'Allergies' to: 'Risques Anaphylactiques'.
    self assert: (engine readDescription: 'Risques Anaphylactiques') notNil.
    self assert: (engine readDescription: 'Allergies') isNil.
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testLecturePsi [
	 "③ — Ψ peut lire n'importe quelle description par son label"

	 | desc |
	 desc := engine readDescription: 'Nom'.
	 self assert: desc notNil.
	 self assert: desc label equals: 'Nom'
]

{ #category : 'tests' }
AXPLReflexivityEngineTest >> testSynchronisationExplication [
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
AXPLReflexivityEngineTest >> testTracabilite [
	 "[t] — Chaque intercession est horodatée dans le traceLog"

	 engine relabelDescription: 'Nom' to: 'Identifiant'.
	 engine relabelDescription: 'Prénom' to: 'Alias'.
	 self assert: engine traceLog size equals: 2.
	 self assert: (engine traceLog first key isKindOf: DateAndTime).
	 self assert: (engine traceLog first value includesSubstring: 'Nom')
]
