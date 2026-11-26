"
Tests de la fenêtre AXPLFormApp sans l'ouvrir. Couvre ce qui n'avait
aucun test jusqu'ici et où se cachaient de vrais plantages (parsing des
options d'un champ Choix créé par Ψ) : rendu par niveau, accès Ψ réservé
au niveau le plus privilégié, Annuler, validation à l'enregistrement,
explication des champs masqués. Les dialogues (UIManager) ne sont pas
testés ; la logique qu'ils utilisent en est extraite et testée ici.
"
Class {
	#name : 'AXPLFormAppTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'app'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLFormAppTest >> setUp [
    super setUp.
    client := ClientHopital new.
    app := AXPLFormApp new.
    app targetObject: client.
]

{ #category : 'tests' }
AXPLFormAppTest >> testRenduParNiveau [
    "Un élément par champ visible, plus un bouton groupé s'il reste des
    champs masqués ; Ψ et la trace seulement au niveau le plus privilégié."
    | framework |
    framework := AXPLFramework for: client.
    AXPLFormBuilder levels do: [ :lvl |
        | visible hidden |
        app levelDropList selectItem: lvl.
        app updateInterface.
        visible := framework visibleFieldsAt: lvl.
        hidden := framework hiddenFieldsAt: lvl.
        self
            assert: app formContainer layout presenters size
            equals: visible size + (hidden isEmpty ifTrue: [ 0 ] ifFalse: [ 1 ]).
        self
            assert: app psiButton isEnabled
            equals: lvl = AXPLFormBuilder mostPrivilegedLevel ].
]

{ #category : 'tests' }
AXPLFormAppTest >> testAnnulerRepartDUnObjetEtDUnMoteurNeufs [
    | ancienMeta |
    client nom: 'Ranjaratiana'.
    ancienMeta := app metaContainer.
    app psiEngine createField: 'Note interne' type: SRStringDescription level: #expert.
    app resetInterface.
    self deny: app targetObject == client.
    self assert: app targetObject nom equals: ''.
    self deny: app metaContainer == ancienMeta.
    self assert: (app psiEngine readDescription: 'Note interne') isNil.
]

{ #category : 'tests' }
AXPLFormAppTest >> testChampsInvalidesAvantEnregistrement [
    client age: -5.
    self assert: (app invalidFields anySatisfy: [ :d | d label = 'Âge' ]).
    client age: 30.
    self deny: (app invalidFields anySatisfy: [ :d | d label = 'Âge' ]).
]

{ #category : 'tests' }
AXPLFormAppTest >> testParseOptionsDUnChampChoix [
    "Régression : utilisait tokenize:/trimSeparators, absents de Pharo 13
    — créer un champ Choix depuis le menu Ψ plantait."
    self assert: (app parseOptions: ' A, B ,AB,  O ') equals: #('A' 'B' 'AB' 'O').
    self assert: (app parseOptions: 'A, , B') equals: #('A' 'B').
]

{ #category : 'tests' }
AXPLFormAppTest >> testExplicationDesChampsMasquesDonneLeNiveauRequis [
    "② Dire pourquoi un champ est masqué = dire quel niveau le débloque."
    | hidden text |
    app levelDropList selectItem: #simple.
    hidden := (AXPLFramework for: client) hiddenFieldsAt: #simple.
    text := app hiddenFieldsExplanationText: hidden.
    self assert: (text includesSubstring: 'Allergies — visible à partir du niveau Expert').
    self assert: (text includesSubstring: 'Médecin Référent — visible à partir du niveau Base').
]

{ #category : 'tests' }
AXPLFormAppTest >> testHauteurSouhaiteeSuitLeNombreDeChamps [
    self assert: (app desiredHeightFor: 5 hiddenButtonShown: true)
        < (app desiredHeightFor: 11 hiddenButtonShown: true).
    self assert: (app desiredHeightFor: 5 hiddenButtonShown: true) equals: 353.
    self assert: (app desiredHeightFor: 0 hiddenButtonShown: false) equals: 300.
]

{ #category : 'tests' }
AXPLFormAppTest >> testFenetreJamaisPlusHauteQueLEcran [
    "Régression : en Expert, la barre Annuler / Ψ / Trace / Enregistrer
    passait sous le bord de l'écran."
    app currentWorld ifNotNil: [ :world |
        self assert: app maxWindowHeight < world height ].
]

{ #category : 'tests' }
AXPLFormAppTest >> testLaFenetreOuverteSAdapteAuNiveau [
    "Régression : resizeWindowFor: appelait SpPresenter >> extent:, qui ne
    fait que mémoriser une valeur — la fenêtre ouverte gardait la même
    taille en Simple, Base et Expert. Ce test ouvre une vraie fenêtre et
    vérifie, à chaque niveau, que sa hauteur réelle est celle attendue :
    la hauteur calculée pour ses champs, plafonnée à l'écran. Il ne
    suppose pas de taille d'écran (celui de la CI fait 240@120)."
    | window framework |
    framework := AXPLFramework for: client.
    window := app open.
    [ AXPLFormBuilder levels do: [ :lvl |
            | expected actual |
            app levelDropList selectItem: lvl.
            app updateInterface.
            expected := (app
                desiredHeightFor: (framework visibleFieldsAt: lvl) size
                hiddenButtonShown: (framework hiddenFieldsAt: lvl) notEmpty)
                    min: app maxWindowHeight.
            actual := window adapter widget height.
            self
                assert: actual = expected
                description: lvl asString , ' : hauteur ' , actual printString , ', attendu '
                    , expected printString , ' (écran ' , app currentWorld extent printString , ')' ] ]
        ensure: [ window close ].
]

{ #category : 'tests' }
AXPLFormAppTest >> testEtatInitialNeutre [
    "À l'ouverture : aucun niveau choisi, aucun formulaire, aucun bouton."
    self assert: app levelDropList selectedItem isNil.
    self assert: app formContainer layout presenters isEmpty.
    self deny: (app bodyContainer layout presenters includes: app actionBar).
]

{ #category : 'tests' }
AXPLFormAppTest >> testChoisirUnNiveauAfficheDirectementLeFormulaire [
    "Plus de bouton Rafraîchir : la sélection suffit."
    app levelDropList selectItem: #base.
    self
        assert: app formContainer layout presenters size
        equals: ((AXPLFramework for: client) visibleFieldsAt: #base) size + 1.
    self assert: (app bodyContainer layout presenters includes: app actionBar).
]

{ #category : 'tests' }
AXPLFormAppTest >> testAnnulerDepuisExpertRevientALEcranNeutre [
    "Régression : depuis Base/Expert, Annuler remettait la liste sur Simple,
    ce qui relançait le rendu de Simple dans une fenêtre réduite."
    app levelDropList selectItem: #expert.
    app resetInterface.
    self assert: app levelDropList selectedItem isNil.
    self assert: app formContainer layout presenters isEmpty.
    self deny: (app bodyContainer layout presenters includes: app actionBar).
]

{ #category : 'tests' }
AXPLFormAppTest >> testRevenirDExpertASimpleRepartDUnFormulaireNeuf [
    "Régression : le conteneur du formulaire était réutilisé d'un niveau
    à l'autre ; son widget gardait la taille du formulaire Expert, et
    Simple s'affichait avec des barres de défilement inutiles."
    | conteneurExpert |
    app levelDropList selectItem: #expert.
    conteneurExpert := app formContainer.
    app levelDropList selectItem: #simple.
    self deny: app formContainer == conteneurExpert.
    self
        assert: app formContainer layout presenters size
        equals: ((AXPLFramework for: client) visibleFieldsAt: #simple) size + 1.
]

{ #category : 'tests' }
AXPLFormAppTest >> testZoneDefilanteSeulementSiLeFormulaireDepasseLEcran [
    "Sans défilement nécessaire, le formulaire est posé directement : la
    zone défilante de Morphic affichait sinon une barre verticale même
    quand tout tenait."
    self assert: ((app formBodyLayoutScrollable: false) presenters includes: app formContainer).
    self deny: ((app formBodyLayoutScrollable: true) presenters includes: app formContainer).
]

{ #category : 'tests' }
AXPLFormAppTest >> testSaisieRefuseeBloqueLEnregistrement [
    "L'écran ne doit pas pouvoir être enregistré tant qu'il affiche une
    valeur que l'objet n'a pas."
    | ageInput |
    app levelDropList selectItem: #simple.
    ageInput := (app formContainer layout presenters at: 3) presenters last.
    ageInput number: -5.
    self assert: (app pendingErrors includesKey: 'Âge').
    self assert: (app statusLabel label includesSubstring: '⚠').
    ageInput number: 30.
    self assert: app pendingErrors isEmpty.
    self assert: app statusLabel label equals: app formTitle.
]

{ #category : 'tests' }
AXPLFormAppTest >> testCiblesDExplication [
    "Ψ → Modifier → l'explication : un niveau précis, ou tous à la fois."
    self
        assert: app explanationTargets
        equals: (AXPLFormBuilder levels collect: [ :each | each asString ]) asArray , #( 'Tous les niveaux' ).
]

{ #category : 'tests' }
AXPLFormAppTest >> testModifierLExplicationDUnNiveauDepuisLaFenetre [
    | desc simpleAvant expert |
    desc := app psiEngine readDescription: 'Nom'.
    simpleAvant := desc commentFor: #simple.
    expert := AXPLFormBuilder levels indexOf: #expert.
    self assert: (app currentExplanationOf: 'Nom' forTarget: expert) equals: (desc commentFor: #expert).
    app applyExplanation: 'Nom de naissance.' to: 'Nom' forTarget: expert.
    self assert: (desc commentFor: #expert) equals: 'Nom de naissance.'.
    self assert: (desc commentFor: #simple) equals: simpleAvant.
    self assert: (app psiEngine traceLog last value includesSubstring: 'Explication').
]

{ #category : 'tests' }
AXPLFormAppTest >> testModifierLExplicationPourTousLesNiveauxDepuisLaFenetre [
    | desc tous |
    desc := app psiEngine readDescription: 'Nom'.
    tous := app explanationTargets size.
    self assert: (app currentExplanationOf: 'Nom' forTarget: tous) equals: (desc commentFor: desc level).
    app applyExplanation: 'Nom de famille.' to: 'Nom' forTarget: tous.
    AXPLFormBuilder levels do: [ :lvl |
        self assert: (desc commentFor: lvl) equals: 'Nom de famille.' ].
]
