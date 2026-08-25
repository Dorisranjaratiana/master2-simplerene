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
            with: [ spec repository: 'github://pharo-contributions/SimpleRene:de059fc2e3732594fc6e0320e25c966b58a7ba64/src' ].

        "Packages du projet dans l'ordre de dépendance"
        spec
            package: 'AXPL-Descriptions' with: [ spec requires: #('SimpleRene') ];
            package: 'AXPL-Core' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-UI' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Tests' with: [ spec requires: #('AXPL-Core') ] ]
]
