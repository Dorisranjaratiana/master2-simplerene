"
""Moteur de réflexivité Ψ. Cœur de la contribution du framework AXPL.
Implémente les relations ③④⑤⑥ et la traçabilité [t].
③ readDescription: — lit une description par son label dans le metaContainer.
④ relabelDescription:to: — modifie un label à l'exécution (intercession).
⑤ updateExplanation:forLevel:with: / updateExplanation:with: — explication ②
d'un champ, pour un niveau ou pour tous ; synchronise l'aide après intercession.
⑥ Les créations acceptent aussi une explication (…level:explanation:) : un
champ créé par Ψ a son aide dès la naissance, comme les champs déclarés.
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

{ #category : 'private' }
AXPLReflexivityEngine >> assertLabelAvailable: aLabel [
    "readDescription: fait un detect: qui ne renvoie que le PREMIER champ
    trouvé — un doublon de label rendrait le second champ inaccessible à
    relabelDescription:/removeField:. On refuse la création plutôt que de
    laisser ce piège silencieux se produire."
    (self readDescription: aLabel) ifNotNil: [
        Error signal: 'Un champ "' , aLabel , '" existe déjà.' ]
]

{ #category : 'private' }
AXPLReflexivityEngine >> assertValidLevel: aLevel [
    "Un niveau inconnu (#inconnu, faute de frappe, chaîne reçue du web...)
    rendrait le champ invisible à tous les niveaux sauf #expert, sans
    aucune erreur : on refuse plutôt que de le cacher silencieusement."
    (AXPLFormBuilder levels includes: aLevel) ifFalse: [
        Error signal: 'Niveau invalide : ' , aLevel printString ,
            ' (attendu l''un de ' , AXPLFormBuilder levels printString , ')' ]
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aDescriptionClass level: aLevel [
    "⑥ Crée un nouveau champ (String/Number/Boolean/Date) à l'exécution."
    ^ self createField: aLabel type: aDescriptionClass level: aLevel explanation: nil
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createField: aLabel type: aDescriptionClass level: aLevel explanation: aTextOrNil [
    "⑥② Crée un nouveau champ (String/Number/Boolean/Date) à l'exécution,
    avec son explication dès la naissance : un champ créé par Ψ ne doit
    pas être le seul du formulaire à rester sans aide pour l'utilisateur."
    | desc |
    self assertValidLevel: aLevel.
    self assertLabelAvailable: aLabel.
    desc := aDescriptionClass new.
    ^ self register: desc labelled: aLabel level: aLevel explanation: aTextOrNil
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createSelectionField: aLabel options: aCollection level: aLevel [
    "⑥ Crée un nouveau champ à choix (SRSingleOptionDescription) à l'exécution."
    ^ self createSelectionField: aLabel options: aCollection level: aLevel explanation: nil
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> createSelectionField: aLabel options: aCollection level: aLevel explanation: aTextOrNil [
    "⑥② Crée un nouveau champ à choix (SRSingleOptionDescription) à
    l'exécution, avec son explication."
    | desc |
    self assertValidLevel: aLevel.
    self assertLabelAvailable: aLabel.
    desc := SRSingleOptionDescription new options: aCollection; yourself.
    ^ self register: desc labelled: aLabel level: aLevel explanation: aTextOrNil
]

{ #category : 'private' }
AXPLReflexivityEngine >> explanationDictionaryOf: aDescription [
    "Le comment d'une description est nil, une String (la même aide à tous
    les niveaux) ou un Dictionary par niveau. On le ramène toujours à un
    Dictionary SANS perdre l'existant : une String devient la valeur de
    chaque niveau, pour qu'expliquer un seul niveau n'efface pas l'aide
    des autres."
    | raw dict |
    raw := aDescription comment.
    (raw isKindOf: Dictionary) ifTrue: [ ^ raw ].
    dict := Dictionary new.
    (raw isString and: [ raw notEmpty ]) ifTrue: [
        AXPLFormBuilder levels do: [ :each | dict at: each put: raw ] ].
    aDescription comment: dict.
    ^ dict
]

{ #category : 'private' }
AXPLReflexivityEngine >> register: aDescription labelled: aLabel level: aLevel explanation: aTextOrNil [
    "Partie commune aux créations ⑥ : accessor vers #properties, niveau,
    position en fin de formulaire, explication ② éventuelle, trace [t]."
    aDescription
        label: aLabel;
        accessor: (self accessorFor: (self accessorKeyFor: aLabel));
        level: aLevel;
        priority: self nextPriority.
    (aTextOrNil notNil and: [ aTextOrNil notEmpty ])
        ifTrue: [ aDescription comment: aTextOrNil ].
    metaContainer add: aDescription.
    traceLog add: (Association key: DateAndTime now value: 'Création : ' , aLabel).
    ^ aDescription
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
    "④ Ne touche QU'AU label : les explications graduées par niveau (②)
    décrivent toujours le même champ et doivent survivre au renommage.
    L'ancien label et l'horodatage vont dans le traceLog [t], pas dans
    le commentaire."
    | desc |
    desc := self readDescription: oldLabel.
    desc ifNil: [ ^ self ].
    oldLabel = newLabel ifTrue: [ ^ self ].
    self assertLabelAvailable: newLabel.
    desc label: newLabel.
    traceLog add: (Association
        key: DateAndTime now
        value: ('Rename: ' , oldLabel , ' → ' , newLabel)).
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
    | desc |
    self assertValidLevel: aNewLevel.
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
    "⑤② Change l'explication d'un champ pour UN niveau ; celles des autres
    niveaux sont conservées (y compris quand le champ n'avait qu'une aide
    commune, cf. explanationDictionaryOf:). Comme les autres intercessions :
    niveau inconnu refusé, champ inconnu sans effet, changement tracé."
    | desc |
    self assertValidLevel: aLevel.
    desc := self readDescription: aLabel.
    desc ifNil: [ ^ self ].
    (self explanationDictionaryOf: desc) at: aLevel put: aText.
    traceLog add: (Association
        key: DateAndTime now
        value: 'Explication : ' , aLabel , ' [' , aLevel asString , ']').
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> updateExplanation: aLabel with: aText [
    "⑤② Donne à un champ la même explication à tous les niveaux."
    | desc |
    desc := self readDescription: aLabel.
    desc ifNil: [ ^ self ].
    desc comment: aText.
    traceLog add: (Association
        key: DateAndTime now
        value: 'Explication : ' , aLabel , ' [tous niveaux]').
]
