Extension { #name : 'SRPriorityContainer' }

{ #category : '*AXPL-Descriptions' }
SRPriorityContainer >> acceptAXPLVisitor: aVisitor [
	^ aVisitor visitPriorityContainer: self
]
