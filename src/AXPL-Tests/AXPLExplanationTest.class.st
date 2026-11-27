"
Tests du décorateur d'explicabilité ② AXPLExplanation : les explications
vivent dans les propriétés de la description (propertyAt: #axplExplanation),
le #comment de SimpleRene reste une String d'aide (son contrat, celui
qu'affiche Spec-Form) et sert de repli ; l'ancien format (Dictionary dans
#comment) reste lu.
"
Class {
	#name : 'AXPLExplanationTest',
	#superclass : 'TestCase',
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'tests' }
AXPLExplanationTest >> testLesExemplesNeDetournentPlusLeCommentDeSimpleRene [
    "Régression (remarque de S. Ducasse, 8 avril) : les explications par
    niveau étaient rangées dans #comment sous forme de Dictionary."
    { ClientHopital. Etudiant } do: [ :class |
        class descriptionForAXPL children do: [ :desc |
            self assert: (desc comment isNil or: [ desc comment isString ]).
            self assert: (desc hasProperty: #axplExplanation) ] ].
]

{ #category : 'tests' }
AXPLExplanationTest >> testExplicationParNiveau [
    | desc |
    desc := SRStringDescription new
        explanation: (Dictionary new at: #simple put: 'Simple.'; at: #expert put: 'Expert.'; yourself);
        yourself.
    self assert: (desc commentFor: #simple) equals: 'Simple.'.
    self assert: (desc commentFor: #expert) equals: 'Expert.'.
    self assert: (desc commentFor: #base) equals: ''.
    self assert: desc comment isNil.
]

{ #category : 'tests' }
AXPLExplanationTest >> testExplicationCommune [
    | desc |
    desc := SRStringDescription new explanation: 'Pour tous.'; yourself.
    AXPLFormBuilder levels do: [ :lvl |
        self assert: (desc commentFor: lvl) equals: 'Pour tous.' ].
]

{ #category : 'tests' }
AXPLExplanationTest >> testLeTexteDuNiveauPrimeSurLeTexteCommun [
    | desc |
    desc := SRStringDescription new explanation: 'Pour tous.'; yourself.
    desc explanation text: 'Pour les experts.' forLevel: #expert.
    self assert: (desc commentFor: #expert) equals: 'Pour les experts.'.
    self assert: (desc commentFor: #simple) equals: 'Pour tous.'.
    desc explanation beCommon: 'Nouveau texte commun.'.
    self assert: (desc commentFor: #expert) equals: 'Nouveau texte commun.'.
]

{ #category : 'tests' }
AXPLExplanationTest >> testLeCommentDeSimpleReneSertDeRepli [
    "Une description SimpleRene ordinaire garde son aide à tous les niveaux."
    | desc |
    desc := SRStringDescription new comment: 'Aide SimpleRene.'; yourself.
    self assert: (desc commentFor: #expert) equals: 'Aide SimpleRene.'.
    self deny: (desc hasProperty: #axplExplanation).
]

{ #category : 'tests' }
AXPLExplanationTest >> testAncienFormatToujoursLu [
    "Compatibilité avec AXPL v1 : Dictionary rangé dans #comment."
    | desc |
    desc := SRStringDescription new
        comment: (Dictionary new at: #simple put: 'Ancien.'; yourself);
        yourself.
    self assert: (desc commentFor: #simple) equals: 'Ancien.'.
    desc explanation text: 'Nouveau.' forLevel: #expert.
    self assert: (desc commentFor: #simple) equals: 'Ancien.'.
    self assert: (desc commentFor: #expert) equals: 'Nouveau.'.
]

{ #category : 'tests' }
AXPLExplanationTest >> testPsiNeToucheJamaisAuCommentDeSimpleRene [
    | container engine desc |
    container := SRPriorityContainer new.
    container add: (SRStringDescription new label: 'Libre'; comment: 'Aide SimpleRene.'; yourself).
    engine := AXPLReflexivityEngine new metaContainer: container; yourself.
    engine updateExplanation: 'Libre' forLevel: #expert with: 'Aide experte.'.
    desc := engine readDescription: 'Libre'.
    self assert: desc comment equals: 'Aide SimpleRene.'.
    self assert: (desc commentFor: #expert) equals: 'Aide experte.'.
    self assert: (desc commentFor: #simple) equals: 'Aide SimpleRene.'.
    "↶ : sans décorateur avant, l'annulation le retire complètement."
    engine undoLast.
    self deny: (desc hasProperty: #axplExplanation).
    self assert: (desc commentFor: #expert) equals: 'Aide SimpleRene.'.
]

{ #category : 'tests' }
AXPLExplanationTest >> testOrigineDuChamp [
    "Le décorateur dit si le champ a été déclaré ou créé par Ψ."
    | container engine |
    container := ClientHopital descriptionForAXPL.
    engine := AXPLReflexivityEngine new metaContainer: container; yourself.
    engine createField: 'Note interne' type: SRStringDescription level: #base.
    self assert: (engine readDescription: 'Note interne') explanation isPsiCreated.
    self deny: (engine readDescription: 'Nom') explanation isPsiCreated.
]

{ #category : 'tests' }
AXPLExplanationTest >> testUneCopieEstIndependante [
    | original copie |
    original := AXPLExplanation common: 'Commun.'.
    original text: 'A' forLevel: #simple.
    copie := original copy.
    copie text: 'B' forLevel: #simple.
    self assert: (original textFor: #simple) equals: 'A'.
    self assert: (copie textFor: #simple) equals: 'B'.
]

{ #category : 'tests' }
AXPLExplanationTest >> testTexteVideEquivautAAucunTexte [
    self assert: (AXPLExplanation common: '') isEmpty.
    self assert: (AXPLExplanation common: nil) isEmpty.
    self deny: (AXPLExplanation common: 'x') isEmpty.
]
