"
Double de test minimal pour un objet requête Teapot : les routes
AXPLWebServer n'appellent jamais que `aRequest entity contents` pour lire
le corps JSON (voir AXPLWebServer >> jsonBodyOf:). Ce double satisfait
exactement cet enchaînement de deux messages, sans démarrer de vrai
serveur Teapot ni dépendre de l'API interne de Zinc/Teapot au-delà de ce
que AXPLWebServer utilise déjà réellement.
"
Class {
	#name : 'AXPLFakeWebRequest',
	#superclass : 'Object',
	#instVars : [
		'jsonString'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'instance creation' }
AXPLFakeWebRequest class >> withJson: aString [
	^ self new jsonString: aString; yourself
]

{ #category : 'accessing' }
AXPLFakeWebRequest >> contents [
	^ jsonString
]

{ #category : 'accessing' }
AXPLFakeWebRequest >> entity [
	^ self
]

{ #category : 'accessing' }
AXPLFakeWebRequest >> jsonString: aString [
	jsonString := aString
]
