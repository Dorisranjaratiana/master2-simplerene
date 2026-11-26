# Framework AXΨL — Pilotage adaptatif des interfaces

Framework Low-Code pour le pilotage natif des interfaces adaptatives.

## Chargement en une ligne (Pharo 13)

Un chargement simple reste **100% côté Pharo** : SimpleRene, les moteurs ①Ψ, l'UI desktop (Spec2) et l'export JSON, sans toucher à Teapot/NeoJSON ni au serveur HTTP.

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2-simplerene:integration-simplerene/src';
    load.
```

Pour charger en plus la partie web (serveur HTTP `AXPL-Web`, Teapot, NeoJSON) :

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2-simplerene:integration-simplerene/src';
    load: #('web').
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

- `AXPL-Descriptions` — Extension du vrai [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (niveau #simple/#base/#expert, explicabilité graduée)
- `AXPL-Core` — Moteurs A et Ψ
- `AXPL-UI` — Interface L (desktop, Spec2)
- `AXPL-Json` — Export JSON pur (aucune dépendance Spec2), pour un frontend web séparé
- `AXPL-Web` *(groupe `web` uniquement)* — API HTTP ([Teapot](https://github.com/zeroflag/Teapot) + [NeoJSON](https://github.com/svenvc/NeoJSON)) exposant AXPL-Json et Ψ à un frontend externe (React, etc.)
- `AXPL-Tests` — suite de tests unitaires (①, Ψ, ⑦, généricité, extensions SimpleRene) — groupe `core`
- `AXPL-Web-Tests` *(groupe `web` uniquement)* — tests du serveur HTTP, seul package avec `AXPL-Web` à dépendre de Teapot/NeoJSON

Un chargement par défaut (`load.`) tire le groupe `default` = `core` = tout sauf `AXPL-Web`/`AXPL-Web-Tests`. C'est volontaire : le framework reste utilisable et testable 100% côté Pharo sans jamais toucher à une dépendance web, celle-ci n'étant chargée qu'à la demande (`load: #('web')`).

## Dépendance

AXPL **dépend réellement** de [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (Ducasse et al., MIT License), déclaré comme projet externe dans `BaselineOfAXPL`. Le package `AXPL-Descriptions` n'y ajoute que ce que SimpleRene n'a pas nativement — les propriétés `level`/`level:` et `commentFor:` (explicabilité graduée par niveau) — via des méthodes d'extension sur `SRDescription`, plutôt qu'en dupliquant sa hiérarchie de classes.

**Sur Spec-Form** : après recherche, aucun projet Pharo nommé « Spec-Form » n'existe (ni dans l'organisation [pharo-spec](https://github.com/pharo-spec), ni ailleurs sur GitHub). Le seul framework réel est [Spec2](https://github.com/pharo-spec/Spec) lui-même, livré nativement avec toute image Pharo — on ne le déclare donc pas en dépendance externe de baseline, comme n'importe quel autre projet qui utilise l'UI native de Pharo.

## Portage vers d'autres cibles

`AXPLVisitor` (dans `AXPL-Core`) est le contrat abstrait de génération, indépendant de tout toolkit UI. `AXPL-UI` (Spec2, desktop) et `AXPL-Json` (export JSON, pour un frontend web séparé) en sont deux implémentations concrètes, chacune ne dépendant que d'`AXPL-Core` — jamais l'une de l'autre.

### Serveur web (AXPL-Web)

Charger d'abord le groupe `web` (voir plus haut) — `AXPL-Web` n'est pas chargé par un `load.` par défaut :

```st
AXPLWebServer onPort: 8080 forTargetObject: ClientHopital new.
```

Routes disponibles (CORS ouvert, pratique pour un frontend en développement local sur un autre port — Vite, CRA...) :

| Route | Description |
|---|---|
| `GET /form?level=simple\|base\|expert` | Champs visibles à ce niveau, en JSON |
| `POST /field` `{label, value}` | Écrit une valeur (validée avant écriture, comme le desktop) |
| `POST /psi/rename` `{oldLabel, newLabel}` | Ψ — renomme un champ |
| `POST /psi/set-level` `{label, level}` | Ψ — change le niveau d'un champ |
| `POST /psi/create-field` `{label, type, level, options?}` | Ψ — crée un champ (`type` : `string`/`number`/`boolean`/`date`/`select`) |
| `POST /psi/remove-field` `{label}` | Ψ — supprime un champ |
| `GET /psi/trace` | Historique horodaté Ψ |

Un champ Date envoyé par le web arrive en String JSON ISO 8601 (`AAAA-MM-JJ`) — `POST /field` la convertit en `Date` Pharo avant validation/écriture, pour ne jamais casser l'affichage desktop du même champ.

Toutes les routes `POST` sont couvertes par des tests qui simulent un vrai corps JSON (`AXPLWebServerTest`), y compris la conversion explicite des clés d'objet JSON en `Symbol` — sans elle, `NeoJSONReader` les parse en `String` par défaut et chaque route échouerait silencieusement (rattrapée en `{error: ...}` par `safely:`, mais jamais fonctionnelle) sur une vraie requête HTTP.

## Licence

MIT License — voir le fichier LICENSE.

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
