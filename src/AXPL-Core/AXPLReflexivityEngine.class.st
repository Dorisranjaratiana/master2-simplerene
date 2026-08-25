"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: — modifie un label à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: — synchronise l'explication après intercession.
[t] traceLog — historique horodaté de toutes les intercessions (DateAndTime).
Instance unique créée dans targetObject: — jamais recréée entre les re-rendus.""
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
    super initialize.
    traceLog := OrderedCollection new.
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> metaContainer: aContainer [
    metaContainer := aContainer
]

{ #category : 'querying' }
AXPLReflexivityEngine >> readDescription: aLabel [
    ^ metaContainer children
        detect: [ :d | d label = aLabel ]
        ifNone: [ nil ]
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> relabelDescription: oldLabel to: newLabel [
    | desc |
    desc := self readDescription: oldLabel.
    desc ifNotNil: [
        desc label: newLabel.
        desc comment: (
            'Champ : ' , newLabel
            , ' | Niveau : ' , desc level asString
            , ' | Modifié par Ψ le : ' , DateAndTime now printString
            , ' | Ancien label : ' , oldLabel).
        traceLog add: (Association
            key: DateAndTime now
            value: ('Rename: ' , oldLabel , ' → ' , newLabel)) ].
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
    | desc |
    desc := metaContainer children
        detect: [ :d | d label = aLabel ]
        ifNone: [ ^ self ].
    desc level: aNewLevel.
    traceLog add: (Association
        key: DateAndTime now
        value: 'Level: ' , aLabel , ' → ' , aNewLevel asString).
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> traceLog [
    ^ traceLog
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> updateExplanation: aLabel forLevel: aLevel with: aText [
    | desc raw |
    desc := self readDescription: aLabel.
    desc ifNotNil: [
        raw := desc comment.
        (raw isKindOf: Dictionary)
            ifTrue: [ raw at: aLevel put: aText ]
            ifFalse: [
                desc comment: (Dictionary new
                    at: aLevel put: aText;
                    yourself) ] ]
]
