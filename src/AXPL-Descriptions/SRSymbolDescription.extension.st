Extension { #name : 'SRSymbolDescription' }

{ #category : '*AXPL-Descriptions' }
SRSymbolDescription >> acceptAXPLVisitor: aVisitor [
	"Hériterait sinon du dispatch de SRStringDescription : un champ texte
	dont la saisie (une String) serait toujours refusée par la validation
	de type (Symbol) — donc jamais enregistrée, sans erreur visible. On
	préfère un refus explicite à un champ qui ne marche pas."
	^ aVisitor visitDescription: self
]
