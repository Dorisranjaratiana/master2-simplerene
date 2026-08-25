"
""Presenter principal du framework AXPL. Orchestre toutes les relations architecturales.
Slots principaux :
  - metaContainer : source unique de vérité, initialisé une seule fois dans targetObject:
  - psiEngine : moteur Ψ, initialisé une seule fois, garde les modifications en mémoire
  - levelDropList : sélection du niveau utilisateur (⑨)
  - psiButton : bouton Ψ visible seulement en mode Expert — ouvre runPsiMenu
    (créer ⑥ / modifier ④⑨ / supprimer ⑥ un champ)
  - traceButton : affiche le log horodaté [t] en mode Expert
updateInterface : méthode centrale qui orchestre ①②⑦⑧⑨⑩.
targetObject: : point d'entrée — initialise metaContainer et psiEngine puis déclenche le rendu.""
"
Class {
	#name : 'SRFormApp',
	#superclass : 'SpPresenter',
	#instVars : [
		'levelDropList',
		'generateButton',
		'formContainer',
		'statusLabel',
		'targetObject',
		'actionBar',
		'psiButton',
		'metaContainer',
		'psiEngine',
		'traceButton'
	],
	#category : 'AXPL-UI',
	#package : 'AXPL-UI'
}

{ #category : 'accessing' }
SRFormApp >> actionBar [

	^ actionBar
]

{ #category : 'accessing' }
SRFormApp >> actionBar: anObject [

	actionBar := anObject
]

{ #category : 'layout' }
SRFormApp >> defaultLayout [
    ^ SpBoxLayout newTopToBottom
        spacing: 10;
        borderWidth: 15;
        add: statusLabel expand: false;
        add: (SpBoxLayout newHorizontal
            spacing: 8;
            add: (self newLabel label: 'Niveau:') expand: false;
            add: levelDropList expand: true;
            yourself) expand: false;
        add: generateButton expand: false;
        add: formContainer expand: true;
        add: actionBar expand: false;
        yourself
]

{ #category : 'accessing' }
SRFormApp >> formContainer [

	^ formContainer
]

{ #category : 'accessing' }
SRFormApp >> formContainer: anObject [

	formContainer := anObject
]

{ #category : 'accessing' }
SRFormApp >> generateButton [

	^ generateButton
]

{ #category : 'accessing' }
SRFormApp >> generateButton: anObject [

	generateButton := anObject
]

{ #category : 'initialization' }
SRFormApp >> initialize [
    super initialize.
    targetObject := nil.
]

{ #category : 'initialization' }
SRFormApp >> initializePresenters [
    statusLabel := self newLabel label: 'Prêt'.
    levelDropList := self newDropList
        items: #( #simple #base #expert );
        display: [ :item | item asString capitalized ];
        whenSelectedItemChangedDo: [ :item | self updateInterface ].
    generateButton := self newButton
        label: 'Générer';
        icon: (self iconNamed: #refresh);
        action: [ self updateInterface ].
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
            action: [ self inform: 'Enregistré !' ];
            yourself) expand: true;
        yourself).
 actionBar visible: false.
]

{ #category : 'initialization' }
SRFormApp >> initializeWindow: aWindowPresenter [
    super initializeWindow: aWindowPresenter.
    aWindowPresenter
        title: 'Framework {A,X,Ψ,L}';
        initialExtent: 500 @ 950.
]

{ #category : 'accessing' }
SRFormApp >> levelDropList [

	^ levelDropList
]

{ #category : 'accessing' }
SRFormApp >> levelDropList: anObject [

	levelDropList := anObject
]

{ #category : 'accessing' }
SRFormApp >> metaContainer [

	^ metaContainer
]

{ #category : 'accessing' }
SRFormApp >> metaContainer: anObject [

	metaContainer := anObject
]

{ #category : 'accessing' }
SRFormApp >> psiButton [

	^ psiButton
]

{ #category : 'accessing' }
SRFormApp >> psiButton: anObject [

	psiButton := anObject
]

{ #category : 'accessing' }
SRFormApp >> psiEngine [

	^ psiEngine
]

{ #category : 'accessing' }
SRFormApp >> psiEngine: anObject [

	psiEngine := anObject
]

{ #category : 'initialization' }
SRFormApp >> resetInterface [
    metaContainer := targetObject class descriptionForAXPL.
    psiEngine := AXPLReflexivityEngine new
        metaContainer: metaContainer;
        yourself.
    formContainer layout: SpBoxLayout newVertical.
    statusLabel label: 'Sélectionnez un niveau et cliquez sur Générer.'.
    levelDropList selectIndex: 1.
    actionBar visible: false.
    self update.
]

{ #category : 'psi' }
SRFormApp >> runPsiCreateField [
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

    niveaux := #( 'simple' 'base' 'expert' ).
    niveauChoix := UIManager default
        chooseFrom: niveaux
        title: 'Ψ — Niveau du nouveau champ "' , label , '"'.
    (niveauChoix isNil or: [ niveauChoix = 0 ]) ifTrue: [ ^ self ].
    niveau := (niveaux at: niveauChoix) asSymbol.

    typeChoix = 5
        ifTrue: [
            | optionsText options |
            optionsText := UIManager default
                request: 'Ψ — Options séparées par des virgules :'
                initialAnswer: ''.
            (optionsText isNil or: [ optionsText isEmpty ]) ifTrue: [ ^ self ].
            options := ((optionsText tokenize: ',') collect: [ :each | each trimSeparators ]) asArray.
            psiEngine createSelectionField: label options: options level: niveau ]
        ifFalse: [
            typeClasses := { SRStringDescription. SRNumberDescription. SRBooleanDescription. SRDateDescription }.
            psiEngine createField: label type: (typeClasses at: typeChoix) level: niveau ].

    self inform:
        'Ψ : champ "' , label , '" créé.'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
SRFormApp >> runPsiEditField: aLabel [
    "④⑨ Ψ change le niveau ou renomme un champ existant."
    | choix |
    choix := UIManager default
        chooseFrom: #( 'Changer le niveau' 'Modifier le label' )
        title: 'Ψ — Que voulez-vous modifier sur "' , aLabel , '" ?'.
    choix = 1 ifTrue: [
        | niveauChoix niveaux nouveauNiveau |
        niveaux := #( 'simple' 'base' 'expert' ).
        niveauChoix := UIManager default
            chooseFrom: niveaux
            title: 'Ψ — Nouveau niveau pour "' , aLabel , '"'.
        (niveauChoix notNil and: [ niveauChoix > 0 ]) ifTrue: [
            nouveauNiveau := (niveaux at: niveauChoix) asSymbol.
            (UIManager default confirm:
                'Changer le niveau de "' , aLabel , '" en #' , nouveauNiveau , ' ?')
                ifTrue: [
                    psiEngine setLevel: nouveauNiveau ofDescription: aLabel.
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
                    psiEngine relabelDescription: aLabel to: nouveauLabel.
                    self inform:
                        'Ψ : "' , aLabel , '" → "' , nouveauLabel , '".'
                        , String cr
                        , 'Horodatage : ' , DateAndTime now printString.
                    self updateInterface ] ] ].
]

{ #category : 'psi' }
SRFormApp >> runPsiMenu [
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
SRFormApp >> runPsiRemoveField: aLabel [
    "⑥ Ψ retire un champ entier du metaContainer."
    (UIManager default confirm: 'Supprimer le champ "' , aLabel , '" ?')
        ifFalse: [ ^ self ].
    psiEngine removeField: aLabel.
    self inform:
        'Ψ : champ "' , aLabel , '" supprimé.'
        , String cr
        , 'Horodatage : ' , DateAndTime now printString.
    self updateInterface.
]

{ #category : 'psi' }
SRFormApp >> runPsiSelectFieldThenDo: aBlock [
    "Demande à l'utilisateur de choisir un champ existant, puis exécute
    aBlock avec son label. Ne fait rien si l'utilisateur annule."
    | currentLabels index |
    currentLabels := metaContainer children collect: [ :d | d label ].
    index := UIManager default
        chooseFrom: currentLabels
        title: 'Ψ — Choisir le champ'.
    (index notNil and: [ index > 0 ])
        ifTrue: [ aBlock value: (currentLabels at: index) ].
]

{ #category : 'accessing' }
SRFormApp >> showTrace [
    | log text |
    log := psiEngine traceLog.
    log isEmpty
        ifTrue: [ self inform: 'Aucune intercession enregistrée.' ]
        ifFalse: [
            text := log inject: '' into: [ :acc :each |
                acc , each key printString , ' — ' , each value , String cr ].
            self inform: text ]
]

{ #category : 'accessing' }
SRFormApp >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
SRFormApp >> statusLabel: anObject [

	statusLabel := anObject
]

{ #category : 'accessing' }
SRFormApp >> targetObject [
	^ targetObject
]

{ #category : 'accessing' }
SRFormApp >> targetObject: anObject [
    targetObject := anObject.
    metaContainer := targetObject class descriptionForAXPL.
    psiEngine := AXPLReflexivityEngine new
        metaContainer: metaContainer;
        yourself.
]

{ #category : 'accessing' }
SRFormApp >> traceButton [

	^ traceButton
]

{ #category : 'accessing' }
SRFormApp >> traceButton: anObject [

	traceButton := anObject
]

{ #category : 'updating' }
SRFormApp >> updateInterface [
    | builder visibleDescs hidden visitor newLayout |
    targetObject ifNil: [ ^ self ].

    "① Filtrage adaptatif (A)"
    builder := AXPLFormBuilder new
        targetObject: targetObject;
        userLevel: levelDropList selectedItem;
        metaContainer: metaContainer;
        yourself.
    visibleDescs := builder build.

    "Titre contextuel"
    statusLabel label: levelDropList selectedItem asString capitalized
        , ' Formulaire pour ' , targetObject class name.

    "Ψ — visible seulement en expert"
    levelDropList selectedItem = #expert
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
    visitor := AXPLSpecVisitor new
        targetObject: targetObject;
        presenter: self.
    newLayout := visitor visit: visibleDescs.

    "② Champs masqués avec explication (X)"
    hidden := metaContainer children
        reject: [ :d | builder canUserSee: d ].
    hidden do: [ :d |
        | expl |
        expl := d commentFor: levelDropList selectedItem.
        newLayout add: (self newButton
            icon: (self iconNamed: #help);
            label: d label , ' (masqué)';
            action: [ self inform: (expl ifNil: [ 'Accès restreint.' ]) ])
            expand: false ].

    formContainer layout: newLayout.
    actionBar visible: true.
    self update.
]
