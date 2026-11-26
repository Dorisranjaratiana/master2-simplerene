"
""Moteur de filtrage adaptatif. Implémente la relation ① (A → Méta).
Reçoit : targetObject, userLevel, metaContainer.
build : retourne uniquement les descriptions visibles selon le niveau.
canUserSee: : filtrage par rang — un niveau voit les champs de son rang
et de tous les rangs inférieurs ; le niveau le plus privilégié voit tout.
Ne recrée jamais le container — travaille toujours sur le metaContainer partagé.

Les niveaux sont configurables sans modifier le framework :
    AXPLFormBuilder levels: #(#visiteur #simple #base #expert).
    AXPLFormBuilder resetLevels.    ""retour à #(#simple #base #expert)""
""
"
Class {
	#name : 'AXPLFormBuilder',
	#superclass : 'Object',
	#instVars : [
		'userLevel',
		'targetObject',
		'metaContainer'
	],
	#classInstVars : [
		'levels'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLFormBuilder class >> defaultLevels [
	^ #( #simple #base #expert )
]

{ #category : 'accessing' }
AXPLFormBuilder class >> levels [
	"Source unique des niveaux reconnus par tout le framework (filtrage ①,
	validation Ψ, listes de l'UI), du moins au plus privilégié."
	^ levels ifNil: [ self defaultLevels ]
]

{ #category : 'accessing' }
AXPLFormBuilder class >> levels: anArrayOfSymbols [
	anArrayOfSymbols isEmpty ifTrue: [
		Error signal: 'Il faut au moins un niveau.' ].
	anArrayOfSymbols asSet size = anArrayOfSymbols size ifFalse: [
		Error signal: 'Niveaux en double : ' , anArrayOfSymbols printString ].
	levels := anArrayOfSymbols asArray
]

{ #category : 'accessing' }
AXPLFormBuilder class >> mostPrivilegedLevel [
	"Le niveau qui voit tout — c'est aussi celui qui a accès à Ψ dans l'UI."
	^ self levels last
]

{ #category : 'querying' }
AXPLFormBuilder class >> requiredLevelFor: aDescription [
	"② Le niveau minimal qui débloque ce champ — c'est la réponse à
	'pourquoi ce champ est-il masqué ?'. Un niveau non reconnu n'est vu
	que par le niveau le plus privilégié (cf. canUserSee:)."
	^ (self levels includes: aDescription level)
		ifTrue: [ aDescription level ]
		ifFalse: [ self mostPrivilegedLevel ]
]

{ #category : 'accessing' }
AXPLFormBuilder class >> resetLevels [
	levels := nil
]

{ #category : 'building' }
AXPLFormBuilder >> build [
    metaContainer ifNil: [
        Error signal: targetObject class name ,
            ' : metaContainer non initialisé.' ].
    ^ metaContainer children select: [ :d | self canUserSee: d ]
]

{ #category : 'testing' }
AXPLFormBuilder >> canUserSee: aDescription [
    "Visible si le rang du champ est inférieur ou égal à celui de
    l'utilisateur. Un champ dont le niveau n'est pas reconnu (faute de
    frappe dans descriptionForAXPL) n'est vu que par le niveau le plus
    privilégié, comme avant — jamais exposé aux autres par erreur."
    | levels userRank fieldRank |
    levels := self class levels.
    userRank := levels indexOf: userLevel.
    userRank = levels size ifTrue: [ ^ true ].
    fieldRank := levels indexOf: aDescription level.
    ^ fieldRank > 0 and: [ fieldRank <= userRank ]
]

{ #category : 'accessing' }
AXPLFormBuilder >> metaContainer: aContainer [
    metaContainer := aContainer
]

{ #category : 'accessing' }
AXPLFormBuilder >> targetObject: anObject [
	"L'objet métier à décrire (n'importe quelle classe implémentant descriptionForAXPL)"
	targetObject := anObject
]

{ #category : 'accessing' }
AXPLFormBuilder >> userLevel: aSymbol [
	"Un niveau invalide était auparavant traité silencieusement comme le
	plus bas — dangereux maintenant qu'AXPLWebServer accepte ce niveau
	depuis une requête HTTP externe non fiable."
	(self class levels includes: aSymbol) ifFalse: [
		Error signal: 'Niveau invalide : ' , aSymbol printString ,
			' (attendu l''un de ' , self class levels printString , ')' ].
	userLevel := aSymbol
]
