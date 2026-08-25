Extension { #name : 'SRNumberDescription' }

{ #category : '*AXPL-Descriptions' }
SRNumberDescription >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitNumberDescription: self
]
