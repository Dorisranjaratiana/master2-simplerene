Extension { #name : 'SRBooleanDescription' }

{ #category : '*AXPL-Descriptions' }
SRBooleanDescription >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitBooleanDescription: self
]
