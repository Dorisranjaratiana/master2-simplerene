"
Objectif 2 (S. Ducasse, 16 février) : « créer une petite hiérarchie de
contextes ; par exemple un contexte peut enlever les descriptions qui
sont optionnelles ».

Un contexte décide quelles descriptions du formulaire montrer (accepts:)
et sait dire pourquoi il en masque une (reasonForHiding: — l'explicabilité
② appliquée au masquage). Hiérarchie :

	AXPLContext                    abstrait
	 ├─ AXPLLevelContext           le niveau de l'utilisateur (Simple / Base / Expert)
	 ├─ AXPLRequiredOnlyContext    seulement les champs obligatoires
	 └─ AXPLCompositeContext       plusieurs contextes à la fois (&)

	(AXPLContext level: #simple) & AXPLContext requiredOnly.
	(AXPLFramework for: ClientHopital new) visibleFieldsIn: (AXPLContext level: #base).

Un nouveau contexte = une sous-classe qui définit accepts:, reasonForHiding:
et label ; le framework n'a pas à changer.
"
Class {
	#name : 'AXPLContext',
	#superclass : 'Object',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'testing' }
AXPLContext class >> isAbstract [
	^ self == AXPLContext
]

{ #category : 'instance creation' }
AXPLContext class >> level: aLevel [
	^ AXPLLevelContext level: aLevel
]

{ #category : 'instance creation' }
AXPLContext class >> requiredOnly [
	^ AXPLRequiredOnlyContext new
]

{ #category : 'combining' }
AXPLContext >> & aContext [
	"Les deux contextes à la fois : un champ n'est montré que si tous l'acceptent."
	^ AXPLCompositeContext with: self contexts , aContext contexts
]

{ #category : 'testing' }
AXPLContext >> accepts: aDescription [
	"Ce champ est-il montré dans ce contexte ?"
	^ self subclassResponsibility
]

{ #category : 'accessing' }
AXPLContext >> contexts [
	"Les contextes élémentaires qui composent celui-ci."
	^ { self }
]

{ #category : 'accessing' }
AXPLContext >> explanationLevel [
	"Le niveau dont on montre les explications ② (nil si ce contexte n'en impose pas)."
	^ nil
]

{ #category : 'filtering' }
AXPLContext >> filter: aCollectionOfDescriptions [
	^ aCollectionOfDescriptions select: [ :each | self accepts: each ]
]

{ #category : 'filtering' }
AXPLContext >> hidden: aCollectionOfDescriptions [
	^ aCollectionOfDescriptions reject: [ :each | self accepts: each ]
]

{ #category : 'accessing' }
AXPLContext >> label [
	"Nom du contexte, montré à l'utilisateur."
	^ self subclassResponsibility
]

{ #category : 'printing' }
AXPLContext >> printOn: aStream [
	aStream nextPutAll: self label
]

{ #category : 'explaining' }
AXPLContext >> reasonForHiding: aDescription [
	"② Pourquoi ce champ est masqué dans ce contexte (phrase pour l'utilisateur)."
	^ self subclassResponsibility
]
