"
""Registre des domaines métier disponibles. Plutôt qu'une liste câblée en dur
(l'ancien péché du framework : AXPLHttpServer connaissait ClientHopital par son
nom), #discover scanne l'image à la recherche de toute classe qui répond à
#descriptionForAXPL — le seul contrat que doit honorer un domaine métier pour
devenir utilisable par le framework — et l'enregistre automatiquement. Ajouter
un nouveau domaine (nouvelle classe métier) ne nécessite donc plus de modifier
une seule ligne du framework : il suffit qu'elle implémente #descriptionForAXPL.
C'est la découverte de domaines elle-même qui devient un acte réflexif (①).""
"
Class {
	#name : 'AXPLDomainRegistry',
	#superclass : 'Object',
	#instVars : [
		'domains'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'instance creation' }
AXPLDomainRegistry class >> discover [
	^ self new discoverDomains; yourself
]

{ #category : 'querying' }
AXPLDomainRegistry >> at: aKey [
	^ domains at: aKey ifAbsent: [
		AXPLDomainNotFoundError signal: 'Domaine introuvable : "' , aKey , '".' ]
]

{ #category : 'querying' }
AXPLDomainRegistry >> domains [
	^ domains values asArray
]

{ #category : 'discovery' }
AXPLDomainRegistry >> discoverDomains [
	(SystemNavigation default allClasses
		select: [ :c | c class canUnderstand: #descriptionForAXPL ])
		do: [ :c | self register: c ]
]

{ #category : 'initialization' }
AXPLDomainRegistry >> initialize [
	super initialize.
	domains := Dictionary new.
]

{ #category : 'registering' }
AXPLDomainRegistry >> register: aDomainClass [
	| domain |
	domain := AXPLDomain new
		key: aDomainClass name asString;
		label: aDomainClass descriptionForAXPL label;
		domainClass: aDomainClass;
		yourself.
	domains at: domain key put: domain.
]
