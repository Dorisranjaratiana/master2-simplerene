"
""Regroupe l'état d'exécution d'UN domaine métier : son instance cible, sa
méta-description et son moteur de réflexivité Ψ. Remplace les trois variables
d'instance targetObject/metaContainer/psiEngine qui vivaient directement dans
AXPLHttpServer — désormais un serveur peut tenir plusieurs sessions en
parallèle (une par domaine), chacune totalement isolée des autres.""
"
Class {
	#name : 'AXPLDomainSession',
	#superclass : 'Object',
	#instVars : [
		'domain',
		'targetObject',
		'metaContainer',
		'psiEngine'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLDomainSession >> domain [
	^ domain
]

{ #category : 'initialization' }
AXPLDomainSession >> initializeFor: aDomain [
	domain := aDomain.
	targetObject := aDomain domainClass new.
	metaContainer := targetObject class descriptionForAXPL.
	psiEngine := AXPLReflexivityEngine new
		metaContainer: metaContainer;
		targetClass: targetObject class;
		yourself.
	"Une session précédente a pu supprimer un champ natif, donc ses accesseurs, que
	#descriptionForAXPL redéclare pourtant : on les rétablit pour que la session
	reparte d'un état cohérent."
	psiEngine restoreMissingAccessors.
]

{ #category : 'accessing' }
AXPLDomainSession >> metaContainer [
	^ metaContainer
]

{ #category : 'accessing' }
AXPLDomainSession >> psiEngine [
	^ psiEngine
]

{ #category : 'accessing' }
AXPLDomainSession >> targetObject [
	^ targetObject
]
