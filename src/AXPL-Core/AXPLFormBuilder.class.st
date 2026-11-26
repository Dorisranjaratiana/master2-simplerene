"
""Moteur de filtrage adaptatif. Implémente la relation ① (A → Méta).
Reçoit : targetObject, userLevel (#simple/#base/#expert), metaContainer.
build : retourne uniquement les descriptions visibles selon le niveau.
canUserSee: : logique de filtrage — simple voit simple, base voit simple+base, expert voit tout.
Ne recrée jamais le container — travaille toujours sur le metaContainer partagé.""
"
Class {
	#name : 'AXPLFormBuilder',
	#superclass : 'Object',
	#instVars : [
		'userLevel',
		'targetObject',
		'metaContainer'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLFormBuilder class >> levels [
    "Source unique des niveaux reconnus par le framework, du moins au plus
    privilégié — le moteur Ψ s'en sert aussi pour valider un niveau."
    ^ #( #simple #base #expert )
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
    "L'Expert voit absolument tout"
    userLevel = #expert ifTrue: [ ^ true ].
    
    "Le niveau Base voit Simple et Base"
    userLevel = #base ifTrue: [ ^ aDescription level = #base 
        or: [ aDescription level = #simple ] ].
    
    "Le niveau Simple voit uniquement Simple"
    ^ aDescription level = #simple
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
	"Définit le rôle : #simple, #base ou #expert. Un niveau invalide était
	auparavant traité silencieusement comme #simple (aucun des = ne
	matchait) — dangereux maintenant qu'AXPLWebServer accepte ce niveau
	depuis une requête HTTP externe non fiable."
	(self class levels includes: aSymbol) ifFalse: [
		Error signal: 'Niveau invalide : ' , aSymbol printString ,
			' (attendu l''un de ' , self class levels printString , ')' ].
	userLevel := aSymbol
]
