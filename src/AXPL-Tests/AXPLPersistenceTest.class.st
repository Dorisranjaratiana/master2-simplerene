"
Tests de la sauvegarde STON (💾) : AXPLFramework stonString / fromStonString:
et saveTo: / loadFrom:, AXPLReflexivityEngine changes / replayChanges:.
Un dossier rechargé doit redonner le même objet (valeurs lues et réécrites
par les descriptions, champs créés par Ψ compris), le même formulaire
(modifications Ψ rejouées), la même trace — et rester annulable.
Les fichiers sont écrits dans un système de fichiers en mémoire.
"
Class {
	#name : 'AXPLPersistenceTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'framework'
	],
	#category : 'AXPL-Tests',
	#package : 'AXPL-Tests'
}

{ #category : 'running' }
AXPLPersistenceTest >> setUp [
    super setUp.
    client := ClientHopital new.
    framework := AXPLFramework for: client.
]

{ #category : 'private' }
AXPLPersistenceTest >> reloaded [
    ^ AXPLFramework fromStonString: framework stonString
]

{ #category : 'tests' }
AXPLPersistenceTest >> testLesValeursSontRestaurees [
    | copie |
    client nom: 'Ranjaratiana'; age: 30; isUrgent: true.
    client dateAdmission: (Date year: 2024 month: 3 day: 15).
    copie := self reloaded targetObject.
    self deny: copie identicalTo: client.
    self assert: copie class equals: ClientHopital.
    self assert: copie nom equals: 'Ranjaratiana'.
    self assert: copie age equals: 30.
    self assert: copie isUrgent.
    self assert: copie dateAdmission equals: (Date year: 2024 month: 3 day: 15).
]

{ #category : 'tests' }
AXPLPersistenceTest >> testLesModificationsPsiSontRejouees [
    | copie |
    framework psiEngine
        createSelectionField: 'Groupe sanguin'
        options: #('A' 'B' 'AB' 'O')
        level: #base
        explanation: 'Avant toute transfusion.'.
    framework psiEngine relabelDescription: 'Allergies' to: 'Risques'.
    framework psiEngine setLevel: #simple ofDescription: 'Risques'.
    framework psiEngine updateExplanation: 'Nom' forLevel: #expert with: 'Nom d''état civil.'.
    framework psiEngine removeField: 'Prénom'.
    copie := self reloaded psiEngine.
    self assert: ((copie readDescription: 'Groupe sanguin') options) asArray equals: #('A' 'B' 'AB' 'O').
    self assert: ((copie readDescription: 'Groupe sanguin') commentFor: #base) equals: 'Avant toute transfusion.'.
    self assert: (copie readDescription: 'Allergies') isNil.
    self assert: (copie readDescription: 'Risques') level equals: #simple.
    self assert: ((copie readDescription: 'Nom') commentFor: #expert) equals: 'Nom d''état civil.'.
    self assert: (copie readDescription: 'Prénom') isNil.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testLaValeurDUnChampCreeParPsiEstRestauree [
    | desc copie |
    desc := framework psiEngine createField: 'Note interne' type: SRStringDescription level: #base.
    desc write: 'RAS' to: client.
    copie := self reloaded.
    self
        assert: ((copie psiEngine readDescription: 'Note interne') read: copie targetObject)
        equals: 'RAS'.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testLesModificationsAnnuleesNeSontPasSauvegardees [
    framework psiEngine createField: 'Brouillon' type: SRStringDescription level: #base.
    framework psiEngine undoLast.
    self assert: framework psiEngine changes isEmpty.
    self assert: (self reloaded psiEngine readDescription: 'Brouillon') isNil.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testLaTraceEstConservee [
    | copie |
    framework psiEngine relabelDescription: 'Nom' to: 'Identifiant'.
    framework psiEngine relabelDescription: 'Identifiant' to: 'Nom'.
    framework psiEngine undoLast.
    copie := self reloaded psiEngine traceLog.
    self assert: (copie collect: [ :each | each value ]) asArray
        equals: (framework psiEngine traceLog collect: [ :each | each value ]) asArray.
    self assert: copie first key equals: framework psiEngine traceLog first key.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testUnDossierRechargeResteAnnulable [
    | copie |
    framework psiEngine relabelDescription: 'Allergies' to: 'Risques'.
    copie := self reloaded psiEngine.
    self assert: copie canUndo.
    copie undoLast.
    self assert: (copie readDescription: 'Allergies') notNil.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testMotDePasseJamaisEcritEnClair [
    | desc |
    desc := framework psiEngine createField: 'Code d''accès' type: SRPasswordDescription level: #simple.
    desc write: 'secret123' to: client.
    self deny: (framework stonString includesSubstring: 'secret123').
]

{ #category : 'tests' }
AXPLPersistenceTest >> testUneValeurInvalideNEstPasReecrite [
    "Un fichier modifié à la main ne doit pas contourner la validation."
    | texte copie |
    client age: 30.
    texte := framework stonString copyReplaceAll: ': 30' with: ': -5'.
    self assert: (texte includesSubstring: ': -5').
    copie := AXPLFramework fromStonString: texte.
    self deny: copie targetObject age equals: -5.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testFichierQuiNEstPasUneSauvegardeAXPLRefuse [
    self should: [ AXPLFramework fromStonString: '{#a:1}' ] raise: Error.
    self should: [ AXPLFramework fromStonString: 'pas du STON {{{' ] raise: Error.
    self should: [ AXPLFramework fromStonString: '[1,2]' ] raise: Error.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testTypeDeChampQuiNEstPasUneDescriptionRefuse [
    "Le type d'un champ Ψ vient du fichier : jamais une classe quelconque."
    | change |
    change := Dictionary new
        at: #op put: #create; at: #label put: 'X'; at: #type put: #Object;
        at: #level put: #base; at: #explanation put: nil; at: #options put: nil;
        yourself.
    self should: [ framework psiEngine replayChanges: { change } ] raise: Error.
    self assert: (framework psiEngine readDescription: 'X') isNil.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testSaveToEtLoadFromUnFichier [
    | file copie |
    client nom: 'Ranjaratiana'.
    framework psiEngine createField: 'Note interne' type: SRStringDescription level: #expert.
    file := (FileSystem memory / 'dossiers' / 'patient.ston').
    framework saveTo: file.
    self assert: file exists.
    client nom: 'Autre'.
    framework saveTo: file.
    copie := AXPLFramework loadFrom: file.
    self assert: copie targetObject nom equals: 'Autre'.
    self assert: (copie psiEngine readDescription: 'Note interne') notNil.
]

{ #category : 'tests' }
AXPLPersistenceTest >> testFonctionneAvecUnAutreObjetMetier [
    "Généricité : rien n'est propre à ClientHopital."
    | etudiant copie |
    etudiant := Etudiant new.
    framework := AXPLFramework for: etudiant.
    (framework metaContainer children detect: [ :d | d label = 'Nom' ]) write: 'Rakoto' to: etudiant.
    copie := self reloaded targetObject.
    self assert: copie class equals: Etudiant.
    self assert: copie nom equals: 'Rakoto'.
]
