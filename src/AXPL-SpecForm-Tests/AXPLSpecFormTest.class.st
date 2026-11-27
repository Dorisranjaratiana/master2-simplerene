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
	"La grille alterne label (SpLabelPresenter) et widget."
	^ aPresenter layout presenters reject: [ :each | each isKindOf: SpLabelPresenter ]
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
	labels := ((framework specFormPresenterAt: #simple) layout presenters
		select: [ :each | each isKindOf: SpLabelPresenter ])
			collect: [ :each | each label ].
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
AXPLSpecFormTest >> testChaqueSaisieEstValideeAvantDEtreEcrite [
	"Une valeur refusée par SimpleRene n'est pas écrite : l'infobulle du
	champ l'indique et l'application est prévenue ; une valeur correcte
	est écrite tout de suite et l'explication revient."
	| refus presenter ageInput age |
	refus := Dictionary new.
	presenter := AXPLSpecFormPresenter
		on: framework
		level: #simple
		owner: nil
		validationHandler: [ :desc :message | refus at: desc label put: message ].
	age := framework psiEngine readDescription: 'Âge'.
	ageInput := presenter widgetFor: 'Âge'.
	ageInput number: -5.
	self assert: client age equals: 0.
	self assert: (refus at: 'Âge') notNil.
	self assert: (ageInput help beginsWith: '⚠').
	ageInput number: 30.
	self assert: client age equals: 30.
	self assert: (refus at: 'Âge') isNil.
	self assert: ageInput help equals: (age commentFor: #simple).
]

{ #category : 'tests' }
AXPLSpecFormTest >> testSaveVerifieToutLeFormulaire [
	| presenter |
	"Un âge négatif écrit hors du formulaire (bePositive) est détecté."
	client nom: 'Ranjaratiana'; prenom: 'Doris'; age: -5.
	presenter := framework specFormPresenterAt: #simple.
	self assert: presenter save notNil.
	client age: 30.
	self assert: presenter save isNil.
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLaFenetreSOuvreAChaqueNiveau [
	"Régression, constatée dans une vraie image : le newDropDown de
	Spec-Form n'a pas d'adaptateur Morphic (« No binding for
	DropDownAdapter found »). Les autres tests ne construisent que les
	presenters ; celui-ci ouvre vraiment la fenêtre."
	AXPLFormBuilder levels do: [ :lvl |
		| window |
		window := (framework specFormPresenterAt: lvl) open.
		window close ]
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLeChampAChoixGardeSaValeur [
	| sexe dropList |
	sexe := framework psiEngine readDescription: 'Sexe'.
	sexe write: 'Féminin' to: client.
	dropList := (self widgetsOf: (framework specFormPresenterAt: #simple))
		detect: [ :w | w isKindOf: SpDropListPresenter ].
	self assert: dropList selectedItem equals: 'Féminin'.
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLeLabelPorteLExplicationDuNiveau [
	"Régression, constatée dans une vraie image : avec les labels String de
	Spec-Form, plus aucune infobulle d'explication au survol."
	| nom |
	nom := framework psiEngine readDescription: 'Nom'.
	#( #simple #expert ) do: [ :lvl |
		self
			assert: ((framework specFormPresenterAt: lvl) labelFor: 'Nom') help
			equals: (nom commentFor: lvl) ]
]

{ #category : 'tests' }
AXPLSpecFormTest >> testLeLabelSignaleUneSaisieRefusee [
	| presenter age |
	presenter := framework specFormPresenterAt: #simple.
	age := framework psiEngine readDescription: 'Âge'.
	(presenter widgetFor: 'Âge') number: -5.
	self assert: ((presenter labelFor: 'Âge') help beginsWith: '⚠').
	(presenter widgetFor: 'Âge') number: 30.
	self assert: (presenter labelFor: 'Âge') help equals: (age commentFor: #simple).
	self assert: (presenter labelFor: 'Âge') label equals: 'Âge *'.
]
