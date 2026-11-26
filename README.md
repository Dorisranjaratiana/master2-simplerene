# Framework AXΨL — Pilotage adaptatif des interfaces

Framework Low-Code pour le pilotage natif des interfaces adaptatives.

## Chargement en une ligne (Pharo 13)

Version de **développement** (branche `integration-simplerene`) : les dernières améliorations, peut changer à tout moment. La version stable figée **v1.0.0** se trouve dans le dépôt `AXPL-Pharo` (voir son README).

Un chargement simple reste **100% côté Pharo** : SimpleRene, les moteurs ①Ψ, l'UI desktop (Spec2) et l'export JSON, sans toucher à Teapot/NeoJSON ni au serveur HTTP.

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2-simplerene:integration-simplerene/src';
    onConflict: [ :ex | ex useIncoming ];
    load.
```

Pour charger en plus la partie web (serveur HTTP `AXPL-Web`, Teapot, NeoJSON) :

```st
Metacello new
    baseline: 'AXPL';
    repository: 'github://Dorisranjaratiana/master2-simplerene:integration-simplerene/src';
    onConflict: [ :ex | ex useIncoming ];
    load: #('web').
```


`onConflict: [ :ex | ex useIncoming ]` : SimpleRene, Teapot et NeoJSON sont épinglés sur un commit précis. Si l'image en contient déjà une autre version (NeoJSON chargé par un autre projet, par exemple), Metacello lève sinon un `MetacelloConflictingProjectError` au lieu de choisir : cette ligne lui dit de prendre la version demandée par AXPL — la même règle que la CI (`.smalltalk.ston`).

## Versions

**En développement** (branche `integration-simplerene`, après v1.0.0) :
- Ψ ② : un champ créé par Ψ reçoit son explication dès la création (facultative) ; *Ψ → Modifier un champ → Modifier l'explication* change l'aide d'un champ, pour un niveau ou pour tous, sans effacer celle des autres niveaux ; chaque changement d'explication est tracé
- web : `explanation` facultatif dans `POST /psi/create-field`, nouvelle route `POST /psi/explain`
- 105 tests

**v1.0.0** — première version stable :
- dépendance réelle à SimpleRene (extensions, jamais de réimplémentation), Teapot et NeoJSON — toutes épinglées sur un commit
- façade `AXPLFramework`, protocole d'extension `descriptionForAXPL` documenté
- niveaux configurables (`AXPLFormBuilder levels:`), contrat de visiteur commun (`on:level:`)
- Ψ : création, suppression, renommage (explications ② conservées, doublons refusés), changement de niveau validé, traçabilité horodatée
- explication des champs masqués par le niveau qui les débloque (desktop et web)
- types SimpleRene non gérés refusés explicitement ; mots de passe masqués et jamais renvoyés au web
- toute saisie validée par les règles de SimpleRene avant d'être écrite ; une saisie refusée est signalée (infobulle du champ, haut de la fenêtre) et bloque Enregistrer ; le web renvoie le message de SimpleRene
- interface desktop (`AXPLFormApp`) : écran neutre au départ et après Annuler, un niveau choisi s'affiche directement, fenêtre ajustée au nombre de champs et jamais plus haute que l'écran
- serveur web : CORS complet pour un frontend séparé, mode débogage de Zinc désactivé par défaut
- groupes de chargement `core` (100% Pharo) et `web`
- 89 tests (cœur, Ψ, validation, visiteurs, interface desktop dont une vraie fenêtre ouverte, serveur web), exécutés par la CI à chaque push

## Utilisation

```st
"Domaine médical"
AXPLFormApp new
    targetObject: ClientHopital new;
    open.
```

```st
"Domaine académique"
AXPLFormApp new
    targetObject: Etudiant new;
    open.
```

## Façade (AXPLFramework)

Un point d'entrée unique cache l'assemblage manuel de ① et Ψ (dériver le metaContainer, construire un `AXPLFormBuilder`, créer l'engine Ψ) — utile dès qu'on n'a pas besoin d'un `AXPLFormApp` complet (export JSON, script, tests...) :

```st
| framework visible |
framework := AXPLFramework for: ClientHopital new.
visible := framework visibleFieldsAt: #simple.    "① — filtrage par niveau"
framework psiEngine createField: 'Note interne' type: SRStringDescription level: #expert.    "Ψ"
framework psiEngine
    createField: 'Groupe sanguin' type: SRStringDescription level: #base
    explanation: 'Indispensable avant une transfusion.'.    "Ψ ② — avec son aide"
framework psiEngine updateExplanation: 'Nom' forLevel: #expert with: 'Nom d''état civil.'.    "② un niveau"
framework psiEngine updateExplanation: 'Nom' with: 'Nom de famille.'.    "② tous les niveaux"
```

Tous les visiteurs se construisent de la même façon, avec l'objet métier et le niveau — le visiteur Spec2 demande en plus un presenter pour ses widgets :

```st
json := (AXPLJsonVisitor on: client level: #simple) visit: visible.
layout := ((AXPLSpecVisitor on: client level: #simple) presenter: unSpPresenter; yourself) visit: visible.
```

## Niveaux configurables

Les niveaux ne sont pas figés à `#simple #base #expert` : ils se configurent sans toucher au framework, du moins au plus privilégié. Chaque niveau voit ses champs et ceux des niveaux inférieurs ; le dernier voit tout et a accès à Ψ dans `AXPLFormApp`.

```st
AXPLFormBuilder levels: #(#visiteur #simple #base #expert).
AXPLFormBuilder resetLevels.    "retour à #(#simple #base #expert)"
```

Le filtrage ①, la validation Ψ et les listes de l'interface lisent tous `AXPLFormBuilder levels`. Un champ dont le niveau n'est pas dans la liste n'est visible que par le niveau le plus privilégié.

## Étendre AXPL — le protocole `descriptionForAXPL`

C'est l'unique point de branchement entre une classe métier et le framework. `ClientHopital` et `Etudiant` (dans `AXPL-Examples`) ne sont que deux exemples parmi une infinité possible — n'importe quelle classe peut devenir utilisable par AXPL en implémentant une seule méthode **de classe** :

```st
MaClasse class >> descriptionForAXPL [
    ^ SRPriorityContainer new
]
```

### Contrat

| | Obligatoire | Détail |
|---|---|---|
| Retour | **Oui** | Une instance de `SRPriorityContainer` (réel, de SimpleRene) |
| `label:` sur chaque description | **Oui** | Une String, **unique** dans le container — Ψ (`readDescription:`/`relabelDescription:`/`removeField:`) identifie un champ par son label ; un doublon rend le second champ inaccessible à Ψ |
| `accessor:` sur chaque description | **Oui** | Un Symbol correspondant à un getter/setter d'instance sur `MaClasse` (ex: `#nom` requiert `nom`/`nom:`) |
| `priority:` sur chaque description | Recommandé | Un Integer — `SRPriorityContainer` trie ses enfants par priorité ; sans cette valeur, l'ordre d'affichage n'est pas garanti |
| `level:` sur chaque description | Recommandé | Un des niveaux de `AXPLFormBuilder levels` (par défaut `#simple`, `#base`, `#expert`) — sans cette valeur, `#simple` s'applique (valeur de repli dans `SRDescription >> level`, extension AXPL) |
| `comment:` sur chaque description | Optionnel | Une String (même explication à tous les niveaux) ou un `Dictionary` clé = niveau (② — explicabilité graduée, ex: `Dictionary new at: #simple put: '...'; at: #expert put: '...'; yourself`) |
| `properties` sur `MaClasse` | Nécessaire **seulement** pour Ψ | `^ properties ifNil: [ properties := Dictionary new ]` — requis uniquement si vous voulez que `AXPLReflexivityEngine>>createField:type:level:` puisse ajouter un champ à l'exécution sans variable d'instance dédiée (voir `SRPluggableAccessor`) |

### Classes de description disponibles

Toutes réelles, de SimpleRene, étendues par `AXPL-Descriptions` (jamais réimplémentées) :

- `SRStringDescription` — texte
- `SRNumberDescription` — nombre (`bePositive` pour valider > 0)
- `SRBooleanDescription` — case à cocher
- `SRDateDescription` — date
- `SRSingleOptionDescription` — liste déroulante (requiert aussi `options: #('A' 'B' ...)`)
- `SRPasswordDescription` — mot de passe : masqué sur le desktop, **jamais renvoyé** dans le JSON du web (il s'écrit, il ne se relit pas)

`SRMemoDescription` est affiché comme un texte d'une ligne. Tout autre type SimpleRene (`SRTimeDescription`, `SRDateAndTimeDescription`, `SRMultipleOptionDescription`, `SRSymbolDescription`, relations, fichiers…) **lève une erreur explicite** au rendu (« Type de description non supporté par AXPL : … ») plutôt que de devenir un champ texte qui n'enregistrerait jamais rien. Pour en ajouter un : une méthode d'extension `acceptAXPLVisitor:` sur la classe SimpleRene, et la méthode `visitXxxDescription:` correspondante dans chaque visiteur.

Validation native de SimpleRene, transparente avec AXPL : `beRequired`, `bePositive`, `addCondition: [ :v | ... ] labelled: 'message'`.

### Exemple minimal

```st
Object subclass: #Produit
    instanceVariableNames: 'nom prix'
    classVariableNames: ''
    package: 'MonAppli'.

Produit class >> descriptionForAXPL [
    | container |
    container := SRPriorityContainer new.
    container add: (SRStringDescription new
        label: 'Nom'; accessor: #nom; priority: 10; level: #simple; beRequired).
    container add: (SRNumberDescription new
        label: 'Prix'; accessor: #prix; priority: 20; level: #simple; bePositive).
    ^ container
]

"accessor: #nom exige un getter/setter d'instance — ici générés par
l'outil 'Create accessors' du navigateur, ou écrits à la main :"
Produit >> nom [ ^ nom ]
Produit >> nom: anObject [ nom := anObject ]
Produit >> prix [ ^ prix ]
Produit >> prix: anObject [ prix := anObject ]
```

Puis, exactement comme avec `ClientHopital` ou `Etudiant` : `AXPLFramework for: Produit new`, ou `AXPLFormApp new targetObject: Produit new; open`. **Aucune ligne du framework à modifier.**

Votre classe métier n'a pas à vivre dans un package AXPL — `AXPL-Examples` n'est qu'une démonstration ; la vôtre vit dans votre propre package, qui ne requiert qu'`AXPL-Descriptions` dans sa baseline.

## Architecture

Le framework intègre nativement quatre dimensions autour d'une méta-description unique :

- **A** — Adaptation contextuelle (AXPLFormBuilder, exposé via AXPLFramework)
- **X** — Explicabilité native (AXPLSpecVisitor)
- **Ψ** — Réflexivité actionnable (AXPLReflexivityEngine, exposé via AXPLFramework)
- **L** — Accessibilité Low-Code (AXPLFormApp)

## Packages

- `AXPL-Descriptions` — Extension du vrai [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (niveau #simple/#base/#expert, explicabilité graduée)
- `AXPL-Core` — Moteurs A et Ψ, et la façade `AXPLFramework`
- `AXPL-Examples` — objets métier de démonstration (`ClientHopital`, `Etudiant`) — **ne fait pas partie du framework** : il ne requiert qu'`AXPL-Descriptions`, jamais l'inverse
- `AXPL-UI` — Interface L (desktop, Spec2)
- `AXPL-Json` — Export JSON pur (aucune dépendance Spec2), pour un frontend web séparé
- `AXPL-Web` *(groupe `web` uniquement)* — API HTTP ([Teapot](https://github.com/zeroflag/Teapot) + [NeoJSON](https://github.com/svenvc/NeoJSON)) exposant AXPL-Json et Ψ à un frontend externe (React, etc.)
- `AXPL-Tests` — suite de tests unitaires (①, Ψ, ⑦, généricité, extensions SimpleRene, façade) — groupe `core`
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

Le mode débogage de Zinc est désactivé par défaut (une erreur renvoie une réponse 500 au lieu d'ouvrir le débogueur Pharo et de bloquer la requête). Pour déboguer en local : `AXPLWebServer new targetObject: ClientHopital new; debugMode: true; start: 8080`. Pour arrêter un serveur dont on a perdu la référence : `Teapot stopAll`.

Routes disponibles (CORS ouvert, pratique pour un frontend en développement local sur un autre port — Vite, CRA...) :

| Route | Description |
|---|---|
| `GET /form?level=simple\|base\|expert` | Champs visibles à ce niveau (`fields`), et champs masqués avec le niveau qui les débloque (`hidden: [{label, requiredLevel}]`) |
| `POST /field` `{label, value}` | Écrit une valeur validée ; sinon `{error}` contient le message de SimpleRene (champ requis, condition non respectée…) |
| `POST /psi/rename` `{oldLabel, newLabel}` | Ψ — renomme un champ |
| `POST /psi/set-level` `{label, level}` | Ψ — change le niveau d'un champ |
| `POST /psi/create-field` `{label, type, level, options?, explanation?}` | Ψ — crée un champ (`type` : `string`/`number`/`boolean`/`date`/`select`), avec son explication ② facultative |
| `POST /psi/explain` `{label, text, level?}` | Ψ ② — change l'explication d'un champ pour `level`, ou pour tous les niveaux sans `level` |
| `POST /psi/remove-field` `{label}` | Ψ — supprime un champ |
| `GET /psi/trace` | Historique horodaté Ψ |

Un champ Date envoyé par le web arrive en String JSON ISO 8601 (`AAAA-MM-JJ`) — `POST /field` la convertit en `Date` Pharo avant validation/écriture, pour ne jamais casser l'affichage desktop du même champ.

Toutes les routes `POST` sont couvertes par des tests qui simulent un vrai corps JSON (`AXPLWebServerTest`), y compris la conversion explicite des clés d'objet JSON en `Symbol` — sans elle, `NeoJSONReader` les parse en `String` par défaut et chaque route échouerait silencieusement (rattrapée en `{error: ...}` par `safely:`, mais jamais fonctionnelle) sur une vraie requête HTTP.

## Licence

MIT License — voir le fichier LICENSE.

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
