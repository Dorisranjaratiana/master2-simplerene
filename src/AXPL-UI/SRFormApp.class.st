"
""Presenter principal du framework AXPL. Orchestre toutes les relations architecturales.
Slots principaux :
  - metaContainer : source unique de vérité, initialisé une seule fois dans targetObject:
  - psiEngine : moteur Ψ, initialisé une seule fois, garde les modifications en mémoire
  - levelDropList : sélection du niveau utilisateur (⑨)
  - psiButton : bouton Ψ visible seulement en mode Expert
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
        add: (SpScrollableLayout with: formContainer) expand: true;
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
SRFormApp >> generateForm [
    "À compléter avec la logique de génération du formulaire"
    statusLabel label: 'Formulaire généré'.

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
        display: [ :item | item asString capitalized ].
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
   actionBar visible: false.
    self update.
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
                action: [
                    | index ancienLabel currentLabels choix |
                    currentLabels := metaContainer children
                        collect: [ :d | d label ].
                    index := UIManager default
                        chooseFrom: currentLabels
                        title: 'Ψ — Choisir le champ à modifier'.
                    (index notNil and: [ index > 0 ]) ifTrue: [
                        ancienLabel := currentLabels at: index.
                        choix := UIManager default
                            chooseFrom: #( 'Changer le niveau' 'Modifier' )
                            title: 'Ψ — Que voulez-vous modifier ?'.
                        choix = 1 ifTrue: [
                            | niveauChoix niveaux nouveauNiveau |
                            niveaux := #( 'simple' 'base' 'expert' ).
                            niveauChoix := UIManager default
                                chooseFrom: niveaux
                                title: 'Ψ — Nouveau niveau pour "' , ancienLabel , '"'.
                            (niveauChoix notNil and: [ niveauChoix > 0 ]) ifTrue: [
                                nouveauNiveau := (niveaux at: niveauChoix) asSymbol.
                                psiEngine setLevel: nouveauNiveau ofDescription: ancienLabel.
                                self inform:
                                    'Ψ appliqué : "' , ancienLabel
                                    , '" → niveau #' , nouveauNiveau
                                    , String cr
                                    , 'Horodatage : ' , DateAndTime now printString.
                                self updateInterface ] ].
                        choix = 2 ifTrue: [
                            | nouveauLabel |
                            nouveauLabel := UIManager default
                                request: 'Nouveau label pour "' , ancienLabel , '" :'
                                initialAnswer: ancienLabel.
                            (nouveauLabel notNil and: [ nouveauLabel notEmpty ]) ifTrue: [
                                psiEngine relabelDescription: ancienLabel to: nouveauLabel.
                                self inform:
                                    'Ψ : "' , ancienLabel , '" → "' , nouveauLabel , '".'
                                    , String cr
                                    , 'Horodatage : ' , DateAndTime now printString.
                                self updateInterface ] ] ] ] ]
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
