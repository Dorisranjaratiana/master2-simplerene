"
Tests de AXPLWebServer : vérifie que le backend HTTP ne réimplémente
rien (réutilise AXPLFormBuilder et AXPLJsonVisitor tel quel), qu'une
requête malformée ne fait jamais fuiter de trace Smalltalk brute au
client, et — surtout — que chaque route POST sait vraiment lire un
corps JSON réel (AXPLFakeWebRequest simule l'unique enchaînement
`entity contents` utilisé par AXPLWebServer, sans démarrer de vrai
serveur Teapot). Couvre la régression propertyNamesAsSymbols : sans
elle, `body at: #label` échouait sur toute requête HTTP réelle car
NeoJSONReader parse les clés d'objet JSON en String par défaut.
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

{ #category : 'tests' }
AXPLWebServerTest >> testJsonBodyOfParseLesClesEnSymbol [
    "Régression : NeoJSONReader parse les clés d'objet JSON en String par
    défaut (propertyNamesAsSymbols vaut false) — sans le réglage explicite
    dans jsonBodyOf:, `body at: #label` échouait sur CHAQUE route POST
    avec une vraie requête HTTP, masqué en erreur propre par safely: mais
    jamais fonctionnel."
    | server body request |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Nom","value":"Ranjaratiana"}'.
    body := server jsonBodyOf: request.
    self assert: (body at: #label) equals: 'Nom'.
    self assert: (body at: #value) equals: 'Ranjaratiana'.
]

{ #category : 'tests' }
AXPLWebServerTest >> testWriteFieldRouteEcritUneValeur [
    "POST /field : écrit une valeur validée, exactement comme un vrai
    client HTTP le ferait (corps JSON réel, pas un appel direct à writeField:)."
    | server request result |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Nom","value":"Ranjaratiana"}'.
    result := server safely: [ server writeField: request ].
    self assert: (result at: #ok) equals: true.
    self assert: client nom equals: 'Ranjaratiana'.
]

{ #category : 'tests' }
AXPLWebServerTest >> testWriteFieldRouteChampInconnuRenvoieErreur [
    | server request result |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"ChampInexistant","value":"x"}'.
    result := server safely: [ server writeField: request ].
    self assert: (result at: #error) notNil.
]

{ #category : 'tests' }
AXPLWebServerTest >> testWriteFieldRouteCoerceDateDepuisJson [
    "Un champ Date arrive du web en String ISO 8601 — writeField: doit la
    convertir en vraie Date Pharo avant d'écrire, pas la stocker telle
    quelle (ce qui casserait l'affichage desktop)."
    | server request result |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Date d''Admission","value":"2024-03-15"}'.
    result := server safely: [ server writeField: request ].
    self assert: (result at: #ok) equals: true.
    self assert: (client dateAdmission isKindOf: Date).
    self assert: client dateAdmission equals: (Date year: 2024 month: 3 day: 15).
]

{ #category : 'tests' }
AXPLWebServerTest >> testWriteFieldRouteDateInvalideRenvoieErreur [
    | server request result |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Date d''Admission","value":"pas-une-date"}'.
    result := server safely: [ server writeField: request ].
    self assert: (result at: #error) notNil.
]

{ #category : 'tests' }
AXPLWebServerTest >> testPsiRenameRouteRenommeLeChamp [
    "POST /psi/rename — ④ depuis une vraie requête HTTP."
    | server request result json |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"oldLabel":"Allergies","newLabel":"Risques Anaphylactiques"}'.
    result := server safely: [ server psiRename: request ].
    self assert: (result at: #ok) equals: true.
    json := server formJsonFor: #expert.
    self assert: ((json at: #fields) anySatisfy: [ :f | (f at: #label) = 'Risques Anaphylactiques' ]).
    self deny: ((json at: #fields) anySatisfy: [ :f | (f at: #label) = 'Allergies' ]).
]

{ #category : 'tests' }
AXPLWebServerTest >> testPsiSetLevelRouteChangeLeNiveau [
    "POST /psi/set-level — ④⑨ depuis une vraie requête HTTP."
    | server request result json champ |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Allergies","level":"simple"}'.
    result := server safely: [ server psiSetLevel: request ].
    self assert: (result at: #ok) equals: true.
    json := server formJsonFor: #simple.
    champ := (json at: #fields) detect: [ :f | (f at: #label) = 'Allergies' ] ifNone: [ nil ].
    self assert: champ notNil.
]

{ #category : 'tests' }
AXPLWebServerTest >> testPsiCreateFieldRouteChampSimple [
    "POST /psi/create-field — ⑥ pour un type simple (string/number/boolean/date)."
    | server request result json |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson: '{"label":"Note interne","type":"string","level":"expert"}'.
    result := server safely: [ server psiCreateField: request ].
    self assert: (result at: #ok) equals: true.
    json := server formJsonFor: #expert.
    self assert: ((json at: #fields) anySatisfy: [ :f | (f at: #label) = 'Note interne' ]).
]

{ #category : 'tests' }
AXPLWebServerTest >> testPsiCreateFieldRouteChampSelect [
    "POST /psi/create-field avec type: 'select' — passe par
    createSelectionField:options:level: plutôt que createField:type:level:."
    | server request result json champ |
    server := AXPLWebServer new targetObject: client; yourself.
    request := AXPLFakeWebRequest withJson:
        '{"label":"Groupe Sanguin","type":"select","level":"base","options":["A","B","AB","O"]}'.
    result := server safely: [ server psiCreateField: request ].
    self assert: (result at: #ok) equals: true.
    json := server formJsonFor: #base.
    champ := (json at: #fields) detect: [ :f | (f at: #label) = 'Groupe Sanguin' ] ifNone: [ nil ].
    self assert: champ notNil.
    self assert: (champ at: #options) equals: #('A' 'B' 'AB' 'O').
]

{ #category : 'tests' }
AXPLWebServerTest >> testPsiRemoveFieldRouteSupprimeLeChamp [
    "POST /psi/remove-field — ⑥ depuis une vraie requête HTTP."
    | server createRequest removeRequest json |
    server := AXPLWebServer new targetObject: client; yourself.
    createRequest := AXPLFakeWebRequest withJson: '{"label":"Note interne","type":"string","level":"expert"}'.
    server safely: [ server psiCreateField: createRequest ].
    removeRequest := AXPLFakeWebRequest withJson: '{"label":"Note interne"}'.
    server safely: [ server psiRemoveField: removeRequest ].
    json := server formJsonFor: #expert.
    self deny: ((json at: #fields) anySatisfy: [ :f | (f at: #label) = 'Note interne' ]).
]
