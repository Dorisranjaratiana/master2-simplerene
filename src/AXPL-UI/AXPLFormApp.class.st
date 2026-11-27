"
""Presenter principal du framework AXPL. Orchestre toutes les relations architecturales.
Slots principaux :
  - framework : la façade AXPLFramework — porte le metaContainer (source
    unique de vérité) et l'unique moteur Ψ, créés une seule fois dans targetObject:
  - levelDropList : sélection du niveau utilisateur (⑨)
  - psiButton : bouton Ψ visible seulement au niveau le plus privilégié —
    ouvre runPsiMenu (créer ⑥ / modifier ④⑨ / supprimer ⑥ un champ)
  - traceButton : affiche le log horodaté [t] au niveau le plus privilégié
  - openButton / Enregistrer : 💾 dossiers STON (objet + modifications Ψ)
    rangés dans dossiersDirectory (par défaut <image>/axpl-dossiers)
updateInterface : méthode centrale qui orchestre ①②⑦⑧⑨⑩. Le formulaire
lui-même est dessiné par Spec-Form (AXPLSpecFormPresenter, package
AXPL-SpecForm), sous la liste des niveaux ; AXΨL lui donne les champs
visibles ①, l'explication de chaque champ ② et la validation des saisies.
targetObject: : point d'entrée — crée la façade puis déclenche le rendu.""
"
Class {
	#name : 'AXPLFormApp',
	#superclass : 'SpPresenter',
	#instVars : [
		'levelDropList',
		'formContainer',
		'bodyContainer',
		'statusLabel',
		'targetObject',
		'actionBar',
		'psiButton',
		'framework',
		'traceButton',
		'pendingErrors',
		'openButton',
		'dossiersDirectory',
		'currentDossierName',
		'formPresenter'
	],
	#category : 'AXPL-UI',
	#package : 'AXPL-UI'
}

{ #category : 'accessing' }
AXPLFormApp class >> neutralHeight [
    "Écran neutre : statut + liste des niveaux, sans formulaire ni boutons."
    ^ 130
]

{ #category : 'instance creation' }
AXPLFormApp class >> openOn: anAXPLFramework level: aLevel [
	"Ouvre la fenêtre sur ce formulaire, au niveau donné."
	| app |
	app := self new.
	app framework: anAXPLFramework.
	app open.
	app levelDropList selectItem: aLevel.
	^ app
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
            add: openButton expand: false;
            yourself) expand: false;
        add: bodyContainer expand: true;
        yourself
]

{ #category : 'layout' }
AXPLFormApp >> formBodyLayoutScrollable: needsScroll [
    "Zone sous la liste des niveaux quand un niveau est choisi : le
    formulaire puis la barre d'actions. Elle est remplacée d'un bloc
    (bodyContainer layout:) plutôt que de masquer/afficher la barre : une
    barre construite masquée gardait une hauteur nulle une fois
    réaffichée — les boutons n'étaient plus qu'une fine ligne.
    Le formulaire n'est défilant que s'il ne tient pas à l'écran : la
    zone défilante de Morphic affichait sinon une barre verticale dès que
    son contenu dépassait de quelques pixels, même quand tout tenait."
    ^ SpBoxLayout newTopToBottom
        spacing: 10;
        add: (needsScroll
            ifTrue: [ SpScrollableLayout with: formContainer ]
            ifFalse: [ formContainer ])
            expand: true;
        add: actionBar expand: false;
        yourself
]

{ #category : 'accessing' }
AXPLFormApp >> bodyContainer [
    ^ bodyContainer
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
    bodyContainer := self newPresenter.
    bodyContainer layout: SpBoxLayout newVertical.
    psiButton := self newButton label: ''; yourself.
    openButton := self newButton
        label: 'Ouvrir…';
        icon: (self iconNamed: #open);
        help: 'Ouvrir un dossier enregistré (valeurs et modifications Ψ)';
        action: [ self runOpenDossier ];
        yourself.
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
AXPLFormApp >> displayedRowCount [
	"Lignes du formulaire affiché : une par champ (la grille Spec-Form
	alterne label et widget), plus le bouton des champs masqués s'il y en a."
	formPresenter ifNil: [ ^ 0 ].
	^ (formPresenter layout presenters size // 2)
		+ (formContainer layout presenters size - 1)
]

{ #category : 'accessing' }
AXPLFormApp >> formPresenter [
	"Le formulaire Spec-Form du niveau affiché (nil sur l'écran neutre)."
	^ formPresenter
]

{ #category : 'accessing' }
AXPLFormApp >> framework [
	^ framework
]

{ #category : 'accessing' }
AXPLFormApp >> framework: anAXPLFramework [
	"Affiche un formulaire déjà préparé (par exemple modifié par Ψ dans
	un script ou un scénario) au lieu d'en créer un neuf."
	framework := anAXPLFramework.
	targetObject := anAXPLFramework targetObject
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
    currentDossierName := nil.
    levelDropList resetSelection.
    self showNeutralState.
]

{ #category : 'updating' }
AXPLFormApp >> showNeutralState [
    self window ifNotNil: [ :w | w resize: 500 @ self class neutralHeight ].
    formPresenter := nil.
    formContainer layout: SpBoxLayout newVertical.
    bodyContainer layout: SpBoxLayout newVertical.
    statusLabel label: self class neutralMessage.
]

{ #category : 'psi' }
AXPLFormApp >> runPsiCreateField [
    "⑥② Ψ crée un champ entièrement nouveau dans le metaContainer, adossé
    au dictionnaire #properties de targetObject plutôt qu'à une variable
    d'instance — avec son explication, facultative, dès la création."
    | types typeChoix label niveaux niveauChoix niveau typeClasses options explication |
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

    typeChoix = 5 ifTrue: [
        | optionsText |
        optionsText := UIManager default
            request: 'Ψ — Options séparées par des virgules :'
            initialAnswer: ''.
        (optionsText isNil or: [ optionsText isEmpty ]) ifTrue: [ ^ self ].
        options := self parseOptions: optionsText ].

    "Facultative : laisser vide (ou fermer) crée le champ sans aide ;
    elle reste modifiable ensuite par Ψ → Modifier → l'explication."
    explication := UIManager default
        request: 'Ψ — Explication ② de "' , label , '" (aide affichée au survol, facultative) :'
        initialAnswer: ''.

    [ typeChoix = 5
        ifTrue: [
            self psiEngine
                createSelectionField: label
                options: options
                level: niveau
                explanation: explication ]
        ifFalse: [
            typeClasses := { SRStringDescription. SRNumberDescription. SRBooleanDescription. SRDateDescription }.
            self psiEngine
                createField: label
                type: (typeClasses at: typeChoix)
                level: niveau
                explanation: explication ] ]
        on: Error
        do: [ :err | ^ self inform: 'Ψ refusé : ' , err messageText ].

    self inform:
        'Ψ : champ "' , label , '" créé.'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
AXPLFormApp >> explanationTargets [
    "Choix proposés pour modifier une explication : un niveau précis, ou
    tous les niveaux à la fois."
    ^ (AXPLFormBuilder levels collect: [ :each | each asString ]) asArray
        , #( 'Tous les niveaux' )
]

{ #category : 'psi' }
AXPLFormApp >> currentExplanationOf: aLabel forTarget: anIndex [
    "Texte proposé dans le dialogue : l'explication actuelle du niveau
    choisi, ou celle du niveau du champ pour 'Tous les niveaux'."
    | desc levels |
    desc := self psiEngine readDescription: aLabel.
    desc ifNil: [ ^ '' ].
    levels := AXPLFormBuilder levels.
    ^ desc commentFor: (anIndex <= levels size
        ifTrue: [ levels at: anIndex ]
        ifFalse: [ desc level ])
]

{ #category : 'psi' }
AXPLFormApp >> applyExplanation: aText to: aLabel forTarget: anIndex [
    "Applique l'explication via le moteur Ψ (donc tracée) au niveau
    choisi dans explanationTargets."
    | levels |
    levels := AXPLFormBuilder levels.
    anIndex <= levels size
        ifTrue: [ self psiEngine updateExplanation: aLabel forLevel: (levels at: anIndex) with: aText ]
        ifFalse: [ self psiEngine updateExplanation: aLabel with: aText ]
]

{ #category : 'psi' }
AXPLFormApp >> runPsiEditExplanation: aLabel [
    "⑤② Ψ modifie l'explication d'un champ, pour un niveau ou pour tous."
    | cibles cible texte |
    cibles := self explanationTargets.
    cible := UIManager default
        chooseFrom: cibles
        title: 'Ψ — Explication de "' , aLabel , '" pour quel niveau ?'.
    (cible isNil or: [ cible = 0 ]) ifTrue: [ ^ self ].
    texte := UIManager default
        request: 'Ψ — Explication ② de "' , aLabel , '" (' , (cibles at: cible) , ') :'
        initialAnswer: (self currentExplanationOf: aLabel forTarget: cible).
    texte ifNil: [ ^ self ].
    [ self applyExplanation: texte to: aLabel forTarget: cible ]
        on: Error
        do: [ :err | ^ self inform: 'Ψ refusé : ' , err messageText ].
    self inform:
        'Ψ : explication de "' , aLabel , '" mise à jour (' , (cibles at: cible) , ').'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
AXPLFormApp >> runPsiEditField: aLabel [
    "④⑨⑤ Ψ change le niveau, renomme ou réexplique un champ existant."
    | choix |
    choix := UIManager default
        chooseFrom: #( 'Changer le niveau' 'Modifier le label' 'Modifier l''explication' )
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
    choix = 3 ifTrue: [ self runPsiEditExplanation: aLabel ].
]

{ #category : 'psi' }
AXPLFormApp >> runPsiMenu [
    "Point d'entrée du bouton Ψ : créer, modifier ou supprimer un champ,
    ou annuler la dernière modification Ψ."
    | action |
    action := UIManager default
        chooseFrom: #( 'Créer un champ' 'Modifier un champ existant' 'Supprimer un champ' 'Annuler la dernière modification Ψ' )
        title: 'Ψ — Que voulez-vous faire ?'.
    action = 1 ifTrue: [ ^ self runPsiCreateField ].
    action = 2 ifTrue: [ ^ self runPsiSelectFieldThenDo: [ :label | self runPsiEditField: label ] ].
    action = 3 ifTrue: [ ^ self runPsiSelectFieldThenDo: [ :label | self runPsiRemoveField: label ] ].
    action = 4 ifTrue: [ ^ self runPsiUndo ].
]

{ #category : 'psi' }
AXPLFormApp >> runPsiUndo [
    "↶ Montre la modification Ψ qui va être défaite, puis l'annule."
    | change |
    self psiEngine canUndo ifFalse: [
        ^ self inform: 'Aucune modification Ψ à annuler.' ].
    (UIManager default confirm:
        'Annuler la dernière modification Ψ ?' , String cr
        , '« ' , self psiEngine lastUndoableChange , ' »')
        ifFalse: [ ^ self ].
    change := self undoLastPsiChange.
    self inform:
        'Ψ annulé : ' , change
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
]

{ #category : 'psi' }
AXPLFormApp >> undoLastPsiChange [
    "Annule la dernière intercession Ψ et redessine le formulaire au
    niveau courant. Renvoie le texte de la modification annulée."
    | change |
    change := self psiEngine undoLast.
    self updateInterface.
    ^ change
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
    l'enregistrement. Les valeurs sont déjà sur targetObject au fil de la
    saisie (cf. AXPLSpecVisitor) ; si toutes sont valides, le dossier
    (valeurs + modifications Ψ) est écrit dans un fichier STON."
    | invalides |
    self pendingErrors ifNotEmpty: [ :errors |
        ^ self inform:
            'Impossible d''enregistrer : ces champs affichent une saisie refusée'
            , ' (l''objet garde l''ancienne valeur) :'
            , String cr
            , (errors associations
                inject: ''
                into: [ :acc :each | acc , '- ' , each key , ' : ' , each value asString , String cr ]) ].
    invalides := self invalidFields.
    invalides isEmpty
        ifTrue: [ self runSaveDossier ]
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
    | level visibleDescs hidden newLayout |
    targetObject ifNil: [ ^ self ].
    level := levelDropList selectedItem.
    level ifNil: [ ^ self showNeutralState ].

    "① Filtrage adaptatif (A)"
    visibleDescs := framework visibleFieldsAt: level.

    "Titre contextuel ; les nouveaux widgets affichent les valeurs de
    l'objet, donc aucune saisie refusée en attente."
    pendingErrors := Dictionary new.
    statusLabel label: self formTitle.

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

    "⑦ Génération des widgets (L) par Spec-Form : la grille label / champ
    est dessinée par Spec-Form (pharo-spec/Spec-Form), alimentée par AXΨL."
    formPresenter := AXPLSpecFormPresenter
        on: framework
        level: level
        owner: self
        validationHandler: [ :desc :message | self validationOf: desc changedTo: message ].
    newLayout := SpBoxLayout newVertical
        spacing: 8;
        add: formPresenter expand: false;
        yourself.

    "② Champs masqués avec explication (X) — un seul bouton groupé plutôt
    qu'un par champ, pour ne pas noyer les champs visibles."
    hidden := framework hiddenFieldsAt: level.
    hidden notEmpty ifTrue: [
        newLayout add: (self newButton
            icon: (self iconNamed: #help);
            label: hidden size printString , ' champ(s) supplémentaire(s) masqué(s) — niveau supérieur requis';
            action: [ self showHiddenFieldsExplanation: hidden ])
            expand: false ].

    "On remplace la zone sous la liste des niveaux (bodyContainer layout:,
    un ObservableSlot que Spec2 reconstruit seul) au lieu d'appeler
    self update : cette reconstruction de toute la fenêtre, marquée
    obsolète par Spec2, recréait aussi la liste des niveaux — qui,
    démarrant sans sélection, effaçait alors le niveau qu'on venait de
    choisir (SpMorphicDropListAdapter>>verifyInitialStatus).
    La fenêtre prend sa taille finale AVANT la construction du nouveau
    formulaire : la zone défilante (GeneralScrollPaneMorph) étire son
    contenu (spaceFill) à la taille qu'elle a au moment de la
    construction. Construit dans la fenêtre encore haute d'Expert, le
    formulaire Simple gardait cette hauteur une fois la fenêtre réduite
    — d'où des barres de défilement en revenant à Simple, jamais en
    partant de l'écran neutre (la fenêtre y grandit au lieu de rétrécir)."
    self resizeWindowFor: visibleDescs size hiddenButtonShown: hidden notEmpty.
    formContainer := self newPresenter.
    formContainer layout: newLayout.
    bodyContainer layout: (self formBodyLayoutScrollable:
        (self desiredHeightFor: visibleDescs size hiddenButtonShown: hidden notEmpty)
            > self maxWindowHeight).
]

{ #category : 'updating' }
AXPLFormApp >> formTitle [
    ^ levelDropList selectedItem asString capitalized
        , ' Formulaire pour ' , targetObject class name
        , (currentDossierName ifNil: [ '' ] ifNotNil: [ :name | ' — ' , name ])
]

{ #category : 'accessing' }
AXPLFormApp >> pendingErrors [
    "Champs dont l'écran montre une saisie refusée : label -> message de
    SimpleRene. L'objet garde alors son ancienne valeur ; tant que ce
    dictionnaire n'est pas vide, Enregistrer refuse."
    ^ pendingErrors ifNil: [ pendingErrors := Dictionary new ]
]

{ #category : 'updating' }
AXPLFormApp >> validationOf: aDescription changedTo: messageOrNil [
    "Appelé par le visiteur à chaque saisie. En haut de la fenêtre, un
    message COURT : le message complet de SimpleRene, parfois long,
    élargissait tout le formulaire au-delà de la fenêtre. Il reste dans
    l'infobulle du champ et dans le refus d'Enregistrer. Une saisie
    corrigée retire l'erreur."
    messageOrNil
        ifNil: [ self pendingErrors removeKey: aDescription label ifAbsent: [ ] ]
        ifNotNil: [ self pendingErrors at: aDescription label put: messageOrNil ].
    statusLabel label: (messageOrNil
        ifNil: [
            self pendingErrors
                ifEmpty: [ self formTitle ]
                ifNotEmpty: [ :errors | '⚠ ' , errors size printString , ' saisie(s) refusée(s)' ] ]
        ifNotNil: [ '⚠ ' , aDescription label , ' : saisie refusée — survolez le champ' ])
]

{ #category : 'dossiers' }
AXPLFormApp >> dossiersDirectory [
    "💾 Où sont rangés les dossiers ; modifiable (tests : système de
    fichiers en mémoire)."
    ^ dossiersDirectory ifNil: [ FileLocator imageDirectory asFileReference / 'axpl-dossiers' ]
]

{ #category : 'dossiers' }
AXPLFormApp >> dossiersDirectory: aFileReference [
    dossiersDirectory := aFileReference asFileReference
]

{ #category : 'dossiers' }
AXPLFormApp >> currentDossierName [
    ^ currentDossierName
]

{ #category : 'dossiers' }
AXPLFormApp >> dossierNames [
    "Noms des dossiers enregistrés, triés."
    self dossiersDirectory exists ifFalse: [ ^ #() ].
    ^ ((self dossiersDirectory files select: [ :f | f extension = 'ston' ])
        collect: [ :f | f basenameWithoutExtension ]) asSortedCollection asArray
]

{ #category : 'dossiers' }
AXPLFormApp >> dossierFileNamed: aName [
    "Un nom simple, jamais un chemin : le dossier reste dans dossiersDirectory."
    | name |
    name := aName trimBoth.
    (name isEmpty or: [ name includesAny: '/\:' ]) ifTrue: [
        Error signal: 'Nom de dossier invalide : « ' , aName , ' » (pas de / \ : ni nom vide).' ].
    ^ self dossiersDirectory / (name , '.ston')
]

{ #category : 'dossiers' }
AXPLFormApp >> saveDossierAs: aName [
    "💾 Écrit le dossier courant et s'en souvient comme dossier ouvert."
    | file |
    file := framework saveTo: (self dossierFileNamed: aName).
    currentDossierName := file basenameWithoutExtension.
    ^ file
]

{ #category : 'dossiers' }
AXPLFormApp >> openDossier: aName [
    "💾 Remplace l'objet et le formulaire par ceux du dossier ; le niveau
    choisi est conservé et le formulaire redessiné."
    | loaded |
    loaded := AXPLFramework loadFrom: (self dossierFileNamed: aName).
    framework := loaded.
    targetObject := loaded targetObject.
    currentDossierName := aName trimBoth.
    levelDropList selectedItem
        ifNil: [ statusLabel label: 'Dossier « ' , currentDossierName , ' » ouvert — choisissez un niveau.' ]
        ifNotNil: [ self updateInterface ]
]

{ #category : 'dossiers' }
AXPLFormApp >> runSaveDossier [
    | name file |
    name := UIManager default
        request: 'Enregistrer le dossier sous le nom :'
        initialAnswer: (currentDossierName ifNil: [ targetObject class name asString ]).
    (name isNil or: [ name trimBoth isEmpty ]) ifTrue: [ ^ self ].
    ((self dossierNames includes: name trimBoth) and: [ name trimBoth ~= currentDossierName ])
        ifTrue: [
            (UIManager default confirm: 'Le dossier « ' , name trimBoth , ' » existe déjà. Le remplacer ?')
                ifFalse: [ ^ self ] ].
    file := [ self saveDossierAs: name ]
        on: Error
        do: [ :err | ^ self inform: 'Enregistrement impossible : ' , err messageText ].
    self inform: 'Enregistré : toutes les valeurs sont valides.' , String cr , file fullName
]

{ #category : 'dossiers' }
AXPLFormApp >> runOpenDossier [
    | names index |
    names := self dossierNames.
    names ifEmpty: [
        ^ self inform: 'Aucun dossier enregistré dans :' , String cr , self dossiersDirectory fullName ].
    index := UIManager default chooseFrom: names title: 'Ouvrir un dossier'.
    (index isNil or: [ index = 0 ]) ifTrue: [ ^ self ].
    [ self openDossier: (names at: index) ]
        on: Error
        do: [ :err | ^ self inform: 'Ouverture impossible : ' , err messageText ].
    self inform: 'Dossier « ' , (names at: index) , ' » ouvert.'
]
