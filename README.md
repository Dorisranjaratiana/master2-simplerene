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
- Ψ ↶ : *Ψ → Annuler la dernière modification Ψ* défait les intercessions une à une, de la plus récente à la plus ancienne (création, suppression — le champ revient à sa place avec sa valeur et ses explications —, renommage, niveau, explication) ; l'annulation est tracée
- 💾 sauvegarde STON : *Enregistrer* écrit le dossier (valeurs + modifications Ψ + trace) dans un fichier lisible, *Ouvrir…* le recharge ; les modifications Ψ sont rejouées sur un formulaire neuf et restent annulables ; les mots de passe ne sont jamais écrits ; une valeur invalide dans le fichier n'est pas réécrite
- web : `explanation` facultatif dans `POST /psi/create-field`, nouvelles routes `POST /psi/explain` et `POST /psi/undo`
- ② explications rangées dans les propriétés de la description (`propertyAt: #axplExplanation`) par un décorateur `AXPLExplanation`, au lieu du `comment` de SimpleRene (qui reste une aide String, affichable par Spec-Form) ; ancien format toujours lu
- Ψ : API documentée en trois familles (introspection, intercession, histoire), introspection complétée (`fields`, `labels`, `levelOf:`, `typeOf:`, `explanationOf:forLevel:`, `psiCreatedLabels`)
- scénario réflexif exécutable `AXPLReflexiveScenario` (l'épidémie), `AXPLFormApp openOn:level:`
- 148 tests

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
framework psiEngine lastUndoableChange.    "'Explication : Nom [tous niveaux]'"
framework psiEngine undoLast.    "↶ défait la dernière intercession (canUndo pour savoir s'il en reste)"
framework saveTo: 'patient.ston'.    "💾 valeurs + modifications Ψ + trace, en STON"
framework := AXPLFramework loadFrom: 'patient.ston'.    "💾 objet et formulaire retrouvés"
```

Dans `AXPLFormApp`, *Enregistrer* (si toutes les valeurs sont valides) et *Ouvrir…* utilisent le dossier `axpl-dossiers` à côté de l'image Pharo.

Tous les visiteurs se construisent de la même façon, avec l'objet métier et le niveau — le visiteur Spec2 demande en plus un presenter pour ses widgets :

```st
json := (AXPLJsonVisitor on: client level: #simple) visit: visible.
layout := ((AXPLSpecVisitor on: client level: #simple) presenter: unSpPresenter; yourself) visit: visible.
```

## Réflexivité Ψ — l'API

Le moteur Ψ (`framework psiEngine`, classe `AXPLReflexivityEngine`) permet au formulaire de **s'observer et de se modifier pendant que l'application tourne**, sans toucher au code de la classe métier, sans recompiler ni redémarrer. Il agit sur le méta-modèle (les descriptions SimpleRene du formulaire). Ses méthodes sont rangées en trois familles, qui sont aussi les catégories de méthodes de la classe :

**Introspection ③** — lire le méta-modèle

| Message | Réponse |
|---|---|
| `fields`, `labels` | les champs du formulaire |
| `readDescription: 'Nom'` | la description SimpleRene du champ (ou `nil`) |
| `levelOf: 'Nom'`, `typeOf: 'Nom'` | son niveau, sa classe de description |
| `explanationOf: 'Nom' forLevel: #base` | son explication ② à ce niveau |
| `psiCreatedLabels` | les champs créés à l'exécution par Ψ |

**Intercession ④⑤⑥⑨** — modifier le méta-modèle à l'exécution

| Message | Effet |
|---|---|
| `createField: 'Note' type: SRStringDescription level: #base explanation: '…'` | ⑥ nouveau champ (Texte, Nombre, Booléen, Date…) |
| `createSelectionField: 'Groupe' options: #('A' 'B') level: #base explanation: '…'` | ⑥ nouveau champ à choix |
| `removeField: 'Note'` | ⑥ retire un champ |
| `relabelDescription: 'Allergies' to: 'Risques'` | ④ renomme (les explications sont gardées) |
| `setLevel: #simple ofDescription: 'Allergies'` | ⑨ change le niveau qui voit le champ |
| `updateExplanation: 'Nom' forLevel: #expert with: '…'` / `updateExplanation: 'Nom' with: '…'` | ⑤② change l'explication (un niveau / tous) |

Garanties : niveau inconnu refusé, label en double refusé, champ inconnu sans effet. Un champ créé n'a pas de variable d'instance : sa valeur vit dans le dictionnaire `properties` de l'objet métier.

**Histoire [t] ↶ 💾** — garder la trace, annuler, rejouer

| Message | Rôle |
|---|---|
| `traceLog` | chaque intercession, horodatée |
| `canUndo`, `lastUndoableChange`, `undoLast` | annuler, de la plus récente à la plus ancienne |
| `changes`, `replayChanges:` | les intercessions actives en données (sans bloc) : sauvegarde STON et rejeu |

## Scénario réflexif : l'épidémie

`AXPLReflexiveScenario` (package `AXPL-Scenarios`) est un scénario d'action réflexive exécutable, vérifié par la CI (`AXPLReflexiveScenarioTest`). Le dossier patient `ClientHopital` est en service ; une épidémie se déclare et le médecin-chef adapte le formulaire **pendant que l'application tourne** :

1. **Introspection ③** — l'infirmière (Simple) voit 5 champs ; « Allergies » est réservé au niveau Expert.
2. **Intercession ⑥②** — création de « Statut infectieux » (Simple), avec une explication par niveau.
3. **Intercession ⑨** — « Allergies » devient visible dès le niveau Simple.
4. **Intercession ④⑤** — renommé « Risques allergiques », explication Simple adaptée.
5. **Effet ①** — sans redémarrer, l'infirmière voit 7 champs et saisit les valeurs.
6. **Trace [t]** — 5 intercessions horodatées.
7. **Sauvegarde 💾** — le dossier rechargé a le même formulaire et les mêmes valeurs.
8. **Annulation ↶** — fin de l'épidémie : le formulaire redevient celui du code.

```st
AXPLReflexiveScenario run log.    "exécute les 8 étapes et renvoie le récit"
AXPLReflexiveScenario demo.       "étapes 1 à 7, récit dans le Transcript, fenêtre ouverte au niveau Simple"
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
| `explanation:` sur chaque description | Optionnel | ② explicabilité graduée : une String (même explication à tous les niveaux) ou un `Dictionary` clé = niveau (ex: `Dictionary new at: #simple put: '...'; at: #expert put: '...'; yourself`). Rangée dans les **propriétés** de la description (`propertyAt: #axplExplanation`, décorateur `AXPLExplanation`) ; le `comment:` de SimpleRene reste une simple aide (String) et sert de repli. Un ancien `comment:` Dictionary (AXPL v1) reste lu |
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
- `AXPL-Scenarios` — scénario réflexif exécutable (`AXPLReflexiveScenario`), au-dessus du framework et des exemples
- `AXPL-Json` — Export JSON pur (aucune dépendance Spec2), pour un frontend web séparé
- `AXPL-Web` *(groupe `web` uniquement)* — API HTTP ([Teapot](https://github.com/zeroflag/Teapot) + [NeoJSON](https://github.com/svenvc/NeoJSON)) exposant AXPL-Json et Ψ à un frontend externe (React, etc.)
- `AXPL-Tests` — suite de tests unitaires (①, Ψ, ⑦, généricité, extensions SimpleRene, façade) — groupe `core`
- `AXPL-Web-Tests` *(groupe `web` uniquement)* — tests du serveur HTTP, seul package avec `AXPL-Web` à dépendre de Teapot/NeoJSON

Un chargement par défaut (`load.`) tire le groupe `default` = `core` = tout sauf `AXPL-Web`/`AXPL-Web-Tests`. C'est volontaire : le framework reste utilisable et testable 100% côté Pharo sans jamais toucher à une dépendance web, celle-ci n'étant chargée qu'à la demande (`load: #('web')`).

## Dépendance

AXPL **dépend réellement** de [SimpleRene](https://github.com/pharo-contributions/SimpleRene) (Ducasse et al., MIT License), déclaré comme projet externe dans `BaselineOfAXPL`. Le package `AXPL-Descriptions` n'y ajoute que ce que SimpleRene n'a pas nativement — le niveau `level`/`level:` et l'explicabilité graduée `explanation:`/`commentFor:` — via des méthodes d'extension sur `SRDescription`, rangés dans son dictionnaire de **propriétés** (`propertyAt:`, le mécanisme d'extension de SimpleRene) plutôt qu'en dupliquant sa hiérarchie de classes ou en détournant un de ses champs. L'explication est un décorateur, `AXPLExplanation` (texte par niveau, texte commun, origine : champ déclaré ou créé par Ψ).

**Spec2** est livré avec toute image Pharo : on ne le déclare pas en dépendance de baseline, comme tout projet qui utilise l'interface native de Pharo.

**Sur Spec-Form** : [Spec-Form](https://github.com/pharo-spec/Spec-Form) (Esteban Lorenzano, organisation pharo-spec) est un prototype qui génère des formulaires Spec2 à partir des descriptions SimpleRene (`unObjet asFormPresenter`, mise en page en grille). AXPL **ne l'utilise pas encore** : son générateur desktop (`AXPLSpecVisitor`) est autonome — c'est la version présentée au jury. Ce qu'AXPL apporte en plus d'un formulaire généré (filtrage par niveau ①, explications graduées ②, réflexivité Ψ, trace, annulation, sauvegarde) ne dépend pas de la façon d'afficher les champs ; réutiliser Spec-Form pour l'affichage est une piste de travail. Deux points à régler pour cela :
- ✅ Spec-Form affiche le `comment` d'une description comme texte d'aide : AXPL n'y range plus ses explications par niveau (elles sont dans `propertyAt: #axplExplanation`), le `comment` reste une String comme le prévoit SimpleRene ;
- vérifier que Spec-Form (dernier commit : novembre 2023) se charge et fonctionne avec Pharo 13 et la version de SimpleRene épinglée par AXPL.

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
| `POST /psi/undo` | Ψ ↶ — annule la dernière modification Ψ (`{ok, undone}`), ou `{error}` s'il n'y en a plus |
| `POST /psi/remove-field` `{label}` | Ψ — supprime un champ |
| `GET /psi/trace` | Historique horodaté Ψ |

Un champ Date envoyé par le web arrive en String JSON ISO 8601 (`AAAA-MM-JJ`) — `POST /field` la convertit en `Date` Pharo avant validation/écriture, pour ne jamais casser l'affichage desktop du même champ.

Toutes les routes `POST` sont couvertes par des tests qui simulent un vrai corps JSON (`AXPLWebServerTest`), y compris la conversion explicite des clés d'objet JSON en `Symbol` — sans elle, `NeoJSONReader` les parse en `String` par défaut et chaque route échouerait silencieusement (rattrapée en `{error: ...}` par `safely:`, mais jamais fonctionnelle) sur une vraie requête HTTP.

## Licence

MIT License — voir le fichier LICENSE.

## Auteur

RANJARATIANA Doris Michel — ENI Fianarantsoa — 2026
