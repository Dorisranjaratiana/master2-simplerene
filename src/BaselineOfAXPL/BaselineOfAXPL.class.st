"
Une baseline définit les packages du projet, leurs dépendances mutuelles et vis-à-vis des projets externes, ainsi que les sous-groupes indépendants pouvant être chargés.
"
Class {
	#name : 'BaselineOfAXPL',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAXPL',
	#package : 'BaselineOfAXPL'
}

{ #category : 'baselines' }
BaselineOfAXPL >> baseline: spec [
    <baseline>
    spec for: #common do: [
        "Dépendance externe : AXPL étend le vrai framework SimpleRene au lieu
        d'en réimplémenter une version simplifiée (cf. suggestion S. Ducasse).
        Épinglé sur un commit précis (plutôt que la branche master mobile)
        pour la reproductibilité du build."
        spec
            baseline: 'SimpleRene'
            with: [
                spec
                    repository: 'github://pharo-contributions/SimpleRene:de059fc2e3732594fc6e0320e25c966b58a7ba64/src';
                    loads: #( Core ) ].

        "Dépendances externes pour AXPL-Web : Teapot (serveur HTTP léger)
        et NeoJSON (sérialisation), déclarées ici plutôt que supposées
        déjà présentes dans l'image — même principe que SimpleRene."
        spec
            baseline: 'Teapot'
            with: [ spec repository: 'github://zeroflag/Teapot:master/source' ].
        spec
            baseline: 'NeoJSON'
            with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].

        "Packages du projet dans l'ordre de dépendance.
        AXPL-UI (Spec2), AXPL-Json (export JSON) et AXPL-Web (API HTTP,
        pour un frontend séparé type React) sont trois implémentations
        concrètes d'AXPLVisitor/AXPLReflexivityEngine, chacune ne dépendant
        que d'AXPL-Core — jamais l'une de l'autre. C'est ce qui rend le
        portage vers d'autres cibles possible sans dupliquer A/X/Ψ."
        spec
            package: 'AXPL-Descriptions' with: [ spec requires: #('SimpleRene') ];
            package: 'AXPL-Core' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-UI' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Json' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Web' with: [ spec requires: #('AXPL-Json' 'Teapot' 'NeoJSON') ];
            package: 'AXPL-Tests' with: [ spec requires: #('AXPL-Core' 'AXPL-Json' 'AXPL-Web') ] ]
]
