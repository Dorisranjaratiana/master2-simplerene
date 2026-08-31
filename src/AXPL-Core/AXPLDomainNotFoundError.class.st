Class {
	#name : 'AXPLDomainNotFoundError',
	#superclass : 'AXPLApiError',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLDomainNotFoundError class >> code [
	^ #DOMAIN_NOT_FOUND
]
