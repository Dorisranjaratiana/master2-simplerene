"
Tests de la hiérarchie de contextes (objectif 2 de S. Ducasse) :
AXPLContext et ses sous-classes AXPLLevelContext, AXPLRequiredOnlyContext,
AXPLCompositeContext — quels champs chacun montre, et pourquoi il masque
les autres (②).
"
Class {
	#name : 'AXPLContextTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'framework'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLContextTest >> setUp [
	super setUp.
	client := ClientHopital new.
	framework := AXPLFramework for: client
]

{ #category : 'private' }
AXPLContextTest >> labelsIn: aContext [
	^ ((framework visibleFieldsIn: aContext) collect: [ :d | d label ]) asArray
]

{ #category : 'tests' }
AXPLContextTest >> testHierarchie [
	self assert: AXPLContext isAbstract.
	{ AXPLLevelContext. AXPLRequiredOnlyContext. AXPLCompositeContext } do: [ :each |
		self assert: (each inheritsFrom: AXPLContext).
		self deny: each isAbstract ]
]

{ #category : 'tests' }
AXPLContextTest >> testLeContexteDeNiveauEstLeFiltrageHistorique [
	"Rien ne change pour les niveaux : même résultat que visibleFieldsAt:."
	AXPLFormBuilder levels do: [ :lvl |
		self
			assert: (self labelsIn: (AXPLContext level: lvl))
			equals: ((framework visibleFieldsAt: lvl) collect: [ :d | d label ]) asArray ]
]

{ #category : 'tests' }
AXPLContextTest >> testNiveauInconnuRefuse [
	self should: [ AXPLContext level: #inconnu ] raise: Error
]

{ #category : 'tests' }
AXPLContextTest >> testObligatoiresSeulementEnleveLesChampsOptionnels [
	"L'exemple de S. Ducasse : un contexte enlève les descriptions optionnelles."
	| context |
	context := AXPLContext requiredOnly.
	self assert: ((framework visibleFieldsIn: context) allSatisfy: [ :d | d isRequired ]).
	self assert: ((framework hiddenFieldsIn: context) allSatisfy: [ :d | d isRequired not ]).
	self assert: ((self labelsIn: context) includes: 'Nom').
	self deny: ((self labelsIn: context) includes: 'Sexe').
]

{ #category : 'tests' }
AXPLContextTest >> testCompositionDeContextes [
	"Simple + obligatoires seulement : les champs obligatoires du niveau Simple."
	| context attendu |
	context := (AXPLContext level: #simple) & AXPLContext requiredOnly.
	self assert: (context isKindOf: AXPLCompositeContext).
	attendu := ((framework visibleFieldsAt: #simple) select: [ :d | d isRequired ])
		collect: [ :d | d label ].
	self assert: (self labelsIn: context) equals: attendu asArray.
	self assert: context explanationLevel equals: #simple.
	self assert: context label equals: 'Niveau Simple + Champs obligatoires seulement'.
]

{ #category : 'tests' }
AXPLContextTest >> testUneCompositionSeCompose [
	| context |
	context := (AXPLContext level: #expert) & AXPLContext requiredOnly & (AXPLContext level: #simple).
	self assert: context contexts size equals: 3.
	self
		assert: (self labelsIn: context)
		equals: (self labelsIn: (AXPLContext level: #simple) & AXPLContext requiredOnly).
]

{ #category : 'tests' }
AXPLContextTest >> testChaqueContexteDitPourquoiIlMasque [
	"② La raison donnée est celle du contexte qui masque le champ."
	| allergies sexe context |
	allergies := framework psiEngine readDescription: 'Allergies'.
	sexe := framework psiEngine readDescription: 'Sexe'.
	self
		assert: ((AXPLContext level: #simple) reasonForHiding: allergies)
		equals: 'visible à partir du niveau Expert'.
	self assert: ((AXPLContext requiredOnly reasonForHiding: sexe) includesSubstring: 'facultatif').
	context := (AXPLContext level: #simple) & AXPLContext requiredOnly.
	self assert: (context reasonForHiding: allergies) equals: 'visible à partir du niveau Expert'.
	self assert: ((context reasonForHiding: sexe) includesSubstring: 'facultatif').
]

{ #category : 'tests' }
AXPLContextTest >> testLesChampsPsiSuiventLesContextes [
	"Un champ créé par Ψ est filtré comme les autres (ici : facultatif)."
	framework psiEngine createField: 'Note interne' type: SRStringDescription level: #simple.
	self assert: ((self labelsIn: (AXPLContext level: #simple)) includes: 'Note interne').
	self deny: ((self labelsIn: (AXPLContext level: #simple) & AXPLContext requiredOnly) includes: 'Note interne').
]

{ #category : 'tests' }
AXPLContextTest >> testUnNouveauContexteSansToucherAuFramework [
	"Extensibilité : un contexte écrit à la volée (ici les champs Date)
	fonctionne sans modifier AXΨL."
	| context |
	context := AXPLContextDatesOnly new.
	self assert: (self labelsIn: context) equals: #( 'Date d''Admission' ).
	self assert: ((framework hiddenFieldsIn: context) size) equals: framework metaContainer children size - 1.
]
