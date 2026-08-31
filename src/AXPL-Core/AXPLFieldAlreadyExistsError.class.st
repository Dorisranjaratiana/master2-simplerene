Class {
	#name : 'AXPLFieldAlreadyExistsError',
	#superclass : 'AXPLApiError',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLFieldAlreadyExistsError class >> code [
	^ #FIELD_ALREADY_EXISTS
]
