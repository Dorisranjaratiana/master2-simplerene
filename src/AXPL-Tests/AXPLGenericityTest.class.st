"
Tests de généricité et de validation du framework : le même AXPLFormBuilder
fonctionne avec tout objet métier qui implémente descriptionForAXPL
(ClientHopital et Etudiant), l'ordre des champs déclaré via priority: est
préservé par le vrai SRPriorityContainer, et les conditions de validation
(beRequired, bePositive, addCondition:labelled:) sont respectées.
"
Class {
	#name : 'AXPLGenericityTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'container',
		'builder'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLGenericityTest >> setUp [
    super setUp.
    client := ClientHopital new.
    container := client class descriptionForAXPL.
    builder := AXPLFormBuilder new
        targetObject: client;
        metaContainer: container;
        yourself.
]

{ #category : 'tests' }
AXPLGenericityTest >> testGenericite [
    "Le framework fonctionne avec tout objet qui implémente descriptionForAXPL"
    self assert: (client class respondsTo: #descriptionForAXPL).
    self assert: container children notEmpty.
    self assert: (builder build isKindOf: Collection).
]

{ #category : 'tests' }
AXPLGenericityTest >> testGenericiteEtudiant [
    "Le framework fonctionne aussi avec Etudiant, pas seulement ClientHopital"
    | etudiant etudiantContainer etudiantBuilder |
    etudiant := Etudiant new.
    etudiantContainer := etudiant class descriptionForAXPL.
    etudiantBuilder := AXPLFormBuilder new
        targetObject: etudiant;
        metaContainer: etudiantContainer;
        userLevel: #simple;
        yourself.
    self assert: etudiantContainer children notEmpty.
    self assert: (etudiantBuilder build allSatisfy: [ :d | d level = #simple ]).
    self assert: etudiantContainer children first label equals: 'Nom'.
]

{ #category : 'tests' }
AXPLGenericityTest >> testOrdreChampsParPriorite [
    "Le vrai SRPriorityContainer trie ses enfants par priority: — vérifie
    que l'ordre déclaré complet (pas seulement le premier) est préservé
    après la migration vers le vrai container de SimpleRene."
    | labels |
    labels := container children collect: [ :d | d label ].
    self assert: labels asArray equals: #(
        'Nom' 'Prénom' 'Âge' 'Sexe' 'Urgent' 'Allergies' 'Diagnostic'
        'Traitement' 'Antécédents' 'Médecin Référent' 'Date d''Admission'
        'N° Chambre' 'Téléphone' 'Contact d''Urgence' 'Assurance' 'Statut de Sortie').
]

{ #category : 'tests' }
AXPLGenericityTest >> testOrdreChampsParPrioriteEtudiant [
    "Même vérification que testOrdreChampsParPriorite, côté Etudiant —
    parité de couverture entre les deux objets métier de démonstration."
    | etudiant labels |
    etudiant := Etudiant new.
    labels := etudiant class descriptionForAXPL children collect: [ :d | d label ].
    self assert: labels asArray equals: #(
        'Nom' 'Prénom' 'Matricule' 'Filière' 'Moyenne' 'Date Naissance'
        'E-mail' 'Boursier' 'Montant Bourse' 'Remarques' 'Éligible Diplôme' 'Adresse').
]

{ #category : 'tests' }
AXPLGenericityTest >> testValidationAgePositif [
    "beRequired + bePositive sur 'Âge' (ClientHopital)"
    | desc |
    desc := container children detect: [ :d | d label = 'Âge' ].
    self deny: (desc isSatisfiedBy: -5).
    self assert: (desc isSatisfiedBy: 42).
]

{ #category : 'tests' }
AXPLGenericityTest >> testValidationChampRequis [
    "beRequired sur 'Nom' (ClientHopital) : refuse nil, accepte une String"
    | desc |
    desc := container children detect: [ :d | d label = 'Nom' ].
    self deny: (desc isSatisfiedBy: nil).
    self assert: (desc isSatisfiedBy: 'Doris').
]

{ #category : 'tests' }
AXPLGenericityTest >> testValidationMoyenneEtudiant [
    "Condition personnalisée sur 'Moyenne' (Etudiant) : bornée entre 0 et 20"
    | etudiant etudiantContainer desc |
    etudiant := Etudiant new.
    etudiantContainer := etudiant class descriptionForAXPL.
    desc := etudiantContainer children detect: [ :d | d label = 'Moyenne' ].
    self deny: (desc isSatisfiedBy: 25).
    self assert: (desc isSatisfiedBy: 15).
]
