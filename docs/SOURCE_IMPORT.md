# Import du pack Build a Pyramid

Ce dépôt contient le miroir Git des **49 scripts Lua** extraits du fichier Roblox d'origine.

## Principe

- Les sources importées sont conservées sans refactor de gameplay lors de l'import initial.
- Les suffixes `.server.lua` et `.client.lua` représentent respectivement les `Script` et `LocalScript` Roblox.
- Les autres fichiers `.lua` représentent des `ModuleScript`.
- Les chemins sous `src/` reprennent les services et l'arborescence Roblox d'origine.

## Important : contenu non scripté

Le fichier `.rbxl` d'origine contient également la map, les GUI, Parts, MeshParts, RemoteEvents, BindableEvents, Attributes et autres instances nécessaires au fonctionnement du jeu. Ils ne sont pas tous recréés par ces fichiers Lua.

Le projet Rojo utilise `$ignoreUnknownInstances: true` afin de ne pas supprimer les instances existantes de la place pendant une synchronisation. Il doit être utilisé avec la place Roblox d'origine ou avec une place contenant les mêmes dépendances.

## Répartition

- 14 scripts serveur
- 14 scripts client
- 21 ModuleScripts
- 49 scripts au total

## Source de référence

L'import initial provient du fichier `buildapiramid.rbxl` fourni pour le projet **Construit la Pyramide** avec autorisation d'utilisation du développeur du pack.
