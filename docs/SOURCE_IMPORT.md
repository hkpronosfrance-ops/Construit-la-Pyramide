# Import du pack Build a Pyramid

Ce dépôt conserve maintenant une copie complète de la place Roblox d'origine ainsi qu'une extraction lisible de tout son code Lua.

## Snapshot intégral

Le fichier original est versionné sous :

`place/buildapiramid.rbxl`

Vérification :

- taille : **609084 octets**
- SHA-256 : `8ed8a1315d2a69fffa87a1e81c0bac8f44e8d3a2f50b780175d7de1197ec5e50`
- Git blob SHA : `7cab2b3aeb70a8eff1e14cad877dc97d47c867c1`

Ce snapshot est la source de vérité pour les éléments non représentés individuellement dans le dépôt : map, GUI, modèles, Parts, MeshParts, propriétés, Attributes, RemoteEvents, BindableEvents, prompts et autres instances Roblox sérialisées.

## Sources Lua extraites

Les **49 scripts Lua** ont également été extraits dans `src/` afin de pouvoir travailler proprement avec Git :

- 14 scripts serveur
- 14 scripts client
- 21 ModuleScripts

Les suffixes `.server.lua` et `.client.lua` représentent respectivement les `Script` et `LocalScript` Roblox. Les autres fichiers `.lua` représentent des `ModuleScript`.

Les chemins sous `src/` reprennent les services et l'arborescence Roblox d'origine.

## Rojo

Le projet Rojo utilise `$ignoreUnknownInstances: true`. Cette configuration permet de synchroniser les scripts avec la place sans supprimer les milliers d'instances qui ne sont pas encore décrites individuellement comme fichiers Rojo.

Le `.rbxl` complet reste donc la référence exacte de la place, tandis que `src/` est la représentation pratique pour modifier le code.

## Assets

Les IDs et références aux assets Roblox sont conservés dans la place. Lorsqu'un asset est hébergé séparément sur Roblox, son fichier source externe n'est pas nécessairement embarqué dans le `.rbxl` ; le snapshot conserve toutefois la référence exacte utilisée par la place.

## Provenance

L'import initial provient du fichier `buildapiramid.rbxl` fourni pour le projet **Construit la Pyramide**, avec autorisation d'utilisation du développeur du pack.
