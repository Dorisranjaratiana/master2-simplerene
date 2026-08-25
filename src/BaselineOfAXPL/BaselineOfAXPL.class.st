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

        "Packages du projet dans l'ordre de dépendance"
        spec
            package: 'AXPL-Descriptions' with: [ spec requires: #('SimpleRene') ];
            package: 'AXPL-Core' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-UI' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Tests' with: [ spec requires: #('AXPL-Core') ] ]
]
