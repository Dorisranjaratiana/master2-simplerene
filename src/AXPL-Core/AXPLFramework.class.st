"
""Façade d'entrée du framework AXPL. Cache l'assemblage manuel de ① et Ψ
qu'un utilisateur du framework devait jusqu'ici refaire à la main à
chaque point d'intégration (AXPLFormApp, AXPLWebServer, les tests...) :
dériver le metaContainer depuis targetObject class descriptionForAXPL,
construire un AXPLFormBuilder pour filtrer par niveau, et créer UNE
instance d'AXPLReflexivityEngine par cible — jamais recréée entre les
re-rendus, comme le veut le commentaire de classe d'AXPLReflexivityEngine
lui-même (jusqu'ici un vœu pieux : rien ne l'imposait vraiment).

Ne construit PAS le visiteur à la place de l'appelant : tous les
visiteurs se créent par AXPLVisitor class >> on:level:, mais chaque cible
peut demander en plus ce qui lui est propre (AXPLSpecVisitor : un
presenter Spec2 pour ses fabriques de widgets). La façade s'arrête donc
à visibleFieldsAt:, qui renvoie une Collection de descriptions prête à
être passée à visit: sur n'importe quel AXPLVisitor concret.

💾 Sauvegarde STON (saveTo: / loadFrom:, stonString / fromStonString:) :
un dossier = la classe de l'objet, ses valeurs lues PAR LES DESCRIPTIONS
(label → valeur ; les mots de passe ne sont jamais écrits en clair), les
modifications Ψ actives (psiEngine changes) et la trace. Au chargement,
les modifications Ψ sont rejouées sur un metaContainer neuf, puis chaque
valeur est réécrite par sa description — seulement si elle est valide.
Aucun bloc n'est sérialisé : le fichier reste lisible et modifiable à la main.""
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

{ #category : 'private' }
AXPLFramework >> builderAt: aLevelSymbol [
	^ AXPLFormBuilder new
		targetObject: targetObject;
		userLevel: aLevelSymbol;
		metaContainer: metaContainer;
		yourself
]

{ #category : 'building' }
AXPLFramework >> hiddenFieldsAt: aLevelSymbol [
	"② — le complément exact de visibleFieldsAt: : les champs masqués à ce
	niveau, pour pouvoir expliquer à l'utilisateur ce qu'il ne voit pas."
	| builder |
	builder := self builderAt: aLevelSymbol.
	^ metaContainer children reject: [ :d | builder canUserSee: d ]
]

{ #category : 'building' }
AXPLFramework >> visibleFieldsAt: aLevelSymbol [
	"① — la liste filtrée de descriptions visibles à ce niveau, prête à
	être passée à visit: sur n'importe quel AXPLVisitor concret (Spec2,
	JSON, ou un futur visiteur)."
	^ (self builderAt: aLevelSymbol) build
]

{ #category : 'persistence' }
AXPLFramework class >> formatVersion [
	^ 1
]

{ #category : 'persistence' }
AXPLFramework class >> fromStonString: aString [
	"💾 Reconstruit une façade (objet + formulaire modifié par Ψ) depuis
	une sauvegarde produite par #stonString."
	| data class framework |
	data := [ STON fromString: aString ]
		on: Error
		do: [ :err | Error signal: 'Fichier illisible : ' , err messageText ].
	((data isKindOf: Dictionary) and: [ (data at: #format ifAbsent: [ nil ]) = 'AXPL' ])
		ifFalse: [ Error signal: 'Ce fichier n''est pas une sauvegarde AXPL.' ].
	(data at: #version ifAbsent: [ nil ]) = self formatVersion
		ifFalse: [ Error signal: 'Version de sauvegarde non prise en charge : '
			, (data at: #version ifAbsent: [ nil ]) printString ].
	class := Smalltalk globals at: (data at: #class) asSymbol ifAbsent: [ nil ].
	(class isClass and: [ class respondsTo: #descriptionForAXPL ])
		ifFalse: [ Error signal: 'Classe inconnue ou sans descriptionForAXPL : '
			, (data at: #class) printString ].
	framework := self for: class new.
	framework restoreFrom: data.
	^ framework
]

{ #category : 'persistence' }
AXPLFramework class >> loadFrom: aFileReference [
	^ self fromStonString: aFileReference asFileReference contents
]

{ #category : 'persistence' }
AXPLFramework >> restoreFrom: aDictionary [
	psiEngine replayChanges: (aDictionary at: #psi).
	psiEngine restoreTrace: (aDictionary at: #trace).
	(aDictionary at: #values) keysAndValuesDo: [ :label :value |
		(psiEngine readDescription: label) ifNotNil: [ :desc |
			(desc validationMessageFor: value) ifNil: [ desc write: value to: targetObject ] ] ]
]

{ #category : 'persistence' }
AXPLFramework >> saveTo: aFileReference [
	"💾 Écrit le dossier (remplace le fichier s'il existe)."
	| file |
	file := aFileReference asFileReference.
	file parent ensureCreateDirectory.
	file ensureDelete.
	file writeStreamDo: [ :stream | stream nextPutAll: self stonString ].
	^ file
]

{ #category : 'persistence' }
AXPLFramework >> savedValues [
	"label → valeur, pour chaque champ décrit ayant une valeur. Passer
	par les descriptions (et pas par les variables d'instance) couvre
	aussi les champs créés par Ψ, rangés dans #properties."
	| values |
	values := Dictionary new.
	metaContainer children do: [ :desc |
		(desc isKindOf: SRPasswordDescription) ifFalse: [
			(desc read: targetObject) ifNotNil: [ :value | values at: desc label put: value ] ] ].
	^ values
]

{ #category : 'persistence' }
AXPLFramework >> snapshot [
	^ Dictionary new
		at: #format put: 'AXPL';
		at: #version put: self class formatVersion;
		at: #class put: targetObject class name;
		at: #values put: self savedValues;
		at: #psi put: psiEngine changes;
		at: #trace put: (psiEngine traceLog collect: [ :each | { each key. each value } ]) asArray;
		yourself
]

{ #category : 'persistence' }
AXPLFramework >> stonString [
	^ STON toStringPretty: self snapshot
]

{ #category : 'building' }
AXPLFramework >> hiddenFieldsIn: anAXPLContext [
	"② Les champs masqués dans ce contexte (complément de visibleFieldsIn:) ;
	anAXPLContext reasonForHiding: dit pourquoi."
	^ anAXPLContext hidden: metaContainer children
]

{ #category : 'building' }
AXPLFramework >> visibleFieldsIn: anAXPLContext [
	"Objectif 2 : les champs montrés dans ce contexte (AXPLContext et ses
	sous-classes), dans l'ordre du formulaire, champs Ψ compris."
	^ anAXPLContext filter: metaContainer children
]
