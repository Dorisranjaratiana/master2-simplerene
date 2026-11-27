"
Contexte d'exemple pour AXPLContextTest : prouve qu'on ajoute un contexte
par une simple sous-classe d'AXPLContext, sans toucher au framework.
"
Class {
	#name : 'AXPLContextDatesOnly',
	#superclass : 'AXPLContext',
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'testing' }
AXPLContextDatesOnly >> accepts: aDescription [
	^ aDescription isKindOf: SRDateDescription
]

{ #category : 'accessing' }
AXPLContextDatesOnly >> label [
	^ 'Dates seulement'
]

{ #category : 'explaining' }
AXPLContextDatesOnly >> reasonForHiding: aDescription [
	^ 'ce n''est pas une date'
]
