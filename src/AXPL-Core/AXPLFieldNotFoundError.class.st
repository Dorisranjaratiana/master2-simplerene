Class {
	#name : 'AXPLFieldNotFoundError',
	#superclass : 'AXPLApiError',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLFieldNotFoundError class >> code [
	^ #FIELD_NOT_FOUND
]
