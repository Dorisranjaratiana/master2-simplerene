"
Scénario d'action réflexive (Ψ), exécutable — réponse à la question de
S. Ducasse : « As-tu un scénario d'action réflexive ? ».

Situation : le dossier patient ClientHopital est en service. Une épidémie
se déclare. Le médecin-chef (niveau Expert) adapte le formulaire PENDANT
que l'application tourne — sans toucher au code de ClientHopital, sans
recompiler ni redémarrer. L'infirmière (niveau Simple) voit aussitôt le
nouveau formulaire. À la fin de l'épidémie, tout est annulé.

  1. Introspection ③    : que voit l'infirmière ? à quel niveau est « Allergies » ?
  2. Intercession ⑥②    : créer « Statut infectieux » (Simple), avec une explication par niveau
  3. Intercession ⑨     : rendre « Allergies » visible dès le niveau Simple
  4. Intercession ④⑤    : la renommer « Risques allergiques » et adapter son explication
  5. Effet ①            : l'infirmière voit 2 champs de plus et saisit (valeurs validées par SimpleRene)
  6. Trace [t]          : chaque intercession est horodatée
  7. Sauvegarde 💾      : le dossier rechargé a le même formulaire et les mêmes valeurs
  8. Annulation ↶       : fin de l'épidémie, le formulaire redevient celui du code

Exécuter et lire le récit :
	AXPLReflexiveScenario run log.
Voir le résultat dans la fenêtre (étapes 1 à 7, puis ouverture au niveau Simple) :
	AXPLReflexiveScenario demo.
"
Class {
	#name : 'AXPLReflexiveScenario',
	#superclass : 'Object',
	#instVars : [
		'framework',
		'log',
		'initialSimpleCount'
	],
	#category : 'AXPL-Scenarios',
	#package : 'AXPL-Scenarios'
}

{ #category : 'running' }
AXPLReflexiveScenario class >> demo [
	"Joue l'épidémie (sans l'annuler), écrit le récit dans le Transcript et
	ouvre la fenêtre au niveau Simple : on voit le formulaire modifié."
	| scenario |
	scenario := self new.
	scenario runEpidemic.
	scenario log do: [ :line | Transcript show: line; cr ].
	^ AXPLFormApp openOn: scenario framework level: #simple
]

{ #category : 'running' }
AXPLReflexiveScenario class >> run [
	^ self new run; yourself
]

{ #category : 'accessing' }
AXPLReflexiveScenario >> framework [
	^ framework
]

{ #category : 'initialization' }
AXPLReflexiveScenario >> initialize [
	super initialize.
	framework := AXPLFramework for: ClientHopital new.
	log := OrderedCollection new
]

{ #category : 'accessing' }
AXPLReflexiveScenario >> log [
	^ log
]

{ #category : 'accessing' }
AXPLReflexiveScenario >> psi [
	^ framework psiEngine
]

{ #category : 'running' }
AXPLReflexiveScenario >> run [
	self runEpidemic.
	self step8EndOfEpidemic
]

{ #category : 'running' }
AXPLReflexiveScenario >> runEpidemic [
	self
		step1Introspection;
		step2CreateField;
		step3ChangeLevel;
		step4Rename;
		step5NurseSeesTheNewForm;
		step6Trace;
		step7SaveAndReload
]

{ #category : 'private' }
AXPLReflexiveScenario >> say: aString [
	log add: aString
]

{ #category : 'private' }
AXPLReflexiveScenario >> simpleLabels [
	^ (framework visibleFieldsAt: #simple) collect: [ :desc | desc label ]
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step1Introspection [
	initialSimpleCount := self simpleLabels size.
	self say: '1. Introspection — l''infirmière (Simple) voit ' , initialSimpleCount printString
		, ' champs : ' , (', ' join: self simpleLabels) , '.'.
	self say: '   « Allergies » est un champ ' , (self psi typeOf: 'Allergies') name
		, ' du niveau ' , (self psi levelOf: 'Allergies') , ' : l''infirmière ne le voit pas.'
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step2CreateField [
	self psi
		createSelectionField: 'Statut infectieux'
		options: #( 'Non testé' 'Négatif' 'Positif' )
		level: #simple
		explanation: 'À renseigner à chaque admission pendant l''épidémie.'.
	self psi
		updateExplanation: 'Statut infectieux'
		forLevel: #expert
		with: 'Test PCR de moins de 48 h ; Positif impose l''isolement (protocole épidémie).'.
	self say: '2. Intercession ⑥ — le médecin-chef crée « Statut infectieux » (niveau Simple), avec son explication ②.'
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step3ChangeLevel [
	self psi setLevel: #simple ofDescription: 'Allergies'.
	self say: '3. Intercession ⑨ — « Allergies » devient visible dès le niveau Simple.'
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step4Rename [
	self psi relabelDescription: 'Allergies' to: 'Risques allergiques'.
	self psi
		updateExplanation: 'Risques allergiques'
		forLevel: #simple
		with: 'Signalez toute allergie connue : médicaments, latex, aliments.'.
	self say: '4. Intercession ④⑤ — « Allergies » est renommé « Risques allergiques », son explication Simple est adaptée.'
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step5NurseSeesTheNewForm [
	| patient |
	patient := framework targetObject.
	(self psi readDescription: 'Statut infectieux') write: 'Positif' to: patient.
	(self psi readDescription: 'Risques allergiques') write: 'Pénicilline' to: patient.
	self say: '5. Effet ① — sans redémarrer, l''infirmière voit ' , self simpleLabels size printString
		, ' champs (' , initialSimpleCount printString , ' avant) et saisit « Positif » et « Pénicilline ».'.
	self say: '   Au survol de « Statut infectieux », elle lit : '
		, (self psi explanationOf: 'Statut infectieux' forLevel: #simple)
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step6Trace [
	self say: '6. Trace [t] — ' , self psi traceLog size printString , ' intercessions horodatées :'.
	self psi traceLog do: [ :entry |
		self say: '   ' , entry key asTime printString , '  ' , entry value ]
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step7SaveAndReload [
	| copy |
	copy := AXPLFramework fromStonString: framework stonString.
	self say: '7. Sauvegarde 💾 — le dossier rechargé a ' , (copy visibleFieldsAt: #simple) size printString
		, ' champs au niveau Simple ; Statut infectieux = '
		, ((copy psiEngine readDescription: 'Statut infectieux') read: copy targetObject) , '.'
]

{ #category : 'steps' }
AXPLReflexiveScenario >> step8EndOfEpidemic [
	| count |
	count := 0.
	[ self psi canUndo ] whileTrue: [
		self psi undoLast.
		count := count + 1 ].
	self say: '8. Annulation ↶ — fin de l''épidémie : ' , count printString
		, ' intercessions annulées, l''infirmière revoit ' , self simpleLabels size printString , ' champs.'
]
