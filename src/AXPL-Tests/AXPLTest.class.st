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
        yourself.
    builder := AXPLFormBuilder new
        targetObject: client;
        metaContainer: container;
        yourself.
]

{ #category : 'tests' }
AXPLTest >> testCreationChampSelectionPsi [
    "⑥ — Ψ peut créer un champ à choix (SRSingleOptionDescription)"
    | desc |
    desc := engine createSelectionField: 'Groupe sanguin' options: #('A' 'B' 'AB' 'O') level: #base.
    self assert: desc options equals: #('A' 'B' 'AB' 'O').
    self assert: (container children includes: desc).
]

{ #category : 'tests' }
AXPLTest >> testCreationEtSuppressionChampPsi [
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
AXPLTest >> testAcceptAXPLVisitorDispatch [
    "⑦ — chaque type de description doit dispatcher vers la bonne méthode
    du visiteur ET renvoyer sa valeur de retour. Régression : le
    acceptSimpleReneVisitor: natif de SimpleRene n'a pas de ^ et ne
    renvoie donc pas le widget construit par le visiteur (bug corrigé)."
    | probe |
    probe := AXPLVisitorProbe new.
    self
        assert: ((SRStringDescription new accessor: #nom; yourself) acceptAXPLVisitor: probe)
        equals: #stringVisited.
    self
        assert: ((SRNumberDescription new accessor: #age; yourself) acceptAXPLVisitor: probe)
        equals: #numberVisited.
    self
        assert: ((SRBooleanDescription new accessor: #isUrgent; yourself) acceptAXPLVisitor: probe)
        equals: #booleanVisited.
    self
        assert: ((SRDateDescription new accessor: #dateAdmission; yourself) acceptAXPLVisitor: probe)
        equals: #dateVisited.
    self
        assert: ((SRSingleOptionDescription new accessor: #sexe; options: #('a' 'b'); yourself) acceptAXPLVisitor: probe)
        equals: #singleOptionVisited.
    self
        assert: (container acceptAXPLVisitor: probe)
        equals: #priorityContainerVisited.
]

{ #category : 'tests' }
AXPLTest >> testAXPLSpecVisitorEstUnAXPLVisitor [
    "Prépare le portage vers d'autres cibles (web, JSON...) : AXPLSpecVisitor
    n'est qu'une implémentation concrète du contrat abstrait AXPLVisitor,
    qui lui ne dépend d'aucun toolkit UI."
    self assert: (AXPLSpecVisitor inheritsFrom: AXPLVisitor).
    self
        should: [ AXPLVisitor new visitStringDescription: SRStringDescription new ]
        raise: Error.
]

{ #category : 'tests' }
AXPLTest >> testJsonVisitorAssembleContainer [
    "Le visiteur JSON produit une structure pure (Dictionary/Array), pas
    de widget Spec — la preuve que le portage n'a pas besoin de Spec2."
    | visitor result |
    visitor := AXPLJsonVisitor on: client level: #simple.
    result := visitor visit: (container children select: [ :d | d level = #simple ]).
    self assert: (result at: #type) equals: 'group'.
    self assert: (result at: #fields) notEmpty.
    self assert: ((result at: #fields) allSatisfy: [ :f | f isKindOf: Dictionary ]).
]

{ #category : 'tests' }
AXPLTest >> testJsonVisitorStringDescription [
    | visitor desc json |
    desc := container children detect: [ :d | d label = 'Nom' ].
    client nom: 'Ranjaratiana'.
    visitor := AXPLJsonVisitor on: client level: #expert.
    json := desc acceptAXPLVisitor: visitor.
    self assert: (json at: #label) equals: 'Nom'.
    self assert: (json at: #type) equals: 'string'.
    self assert: (json at: #value) equals: 'Ranjaratiana'.
]

{ #category : 'tests' }
AXPLTest >> testGenericite [
    "Le framework fonctionne avec tout objet qui implémente descriptionForAXPL"
    self assert: (client class respondsTo: #descriptionForAXPL).
    self assert: container children notEmpty.
    self assert: (builder build isKindOf: Collection).
]

{ #category : 'tests' }
AXPLTest >> testGenericiteEtudiant [
    "Le framework fonctionne aussi avec Etudiant, pas seulement ClientHopital"
    | etudiant etudiantContainer etudiantBuilder |
    etudiant := Etudiant new.
    etudiantContainer := etudiant class descriptionForAXPL.
    etudiantBuilder := AXPLFormBuilder new
        targetObject: etudiant;
        metaContainer: etudiantContainer;
        userLevel: #simple;
        yourself.
    self assert: etudiantContainer children notEmpty.
    self assert: (etudiantBuilder build allSatisfy: [ :d | d level = #simple ]).
    self assert: etudiantContainer children first label equals: 'Nom'.
]

{ #category : 'tests' }
AXPLTest >> testOrdreChampsParPriorite [
    "Le vrai SRPriorityContainer trie ses enfants par priority: — vérifie
    que l'ordre déclaré (Nom en premier) est préservé après la migration
    vers le vrai container de SimpleRene."
    self assert: container children first label equals: 'Nom'.
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
AXPLTest >> testTracabilite [
	 "[t] — Chaque intercession est horodatée dans le traceLog"

	 engine relabelDescription: 'Nom' to: 'Identifiant'.
	 engine relabelDescription: 'Prénom' to: 'Alias'.
	 self assert: engine traceLog size equals: 2.
	 self assert: (engine traceLog first key isKindOf: DateAndTime).
	 self assert: (engine traceLog first value includesSubstring: 'Nom')
]

{ #category : 'tests' }
AXPLTest >> testValidationAgePositif [
    "beRequired + bePositive sur 'Âge' (ClientHopital)"
    | desc |
    desc := container children detect: [ :d | d label = 'Âge' ].
    self deny: (desc isSatisfiedBy: -5).
    self assert: (desc isSatisfiedBy: 42).
]

{ #category : 'tests' }
AXPLTest >> testValidationChampRequis [
    "beRequired sur 'Nom' (ClientHopital) : refuse nil, accepte une String"
    | desc |
    desc := container children detect: [ :d | d label = 'Nom' ].
    self deny: (desc isSatisfiedBy: nil).
    self assert: (desc isSatisfiedBy: 'Doris').
]

{ #category : 'tests' }
AXPLTest >> testValidationMoyenneEtudiant [
    "Condition personnalisée sur 'Moyenne' (Etudiant) : bornée entre 0 et 20"
    | etudiant etudiantContainer desc |
    etudiant := Etudiant new.
    etudiantContainer := etudiant class descriptionForAXPL.
    desc := etudiantContainer children detect: [ :d | d label = 'Moyenne' ].
    self deny: (desc isSatisfiedBy: 25).
    self assert: (desc isSatisfiedBy: 15).
]
