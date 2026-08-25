Extension { #name : 'SRDateDescription' }

{ #category : '*AXPL-Descriptions' }
SRDateDescription >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitDateDescription: self
]
