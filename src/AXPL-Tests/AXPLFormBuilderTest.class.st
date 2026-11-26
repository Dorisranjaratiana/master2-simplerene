"
Tests de AXPLFormBuilder (①) : filtrage adaptatif par niveau, et les
deux chemins d'erreur qui doivent échouer clairement plutôt que se
comporter silencieusement (metaContainer absent, niveau invalide).
"
Class {
	#name : 'AXPLFormBuilderTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container',
		'builder'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLFormBuilderTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
    builder := AXPLFormBuilder new
        targetObject: client;
        metaContainer: container;
        yourself.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testErreurMetaContainerNonInitialise [
    "build sans metaContainer signale une erreur explicite plutôt que de
    planter silencieusement plus loin."
    | builderSansContainer |
    builderSansContainer := AXPLFormBuilder new
        targetObject: client;
        userLevel: #simple;
        yourself.
    self should: [ builderSansContainer build ] raise: Error.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testFiltragBase [
    "En mode base, les champs simple ET base sont visibles, jamais expert"
    | result |
    builder userLevel: #base.
    result := builder build.
    self assert: result notEmpty.
    self assert: (result allSatisfy: [ :d | d level = #simple or: [ d level = #base ] ]).
    self deny: (result anySatisfy: [ :d | d level = #expert ]).
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testFiltragExpert [
    "En mode expert, tous les champs sont visibles"
    | resultSimple resultExpert |
    builder userLevel: #simple.
    resultSimple := builder build.
    builder userLevel: #expert.
    resultExpert := builder build.
    self assert: resultExpert size > resultSimple size.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testFiltragSimple [
    "En mode simple, seuls les champs #simple sont visibles"
    | result |
    builder userLevel: #simple.
    result := builder build.
    self assert: result notEmpty.
    self assert: (result allSatisfy: [ :d | d level = #simple ]).
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testNiveauInvalideLeveUneErreur [
    "Un niveau qui n'est ni #simple, ni #base, ni #expert doit échouer
    clairement plutôt que d'être traité silencieusement comme #simple —
    important maintenant qu'AXPLWebServer accepte le niveau depuis une
    requête HTTP externe non fiable."
    self should: [ builder userLevel: #inconnu ] raise: Error.
]

{ #category : 'running' }
AXPLFormBuilderTest >> tearDown [
    AXPLFormBuilder resetLevels.
    super tearDown.
]

{ #category : 'private' }
AXPLFormBuilderTest >> containerAvecNiveaux: aCollectionOfLevels [
    | c |
    c := SRPriorityContainer new.
    aCollectionOfLevels doWithIndex: [ :lvl :i |
        c add: (SRStringDescription new
            label: 'Champ ' , lvl;
            accessor: #nom;
            priority: i * 10;
            level: lvl;
            yourself) ].
    ^ c
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testNiveauxParDefaut [
    self assert: AXPLFormBuilder levels equals: #( #simple #base #expert ).
    self assert: AXPLFormBuilder mostPrivilegedLevel equals: #expert.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testNiveauxConfigurablesSansModifierLeFramework [
    "Un 4e niveau s'ajoute par configuration ; le filtrage suit le rang."
    AXPLFormBuilder levels: #( #visiteur #simple #base #expert ).
    builder metaContainer: (self containerAvecNiveaux: #( #visiteur #simple #expert )).
    builder userLevel: #visiteur.
    self assert: builder build size equals: 1.
    builder userLevel: #simple.
    self assert: builder build size equals: 2.
    builder userLevel: #base.
    self assert: builder build size equals: 2.
    builder userLevel: #expert.
    self assert: builder build size equals: 3.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testChampDeNiveauInconnuVuSeulementParLePlusPrivilegie [
    "Une faute de frappe dans descriptionForAXPL ne doit jamais exposer
    un champ aux niveaux inférieurs."
    builder metaContainer: (self containerAvecNiveaux: #( #simple #exprt )).
    builder userLevel: #base.
    self assert: builder build size equals: 1.
    builder userLevel: #expert.
    self assert: builder build size equals: 2.
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testConfigurationDeNiveauxInvalideRefusee [
    self should: [ AXPLFormBuilder levels: #() ] raise: Error.
    self should: [ AXPLFormBuilder levels: #( #simple #simple ) ] raise: Error.
    self assert: AXPLFormBuilder levels equals: #( #simple #base #expert ).
]

{ #category : 'tests' }
AXPLFormBuilderTest >> testPsiValideContreLesNiveauxConfigures [
    | engine |
    AXPLFormBuilder levels: #( #visiteur #simple #base #expert ).
    engine := AXPLReflexivityEngine new metaContainer: container; yourself.
    engine setLevel: #visiteur ofDescription: 'Nom'.
    self assert: (engine readDescription: 'Nom') level equals: #visiteur.
    self should: [ engine setLevel: #inconnu ofDescription: 'Nom' ] raise: Error.
]
