# Construit la Pyramide

Dépôt source du jeu Roblox **Construit la Pyramide**.

Le code initial provient du pack **Build a Pyramid** fourni au projet avec autorisation d'utilisation du développeur. L'import Git conserve une baseline fidèle avant nos futures modifications.

## Baseline complète

Le dépôt contient désormais les deux représentations complémentaires du projet d'origine :

- **`place/buildapiramid.rbxl`** : snapshot binaire intégral de la place Roblox d'origine.
- **`src/`** : les **49 scripts Lua** extraits et organisés en fichiers lisibles/modifiables.

Le snapshot `.rbxl` conserve tout ce qui est sérialisé dans la place : map, GUI, modèles, Parts/MeshParts, propriétés, Attributes, RemoteEvents, BindableEvents, prompts, références d'assets et scripts.

### Vérification du snapshot

- Taille : **609084 octets**
- SHA-256 : `8ed8a1315d2a69fffa87a1e81c0bac8f44e8d3a2f50b780175d7de1197ec5e50`
- Git blob SHA : `7cab2b3aeb70a8eff1e14cad877dc97d47c867c1`

Le Git blob SHA obtenu sur GitHub correspond exactement au hash calculé depuis le fichier original fourni, ce qui confirme une copie octet pour octet.

## Scripts importés

- **14 Script** serveur
- **14 LocalScript** client
- **21 ModuleScript**
- **49 scripts Lua au total**

Les systèmes présents couvrent notamment la construction de pyramides, le ramassage de blocs, les chambres, l'entraînement, les upgrades, la sauvegarde, les achats, Pharaoh, les récompenses de groupe, les classements, l'administration, les paramètres et l'interface.

## Organisation

```text
place/
└── buildapiramid.rbxl       # snapshot intégral de référence

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

`default.project.json` permet de synchroniser les sources Lua avec une place Roblox existante. Les nœuds utilisent `$ignoreUnknownInstances: true` afin de ne pas supprimer les instances non représentées individuellement dans `src/`.

Pour retrouver exactement la place d'origine, utilisez directement `place/buildapiramid.rbxl`. Pour développer le code avec Git/Rojo, utilisez les fichiers sous `src/`.

## Assets externes

Les références Roblox d'assets (meshes, textures, images, vêtements, animations, etc.) sont conservées exactement dans le `.rbxl` et dans les scripts lorsqu'elles y figurent. Les octets des assets hébergés séparément par Roblox ne sont pas nécessairement intégrés au fichier `.rbxl` lui-même.

## Méthode de travail

Cette version constitue la **baseline de référence complète**. Les prochaines modifications du jeu devront être faites dans des commits ou branches séparés afin de garder une trace claire des différences avec le pack d'origine.
