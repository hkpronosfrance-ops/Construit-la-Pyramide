# Liaison Roblox Studio ↔ GitHub avec Rojo

Ce projet utilise **Rojo 7.7.1** pour synchroniser les fichiers du dépôt avec Roblox Studio.

## Architecture

```
GitHub ↔ dossier local Git ↔ Rojo ↔ Roblox Studio
```

GitHub ne parle pas directement à Roblox Studio. Le dépôt est cloné sur ton PC, Rojo surveille les fichiers locaux, puis le plugin Rojo applique les changements dans Studio.

## Première installation sous Windows

1. Installe Git si nécessaire.
2. Installe Rokit : https://github.com/rojo-rbx/rokit
3. Clone le dépôt :

```powershell
git clone https://github.com/hkpronosfrance-ops/Construit-la-Pyramide.git
cd Construit-la-Pyramide
```

4. Installe les outils définis dans `rokit.toml` :

```powershell
rokit install
```

5. Installe le plugin Rojo dans Roblox Studio :

```powershell
rojo plugin install
```

6. Ouvre **`place/buildapiramid.rbxl`** dans Roblox Studio.
7. À la racine du dépôt, démarre Rojo :

```powershell
rojo serve default.project.json
```

8. Dans Roblox Studio, ouvre le plugin **Rojo**, puis clique sur **Connect**.

Les modifications apportées aux fichiers dans `src/` sont alors synchronisées dans Studio.

## Travail quotidien

Avant de commencer :

```powershell
git pull
rojo serve default.project.json
```

Puis ouvre la place et connecte le plugin Rojo.

Quand tu as fini :

```powershell
git status
git add .
git commit -m "Description de la modification"
git push
```

## Modifications faites directement dans Roblox Studio

Rojo 7.7 propose aussi des fonctions de synchronisation inverse. Cependant, pour ce projet, la méthode la plus sûre reste :

- scripts/code : modifier les fichiers dans le dépôt local ;
- map/GUI/modèles : modifier dans Studio puis sauvegarder la place `.rbxl` ;
- pour une conversion plus complète Studio → fichiers, utiliser `rojo syncback` de manière volontaire, hors d'une session `rojo serve` active.

Éviter d'utiliser un syncback global pendant que `rojo serve` est connecté : certains cas de duplication d'instances sont encore signalés avec Rojo 7.7.x.

## Important

Le fichier `default.project.json` utilise `$ignoreUnknownInstances: true`. Rojo peut donc mettre à jour les scripts suivis par Git sans supprimer la map, les GUI ou les autres objets qui ne sont pas encore décrits individuellement dans `src/`.

Le fichier `place/buildapiramid.rbxl` reste le snapshot complet de référence.
