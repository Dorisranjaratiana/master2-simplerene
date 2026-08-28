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
        d'en réimplémenter une version simplifiée (cf. suggestion S. Ducasse)"
        spec
            baseline: 'SimpleRene'
            with: [ spec repository: 'github://pharo-contributions/SimpleRene:master/src' ].

        "Dépendances externes pour le serveur HTTP exposé au frontend web (AXPL-HTTP)"
        spec
            baseline: 'Teapot'
            with: [ spec repository: 'github://zeroflag/Teapot:master/source' ].
        spec
            baseline: 'NeoJSON'
            with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].

        "Packages du projet dans l'ordre de dépendance"
        spec
            package: 'AXPL-Descriptions' with: [ spec requires: #('SimpleRene') ];
            package: 'AXPL-Core' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-UI' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-HTTP' with: [ spec requires: #('AXPL-Core' 'Teapot' 'NeoJSON') ];
            package: 'AXPL-Tests' with: [ spec requires: #('AXPL-Core') ] ]
]
