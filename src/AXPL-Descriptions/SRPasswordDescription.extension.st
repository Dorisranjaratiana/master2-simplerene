Extension { #name : 'SRPasswordDescription' }

{ #category : '*AXPL-Descriptions' }
SRPasswordDescription >> acceptAXPLVisitor: aVisitor [
	"Sans cette méthode, SRPasswordDescription hériterait du dispatch de
	SRStringDescription : mot de passe affiché en clair sur le desktop et
	renvoyé en clair dans le JSON du web."
	^ aVisitor visitPasswordDescription: self
]
