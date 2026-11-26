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
        déjà présentes dans l'image — même principe que SimpleRene, et
        épinglées comme lui sur un commit précis : un changement sur leur
        branche master ne peut plus casser AXPL sans prévenir. Ce sont les
        commits validés par la CI ; les derniers tags (Teapot v2.7.0,
        NeoJSON v18, 2023) précèdent leurs correctifs pour Pharo 13."
        spec
            baseline: 'Teapot'
            with: [ spec repository: 'github://zeroflag/Teapot:e0e125da40bbde6cfddf38d1ebbf938d8f7eb3a5/source' ].
        spec
            baseline: 'NeoJSON'
            with: [ spec repository: 'github://svenvc/NeoJSON:11e274dd96dc9636cab90929937b7cd09719de7c/repository' ].

        "Packages du projet dans l'ordre de dépendance.
        AXPL-UI (Spec2), AXPL-Json (export JSON) et AXPL-Web (API HTTP,
        pour un frontend séparé type React) sont trois implémentations
        concrètes d'AXPLVisitor/AXPLReflexivityEngine, chacune ne dépendant
        que d'AXPL-Core — jamais l'une de l'autre. C'est ce qui rend le
        portage vers d'autres cibles possible sans dupliquer A/X/Ψ.
        AXPL-Web-Tests est séparé d'AXPL-Tests pour la même raison que
        AXPL-Web lui-même : c'est le SEUL package qui a besoin de
        Teapot/NeoJSON, donc le seul exclu du groupe #core ci-dessous.
        AXPL-Examples (ClientHopital, Etudiant) est un package séparé du
        framework lui-même : ce sont des objets métier de démonstration,
        pas du code AXPL — le framework ne dépend jamais d'eux, c'est
        l'inverse (AXPL-Examples ne requiert qu'AXPL-Descriptions, pas
        AXPL-Core, car descriptionForAXPL n'utilise que les descriptions,
        jamais AXPLFormBuilder/AXPLReflexivityEngine/AXPLFramework)."
        spec
            package: 'AXPL-Descriptions' with: [ spec requires: #('SimpleRene') ];
            package: 'AXPL-Core' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-Examples' with: [ spec requires: #('AXPL-Descriptions') ];
            package: 'AXPL-UI' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Json' with: [ spec requires: #('AXPL-Core') ];
            package: 'AXPL-Web' with: [ spec requires: #('AXPL-Json' 'Teapot' 'NeoJSON') ];
            package: 'AXPL-Tests' with: [ spec requires: #('AXPL-Core' 'AXPL-UI' 'AXPL-Json' 'AXPL-Examples') ];
            package: 'AXPL-Web-Tests' with: [ spec requires: #('AXPL-Web' 'AXPL-Examples') ].

        "Groupes de chargement : un simple `load` (sans groupe précisé)
        charge #default, donc reste 100% côté Pharo — Teapot/NeoJSON et
        le serveur HTTP ne sont tirés que par un `load: #('web')`
        explicite, au moment où on veut vraiment la partie web."
        spec
            group: 'core' with: #('AXPL-UI' 'AXPL-Json' 'AXPL-Examples' 'AXPL-Tests');
            group: 'web' with: #('AXPL-Web' 'AXPL-Web-Tests');
            group: 'default' with: #('core') ]
]
