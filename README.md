# Framework AXΨL — Pilotage adaptatif des interfaces

Framework Low-Code pour le pilotage natif des interfaces adaptatives.

## Chargement en une ligne (Pharo 13)

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2-simplerene:integration-simplerene/src';
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

## Serveur HTTP (pour un frontend web)

`AXPL-HTTP` expose le même framework en JSON sur `http://localhost:8080`, pour un
client comme le frontend React `do/` :

```st
AXPLHttpServer start.
"..."
AXPLHttpServer stop.
```

Routes :

| Méthode | Route            | Corps JSON                                   | Réponse                        |
|---------|------------------|-----------------------------------------------|---------------------------------|
| GET     | `/form?level=`   | —                                              | `{ type, fields: [...] }`       |
| POST    | `/field`         | `{label, value}`                              | `{ok:true}` ou `{error}`        |
| POST    | `/field/rename`  | `{oldLabel, newLabel}`                        | `{ok:true}` ou `{error}`        |
| POST    | `/field/level`   | `{label, level}`                              | `{ok:true}` ou `{error}`        |
| POST    | `/field/create`  | `{label, type, level, help, options?}`        | `{ok:true}` ou `{error}`        |
| DELETE  | `/field/<label>` | —                                              | `{ok:true}` ou `{error}`        |
| GET     | `/trace`         | —                                              | `[{timestamp, message}, ...]`   |

Les champs créés via `/field/create` (`AXPLDynamicField`) ne modifient jamais la
classe métier (`ClientHopital`) : ils portent leur propre valeur en mémoire côté
serveur, ce qui permet aussi de les supprimer via `DELETE /field/<label>`. Les
champs natifs (variables d'instance déclarées dans `descriptionForAXPL`) ne
peuvent être ni créés ni supprimés à chaud, seulement renommés ou changés de
niveau — cohérent avec `SRFormApp>>updateInterface` (mode Ψ desktop).

## Architecture

Le framework intègre nativement quatre dimensions autour d'une méta-description unique :

- **A** — Adaptation contextuelle (AXPLFormBuilder)
- **X** — Explicabilité native (AXPLSpecVisitor)
- **Ψ** — Réflexivité actionnable (AXPLReflexivityEngine)
- **L** — Accessibilité Low-Code (SRFormApp)

## Packages

- `AXPL-Descriptions` — Extension du vrai [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (niveau #simple/#base/#expert, explicabilité graduée)
- `AXPL-Core` — Moteurs A et Ψ
- `AXPL-UI` — Interface L
- `AXPL-HTTP` — Serveur Teapot/JSON pour un frontend web
- `AXPL-Tests` — 8 tests unitaires

## Dépendance

AXPL **dépend réellement** de [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (Ducasse et al., MIT License), déclaré comme projet externe dans `BaselineOfAXPL`. Le package `AXPL-Descriptions` n'y ajoute que ce que SimpleRene n'a pas nativement — les propriétés `level`/`level:` et `commentFor:` (explicabilité graduée par niveau) — via des méthodes d'extension sur `SRDescription`, plutôt qu'en dupliquant sa hiérarchie de classes.

## Licence

MIT License — voir le fichier LICENSE.

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
