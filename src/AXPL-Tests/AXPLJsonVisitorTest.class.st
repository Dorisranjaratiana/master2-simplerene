"
Tests de AXPLJsonVisitor (⑦ pour le web) : produit une structure JSON pure
(Dictionary/Array), sans dépendre de Spec2 — la preuve que le portage web
n'a besoin d'aucun toolkit UI desktop.
"
Class {
	#name : 'AXPLJsonVisitorTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLJsonVisitorTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
]

{ #category : 'tests' }
AXPLJsonVisitorTest >> testJsonVisitorAssembleContainer [
    "Le visiteur JSON produit une structure pure (Dictionary/Array), pas
    de widget Spec — la preuve que le portage n'a pas besoin de Spec2."
    | visitor result |
    visitor := AXPLJsonVisitor on: client level: #simple.
    result := visitor visit: (container children select: [ :d | d level = #simple ]).
    self assert: (result at: #type) equals: 'group'.
    self assert: (result at: #fields) notEmpty.
    self assert: ((result at: #fields) allSatisfy: [ :f | f isKindOf: Dictionary ]).
]

{ #category : 'tests' }
AXPLJsonVisitorTest >> testJsonVisitorStringDescription [
    | visitor desc json |
    desc := container children detect: [ :d | d label = 'Nom' ].
    client nom: 'Ranjaratiana'.
    visitor := AXPLJsonVisitor on: client level: #expert.
    json := desc acceptAXPLVisitor: visitor.
    self assert: (json at: #label) equals: 'Nom'.
    self assert: (json at: #type) equals: 'string'.
    self assert: (json at: #value) equals: 'Ranjaratiana'.
]

{ #category : 'tests' }
AXPLJsonVisitorTest >> testJsonVisitorBooleanDescription [
    | visitor desc json |
    desc := container children detect: [ :d | d label = 'Urgent' ].
    client isUrgent: true.
    visitor := AXPLJsonVisitor on: client level: #simple.
    json := desc acceptAXPLVisitor: visitor.
    self assert: (json at: #type) equals: 'boolean'.
    self assert: (json at: #value) equals: true.
]

{ #category : 'tests' }
AXPLJsonVisitorTest >> testJsonVisitorNumberDescription [
    | visitor desc json |
    desc := container children detect: [ :d | d label = 'Âge' ].
    client age: 42.
    visitor := AXPLJsonVisitor on: client level: #simple.
    json := desc acceptAXPLVisitor: visitor.
    self assert: (json at: #type) equals: 'number'.
    self assert: (json at: #value) equals: 42.
]

{ #category : 'tests' }
AXPLJsonVisitorTest >> testJsonVisitorSingleOptionDescription [
    | visitor desc json |
    desc := container children detect: [ :d | d label = 'Sexe' ].
    client sexe: 'Féminin'.
    visitor := AXPLJsonVisitor on: client level: #simple.
    json := desc acceptAXPLVisitor: visitor.
    self assert: (json at: #type) equals: 'select'.
    self assert: (json at: #value) equals: 'Féminin'.
    self assert: (json at: #options) equals: #('Masculin' 'Féminin' 'Autre').
]
