"
Ψ : historique horodaté des intercessions.
"
Class {
	#name : 'AXPLTraceCommand',
	#superclass : 'AXPLCommand',
	#category : 'AXPL-UI-Commands',
	#package : 'AXPL-UI',
	#tag : 'Commands'
}

{ #category : 'testing' }
AXPLTraceCommand >> canBeExecuted [
	^ self isPsiAvailable
]

{ #category : 'executing' }
AXPLTraceCommand >> execute [
	self app showTrace
]

{ #category : 'initialization' }
AXPLTraceCommand >> initialize [
	super initialize.
	self
		name: 'Trace Ψ';
		description: 'Ψ : historique horodaté des intercessions.'
]
