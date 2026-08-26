"
Tests du dispatch ⑦ acceptAXPLVisitor: (régression : le
acceptSimpleReneVisitor: natif de SimpleRene n'a pas de ^ et ne renvoie
donc pas la valeur produite par le visiteur) et de la hiérarchie
abstraite AXPLVisitor / AXPLSpecVisitor.
"
Class {
	#name : 'AXPLVisitorDispatchTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLVisitorDispatchTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
]

{ #category : 'tests' }
AXPLVisitorDispatchTest >> testAcceptAXPLVisitorDispatch [
    "⑦ — chaque type de description doit dispatcher vers la bonne méthode
    du visiteur ET renvoyer sa valeur de retour. Régression : le
    acceptSimpleReneVisitor: natif de SimpleRene n'a pas de ^ et ne
    renvoie donc pas le widget construit par le visiteur (bug corrigé)."
    | probe |
    probe := AXPLVisitorProbe new.
    self
        assert: ((SRStringDescription new accessor: #nom; yourself) acceptAXPLVisitor: probe)
        equals: #stringVisited.
    self
        assert: ((SRNumberDescription new accessor: #age; yourself) acceptAXPLVisitor: probe)
        equals: #numberVisited.
    self
        assert: ((SRBooleanDescription new accessor: #isUrgent; yourself) acceptAXPLVisitor: probe)
        equals: #booleanVisited.
    self
        assert: ((SRDateDescription new accessor: #dateAdmission; yourself) acceptAXPLVisitor: probe)
        equals: #dateVisited.
    self
        assert: ((SRSingleOptionDescription new accessor: #sexe; options: #('a' 'b'); yourself) acceptAXPLVisitor: probe)
        equals: #singleOptionVisited.
    self
        assert: (container acceptAXPLVisitor: probe)
        equals: #priorityContainerVisited.
]

{ #category : 'tests' }
AXPLVisitorDispatchTest >> testAXPLSpecVisitorEstUnAXPLVisitor [
    "Prépare le portage vers d'autres cibles (web, JSON...) : AXPLSpecVisitor
    n'est qu'une implémentation concrète du contrat abstrait AXPLVisitor,
    qui lui ne dépend d'aucun toolkit UI."
    self assert: (AXPLSpecVisitor inheritsFrom: AXPLVisitor).
    self
        should: [ AXPLVisitor new visitStringDescription: SRStringDescription new ]
        raise: Error.
]
