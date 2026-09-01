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

Le serveur ne connaît **aucune classe métier concrète**. Au démarrage,
`AXPLDomainRegistry discover` scanne l'image et enregistre automatiquement toute
classe qui implémente `descriptionForAXPL` (ClientHopital, Etudiant, et n'importe
quel futur domaine) — ajouter un domaine ne modifie donc jamais ce package.
Chaque domaine obtient sa propre session (`targetObject`/`metaContainer`/`psiEngine`),
créée à la demande et isolée des autres.

### Contrat v1

| Méthode | Route                                              | Corps JSON            | Réponse                          |
|---------|-----------------------------------------------------|------------------------|-----------------------------------|
| GET     | `/health`                                           | —                      | `{status:"ok"}`                  |
| GET     | `/api/v1/domains`                                   | —                      | `{domains:[{key,label}]}`        |
| GET     | `/api/v1/domains/<domain>/form?level=`               | —                      | `{type,label,fields:[...]}`      |
| GET     | `/api/v1/domains/<domain>/fields/<label>`            | —                      | champ unique                     |
| POST    | `/api/v1/domains/<domain>/fields`                    | `{label,type,level,help,options?}` | `{ok:true}`          |
| POST    | `/api/v1/domains/<domain>/fields/<label>/value`      | `{value}`              | `{ok:true}`                      |
| POST    | `/api/v1/domains/<domain>/fields/<label>/rename`     | `{newLabel}`           | `{ok:true}`                      |
| POST    | `/api/v1/domains/<domain>/fields/<label>/level`      | `{level}`              | `{ok:true}`                      |
| DELETE  | `/api/v1/domains/<domain>/fields/<label>`            | —                      | `{ok:true}`                      |
| POST    | `/api/v1/domains/<domain>/reset`                     | —                      | `{ok:true}`                      |
| GET     | `/api/v1/domains/<domain>/trace`                     | —                      | `[{timestamp,message}]`          |

`reset` rejette la session en cache du domaine (recréée fraîche au prochain accès) —
pratique pour rejouer une démo sans redémarrer tout le serveur.

Toute erreur applicative répond avec un statut HTTP correct (404/409/403/400/500)
et un corps uniforme `{error:{code,message}}` — `code` est un identifiant stable
(`FIELD_NOT_FOUND`, `FIELD_ALREADY_EXISTS`, `FIELD_PROTECTED`, `INVALID_PAYLOAD`,
`DOMAIN_NOT_FOUND`, `INTERNAL_ERROR`) pensé pour être testé par un client, pas
parsé comme du texte. Voir `AXPLApiError` et ses sous-classes dans `AXPL-Core`.

Les créations/suppressions de champs (`POST .../fields`, `DELETE .../fields/<label>`)
exploitent une véritable **intercession structurelle** Ψ (au sens de Maes, 1987,
repris au chapitre 4 du mémoire) : la création ajoute réellement une variable
d'instance à la classe métier via `#subclass:instanceVariableNames:classVariableNames:package:`
puis compile ses accesseur/mutateur avec `#compile:` ; Pharo migre automatiquement
les instances existantes vers la nouvelle forme, sans redémarrage (programmation
live). La suppression effectue l'opération inverse (`#removeSelector:` puis retrait
de la variable). Seuls les champs ainsi créés par Ψ sont supprimables — les champs
natifs déclarés dans `descriptionForAXPL` restent protégés, conformément à la
limite documentée dans le mémoire (section 7.3.5). Ces opérations modifiant une
classe globale et partagée, elles sont sérialisées par un `Mutex` dans
`AXPLReflexivityEngine` pour rester sûres sous requêtes concurrentes.

### CORS

`Access-Control-Allow-Origin` vaut `'*'` par défaut (pratique en développement
local). Avant tout déploiement public, restreindre à l'origine exacte du
frontend :

```st
AXPLHttpServer allowedOrigin: 'https://mon-frontend.example.com'.
```

## Architecture

Le framework intègre nativement quatre dimensions autour d'une méta-description unique :

- **A** — Adaptation contextuelle (AXPLFormBuilder)
- **X** — Explicabilité native (AXPLSpecVisitor)
- **Ψ** — Réflexivité actionnable (AXPLReflexivityEngine)
- **L** — Accessibilité Low-Code (SRFormApp)

## Packages

- `AXPL-Descriptions` — Extension du vrai [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (niveau #simple/#base/#expert, explicabilité graduée)
- `AXPL-Core` — Moteurs A et Ψ, registre de domaines (`AXPLDomainRegistry`), registre
  de types de champs (`AXPLFieldTypeRegistry`), hiérarchie d'erreurs (`AXPLApiError`)
- `AXPL-UI` — Interface L
- `AXPL-HTTP` — Serveur Teapot/JSON pour un frontend web, neutre vis-à-vis du domaine
- `AXPL-Tests` — 10 tests unitaires

## Dépendance

AXPL **dépend réellement** de [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (Ducasse et al., MIT License), déclaré comme projet externe dans `BaselineOfAXPL`. Le package `AXPL-Descriptions` n'y ajoute que ce que SimpleRene n'a pas nativement — les propriétés `level`/`level:` et `commentFor:` (explicabilité graduée par niveau) — via des méthodes d'extension sur `SRDescription`, plutôt qu'en dupliquant sa hiérarchie de classes.

## Licence

MIT License — voir le fichier LICENSE.

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
