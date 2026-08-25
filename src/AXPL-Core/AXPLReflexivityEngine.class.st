"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤⑥ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: — modifie un label à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: — synchronise l'explication après intercession.
⑥ createField:type:level: / createSelectionField:options:level: / removeField: —
crée ou retire un champ entier du metaContainer à l'exécution. Un champ créé
n'est adossé à aucune variable d'instance : sa valeur vit dans le dictionnaire
#properties de l'objet cible, via un SRPluggableAccessor.
[t] traceLog — historique horodaté de toutes les intercessions (DateAndTime).
Instance unique créée dans targetObject: — jamais recréée entre les re-rendus.""
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog',
		'nextKeyId'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'private' }
AXPLReflexivityEngine >> accessorFor: aKey [
    "Lit/écrit dans le dictionnaire #properties de l'objet cible plutôt que
    dans une variable d'instance figée — c'est ce qui permet à Ψ de créer
    un champ que la classe métier n'a jamais déclaré."
    ^ SRPluggableAccessor
        read: [ :model | model properties at: aKey ifAbsent: [ nil ] ]
        write: [ :model :value | model properties at: aKey put: value ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> accessorKeyFor: aLabel [
    "Dérive une clé stable pour #properties à partir d'un label libre.
    Le compteur garantit l'unicité même si deux champs créés dans la même
    session partagent le même label."
    | cleaned |
    cleaned := (aLabel select: [ :c | c isLetter or: [ c isDigit ] ]) asLowercase.
    cleaned isEmpty ifTrue: [ cleaned := 'champ' ].
    nextKeyId := nextKeyId + 1.
    ^ (cleaned , nextKeyId printString) asSymbol
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aDescriptionClass level: aLevel [
    "⑥ Crée un nouveau champ (String/Number/Boolean/Date) à l'exécution."
    | desc key |
    key := self accessorKeyFor: aLabel.
    desc := aDescriptionClass new
        label: aLabel;
        accessor: (self accessorFor: key);
        level: aLevel;
        priority: self nextPriority;
        yourself.
    metaContainer add: desc.
    traceLog add: (Association key: DateAndTime now value: 'Création : ' , aLabel).
    ^ desc
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createSelectionField: aLabel options: aCollection level: aLevel [
    "⑥ Crée un nouveau champ à choix (SRSingleOptionDescription) à l'exécution."
    | desc key |
    key := self accessorKeyFor: aLabel.
    desc := SRSingleOptionDescription new
        label: aLabel;
        accessor: (self accessorFor: key);
        options: aCollection;
        level: aLevel;
        priority: self nextPriority;
        yourself.
    metaContainer add: desc.
    traceLog add: (Association key: DateAndTime now value: 'Création : ' , aLabel).
    ^ desc
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
    super initialize.
    traceLog := OrderedCollection new.
    nextKeyId := 0.
]

{ #category : 'private' }
AXPLReflexivityEngine >> nextPriority [
    "Place un nouveau champ après tous les champs existants."
    ^ (metaContainer children
        ifEmpty: [ 0 ]
        ifNotEmpty: [ :children | (children collect: [ :d | d priority ]) max ]) + 10
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> removeField: aLabel [
    "⑥ Retire un champ entier du metaContainer à l'exécution."
    | desc |
    desc := self readDescription: aLabel.
    desc ifNotNil: [
        metaContainer remove: desc.
        traceLog add: (Association key: DateAndTime now value: 'Suppression : ' , aLabel) ].
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

{ #category : 'intercession' }
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
