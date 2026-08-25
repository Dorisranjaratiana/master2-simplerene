Extension { #name : 'SRStringDescription' }

{ #category : '*AXPL-Descriptions' }
SRStringDescription >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitStringDescription: self
]
