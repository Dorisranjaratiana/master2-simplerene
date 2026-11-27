"
Contexte qui enlève les descriptions optionnelles — l'exemple donné par
S. Ducasse pour l'objectif 2 : seuls les champs obligatoires (beRequired)
sont montrés. Combiné à un niveau, il donne un formulaire minimal, par
exemple pour une admission en urgence :

	(AXPLContext level: #simple) & AXPLContext requiredOnly.
"
Class {
	#name : 'AXPLRequiredOnlyContext',
	#superclass : 'AXPLContext',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'testing' }
AXPLRequiredOnlyContext >> accepts: aDescription [
	^ aDescription isRequired
]

{ #category : 'accessing' }
AXPLRequiredOnlyContext >> label [
	^ 'Champs obligatoires seulement'
]

{ #category : 'explaining' }
AXPLRequiredOnlyContext >> reasonForHiding: aDescription [
	^ 'champ facultatif, masqué par le contexte « Champs obligatoires seulement »'
]
