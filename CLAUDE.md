# CLAUDE.md — Construit la Pyramide

Ce fichier est la **référence de travail principale** pour Claude Code lorsqu’il intervient sur le projet Roblox **Construit la Pyramide**, en particulier lorsqu’il est connecté à Roblox Studio via MCP.

L’objectif est de permettre des modifications sûres, cohérentes et autonomes sans casser la map, Rojo, l’économie, les GUI existantes ou les systèmes du jeu.

---

# 1. Identité du projet

## Jeu

Nom : **Construit la Pyramide**

Concept général :
- jeu Roblox de construction/progression autour d’une pyramide ;
- le joueur ramasse des blocs, les transporte et les dépose pour construire une pyramide ;
- il entraîne sa **Vitesse** et sa **Force** ;
- il gagne des **Pièces** ;
- il termine des **Pyramides** ;
- des upgrades, zones d’entraînement, boosts, achats, classements et récompenses accompagnent la progression ;
- le jeu utilise un style visuel Roblox/cartoon très lisible, coloré et volontairement exagéré.

Le projet provient à l’origine d’un pack **Build a Pyramid** utilisé avec autorisation du développeur. Le code a ensuite été fortement modifié.

## GitHub

Repository :

\`\`\`text
hkpronosfrance-ops/Construit-la-Pyramide
\`\`\`

## Dossier local principal

Sous Windows :

\`\`\`text
C:\Users\Hayati\Desktop\PYRAMIDE\Construit-la-Pyramide
\`\`\`

## Place Roblox active

\`\`\`text
place\buildapiramid.rbxl
\`\`\`

Cette place contient notamment :
- la map réelle ;
- Workspace ;
- les GUI originales ;
- les instances non recréées par Rojo ;
- RemoteEvents / BindableEvents ;
- Attributes ;
- Parts / MeshParts ;
- assets et instances Roblox nécessaires au jeu.

## Backup factory ABSOLUMENT protégé

\`\`\`text
place\buildapiramid_FACTORY_BACKUP.rbxl
\`\`\`

### Règle absolue

**NE JAMAIS :**
- modifier ce fichier ;
- ouvrir puis sauvegarder par-dessus ;
- remplacer ce fichier ;
- le renommer ;
- le supprimer ;
- le versionner ;
- l’utiliser comme cible de travail ;
- automatiser une écriture dessus.

Le script de sauvegarde du projet exclut volontairement ce backup.

---

# 2. Architecture Git / Rojo / Roblox Studio

## Principe fondamental

Le projet fonctionne avec une séparation volontaire :

### Git + Rojo gèrent principalement

- \`ReplicatedStorage\`
- \`ServerScriptService\`
- \`StarterPlayer/StarterPlayerScripts\`
- les scripts Lua ;
- les ModuleScripts ;
- la logique client et serveur ;
- une grande partie des UI générées/modifiées au runtime.

### La place \`.rbxl\` gère

- la map réelle ;
- \`Workspace\` ;
- les GUI originales non reconstruites entièrement par code ;
- les objets créés manuellement dans Studio ;
- les modèles ;
- les Parts ;
- les MeshParts ;
- les positions ;
- les assets visuels ;
- les RemoteEvents et autres instances non déclarées dans Rojo.

---

# 3. Workspace : règle critique

## Workspace n’est volontairement PAS géré par Rojo

Le fichier :

\`\`\`text
default.project.json
\`\`\`

ne contient volontairement aucun mapping \`Workspace\`.

Configuration actuelle :

\`\`\`json
{
  "name": "Construit la Pyramide",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "$path": "src/ReplicatedStorage",
      "$ignoreUnknownInstances": true
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/ServerScriptService",
      "$ignoreUnknownInstances": true
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$path": "src/StarterPlayer/StarterPlayerScripts",
        "$ignoreUnknownInstances": true
      }
    }
  }
}
\`\`\`

## Règles obligatoires

**NE JAMAIS :**
- réactiver \`Workspace\` dans \`default.project.json\` ;
- ajouter \`src/Workspace\` au tree Rojo ;
- utiliser Rojo pour remplacer la map ;
- lancer une synchronisation qui détruirait des instances inconnues de la place ;
- retirer \`$ignoreUnknownInstances: true\` sans décision explicite du propriétaire.

Le dossier \`src/Workspace\` existe encore comme trace/import de certaines sources historiques, notamment le script du NPC Pharaoh, mais **ce dossier ne signifie pas que Workspace doit être remappé dans Rojo**.

---

# 4. Rojo

Rojo est servi localement sur :

\`\`\`text
localhost:34872
\`\`\`

Après redémarrage du PC :

\`\`\`powershell
cd C:\Users\Hayati\Desktop\PYRAMIDE\Construit-la-Pyramide
git pull
rojo serve
\`\`\`

Puis :
1. ouvrir \`place\buildapiramid.rbxl\` dans Roblox Studio ;
2. connecter le plugin Rojo à \`localhost:34872\` ;
3. Sync ;
4. Ctrl+S ;
5. Stop → Play pour tester.

Quand Claude Code travaille avec le MCP Roblox Studio, il doit tenir compte du fait que Studio et Rojo peuvent modifier des zones différentes du projet.

---

# 5. Règle de travail avec GitHub

Le propriétaire veut que les modifications de code soient faites proprement avec Git.

## Pour une modification de code

Toujours préférer :

1. partir de \`main\` à jour ;
2. créer une branche dédiée ;
3. modifier les fichiers ;
4. vérifier le diff ;
5. créer une Pull Request ;
6. fusionner en **squash merge** ;
7. fournir le commit final.

Éviter les modifications directement sur \`main\`.

## Après merge

Le workflow utilisateur attendu est généralement :

\`\`\`powershell
git pull
\`\`\`

Puis :

\`\`\`text
Rojo sync
Ctrl+S
Stop → Play
\`\`\`

Claude ne doit pas demander à l’utilisateur de modifier manuellement du Lua si Claude a accès aux outils permettant de faire le changement lui-même.

---

# 6. Sauvegarde complète

Script prévu :

\`\`\`powershell
.\scripts\save-project.ps1
\`\`\`

Ce script :
- fait \`git add -A\` ;
- exclut explicitement le factory backup ;
- commit la map active et les scripts ;
- push sur GitHub.

La map active est prévue pour être versionnée sur GitHub.

Toujours conserver la distinction :

\`\`\`text
place/buildapiramid.rbxl
\`\`\`

= map active

et :

\`\`\`text
place/buildapiramid_FACTORY_BACKUP.rbxl
\`\`\`

= copie usine intouchable.

---

# 7. Roblox Studio MCP : rôle attendu

Le MCP Roblox Studio peut être utilisé pour intervenir directement dans la place active.

Il est particulièrement adapté à :
- création de modèles ;
- déplacement de Parts ;
- ajustement de positions ;
- modification de propriétés ;
- construction décorative ;
- duplication d’éléments de map ;
- inspection d’objets existants ;
- analyse du style d’un modèle existant ;
- placement de panneaux ;
- modification d’éléments de \`Workspace\`.

## Avant toute modification de map

Claude doit d’abord inspecter :
- le parent ciblé ;
- les objets voisins ;
- 2 à 3 objets similaires ;
- leurs dimensions ;
- leurs matériaux ;
- leurs couleurs ;
- leurs orientations ;
- leur hiérarchie ;
- leurs noms ;
- leurs collisions ;
- leurs attributs éventuels.

**Ne jamais modéliser “à l’aveugle” si un modèle de référence existe déjà dans la map.**

---

# 8. Règles de modélisation

## Style général

Le jeu n’est pas réaliste.

Le style recherché est :
- Roblox/cartoon ;
- lisible à distance ;
- formes simples ;
- silhouettes claires ;
- volumes exagérés ;
- couleurs saturées ;
- gros contrastes ;
- visuels compréhensibles instantanément ;
- proportions adaptées à une caméra Roblox ;
- objets suffisamment gros pour être compris sans zoom.

## Éviter

- réalisme photoréaliste ;
- détails microscopiques ;
- modèles surchargés ;
- matériaux incompatibles avec le reste de la map ;
- nouvelles palettes arbitraires ;
- objets très fins difficiles à voir ;
- éléments décoratifs qui gênent le gameplay ;
- pièces non ancrées involontairement ;
- collisions bloquant les zones de jeu ;
- surfaces invisibles inutiles ;
- géométrie cachée excessive.

## Méthode obligatoire pour créer un nouvel objet

Avant de créer :
1. identifier un objet proche en fonction et style ;
2. inspecter sa taille ;
3. inspecter ses couleurs ;
4. inspecter ses matériaux ;
5. inspecter ses contours / reliefs ;
6. inspecter son orientation ;
7. réutiliser cette grammaire visuelle.

Après création :
1. vérifier l’échelle par rapport au joueur ;
2. vérifier depuis plusieurs distances caméra ;
3. vérifier les collisions ;
4. vérifier que le joueur peut circuler ;
5. vérifier l’apparence de jour et de nuit si pertinent ;
6. sauvegarder la place active.

---

# 9. Règles de modification de la map

Avant de supprimer, déplacer ou remplacer un objet :
- identifier sa fonction ;
- vérifier les scripts qui le cherchent par nom ;
- vérifier les Attributes ;
- vérifier les ProximityPrompts ;
- vérifier les tags CollectionService éventuels ;
- vérifier les contraintes et Welds ;
- vérifier s’il sert de référence à un script.

Ne jamais renommer arbitrairement des objets structurants.

Quelques noms structurants utilisés par le code :
- \`workspace.PyramidMap\`
- \`workspace.PyramidMap.PyramidSite\`
- zones d’entraînement ;
- objets de mine ;
- chambres ;
- modèles Pharaoh ;
- panneaux détectés par certains scripts runtime.

---

# 10. Organisation actuelle des sources

## ReplicatedStorage

\`\`\`text
src/ReplicatedStorage/
├── BobloxAdmin/
├── BobloxLeaderboards/
├── BobloxSettings/
├── BobloxTopbar.lua
├── CustomPrompt.lua
├── PyramidHUD/
└── SandstoneSurface.lua
\`\`\`

### PyramidHUD

Modules importants :

\`\`\`text
src/ReplicatedStorage/PyramidHUD/
├── BlocksConfig.lua
├── ChamberLayouts.lua
├── Config.lua
├── PyramidShape.lua
├── Ranks.lua
├── Theme.lua
├── TileStyle.lua
└── UpgradesConfig.lua
\`\`\`

---

# 11. ServerScriptService

Principaux systèmes :

\`\`\`text
src/ServerScriptService/
├── AdminBootstrap.server.lua
├── BobloxAdminService.lua
├── BobloxSettingsService.lua
├── LeaderboardBootstrap.server.lua
├── LeaderboardService.lua
├── PyramidAdminAdapter.lua
├── PyramidBeltChevrons.server.lua
├── PyramidBlocks.server.lua
├── PyramidBuild.server.lua
├── PyramidChamber.server.lua
├── PyramidData.server.lua
├── PyramidHUDService.server.lua
├── PyramidLeaderstats.server.lua
├── PyramidOutfits.server.lua
├── PyramidServerBoosts.lua
├── PyramidTraining.server.lua
├── PyramidUpgrades.server.lua
└── SettingsBootstrap.server.lua
\`\`\`

---

# 12. StarterPlayerScripts

Principaux LocalScripts :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/
├── AdminZoneStyle.client.lua
├── BackgroundMusic.client.lua
├── LeaderboardClient.client.lua
├── PharaohPurpleAura.client.lua
├── PyramidBlocksClient.client.lua
├── PyramidBuildClient.client.lua
├── PyramidChamberCinematic.client.lua
├── PyramidDiscordInvite.client.lua
├── PyramidGroupRewards.client.lua
├── PyramidHUD.client.lua
├── PyramidMinePile.client.lua
├── PyramidNameplates.client.lua
├── PyramidPharaohClient.client.lua
├── PyramidPromptBootstrap.client.lua
├── PyramidTrainingClient.client.lua
├── PyramidUpgradesClient.client.lua
├── PyramidZoneParticles.client.lua
└── ServerBoostTimer.client.lua
\`\`\`

---

# 13. Système de statistiques

Dans \`PyramidHUD/Config.lua\` :

\`\`\`lua
C.Stats = {
    Coins = "Coins",
    Speed = "Speed",
    Strength = "Strength",
    Pyramids = "Pyramids",
    Carrying = "Carrying",
    Capacity = "Capacity",
    FriendBoost = "FriendBoost",
}
\`\`\`

Les stats utilisent largement des **Attributes sur Player**.

Avant d’ajouter une nouvelle stat :
- chercher si une stat proche existe déjà ;
- respecter les conventions d’Attributes ;
- vérifier la sauvegarde DataStore ;
- vérifier leaderstats ;
- vérifier admin ;
- vérifier HUD.

---

# 14. Gameplay principal

## Construction de pyramide

Fichier serveur principal :

\`\`\`text
src/ServerScriptService/PyramidBuild.server.lua
\`\`\`

La pyramide utilise notamment :
- blocs placés ;
- total requis ;
- récompenses en pièces ;
- fin de pyramide ;
- incrément de Pyramides ;
- système Pharaoh ;
- multiplicateurs serveur.

Total de référence actuel :

\`\`\`lua
C.PyramidTotal = 171700
\`\`\`

Ne pas changer l’échelle de progression sans analyser l’économie complète.

---

# 15. Blocs / mine / transport

Systèmes associés :

\`\`\`text
PyramidBlocks.server.lua
PyramidBlocksClient.client.lua
PyramidMinePile.client.lua
PyramidBuildClient.client.lua
\`\`\`

Actions principales :
- ramassage ;
- transport ;
- capacité ;
- dépôt ;
- construction.

Touches configurées :

\`\`\`text
E = Ramasser
Q = Déposer
\`\`\`

Gamepad :
- X = Pick Up ;
- Y = Drop.

---

# 16. Entraînement

Serveur :

\`\`\`text
src/ServerScriptService/PyramidTraining.server.lua
\`\`\`

Client :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidTrainingClient.client.lua
\`\`\`

Stats :
- Speed ;
- Strength.

Configuration dans :

\`\`\`text
src/ReplicatedStorage/PyramidHUD/Config.lua
\`\`\`

Valeurs de base actuelles :
- BenchInterval = 1 ;
- TreadInterval = 1 ;
- BaseStrength = 1 ;
- BaseSpeed = 1.

Les gains peuvent être affectés par :
- multiplicateurs personnels ;
- bonus amis ;
- zones d’entraînement ;
- multiplicateurs serveur.

---

# 17. Zones d’entraînement

Zones configurées actuellement :

\`\`\`text
Region_2x
Region_5x
Region_10x
Region_25x
Region_50x
Region_75x
Region_100x
Region_ADMIN
\`\`\`

La zone admin est spéciale.

Avant de renommer ou déplacer une zone :
- chercher son nom exact dans \`Config.lua\` ;
- chercher son utilisation client/serveur ;
- vérifier ses Attributes et prompts.

---

# 18. Upgrades

Configuration :

\`\`\`text
src/ReplicatedStorage/PyramidHUD/UpgradesConfig.lua
\`\`\`

Serveur :

\`\`\`text
src/ServerScriptService/PyramidUpgrades.server.lua
\`\`\`

Client :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidUpgradesClient.client.lua
\`\`\`

Les upgrades incluent notamment :
- Bulk Pickup ;
- Bulk Place ;
- Placement Range.

L’Admin Panel peut les modifier.

---

# 19. Pharaoh

Game Pass actuel :

\`\`\`text
GamePassId = 2001986456
\`\`\`

Prix config de référence :

\`\`\`text
149
\`\`\`

Bonus Pyramids :

\`\`\`text
2
\`\`\`

Le Pharaoh peut affecter :
- apparence ;
- récompenses ;
- gameplay ;
- aura ;
- chambre.

Scripts importants :
- \`PyramidOutfits.server.lua\`
- \`PyramidPharaohClient.client.lua\`
- \`PharaohPurpleAura.client.lua\`

---

# 20. Chambre du Pharaoh

Configuration :
- durée initiale : 3 minutes ;
- maximum : 60 minutes.

Scripts :
- \`PyramidChamber.server.lua\`
- \`PyramidChamberCinematic.client.lua\`
- \`ChamberLayouts.lua\`

La chambre s’ouvre après certaines fins de pyramide selon le système existant.

Ne pas casser :
- \`ChamberOpen\`
- \`ChamberEnd\`
- \`ChamberMinutes\`
- \`ChamberReady\`
- \`ChamberMult\`

qui sont utilisés comme Attributes.

---

# 21. Admin propriétaire

Roblox UserId propriétaire :

\`\`\`text
10027646422
\`\`\`

Ce UserId bénéficie de comportements spéciaux.

## Rank admin

Script :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidNameplates.client.lua
\`\`\`

Le propriétaire affiche :

\`\`\`text
👑 ADMIN
\`\`\`

et est traduit en français par le HUD en :

\`\`\`text
👑 ADMINISTRATEUR
\`\`\`

## Style actuel du titre admin

Le titre admin reprend maintenant **exactement l’animation arc-en-ciel utilisée par le texte du bouton +50,000**.

La fonction de référence se trouve dans :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidHUD.client.lua
\`\`\`

Principe :

\`\`\`lua
local h0 = (os.clock() * 0.35) % 1
for i = 0, 6 do
    Color3.fromHSV((h0 + i * 0.12) % 1, 0.7, 1)
end
\`\`\`

Le titre admin conserve un **contour noir épais**.

Ne pas revenir au rouge fixe sans demande explicite.

---

# 22. Apparence propriétaire / Pharaoh admin

Script :

\`\`\`text
src/ServerScriptService/PyramidOutfits.server.lua
\`\`\`

Le propriétaire reçoit un skin Pharaoh/admin spécifique uniquement pour le UserId :

\`\`\`text
10027646422
\`\`\`

Il existe également :
- AdminAura ;
- AdminHighlight ;
- tenue spéciale ;
- staff si disponible.

Ne pas appliquer ces effets à tous les joueurs.

---

# 23. Admin Panel

Scripts principaux :

\`\`\`text
src/ReplicatedStorage/BobloxAdmin/Client.lua
src/ReplicatedStorage/BobloxAdmin/Config.lua
src/ServerScriptService/BobloxAdminService.lua
src/ServerScriptService/PyramidAdminAdapter.lua
\`\`\`

L’Admin Panel gère notamment :
- sélection joueur ;
- kick / ban / unban ;
- teleport / bring ;
- économie ;
- stats ;
- upgrades ;
- zones ;
- Pharaoh ;
- progression pyramide ;
- chambre ;
- lumière jour/nuit ;
- message serveur ;
- multiplicateurs serveur.

Toujours valider les actions sensibles **côté serveur**, même si l’UI valide déjà les entrées.

---

# 24. MESSAGE SERVEUR

Fonction existante dans l’Admin Panel :
- envoi d’un message à tout le serveur ;
- message filtré ;
- bannière runtime auto-size.

Ne pas réutiliser cette bannière pour des données permanentes sans vérifier sa logique d’affichage.

---

# 25. Multiplicateurs serveur

Service :

\`\`\`text
src/ServerScriptService/PyramidServerBoosts.lua
\`\`\`

Types :
- speed ;
- coins ;
- strength ;
- pyramids ;
- all.

Admin actions :
- \`serverboost\`
- \`serverboostoff\`
- \`serverbooststatus\`

Plage actuelle :
- multiplicateur de 1 à 100 ;
- durée de 0.1 à 1440 minutes.

Les boosts serveur sont stockés en Attributes sur \`ReplicatedStorage.PyramidHUD\`.

Exemples :
- \`ServerBoostSpeedMultiplier\`
- \`ServerBoostSpeedEnd\`
- \`ServerBoostCoinsMultiplier\`
- \`ServerBoostCoinsEnd\`
- \`ServerBoostStrengthMultiplier\`
- \`ServerBoostStrengthEnd\`
- \`ServerBoostPyramidsMultiplier\`
- \`ServerBoostPyramidsEnd\`

---

# 26. HUD public des multiplicateurs serveur

Script :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/ServerBoostTimer.client.lua
\`\`\`

État visuel attendu :
- visible par tous ;
- bas à droite ;
- au-dessus de Ramasser / Déposer ;
- grille compacte 2×2 ;
- cartes inspirées du style natif du HUD ;
- vraie icône de stat ;
- seulement le multiplicateur visible (\`2x\`, \`5x\`, \`100x\`) ;
- gros chrono ;
- chrono blanc dans capsule verte ;
- pas de barre verticale décorative à gauche ;
- cartes masquées si boost non actif.

Ne pas revenir à :
- une grande barre en haut de l’écran ;
- une colonne verticale géante ;
- du texte “PIÈCES / VITESSE / FORCE / PYRAMIDES” dans chaque carte.

---

# 27. UI principale

Script majeur :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidHUD.client.lua
\`\`\`

Ce fichier contient beaucoup de logique UI runtime :
- traduction ;
- stats ;
- boosts ;
- progression pyramide ;
- achats ;
- localisation ;
- animation rainbow ;
- settings/admin hooks.

Avant de modifier une GUI existante dans la place, vérifier si \`PyramidHUD.client.lua\` la repositionne ou la restyle au runtime.

---

# 28. Style UI

Modules principaux :

\`\`\`text
src/ReplicatedStorage/PyramidHUD/Theme.lua
src/ReplicatedStorage/PyramidHUD/TileStyle.lua
\`\`\`

## Style général

- \`FredokaOne\` très utilisé ;
- contours épais ;
- coins arrondis ;
- relief / bevel ;
- ombres ;
- gradients saturés ;
- texture studs ;
- forte lisibilité ;
- interfaces compactes mais colorées ;
- gros contraste texte/fond.

## Texture studs

Asset :

\`\`\`text
rbxassetid://138926013267839
\`\`\`

## Couleurs Theme importantes

\`\`\`text
Outline = #081020
Dark = RGB(38,42,56)
Yellow = RGB(255,205,0)
Red = RGB(226,41,41)
TitleInk = RGB(43,23,64)
\`\`\`

Pour une nouvelle UI, préférer réutiliser \`Theme.lua\` ou \`TileStyle.lua\` plutôt que recréer un style incompatible.

---

# 29. Boutons boosts existants

Dans \`Config.lua\` :

## Speed

\`\`\`text
1.5x Speed
\`\`\`

Palette :
- Rim : RGB(24,86,190)
- Top : RGB(150,225,255)
- Bottom : RGB(40,140,255)

Icon :

\`\`\`text
rbxassetid://133205424214665
\`\`\`

## Strength

\`\`\`text
2x Strength
\`\`\`

Palette :
- Rim : RGB(190,84,8)
- Top : RGB(255,236,110)
- Bottom : RGB(255,140,20)

Icon :

\`\`\`text
rbxassetid://126939253803851
\`\`\`

Ces boutons sont des références importantes pour la cohérence visuelle.

---

# 30. Boutons de remplissage pyramide

Montants :
- +1,000 ;
- +5,000 ;
- +10,000 ;
- +50,000.

Le bouton \`+50,000\` est visuellement spécial :
- palette violette ;
- texte avec gradient rainbow animé au runtime.

Configuration :

\`\`\`lua
{ Amount = 50000, Price = 699, ProductId = 3715499751,
  Rim = Color3.fromRGB(90, 20, 180),
  Top = Color3.fromRGB(247, 139, 255),
  Bottom = Color3.fromRGB(151, 53, 255) }
\`\`\`

Ce bouton est actuellement la référence pour l’animation du titre admin.

---

# 31. Popup Récompenses gratuites

Script :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidGroupRewards.client.lua
\`\`\`

Il récupère une GUI existante :
- \`PlayerGui.GroupRewards\`
- \`FreeRewards\`
- \`Header\`
- \`Close\`
- \`Like\`
- \`Join\`
- \`Claim\`
- \`Hint\`
- \`Prize.Amount\`

Il utilise :

\`\`\`lua
T.adoptWindow(panel)
\`\`\`

Le style exact provient fortement :
- de la GUI originale dans le \`.rbxl\` ;
- de \`Theme.lua\`.

Ce popup sert de référence visuelle à d’autres fenêtres.

---

# 32. Popup Discord

Script :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/PyramidDiscordInvite.client.lua
\`\`\`

Fonctionnement :
- détecte un panneau contenant “DISCORD” ;
- ajoute un ProximityPrompt ;
- touche E ;
- texte “Ouvrir” ;
- ouvre une popup ;
- FR/EN automatique.

Asset Discord actuel :

\`\`\`text
rbxassetid://105894278804230
\`\`\`

Le visuel reprend le style général du popup Récompenses gratuites avec adaptation Discord.

Le contenu principal inclut :
- titre Discord ;
- “Rejoins notre Discord !” ;
- “Lien officiel sur la page du jeu !” ;
- “Communauté • Codes • Actus” ;
- texte explicatif ;
- bouton “Compris”.

Ne pas mettre de lien Discord direct dans le jeu. Le lien officiel doit rester géré via les liens sociaux de la page Roblox de l’expérience.

---

# 33. FR / EN automatique

Le jeu est largement traduit automatiquement FR/EN.

La logique importante se trouve notamment dans :

\`\`\`text
PyramidHUD.client.lua
\`\`\`

En Studio, le comportement français est souvent forcé pour faciliter les tests.

Avant d’ajouter du texte visible :
- prévoir FR ;
- prévoir EN ;
- utiliser la logique de localisation existante si possible ;
- éviter de casser les textes déjà reconnus par les tables de traduction.

Exemples :
- \`ADMIN\` → \`ADMINISTRATEUR\`
- \`Speed\` → \`Vitesse\`
- \`Strength\` → \`Force\`
- \`Coins\` → \`Pièces\`
- \`Pyramids\` → \`Pyramides\`.

---

# 34. Background music

Le jeu possède une musique de fond avec réglage :
- Musique ON/OFF.

Script :

\`\`\`text
src/StarterPlayer/StarterPlayerScripts/BackgroundMusic.client.lua
\`\`\`

Ne pas recréer un second système audio global concurrent.

---

# 35. Settings

Scripts :

\`\`\`text
src/ReplicatedStorage/BobloxSettings/
src/ServerScriptService/BobloxSettingsService.lua
src/ServerScriptService/SettingsBootstrap.server.lua
\`\`\`

Les réglages existants doivent être réutilisés si une option globale joueur est ajoutée.

---

# 36. Leaderboards

Scripts :
- \`BobloxLeaderboards\`
- \`LeaderboardService.lua\`
- \`LeaderboardClient.client.lua\`
- \`PyramidLeaderstats.server.lua\`.

Stats de classement existantes incluent :
- Strength ;
- Speed ;
- Pyramids ;
- Blocks ;
- Coins.

Avant de renommer une stat, vérifier tous les classements.

---

# 37. Data / sauvegarde joueur

Script principal :

\`\`\`text
src/ServerScriptService/PyramidData.server.lua
\`\`\`

Toute nouvelle progression permanente doit être intégrée proprement au système de sauvegarde.

Ne pas sauvegarder arbitrairement :
- données temporaires ;
- états runtime de HUD ;
- chronos serveur éphémères ;
- références Instance.

---

# 38. Monétisation

Le jeu contient plusieurs Developer Products / Game Pass.

Avant de modifier :
- ProductId ;
- GamePassId ;
- prix ;
- quantité offerte ;

toujours vérifier \`Config.lua\` et les systèmes serveur/client concernés.

Ne jamais inventer un ProductId.

---

# 39. Sécurité serveur

Règle générale :

**Le client ne doit jamais être considéré comme autoritaire pour l’économie.**

Toute opération concernant :
- Coins ;
- Strength ;
- Speed ;
- Pyramids ;
- progression ;
- achats ;
- admin ;
- boosts ;
- récompenses ;

doit être validée côté serveur.

Éviter :
- RemoteEvent acceptant directement un montant non validé ;
- confiance dans un booléen envoyé par le client ;
- attribution de monnaie uniquement côté LocalScript.

---

# 40. Règle sur les RemoteEvents

Avant d’ajouter un RemoteEvent :
1. vérifier si un Remote existant peut être réutilisé ;
2. documenter la direction client → serveur ou serveur → client ;
3. valider les types ;
4. clamp les valeurs ;
5. vérifier les permissions ;
6. éviter les boucles réseau à haute fréquence.

---

# 41. Performance

Pour toute création de map ou effet :
- éviter des centaines de ParticleEmitters inutiles ;
- limiter les boucles RenderStepped ;
- déconnecter les connexions quand un objet est détruit ;
- éviter de recréer la même UI chaque frame ;
- préférer Attributes et events ;
- limiter les calculs lourds par joueur ;
- éviter des Parts décoratives minuscules en masse.

---

# 42. Connexions et cleanup

Lorsqu’un système crée :
- \`RBXScriptConnection\` ;
- Tween ;
- RenderStepped ;
- UI runtime ;

prévoir son nettoyage si sa durée de vie n’est pas globale.

Exemple actuel :
le rainbow admin déconnecte sa connexion lorsque l’effet est désactivé.

---

# 43. Méthode de modification UI

Avant de modifier une UI :

1. déterminer si elle existe dans le \`.rbxl\` ;
2. déterminer si un LocalScript la modifie au runtime ;
3. inspecter \`Theme.lua\` ;
4. inspecter \`TileStyle.lua\` ;
5. inspecter une UI similaire existante ;
6. tester à plusieurs résolutions.

Ne jamais supposer qu’une propriété Studio restera inchangée après \`Play\`.

---

# 44. Responsiveness

Le jeu utilise plusieurs \`UIScale\` et calculs basés sur :

\`\`\`lua
workspace.CurrentCamera.ViewportSize
\`\`\`

Toute nouvelle UI doit être testée au minimum :
- desktop large ;
- fenêtre Studio réduite ;
- ratio mobile simulé si possible.

Éviter le texte qui :
- dépasse ;
- est coupé ;
- change de taille arbitrairement entre cartes similaires.

---

# 45. Textes UI

Principes :
- très lisibles ;
- peu de mots ;
- informations importantes en gros ;
- contours suffisants ;
- éviter les longues phrases dans de petits boutons ;
- si une icône identifie déjà la stat, ne pas répéter inutilement son nom.

Exemple appliqué au HUD boosts serveur :
l’icône identifie la stat, donc la carte affiche seulement \`2x\` + chrono.

---

# 46. Nommage

Pour de nouveaux objets/scripts :
- noms anglais cohérents avec le code existant ;
- UI visible traduite FR/EN ;
- éviter les noms génériques comme \`Part1\`, \`Frame2\`, \`Script\`;
- préférer \`DiscordHeaderIcon\`, \`ServerBoostTimer\`, etc.

---

# 47. Tests minimum avant considérer une tâche terminée

## Pour code client

Tester :
- aucune erreur Output ;
- UI visible ;
- UI cachée quand nécessaire ;
- respawn ;
- traduction ;
- résolution.

## Pour code serveur

Tester :
- joueur unique ;
- plusieurs joueurs si pertinent ;
- permissions ;
- valeurs limites ;
- respawn ;
- join pendant événement actif.

## Pour modifications map

Tester :
- collisions ;
- placement ;
- orientation ;
- visibilité ;
- accès joueur ;
- absence d’objets non ancrés involontaires ;
- sauvegarde Ctrl+S.

---

# 48. Procédure MCP obligatoire avant une grosse modification Studio

Avant une grosse modification via MCP :

### Étape 1 — comprendre la cible
- inspecter le parent ;
- lire les noms ;
- lire les classes ;
- lire les propriétés importantes.

### Étape 2 — chercher une référence
- choisir 2 ou 3 objets ressemblants ;
- comparer tailles / matériaux / couleurs.

### Étape 3 — plan minimal
- modifier le moins d’objets possible ;
- garder les noms structurants.

### Étape 4 — exécuter
- créer / déplacer / styliser.

### Étape 5 — vérifier
- relire les propriétés finales ;
- inspecter le résultat dans Studio.

### Étape 6 — sauvegarder
- Ctrl+S sur \`buildapiramid.rbxl\`.

---

# 49. Ce qu’il ne faut jamais faire automatiquement

Sans demande explicite :
- reset massif de Workspace ;
- suppression de map ;
- refonte totale de terrain ;
- suppression de GUI originales ;
- changement de tous les ProductIds ;
- reset DataStore ;
- changement d’Owner UserId ;
- suppression des systèmes admin ;
- suppression du Pharaoh ;
- changement de progression économique globale ;
- ajout de Workspace à Rojo ;
- écriture sur le factory backup.

---

# 50. Modifications sensibles nécessitant double vérification

Avant d’exécuter :
- suppression de plus de quelques objets ;
- renommage de modèles importants ;
- déplacement de PyramidSite ;
- modification du total de blocs ;
- changement DataStore ;
- changement de prix Robux ;
- changement d’un Game Pass ;
- changement du système de sauvegarde ;
- modification de la hiérarchie des GUI originales.

Pour ces cas, inspecter d’abord toutes les références code.

---

# 51. Source de vérité selon le type de donnée

## Scripts
Source de vérité :
\`\`\`text
GitHub / src/
\`\`\`

## Map
Source de vérité :
\`\`\`text
place/buildapiramid.rbxl
\`\`\`

## Factory original
Référence de secours seulement :
\`\`\`text
place/buildapiramid_FACTORY_BACKUP.rbxl
\`\`\`

## Configuration gameplay
Source principale :
\`\`\`text
src/ReplicatedStorage/PyramidHUD/Config.lua
\`\`\`

## Style UI
Sources principales :
\`\`\`text
Theme.lua
TileStyle.lua
GUI originale du .rbxl
\`\`\`

---

# 52. Lorsque code + map sont modifiés ensemble

Exemple : nouveau panneau interactif.

Workflow recommandé :
1. créer/modifier le panneau dans Workspace via Studio MCP ;
2. garder le panneau dans le \`.rbxl\` ;
3. créer le script comportemental dans \`src/\` ;
4. Git branch + PR + squash merge pour le code ;
5. Ctrl+S dans Studio pour la map ;
6. versionner la map active avec le workflow de sauvegarde.

---

# 53. Détection d’objets par texte

Certains systèmes runtime détectent des panneaux/objets via leur contenu ou nom.

Exemple :
le panneau Discord est détecté à partir du texte “DISCORD”.

Avant de modifier le texte d’un panneau interactif :
- rechercher si un script s’appuie sur ce texte.

---

# 54. ProximityPrompts

Le jeu utilise des prompts, notamment pour :
- panneaux ;
- actions contextuelles.

Avant d’en créer un nouveau :
- vérifier si un prompt existe déjà ;
- éviter les doublons ;
- vérifier touche clavier ;
- vérifier distance ;
- vérifier HoldDuration ;
- vérifier ObjectText / ActionText ;
- prévoir traduction si visible.

---

# 55. Style de réponse attendu pour le propriétaire

Quand une modification est terminée :
- être direct ;
- donner le numéro de PR ;
- donner le commit final ;
- rappeler uniquement les étapes nécessaires.

Format habituel :

\`\`\`text
C’est fait sur GitHub.
PR #...
Commit : ...

git pull
Rojo sync → Ctrl+S → Stop → Play
\`\`\`

Éviter de demander au propriétaire de coder manuellement si les outils sont disponibles.

---

# 56. État visuel / fonctionnel actuel important

À préserver sauf demande explicite :

- popup Discord fonctionnelle avec E ;
- vrai logo Discord asset \`105894278804230\` ;
- popup Discord inspirée de Récompenses gratuites ;
- FR/EN automatique ;
- musique ON/OFF ;
- UI progression pyramide en bas ;
- boutons +1,000 / +5,000 / +10,000 / +50,000 au-dessus de la barre ;
- Admin Panel fonctionnel ;
- message serveur ;
- boosts serveur ;
- chrono boosts serveur public en grille 2×2 ;
- titre propriétaire rainbow ;
- contour noir propriétaire ;
- skin admin spécifique ;
- map hors Rojo ;
- map active versionnée ;
- factory backup protégé.

---

# 57. Important : le style visuel doit être appris depuis le jeu

Ce document décrit les règles, mais pour une modélisation précise, Claude doit **observer le jeu réel** via MCP.

Lorsqu’une demande est visuelle :
- ne pas inventer à partir du texte uniquement si les références sont visibles dans Studio ;
- inspecter les objets réels ;
- comparer avant/après.

Le meilleur modèle de style est **la map elle-même**.

---

# 58. Si une demande dit “fais comme cet objet”

Interprétation obligatoire :

**copier la grammaire visuelle réelle de l’objet source**, pas créer une approximation libre.

Inspecter :
- dimensions ;
- layout ;
- gradients ;
- stroke ;
- typo ;
- padding ;
- rayons ;
- ombres ;
- animation ;
- texture ;
- ZIndex ;
- responsive scaling.

---

# 59. Si une demande concerne une image/logo exact

Ne pas reconstruire approximativement un logo avec des formes si l’asset exact est disponible.

Préférer un \`ImageLabel\` avec l’AssetId Roblox validé.

Exemple actuel Discord :

\`\`\`text
rbxassetid://105894278804230
\`\`\`

---

# 60. Règle finale de prudence

Quand une décision oppose :
- modification rapide mais destructive ;
- modification légèrement plus longue mais sûre ;

toujours choisir la solution sûre.

Le projet contient :
- une map travaillée manuellement ;
- de nombreuses GUI originales ;
- des dépendances runtime ;
- des systèmes anciens et nouveaux mélangés.

La priorité est :
1. ne rien casser ;
2. préserver le style ;
3. modifier le minimum nécessaire ;
4. tester ;
5. sauvegarder ;
6. garder une trace Git claire.

---

# 61. Checklist courte avant chaque tâche

Claude doit mentalement vérifier :

- [ ] Est-ce du code ou de la map ?
- [ ] Est-ce géré par Rojo ?
- [ ] Est-ce que je risque de toucher Workspace via Rojo ?
- [ ] Est-ce que je touche au factory backup ? → si oui, STOP.
- [ ] Ai-je inspecté les objets similaires ?
- [ ] Ai-je cherché les références de noms dans le code ?
- [ ] Ai-je respecté FR/EN ?
- [ ] Ai-je respecté le style Theme/TileStyle ?
- [ ] Ai-je prévu serveur/client correctement ?
- [ ] Ai-je prévu le cleanup ?
- [ ] Ai-je testé les valeurs limites ?
- [ ] Ai-je sauvegardé la place si Workspace a changé ?
- [ ] Ai-je utilisé branche + PR + squash pour le code ?

---

# 62. Checklist après modification

- [ ] Aucun nouvel error dans Output.
- [ ] Aucun warning inattendu.
- [ ] Aucun objet important supprimé.
- [ ] Aucun changement du factory backup.
- [ ] \`default.project.json\` ne gère toujours pas Workspace.
- [ ] Rojo sync fonctionne.
- [ ] UI responsive.
- [ ] FR/EN correct.
- [ ] Gameplay testé.
- [ ] Ctrl+S effectué si la map a changé.
- [ ] Git propre.
- [ ] PR squash merge.
- [ ] Commit final communiqué.

---

# 63. Commandes utiles

## Projet

\`\`\`powershell
cd C:\Users\Hayati\Desktop\PYRAMIDE\Construit-la-Pyramide
\`\`\`

## Mise à jour

\`\`\`powershell
git pull
\`\`\`

## Rojo

\`\`\`powershell
rojo serve
\`\`\`

Serveur attendu :

\`\`\`text
localhost:34872
\`\`\`

## Sauvegarde complète

\`\`\`powershell
.\scripts\save-project.ps1
\`\`\`

---

# 64. Règle de continuité

Avant de commencer une nouvelle tâche importante, Claude Code doit lire :
1. ce \`CLAUDE.md\` ;
2. \`default.project.json\` ;
3. les fichiers directement concernés ;
4. la structure réelle Studio via MCP si la demande touche la map ou une GUI originale.

Ce document doit être mis à jour lorsqu’une modification importante change :
- architecture ;
- workflow ;
- règle critique ;
- système majeur ;
- référence visuelle principale.

---

# 65. Priorité absolue

**NE JAMAIS TOUCHER AU FACTORY BACKUP.**

**NE JAMAIS RÉACTIVER WORKSPACE DANS ROJO.**

**LES SCRIPTS RESTENT GÉRÉS PAR GIT/ROJO.**

**LA MAP ACTIVE RESTE DANS LE .RBXL ET DOIT ÊTRE SAUVEGARDÉE DANS STUDIO.**

**AVANT DE MODÉLISER, INSPECTER LE STYLE EXISTANT DANS LA MAP.**
