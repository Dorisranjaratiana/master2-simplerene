"
""Façade d'entrée du framework AXPL. Cache l'assemblage manuel de ① et Ψ
qu'un utilisateur du framework devait jusqu'ici refaire à la main à
chaque point d'intégration (SRFormApp, AXPLWebServer, les tests...) :
dériver le metaContainer depuis targetObject class descriptionForAXPL,
construire un AXPLFormBuilder pour filtrer par niveau, et créer UNE
instance d'AXPLReflexivityEngine par cible — jamais recréée entre les
re-rendus, comme le veut le commentaire de classe d'AXPLReflexivityEngine
lui-même (jusqu'ici un vœu pieux : rien ne l'imposait vraiment).

Ne construit PAS le visiteur à la place de l'appelant : AXPLSpecVisitor
(a besoin d'un presenter Spec2) et AXPLJsonVisitor (a besoin d'un niveau)
ont des contrats de construction légitimement différents selon la cible
— c'est précisément le principe du ⑦ abstrait. La façade s'arrête donc
à visibleFieldsAt:, qui renvoie une Collection de descriptions prête à
être passée à visit: sur n'importe quel AXPLVisitor concret.""
"
Class {
	#name : 'AXPLFramework',
	#superclass : 'Object',
	#instVars : [
		'targetObject',
		'metaContainer',
		'psiEngine'
	],
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'instance creation' }
AXPLFramework class >> for: anObject [
	^ self new targetObject: anObject; yourself
]

{ #category : 'accessing' }
AXPLFramework >> metaContainer [
	^ metaContainer
]

{ #category : 'accessing' }
AXPLFramework >> psiEngine [
	"Ψ — une seule instance par cible, créée une fois dans targetObject:
	et jamais recréée entre deux appels à visibleFieldsAt:."
	^ psiEngine
]

{ #category : 'accessing' }
AXPLFramework >> targetObject [
	^ targetObject
]

{ #category : 'accessing' }
AXPLFramework >> targetObject: anObject [
	targetObject := anObject.
	metaContainer := anObject class descriptionForAXPL.
	psiEngine := AXPLReflexivityEngine new
		metaContainer: metaContainer;
		yourself
]

{ #category : 'building' }
AXPLFramework >> visibleFieldsAt: aLevelSymbol [
	"① — la liste filtrée de descriptions visibles à ce niveau, prête à
	être passée à visit: sur n'importe quel AXPLVisitor concret (Spec2,
	JSON, ou un futur visiteur)."
	^ (AXPLFormBuilder new
		targetObject: targetObject;
		userLevel: aLevelSymbol;
		metaContainer: metaContainer;
		yourself) build
]
