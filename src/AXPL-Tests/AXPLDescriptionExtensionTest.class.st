"
Tests des extensions AXPL sur les classes réelles de SimpleRene
(SRDescription et sous-classes) : explication contextuelle ② par niveau,
et niveau par défaut d'une description fraîche.
"
Class {
	#name : 'AXPLDescriptionExtensionTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLDescriptionExtensionTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
]

{ #category : 'tests' }
AXPLDescriptionExtensionTest >> testExplicationContextuelle [
    "② — Chaque champ porte une explication String selon le niveau"
    | desc |
    desc := container children first.
    self assert: (desc commentFor: #simple) isString.
    self assert: (desc commentFor: #base) isString.
    self assert: (desc commentFor: #expert) isString.
]

{ #category : 'tests' }
AXPLDescriptionExtensionTest >> testNiveauParDefaut [
    "Une description fraîche, sans level: explicite, doit être #simple
    (valeur de repli dans SRDescription >> level, extension AXPL)."
    self assert: SRStringDescription new level equals: #simple.
]

{ #category : 'tests' }
AXPLDescriptionExtensionTest >> testMessageDeValidationDeSimpleRene [
    | age |
    age := container children detect: [ :d | d label = 'Âge' ].
    self assert: (age validationMessageFor: 42) isNil.
    self assert: (age validationMessageFor: -5) notNil.
    self assert: (age validationMessageFor: -5) asString notEmpty.
]
