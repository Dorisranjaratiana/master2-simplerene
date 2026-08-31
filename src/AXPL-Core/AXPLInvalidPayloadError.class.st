Class {
	#name : 'AXPLInvalidPayloadError',
	#superclass : 'AXPLApiError',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLInvalidPayloadError class >> code [
	^ #INVALID_PAYLOAD
]
