# Framework AXΨL — Pilotage adaptatif des interfaces

Framework Low-Code pour le pilotage natif des interfaces adaptatives.

## Chargement en une ligne (Pharo 12)

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2:master/src';
    load.
```

## Utilisation

```st
"Domaine médical"
SRFormApp new
    targetObject: ClientHopital new;
    open.
```

```st
"Domaine académique"
SRFormApp new
    targetObject: Etudiant new;
    open.
```

## Architecture

Le framework intègre nativement quatre dimensions autour d'une méta-description unique :

- **A** — Adaptation contextuelle (AXPLFormBuilder)
- **X** — Explicabilité native (AXPLSpecVisitor)
- **Ψ** — Réflexivité actionnable (AXPLReflexivityEngine)
- **L** — Accessibilité Low-Code (SRFormApp)

## Packages

- `AXPL-Descriptions` — Méta-description (source unique de vérité)
- `AXPL-Core` — Moteurs A et Ψ
- `AXPL-UI` — Interface L
- `AXPL-Tests` — 8 tests unitaires

## Licence

MIT License — voir le fichier LICENSE.

## Inspirations

La couche de méta-description est inspirée de [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (Ducasse et al., MIT License), version épurée du paradigme Magritte (Renggli et al., 2007).

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
