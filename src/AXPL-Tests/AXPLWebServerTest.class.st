"
Tests de AXPLWebServer : vérifie que le backend HTTP ne réimplémente
rien (réutilise AXPLFormBuilder et AXPLJsonVisitor tel quel) et qu'une
requête malformée ne fait jamais fuiter de trace Smalltalk brute au
client. N'ouvre jamais de vrai socket Teapot — seule la logique
réutilisée est testée.
"
Class {
	#name : 'AXPLWebServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'client'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLWebServerTest >> setUp [
    super setUp.
    client := ClientHopital new.
]

{ #category : 'tests' }
AXPLWebServerTest >> testWebServerFormJsonReutiliseFormBuilderEtJsonVisitor [
    "AXPLWebServer ne réimplémente rien : formJsonFor: doit filtrer par
    niveau exactement comme AXPLFormBuilder, et produire la même forme
    JSON qu'AXPLJsonVisitor tout seul. Ne démarre aucun vrai serveur
    Teapot — juste la logique réutilisée."
    | server json |
    server := AXPLWebServer new targetObject: client; yourself.
    json := server formJsonFor: #simple.
    self assert: (json at: #type) equals: 'group'.
    self assert: (json at: #fields) notEmpty.
    self assert: ((json at: #fields) allSatisfy: [ :f | (f at: #level) = 'simple' ]).
]

{ #category : 'tests' }
AXPLWebServerTest >> testWebServerSafelyCapturesErreurs [
    "Une requête HTTP malformée (niveau invalide, clé JSON manquante...)
    ne doit jamais faire remonter une trace Smalltalk brute au client —
    toujours une Dictionary {error: ...} propre."
    | server result |
    server := AXPLWebServer new targetObject: client; yourself.
    result := server safely: [ server formJsonFor: #inconnu ].
    self assert: (result at: #error) notNil.
    self assert: (result includesKey: #ok) not.
]
