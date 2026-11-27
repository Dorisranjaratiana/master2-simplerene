"
Moteur de réflexivité Ψ d'AXPL : le formulaire peut s'observer et se
modifier lui-même pendant que l'application tourne, sans recompiler ni
redémarrer. Il agit sur le metaContainer (les descriptions SimpleRene du
formulaire), jamais sur le code de la classe métier. Une instance par
formulaire, créée par AXPLFramework (framework psiEngine).

API, en trois familles (catégories de méthodes du même nom) :

INTROSPECTION ③ — lire le méta-modèle
  fields, labels                       les champs du formulaire
  readDescription: aLabel              la description SimpleRene d'un champ (ou nil)
  levelOf: / typeOf: aLabel            son niveau, sa classe de description
  explanationOf: aLabel forLevel: aLvl son explication ② à ce niveau
  psiCreatedLabels                     les champs créés à l'exécution par Ψ

INTERCESSION ④⑤⑥⑨ — modifier le méta-modèle à l'exécution
  createField:type:level:explanation:                  ⑥ nouveau champ (Texte, Nombre, Booléen, Date…)
  createSelectionField:options:level:explanation:      ⑥ nouveau champ à choix
  removeField:                                         ⑥ retirer un champ
  relabelDescription:to:                               ④ renommer (les explications sont gardées)
  setLevel:ofDescription:                              ⑨ changer le niveau qui voit le champ
  updateExplanation:forLevel:with: / updateExplanation:with:   ⑤② changer l'explication
Garanties : niveau inconnu refusé, label en double refusé, champ inconnu
sans effet ; un champ créé n'a pas de variable d'instance, sa valeur vit
dans le dictionnaire #properties de l'objet (SRPluggableAccessor).

HISTOIRE [t] ↶ 💾 — garder la trace, annuler, rejouer
  traceLog                             chaque intercession, horodatée (DateAndTime)
  canUndo, lastUndoableChange, undoLast   annuler, de la plus récente à la plus ancienne
  changes, replayChanges:              les intercessions actives en données (sans bloc),
                                       pour la sauvegarde STON et leur rejeu

Scénario complet : AXPLReflexiveScenario (package AXPL-Scenarios).
"
Class {
	#name : 'AXPLReflexivityEngine',
	#superclass : 'Object',
	#instVars : [
		'metaContainer',
		'traceLog',
		'undoLog',
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
AXPLReflexivityEngine >> register: aDescription labelled: aLabel level: aLevel explanation: aTextOrNil [
    "Partie commune aux créations ⑥ : accessor vers #properties, niveau,
    position en fin de formulaire, explication ② éventuelle, trace [t]."
    aDescription
        label: aLabel;
        accessor: (self accessorFor: (self accessorKeyFor: aLabel));
        level: aLevel;
        priority: self nextPriority.
    aDescription axplExplanation: ((AXPLExplanation common: aTextOrNil)
        origin: #psi;
        yourself).
    metaContainer add: aDescription.
    self
        record: 'Création : ' , aLabel
        undo: [ metaContainer remove: aDescription ]
        as: (Dictionary new
            at: #op put: #create;
            at: #label put: aLabel;
            at: #type put: aDescription class name;
            at: #level put: aLevel;
            at: #explanation put: aTextOrNil;
            at: #options put: ((aDescription isKindOf: SRSingleOptionDescription)
                ifTrue: [ aDescription options asArray ]
                ifFalse: [ nil ]);
            yourself).
    ^ aDescription
]

{ #category : 'initialization' }
AXPLReflexivityEngine >> initialize [
    super initialize.
    traceLog := OrderedCollection new.
    undoLog := OrderedCollection new.
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
        "Remis dans le container trié par priorité, le champ retrouve sa
        place, son accessor (donc sa valeur) et ses explications."
        self
            record: 'Suppression : ' , aLabel
            undo: [ metaContainer add: desc ]
            as: (Dictionary new at: #op put: #remove; at: #label put: aLabel; yourself) ].
]

{ #category : 'accessing' }
AXPLReflexivityEngine >> metaContainer: aContainer [
    metaContainer := aContainer
]

{ #category : 'introspection' }
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
    self
        record: 'Rename: ' , oldLabel , ' → ' , newLabel
        undo: [ desc label: oldLabel ]
        as: (Dictionary new at: #op put: #relabel; at: #from put: oldLabel; at: #to put: newLabel; yourself).
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> setLevel: aNewLevel ofDescription: aLabel [
    | desc oldLevel |
    self assertValidLevel: aNewLevel.
    desc := metaContainer children
        detect: [ :d | d label = aLabel ]
        ifNone: [ ^ self ].
    oldLevel := desc level.
    desc level: aNewLevel.
    self
        record: 'Level: ' , aLabel , ' → ' , aNewLevel asString
        undo: [ desc level: oldLevel ]
        as: (Dictionary new at: #op put: #level; at: #label put: aLabel; at: #level put: aNewLevel; yourself).
]

{ #category : 'history' }
AXPLReflexivityEngine >> traceLog [
    ^ traceLog
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> updateExplanation: aLabel forLevel: aLevel with: aText [
    "⑤② Change l'explication d'un champ pour UN niveau (décorateur
    AXPLExplanation, dans les propriétés de la description) ; celles des
    autres niveaux, et l'aide commune, sont conservées. Comme les autres intercessions :
    niveau inconnu refusé, champ inconnu sans effet, changement tracé."
    | desc |
    self assertValidLevel: aLevel.
    desc := self readDescription: aLabel.
    desc ifNil: [ ^ self ].
    self
        changeExplanationOf: desc
        by: [ desc explanation text: aText forLevel: aLevel ]
        tracing: 'Explication : ' , aLabel , ' [' , aLevel asString , ']'
        as: (Dictionary new at: #op put: #explain; at: #label put: aLabel; at: #level put: aLevel; at: #text put: aText; yourself).
]

{ #category : 'intercession' }
AXPLReflexivityEngine >> updateExplanation: aLabel with: aText [
    "⑤② Donne à un champ la même explication à tous les niveaux."
    | desc |
    desc := self readDescription: aLabel.
    desc ifNil: [ ^ self ].
    self
        changeExplanationOf: desc
        by: [ desc explanation beCommon: aText ]
        tracing: 'Explication : ' , aLabel , ' [tous niveaux]'
        as: (Dictionary new at: #op put: #explain; at: #label put: aLabel; at: #level put: nil; at: #text put: aText; yourself).
]

{ #category : 'private' }
AXPLReflexivityEngine >> changeExplanationOf: aDescription by: aBlock tracing: aText as: aChange [
    "Le décorateur d'explication est modifié EN PLACE : on en garde une
    copie (ou nil s'il n'y en avait pas) pour le remettre tel quel. Le
    #comment de SimpleRene n'est jamais touché."
    | oldExplanation |
    oldExplanation := aDescription axplExplanation copy.
    aBlock value.
    self record: aText undo: [ aDescription axplExplanation: oldExplanation ] as: aChange
]

{ #category : 'private' }
AXPLReflexivityEngine >> record: aText undo: anUndoBlock as: aChange [
    "[t] + ↶ + 💾 : toute intercession passe par ici — trace horodatée,
    moyen de la défaire, et sa description en données pour la sauvegarde."
    traceLog add: (Association key: DateAndTime now value: aText).
    undoLog add: { aText. anUndoBlock. aChange }
]

{ #category : 'history' }
AXPLReflexivityEngine >> canUndo [
    ^ undoLog notEmpty
]

{ #category : 'history' }
AXPLReflexivityEngine >> lastUndoableChange [
    "Texte de l'intercession qu'undoLast annulerait (nil s'il n'y en a pas),
    pour la montrer à l'utilisateur avant de confirmer."
    ^ undoLog ifEmpty: [ nil ] ifNotEmpty: [ undoLog last first ]
]

{ #category : 'history' }
AXPLReflexivityEngine >> undoLast [
    "↶ Défait la dernière intercession encore active et renvoie son texte.
    L'annulation n'est pas elle-même annulable (pas de « rétablir »), mais
    elle est tracée."
    | change |
    undoLog ifEmpty: [ ^ Error signal: 'Aucune modification Ψ à annuler.' ].
    change := undoLog removeLast.
    change second value.
    traceLog add: (Association key: DateAndTime now value: 'Annulation : ' , change first).
    ^ change first
]

{ #category : 'persistence' }
AXPLReflexivityEngine >> changes [
    "💾 Les intercessions encore actives (les annulées n'y sont plus), dans
    l'ordre, en données pures — sérialisables en STON."
    ^ (undoLog collect: [ :each | each third copy ]) asArray
]

{ #category : 'persistence' }
AXPLReflexivityEngine >> replayChanges: aCollection [
    "💾 Rejoue des intercessions sauvegardées par #changes, dans l'ordre,
    par les mêmes méthodes publiques — mêmes vérifications (niveau connu,
    label libre), même trace, et elles restent annulables."
    aCollection do: [ :each | self replayChange: each ]
]

{ #category : 'persistence' }
AXPLReflexivityEngine >> replayChange: aChange [
    | op |
    op := aChange at: #op.
    op = #create ifTrue: [ ^ self replayCreation: aChange ].
    op = #remove ifTrue: [ ^ self removeField: (aChange at: #label) ].
    op = #relabel ifTrue: [ ^ self relabelDescription: (aChange at: #from) to: (aChange at: #to) ].
    op = #level ifTrue: [ ^ self setLevel: (aChange at: #level) ofDescription: (aChange at: #label) ].
    op = #explain ifTrue: [
        ^ (aChange at: #level)
            ifNil: [ self updateExplanation: (aChange at: #label) with: (aChange at: #text) ]
            ifNotNil: [ :lvl | self updateExplanation: (aChange at: #label) forLevel: lvl with: (aChange at: #text) ] ].
    Error signal: 'Modification Ψ inconnue : ' , op printString
]

{ #category : 'persistence' }
AXPLReflexivityEngine >> replayCreation: aChange [
    "Le type vient d'un fichier : on n'instancie qu'une vraie classe de
    description SimpleRene, jamais une classe quelconque nommée dedans."
    | type |
    type := Smalltalk globals at: (aChange at: #type) asSymbol ifAbsent: [ nil ].
    (type isClass and: [ type inheritsFrom: SRDescription ]) ifFalse: [
        Error signal: 'Type de champ inconnu : ' , (aChange at: #type) printString ].
    ^ (aChange at: #options)
        ifNil: [
            self
                createField: (aChange at: #label)
                type: type
                level: (aChange at: #level)
                explanation: (aChange at: #explanation) ]
        ifNotNil: [ :options |
            self
                createSelectionField: (aChange at: #label)
                options: options
                level: (aChange at: #level)
                explanation: (aChange at: #explanation) ]
]

{ #category : 'persistence' }
AXPLReflexivityEngine >> restoreTrace: aCollectionOfPairs [
    "💾 Remet l'historique sauvegardé ({horodatage. texte}) à la place des
    entrées produites par le rejeu : la trace reste celle d'origine."
    traceLog := (aCollectionOfPairs collect: [ :pair |
        Association key: pair first value: pair second ]) asOrderedCollection
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> explanationOf: aLabel forLevel: aLevel [
    "② L'explication montrée à ce niveau, ou nil si le champ n'existe pas."
    ^ (self readDescription: aLabel) ifNotNil: [ :desc | desc commentFor: aLevel ]
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> fields [
    "Les descriptions du formulaire, dans l'ordre d'affichage."
    ^ metaContainer children asArray
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> labels [
    ^ self fields collect: [ :desc | desc label ]
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> levelOf: aLabel [
    "① Le niveau à partir duquel le champ est visible, ou nil."
    ^ (self readDescription: aLabel) ifNotNil: [ :desc | desc level ]
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> psiCreatedLabels [
    "Les champs créés à l'exécution par Ψ (et non déclarés dans le code)."
    ^ (self fields select: [ :desc |
        desc axplExplanation notNil and: [ desc axplExplanation isPsiCreated ] ])
            collect: [ :desc | desc label ]
]

{ #category : 'introspection' }
AXPLReflexivityEngine >> typeOf: aLabel [
    "La classe de description SimpleRene du champ, ou nil."
    ^ (self readDescription: aLabel) ifNotNil: [ :desc | desc class ]
]
