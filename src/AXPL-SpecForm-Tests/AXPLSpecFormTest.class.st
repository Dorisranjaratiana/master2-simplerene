"
Essai de réutilisation de Spec-Form (pharo-spec/Spec-Form) pour dessiner
les formulaires AXΨL : Spec-Form se charge avec Pharo 13 et la version de
SimpleRene épinglée par AXΨL, et respecte le niveau ①, l'explicabilité ②,
les champs Ψ et la validation de SimpleRene. Aucune fenêtre n'est ouverte.
"
Class {
	#name : 'AXPLSpecFormTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'framework'
	],
	#category : 'AXPL-SpecForm-Tests',
	#package : 'AXPL-SpecForm-Tests'
}

{ #category : 'running' }
AXPLSpecFormTest >> setUp [
	super setUp.
	client := ClientHopital new.
	framework := AXPLFramework for: client
]

{ #category : 'private' }
AXPLSpecFormTest >> widgetsOf: aPresenter [
	"La grille alterne label (String) et widget."
	^ aPresenter layout presenters reject: [ :each | each isString ]
]

{ #category : 'tests' }
AXPLSpecFormTest >> testUnLabelEtUnWidgetParChampVisible [
	AXPLFormBuilder levels do: [ :lvl |
		| presenter |
		presenter := framework specFormPresenterAt: lvl.
		self
			assert: presenter layout presenters size
			equals: 2 * (framework visibleFieldsAt: lvl) size ]
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLesLabelsMarquentLesChampsRequis [
	| labels |
	labels := (framework specFormPresenterAt: #simple) layout presenters select: [ :each | each isString ].
	self assert: (labels includes: 'Nom *').
	self assert: (labels includes: 'Urgent').
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLAideEstLExplicationDuNiveau [
	"② Spec-Form seul afficherait le #comment de SimpleRene (vide ici)."
	| nom |
	nom := framework psiEngine readDescription: 'Nom'.
	#( #simple #expert ) do: [ :lvl |
		| widgets |
		widgets := self widgetsOf: (framework specFormPresenterAt: lvl).
		self assert: (widgets anySatisfy: [ :w | w help = (nom commentFor: lvl) ]) ]
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLeChampDateEstAffiche [
	"Spec-Form n'a pas de visitDateDescription: : sans AXPLSpecFormBuilder,
	« Date d'Admission » disparaissait du formulaire."
	self assert: ((self widgetsOf: (framework specFormPresenterAt: #base))
		anySatisfy: [ :w | w isKindOf: SpDatePresenter ]).
]

{ #category : 'tests' }
AXPLSpecFormTest >> testUnChampCreeParPsiApparait [
	| avant |
	avant := (framework specFormPresenterAt: #simple) layout presenters size.
	framework psiEngine
		createField: 'Note interne'
		type: SRStringDescription
		level: #simple
		explanation: 'Remarque libre.'.
	self assert: (framework specFormPresenterAt: #simple) layout presenters size equals: avant + 2.
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLaSaisieNestEcriteQuApresValidation [
	"Le memento de SimpleRene garde la saisie ; save valide puis écrit."
	| presenter memento nom prenom age |
	presenter := framework specFormPresenterAt: #simple.
	memento := presenter memento.
	nom := framework psiEngine readDescription: 'Nom'.
	prenom := framework psiEngine readDescription: 'Prénom'.
	age := framework psiEngine readDescription: 'Âge'.
	memento simpleReneWrite: 'Ranjaratiana' using: nom.
	memento simpleReneWrite: 'Doris' using: prenom.
	memento simpleReneWrite: -5 using: age.
	self assert: client nom equals: ''.
	self assert: presenter save notNil.
	self assert: client nom equals: ''.
	memento simpleReneWrite: 30 using: age.
	self assert: presenter save isNil.
	self assert: client nom equals: 'Ranjaratiana'.
	self assert: client age equals: 30.
]
