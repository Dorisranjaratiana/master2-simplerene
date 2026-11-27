"
Contexte du niveau de l'utilisateur (①) : un champ est montré si son
niveau est inférieur ou égal à celui de l'utilisateur, selon les niveaux
configurés (AXPLFormBuilder levels). C'est le filtrage historique
d'AXΨL, rangé dans la hiérarchie des contextes.
"
Class {
	#name : 'AXPLLevelContext',
	#superclass : 'AXPLContext',
	#instVars : [
		'builder'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'instance creation' }
AXPLLevelContext class >> level: aLevel [
	"Un niveau inconnu est refusé (AXPLFormBuilder >> userLevel:)."
	^ self new setLevel: aLevel
]

{ #category : 'testing' }
AXPLLevelContext >> accepts: aDescription [
	^ builder canUserSee: aDescription
]

{ #category : 'accessing' }
AXPLLevelContext >> explanationLevel [
	^ self level
]

{ #category : 'accessing' }
AXPLLevelContext >> label [
	^ 'Niveau ' , self level asString capitalized
]

{ #category : 'accessing' }
AXPLLevelContext >> level [
	^ builder userLevel
]

{ #category : 'explaining' }
AXPLLevelContext >> reasonForHiding: aDescription [
	^ 'visible à partir du niveau '
		, (AXPLFormBuilder requiredLevelFor: aDescription) asString capitalized
]

{ #category : 'initialization' }
AXPLLevelContext >> setLevel: aLevel [
	builder := AXPLFormBuilder new userLevel: aLevel; yourself
]
