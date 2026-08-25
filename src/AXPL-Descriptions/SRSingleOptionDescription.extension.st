Extension { #name : 'SRSingleOptionDescription' }

{ #category : '*AXPL-Descriptions' }
SRSingleOptionDescription >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitSingleOptionDescription: self
]
