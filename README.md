# Construit la Pyramide

Dépôt source du jeu Roblox **Construit la Pyramide**.

Le code initial provient du pack **Build a Pyramid** fourni au projet avec autorisation d'utilisation du développeur. L'import Git conserve les scripts du fichier Roblox d'origine comme base de référence avant nos futures modifications.

## Contenu importé

- **49 scripts Lua**
- **14 Script** serveur
- **14 LocalScript** client
- **21 ModuleScript**
- Sources classées selon leur emplacement Roblox dans `src/`

Les systèmes présents couvrent notamment la construction de pyramides, le ramassage de blocs, les chambres, l'entraînement, les upgrades, la sauvegarde, les achats, Pharaoh, les récompenses de groupe, les classements, l'administration, les paramètres et l'interface.

## Organisation

```text
src/
├── ReplicatedStorage/
├── ServerScriptService/
├── StarterPlayer/
│   └── StarterPlayerScripts/
└── Workspace/
    └── PyramidMap/
        └── Pharaoh/
            └── PharaohNPC/
```

Les fichiers `.server.lua` correspondent aux `Script`, les fichiers `.client.lua` aux `LocalScript`, et les fichiers `.lua` aux `ModuleScript`.

## Rojo

`default.project.json` permet de synchroniser ces sources avec la place existante. Les nœuds utilisent `$ignoreUnknownInstances: true` car le dépôt versionne actuellement le code Lua, tandis que la place `.rbxl` contient encore les GUI, la map, les assets, RemoteEvents, Attributes et autres instances indispensables.

**Ne construisez pas une place vide uniquement depuis ce dépôt en supposant qu'elle contiendra toute la map.** Utilisez le fichier Roblox d'origine comme base, puis synchronisez les scripts avec Rojo.

Voir `docs/SOURCE_IMPORT.md` pour les détails de l'import.

## Méthode de travail

L'import initial sert de baseline fidèle. Les prochaines modifications du jeu devront être faites dans des commits ou branches séparés afin de garder une trace claire des différences avec le pack d'origine.
