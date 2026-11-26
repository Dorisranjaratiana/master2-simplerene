"
""Presenter principal du framework AXPL. Orchestre toutes les relations architecturales.
Slots principaux :
  - framework : la façade AXPLFramework — porte le metaContainer (source
    unique de vérité) et l'unique moteur Ψ, créés une seule fois dans targetObject:
  - levelDropList : sélection du niveau utilisateur (⑨)
  - psiButton : bouton Ψ visible seulement au niveau le plus privilégié —
    ouvre runPsiMenu (créer ⑥ / modifier ④⑨ / supprimer ⑥ un champ)
  - traceButton : affiche le log horodaté [t] au niveau le plus privilégié
updateInterface : méthode centrale qui orchestre ①②⑦⑧⑨⑩.
targetObject: : point d'entrée — crée la façade puis déclenche le rendu.""
"
Class {
	#name : 'AXPLFormApp',
	#superclass : 'SpPresenter',
	#instVars : [
		'levelDropList',
		'formContainer',
		'statusLabel',
		'targetObject',
		'actionBar',
		'psiButton',
		'framework',
		'traceButton'
	],
	#category : 'AXPL-UI',
	#package : 'AXPL-UI'
}

{ #category : 'accessing' }
AXPLFormApp class >> neutralHeight [
    "Écran neutre : statut + liste des niveaux, sans formulaire ni boutons."
    ^ 130
]

{ #category : 'accessing' }
AXPLFormApp class >> neutralMessage [
    ^ 'Choisissez un niveau pour afficher le formulaire.'
]

{ #category : 'accessing' }
AXPLFormApp >> actionBar [

	^ actionBar
]

{ #category : 'accessing' }
AXPLFormApp >> actionBar: anObject [

	actionBar := anObject
]

{ #category : 'layout' }
AXPLFormApp >> defaultLayout [
    ^ SpBoxLayout newTopToBottom
        spacing: 10;
        borderWidth: 15;
        add: statusLabel expand: false;
        add: (SpBoxLayout newHorizontal
            spacing: 8;
            add: (self newLabel label: 'Niveau:') expand: false;
            add: levelDropList expand: true;
            yourself) expand: false;
        add: (SpScrollableLayout with: formContainer) expand: true;
        add: actionBar expand: false;
        yourself
]

{ #category : 'accessing' }
AXPLFormApp >> formContainer [

	^ formContainer
]

{ #category : 'accessing' }
AXPLFormApp >> formContainer: anObject [

	formContainer := anObject
]

{ #category : 'initialization' }
AXPLFormApp >> initialize [
    super initialize.
    targetObject := nil.
]

{ #category : 'initialization' }
AXPLFormApp >> initializePresenters [
    statusLabel := self newLabel label: self class neutralMessage.
    "Aucun niveau sélectionné au départ (startWithoutSelection doit précéder
    items:, sinon Spec2 sélectionne d'office le premier) : choisir un
    niveau affiche directement son formulaire — d'où l'absence de bouton
    Rafraîchir, devenu redondant."
    levelDropList := self newDropList
        startWithoutSelection;
        items: AXPLFormBuilder levels;
        display: [ :item | item asString capitalized ];
        whenSelectedItemChangedDo: [ :item | self updateInterface ].
    formContainer := self newPresenter.
    formContainer layout: SpBoxLayout newVertical.
    psiButton := self newButton label: ''; yourself.
    traceButton := self newButton
        label: 'Trace Ψ';
        icon: (self iconNamed: #smallInfo);
        action: [ self showTrace ];
        yourself.
    actionBar := self newPresenter.
    actionBar layout: (SpBoxLayout newHorizontal
        spacing: 8;
        add: (self newButton
            label: 'Annuler';
            icon: (self iconNamed: #smallCancel);
            action: [ self resetInterface ];
            yourself) expand: true;
        add: psiButton expand: true;
        add: traceButton expand: true;
        add: (self newButton
            label: 'Enregistrer';
            icon: (self iconNamed: #smallSave);
            action: [ self save ];
            yourself) expand: true;
        yourself).
 actionBar visible: false.
]

{ #category : 'initialization' }
AXPLFormApp >> initializeWindow: aWindowPresenter [
    super initializeWindow: aWindowPresenter.
    aWindowPresenter
        title: (targetObject
            ifNil: [ 'Framework {A,X,Ψ,L}' ]
            ifNotNil: [ :obj | obj class name , ' — AXΨL' ]);
        initialExtent: 500 @ self class neutralHeight.
]

{ #category : 'accessing' }
AXPLFormApp >> levelDropList [

	^ levelDropList
]

{ #category : 'accessing' }
AXPLFormApp >> levelDropList: anObject [

	levelDropList := anObject
]

{ #category : 'accessing' }
AXPLFormApp >> metaContainer [
	^ framework metaContainer
]

{ #category : 'accessing' }
AXPLFormApp >> psiButton [

	^ psiButton
]

{ #category : 'accessing' }
AXPLFormApp >> psiButton: anObject [

	psiButton := anObject
]

{ #category : 'accessing' }
AXPLFormApp >> psiEngine [
	^ framework psiEngine
]

{ #category : 'initialization' }
AXPLFormApp >> resetInterface [
    "Annule aussi les saisies : targetObject est remplacé par une instance
    fraîche, pas seulement le metaContainer (sinon les valeurs déjà tapées
    restaient malgré le clic sur Annuler)."
    "Revient à l'écran neutre de départ : aucun niveau sélectionné, aucun
    formulaire. Avant, Annuler remettait la liste sur Simple : depuis Base
    ou Expert, ce changement de sélection relançait le rendu de Simple dans
    une fenêtre déjà réduite (champs écrasés, barres de défilement)."
    self targetObject: targetObject class new.
    levelDropList resetSelection.
    self showNeutralState.
]

{ #category : 'updating' }
AXPLFormApp >> showNeutralState [
    formContainer layout: SpBoxLayout newVertical.
    statusLabel label: self class neutralMessage.
    actionBar visible: false.
    self window ifNotNil: [ :w | w resize: 500 @ self class neutralHeight ].
]

{ #category : 'psi' }
AXPLFormApp >> runPsiCreateField [
    "⑥ Ψ crée un champ entièrement nouveau dans le metaContainer, adossé
    au dictionnaire #properties de targetObject plutôt qu'à une variable
    d'instance."
    | types typeChoix label niveaux niveauChoix niveau typeClasses |
    types := #( 'Texte' 'Nombre' 'Booléen' 'Date' 'Choix' ).
    typeChoix := UIManager default
        chooseFrom: types
        title: 'Ψ — Type du nouveau champ'.
    (typeChoix isNil or: [ typeChoix = 0 ]) ifTrue: [ ^ self ].

    label := UIManager default
        request: 'Ψ — Label du nouveau champ :'
        initialAnswer: ''.
    (label isNil or: [ label isEmpty ]) ifTrue: [ ^ self ].

    niveaux := AXPLFormBuilder levels collect: [ :each | each asString ].
    niveauChoix := UIManager default
        chooseFrom: niveaux
        title: 'Ψ — Niveau du nouveau champ "' , label , '"'.
    (niveauChoix isNil or: [ niveauChoix = 0 ]) ifTrue: [ ^ self ].
    niveau := (niveaux at: niveauChoix) asSymbol.

    [ typeChoix = 5
        ifTrue: [
            | optionsText options |
            optionsText := UIManager default
                request: 'Ψ — Options séparées par des virgules :'
                initialAnswer: ''.
            (optionsText isNil or: [ optionsText isEmpty ]) ifTrue: [ ^ self ].
            options := self parseOptions: optionsText.
            self psiEngine createSelectionField: label options: options level: niveau ]
        ifFalse: [
            typeClasses := { SRStringDescription. SRNumberDescription. SRBooleanDescription. SRDateDescription }.
            self psiEngine createField: label type: (typeClasses at: typeChoix) level: niveau ] ]
        on: Error
        do: [ :err | ^ self inform: 'Ψ refusé : ' , err messageText ].

    self inform:
        'Ψ : champ "' , label , '" créé.'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
AXPLFormApp >> runPsiEditField: aLabel [
    "④⑨ Ψ change le niveau ou renomme un champ existant."
    | choix |
    choix := UIManager default
        chooseFrom: #( 'Changer le niveau' 'Modifier le label' )
        title: 'Ψ — Que voulez-vous modifier sur "' , aLabel , '" ?'.
    choix = 1 ifTrue: [
        | niveauChoix niveaux nouveauNiveau |
        niveaux := AXPLFormBuilder levels collect: [ :each | each asString ].
        niveauChoix := UIManager default
            chooseFrom: niveaux
            title: 'Ψ — Nouveau niveau pour "' , aLabel , '"'.
        (niveauChoix notNil and: [ niveauChoix > 0 ]) ifTrue: [
            nouveauNiveau := (niveaux at: niveauChoix) asSymbol.
            (UIManager default confirm:
                'Changer le niveau de "' , aLabel , '" en #' , nouveauNiveau , ' ?')
                ifTrue: [
                    self psiEngine setLevel: nouveauNiveau ofDescription: aLabel.
                    self inform:
                        'Ψ appliqué : "' , aLabel
                        , '" → niveau #' , nouveauNiveau
                        , String cr
                        , 'Horodatage : ' , DateAndTime now printString.
                    self updateInterface ] ] ].
    choix = 2 ifTrue: [
        | nouveauLabel |
        nouveauLabel := UIManager default
            request: 'Nouveau label pour "' , aLabel , '" :'
            initialAnswer: aLabel.
        (nouveauLabel notNil and: [ nouveauLabel notEmpty ]) ifTrue: [
            (UIManager default confirm:
                'Renommer "' , aLabel , '" en "' , nouveauLabel , '" ?')
                ifTrue: [
                    [ self psiEngine relabelDescription: aLabel to: nouveauLabel ]
                        on: Error
                        do: [ :err | ^ self inform: 'Ψ refusé : ' , err messageText ].
                    self inform:
                        'Ψ : "' , aLabel , '" → "' , nouveauLabel , '".'
                        , String cr
                        , 'Horodatage : ' , DateAndTime now printString.
                    self updateInterface ] ] ].
]

{ #category : 'psi' }
AXPLFormApp >> runPsiMenu [
    "Point d'entrée du bouton Ψ : créer, modifier ou supprimer un champ."
    | action |
    action := UIManager default
        chooseFrom: #( 'Créer un champ' 'Modifier un champ existant' 'Supprimer un champ' )
        title: 'Ψ — Que voulez-vous faire ?'.
    action = 1 ifTrue: [ ^ self runPsiCreateField ].
    action = 2 ifTrue: [ ^ self runPsiSelectFieldThenDo: [ :label | self runPsiEditField: label ] ].
    action = 3 ifTrue: [ ^ self runPsiSelectFieldThenDo: [ :label | self runPsiRemoveField: label ] ].
]

{ #category : 'psi' }
AXPLFormApp >> runPsiRemoveField: aLabel [
    "⑥ Ψ retire un champ entier du metaContainer."
    (UIManager default confirm: 'Supprimer le champ "' , aLabel , '" ?')
        ifFalse: [ ^ self ].
    self psiEngine removeField: aLabel.
    self inform:
        'Ψ : champ "' , aLabel , '" supprimé.'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
AXPLFormApp >> runPsiSelectFieldThenDo: aBlock [
    "Demande à l'utilisateur de choisir un champ existant, puis exécute
    aBlock avec son label. Ne fait rien si l'utilisateur annule."
    | currentLabels index |
    currentLabels := self metaContainer children collect: [ :d | d label ].
    index := UIManager default
        chooseFrom: currentLabels
        title: 'Ψ — Choisir le champ'.
    (index notNil and: [ index > 0 ])
        ifTrue: [ aBlock value: (currentLabels at: index) ].
]

{ #category : 'updating' }
AXPLFormApp >> save [
    "Valide chaque champ du metaContainer (règles réelles de SimpleRene :
    beRequired, bePositive, conditions personnalisées...) avant de confirmer
    l'enregistrement. N'écrit rien de nouveau : les valeurs sont déjà sur
    targetObject au fil de la saisie (cf. AXPLSpecVisitor), cette étape ne
    fait que vérifier qu'elles sont toutes valides."
    | invalides |
    invalides := self invalidFields.
    invalides isEmpty
        ifTrue: [ self inform: 'Enregistré : toutes les valeurs sont valides.' ]
        ifFalse: [
            self inform:
                'Impossible d''enregistrer, champs invalides :'
                , String cr
                , ((invalides collect: [ :d | '- ' , d label ]) inject: '' into: [ :acc :line | acc , line , String cr ]) ].
]

{ #category : 'updating' }
AXPLFormApp >> showHiddenFieldsExplanation: aCollectionOfDescriptions [
    "② Explique en un seul écran pourquoi chaque champ masqué ne s'affiche
    pas au niveau courant, au lieu d'un bouton par champ."
    self inform: (self hiddenFieldsExplanationText: aCollectionOfDescriptions)
]

{ #category : 'updating' }
AXPLFormApp >> hiddenFieldsExplanationText: aCollectionOfDescriptions [
    "Pour chaque champ masqué : le niveau qui le débloque (la vraie raison
    du masquage), puis ce qu'il signifie à ce niveau-là. Avant, seule la
    signification au niveau courant était donnée — elle ne disait pas
    pourquoi le champ était caché ni comment le voir."
    ^ aCollectionOfDescriptions
        inject: 'Champs masqués au niveau ' , levelDropList selectedItem asString capitalized , ' :' , String cr
        into: [ :acc :d |
            | required expl |
            required := AXPLFormBuilder requiredLevelFor: d.
            expl := d commentFor: required.
            acc , '- ' , d label , ' — visible à partir du niveau ' , required asString capitalized
                , (expl isEmpty ifTrue: [ '' ] ifFalse: [ ' : ' , expl ])
                , String cr ]
]

{ #category : 'updating' }
AXPLFormApp >> invalidFields [
    "Les champs dont la valeur actuelle ne respecte pas les règles de
    SimpleRene (beRequired, bePositive, conditions personnalisées)."
    ^ self metaContainer children
        reject: [ :d | d isSatisfiedBy: (d read: targetObject) ]
]

{ #category : 'psi' }
AXPLFormApp >> parseOptions: aString [
    "'A, B ,AB' → #('A' 'B' 'AB') : options d'un champ Choix créé par Ψ."
    ^ (((aString substrings: ',') collect: [ :each | each trimBoth ])
        reject: [ :each | each isEmpty ]) asArray
]

{ #category : 'accessing' }
AXPLFormApp >> showTrace [
    "Affiche le log Ψ horodaté et l'exporte aussi vers un fichier texte,
    pour garder une trace consultable en dehors de l'image Pharo."
    | log text path |
    log := self psiEngine traceLog.
    log isEmpty
        ifTrue: [ ^ self inform: 'Aucune intercession enregistrée.' ].
    text := log inject: '' into: [ :acc :each |
        acc , each key printString , ' — ' , each value , String cr ].
    path := FileLocator workingDirectory / ('axpl-trace-' , (DateAndTime now printString copyReplaceAll: ':' with: '-') , '.txt').
    path writeStreamDo: [ :stream | stream nextPutAll: text ].
    self inform: text , String cr , 'Exportée vers : ' , path fullName.
]

{ #category : 'accessing' }
AXPLFormApp >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
AXPLFormApp >> statusLabel: anObject [

	statusLabel := anObject
]

{ #category : 'accessing' }
AXPLFormApp >> targetObject [
	^ targetObject
]

{ #category : 'accessing' }
AXPLFormApp >> targetObject: anObject [
    targetObject := anObject.
    framework := AXPLFramework for: anObject.
]

{ #category : 'layout' }
AXPLFormApp >> resizeWindowFor: visibleFieldCount hiddenButtonShown: hasHiddenButton [
    "Adapte la hauteur de la fenêtre au nombre de champs réellement
    affichés à ce niveau, au lieu d'une hauteur fixe qui laisse un grand
    vide en Simple/Base et déborde à peine en Expert."
    "Corrigé : on appelait `self window extent:`, qui n'est que
    SpPresenter >> extent: (^ extent := aPoint) — la valeur était
    mémorisée mais la fenêtre déjà ouverte ne bougeait jamais.
    SpWindowPresenter >> resize: passe par l'adaptateur Morphic et
    redimensionne réellement la fenêtre (ou attend qu'elle s'ouvre)."
    self window ifNotNil: [ :w |
        w resize: 500 @ ((self desiredHeightFor: visibleFieldCount hiddenButtonShown: hasHiddenButton)
            min: self maxWindowHeight) ].
]

{ #category : 'layout' }
AXPLFormApp >> desiredHeightFor: visibleFieldCount hiddenButtonShown: hasHiddenButton [
    "33 = hauteur d'une ligne de champ (≈25) + espacement du visiteur (8) ;
    155 = barre de titre, statut, niveau, barre d'actions,
    espacements et bordures — mesurés sur une vraie fenêtre. L'ancienne
    estimation (41 et 270) laissait un grand vide sous les champs."
    | rowCount |
    rowCount := visibleFieldCount + (hasHiddenButton ifTrue: [ 1 ] ifFalse: [ 0 ]).
    ^ (rowCount * 33) + 155 max: 300
]

{ #category : 'layout' }
AXPLFormApp >> maxWindowHeight [
    "Jamais plus haut que l'écran Pharo : sinon la barre Annuler / Ψ /
    Trace / Enregistrer passe sous le bord de l'écran. Au-delà, la zone
    du formulaire défile (cf. defaultLayout)."
    ^ self currentWorld
        ifNil: [ 950 ]
        ifNotNil: [ :world | world height - 40 ]
]

{ #category : 'accessing' }
AXPLFormApp >> traceButton [

	^ traceButton
]

{ #category : 'accessing' }
AXPLFormApp >> traceButton: anObject [

	traceButton := anObject
]

{ #category : 'updating' }
AXPLFormApp >> updateInterface [
    | level visibleDescs hidden visitor newLayout |
    targetObject ifNil: [ ^ self ].
    level := levelDropList selectedItem.
    level ifNil: [ ^ self showNeutralState ].

    "① Filtrage adaptatif (A)"
    visibleDescs := framework visibleFieldsAt: level.

    "Titre contextuel"
    statusLabel label: levelDropList selectedItem asString capitalized
        , ' Formulaire pour ' , targetObject class name.

    "Ψ — réservé au niveau le plus privilégié"
    levelDropList selectedItem = AXPLFormBuilder mostPrivilegedLevel
        ifTrue: [
            traceButton visible: true.
            psiButton
                label: 'Ψ — Réflexivité';
                enabled: true;
                action: [ self runPsiMenu ] ]
        ifFalse: [
            traceButton visible: false.
            psiButton
                label: '';
                enabled: false;
                action: [ ] ].

    "⑦ Génération widgets (L)"
    visitor := (AXPLSpecVisitor on: targetObject level: level)
        presenter: self;
        yourself.
    newLayout := visitor visit: visibleDescs.

    "② Champs masqués avec explication (X) — un seul bouton groupé plutôt
    qu'un par champ, pour ne pas noyer les champs visibles."
    hidden := framework hiddenFieldsAt: level.
    hidden notEmpty ifTrue: [
        newLayout add: (self newButton
            icon: (self iconNamed: #help);
            label: hidden size printString , ' champ(s) supplémentaire(s) masqué(s) — niveau supérieur requis';
            action: [ self showHiddenFieldsExplanation: hidden ])
            expand: false ].

    "layout et visible sont des ObservableSlot dans Spec2 : changer le
    layout de formContainer le reconstruit à lui seul (replaceLayoutWith:).
    On n'appelle plus self update : cette reconstruction de toute la
    fenêtre, marquée obsolète par Spec2, recréait aussi la liste des
    niveaux — qui, démarrant sans sélection, effaçait alors le niveau
    qu'on venait de choisir (SpMorphicDropListAdapter>>verifyInitialStatus)."
    formContainer layout: newLayout.
    actionBar visible: true.
    self resizeWindowFor: visibleDescs size hiddenButtonShown: hidden notEmpty.
]
