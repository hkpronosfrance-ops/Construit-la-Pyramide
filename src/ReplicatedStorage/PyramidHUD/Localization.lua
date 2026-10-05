local LocalizationService = game:GetService("LocalizationService")

local L = {}

local EXACT = {
	["Coins"] = "Pièces",
	["Coin"] = "Pièce",
	["Speed"] = "Vitesse",
	["Strength"] = "Force",
	["Pyramids"] = "Pyramides",
	["Pyramid"] = "Pyramide",
	["Capacity"] = "Capacité",
	["Walk Speed"] = "Vitesse de marche",
	["Friend Boost"] = "Bonus d'amis",
	["Pick Up"] = "Ramasser",
	["Pickup"] = "Ramasser",
	["Drop"] = "Déposer",
	["Block"] = "Bloc",
	["Blocks"] = "Blocs",
	["Settings"] = "Paramètres",
	["Admin"] = "Admin",
	["Admin Panel"] = "Panneau Admin",
	["ADMIN PANEL"] = "PANNEAU ADMIN",
	["Player"] = "Joueur",
	["Players"] = "Joueurs",
	["Search"] = "Rechercher",
	["Selected"] = "Sélectionné",
	["Select"] = "Sélectionner",
	["Kick"] = "Expulser",
	["Ban"] = "Bannir",
	["Unban"] = "Débannir",
	["Bring"] = "Téléporter ici",
	["Teleport"] = "Téléporter",
	["Teleport To"] = "Se téléporter",
	["Yes"] = "Oui",
	["No"] = "Non",
	["Close"] = "Fermer",
	["Claim"] = "Récupérer",
	["Claimed"] = "Récupérée",
	["Locked"] = "Verrouillé",
	["Thank You!"] = "Merci !",
	["Join"] = "Rejoindre",
	["Like"] = "J'aime",
	["Free Rewards"] = "Récompenses gratuites",
	["FREE REWARDS"] = "RÉCOMPENSES GRATUITES",
	["Reward"] = "Récompense",
	["Rewards"] = "Récompenses",
	["Shop"] = "Boutique",
	["Upgrades"] = "Améliorations",
	["Upgrade"] = "Amélioration",
	["Max"] = "Max",
	["MAX"] = "MAX",
	["Level"] = "Niveau",
	["Buy"] = "Acheter",
	["Owned"] = "Possédé",
	["Equip"] = "Équiper",
	["Equipped"] = "Équipé",
	["Music"] = "Musique",
	["Sound"] = "Son",
	["Sounds"] = "Sons",
	["Volume"] = "Volume",
	["Max Speed"] = "Vitesse maximale",
	["On"] = "Activé",
	["Off"] = "Désactivé",
	["ON"] = "ACTIVÉ",
	["OFF"] = "DÉSACTIVÉ",
	["Bulk Pickup"] = "Ramassage multiple",
	["Bulk Place"] = "Placement multiple",
	["Placement Range"] = "Portée de placement",
	["Sapphire Pyramid"] = "Pyramide de saphir",
	["Amethyst Pyramid"] = "Pyramide d'améthyste",
	["Golden Pyramid"] = "Pyramide dorée",
	["Diamond Pyramid"] = "Pyramide de diamant",
	["SAPPHIRE PYRAMID"] = "PYRAMIDE DE SAPHIR",
	["AMETHYST PYRAMID"] = "PYRAMIDE D'AMÉTHYSTE",
	["GOLDEN PYRAMID"] = "PYRAMIDE DORÉE",
	["DIAMOND PYRAMID"] = "PYRAMIDE DE DIAMANT",
	["PHARAOH'S CHAMBER"] = "CHAMBRE DU PHARAON",
	["TRAINING INSIDE"] = "ENTRAÎNEMENT À L'INTÉRIEUR",
	["Not available right now"] = "Indisponible pour le moment",
	["The pyramid is finished! Wait for the next one."] = "La pyramide est terminée ! Attends la suivante.",
	["Backpack full! Train Strength for more."] = "Sac plein ! Entraîne ta Force pour porter davantage.",
	["Get blocks from the mine first!"] = "Va d'abord chercher des blocs dans la mine !",
	["Press the thumbs up on the game page to like the game!"] = "Clique sur le pouce levé sur la page du jeu pour aimer le jeu !",
	["You already claimed this reward."] = "Tu as déjà récupéré cette récompense.",
	["Join our group first!"] = "Rejoins d'abord notre communauté !",
	["nobody selected"] = "aucun joueur sélectionné",
	["pick a player on the PLAYER tab first"] = "sélectionne d'abord un joueur dans l'onglet JOUEUR",
	["Enter a value first."] = "Entre d'abord une valeur.",
	["give a UserId"] = "entre un UserId",
	["PLAYER"] = "JOUEUR",
	["SERVER"] = "SERVEUR",
	["ANNOUNCE"] = "ANNONCE",
	["MISC"] = "DIVERS",
	["THIS SERVER"] = "CE SERVEUR",
	["ONLY"] = "SEULEMENT",
	["Complete"] = "Terminée",
	["COMPLETE"] = "TERMINÉE",
	["Training"] = "Entraînement",
	["Mine"] = "Mine",
	["Gym"] = "Salle de sport",
	["Free Gift"] = "Cadeau gratuit",
	["Group Reward"] = "Récompense de communauté",
	["Join Group"] = "Rejoindre la communauté",
	["Like Game"] = "Aimer le jeu",
	["CLAIM"] = "RÉCUPÉRER",
	["CLAIMED"] = "RÉCUPÉRÉE",
	["LOCKED"] = "VERROUILLÉ",
	["SAND SWEEPER"] = "BALAYEUR DE SABLE",
	["WATER BEARER"] = "PORTEUR D'EAU",
	["ROPE PULLER"] = "TIREUR DE CORDE",
	["BRICK HAULER"] = "PORTEUR DE BRIQUES",
	["STONE CARRIER"] = "PORTEUR DE PIERRES",
	["BLOCK PUSHER"] = "POUSSEUR DE BLOCS",
	["RAMP BUILDER"] = "CONSTRUCTEUR DE RAMPES",
	["APPRENTICE MASON"] = "APPRENTI MAÇON",
	["MASON"] = "MAÇON",
	["SENIOR MASON"] = "MAÇON EXPÉRIMENTÉ",
	["CHIEF MASON"] = "CHEF MAÇON",
	["STONE CUTTER"] = "TAILLEUR DE PIERRE",
	["MASTER CUTTER"] = "MAÎTRE TAILLEUR",
	["QUARRY FOREMAN"] = "CONTREMAÎTRE DE CARRIÈRE",
	["SITE OVERSEER"] = "SUPERVISEUR DU CHANTIER",
	["CREW LEADER"] = "CHEF D'ÉQUIPE",
	["MASTER BUILDER"] = "MAÎTRE BÂTISSEUR",
	["SURVEYOR"] = "ARPENTEUR",
	["SCRIBE"] = "SCRIBE",
	["ROYAL SCRIBE"] = "SCRIBE ROYAL",
	["ARCHITECT"] = "ARCHITECTE",
	["SENIOR ARCHITECT"] = "ARCHITECTE EXPÉRIMENTÉ",
	["ROYAL ARCHITECT"] = "ARCHITECTE ROYAL",
	["GRAND ARCHITECT"] = "GRAND ARCHITECTE",
	["PRIEST OF PTAH"] = "PRÊTRE DE PTAH",
	["HIGH PRIEST"] = "GRAND PRÊTRE",
	["VIZIER'S AIDE"] = "AIDE DU VIZIR",
	["VIZIER"] = "VIZIR",
	["GRAND VIZIER"] = "GRAND VIZIR",
	["NOMARCH"] = "NOMARQUE",
	["GOVERNOR"] = "GOUVERNEUR",
	["ROYAL TREASURER"] = "TRÉSORIER ROYAL",
	["KEEPER OF THE SEAL"] = "GARDE DU SCEAU",
	["GENERAL"] = "GÉNÉRAL",
	["COMMANDER"] = "COMMANDANT",
	["PRINCE"] = "PRINCE",
	["CROWN PRINCE"] = "PRINCE HÉRITIER",
	["CO-REGENT"] = "CORÉGENT",
	["PHARAOH"] = "PHARAON",
	["GREAT PHARAOH"] = "GRAND PHARAON",
	["LORD OF TWO LANDS"] = "SEIGNEUR DES DEUX TERRES",
	["SON OF RA"] = "FILS DE RÂ",
	["EYE OF HORUS"] = "ŒIL D'HORUS",
	["CHOSEN OF OSIRIS"] = "ÉLU D'OSIRIS",
	["LIVING SPHINX"] = "SPHINX VIVANT",
	["STAR OF THE NILE"] = "ÉTOILE DU NIL",
	["SUN KING"] = "ROI SOLEIL",
	["DIVINE PHARAOH"] = "PHARAON DIVIN",
	["IMMORTAL PHARAOH"] = "PHARAON IMMORTEL",
	["GOD OF PYRAMIDS"] = "DIEU DES PYRAMIDES",
}

local function locale()
	local ok, value = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	return ok and tostring(value):lower() or "en-us"
end

function L.isFrench()
	return locale():sub(1, 2) == "fr"
end

local function pattern(text, pat, replacement)
	local out, n = text:gsub(pat, replacement)
	if n > 0 then
		return out
	end
end

function L.translate(text)
	if not L.isFrench() or type(text) ~= "string" or text == "" then
		return text
	end
	local exact = EXACT[text]
	if exact then
		return exact
	end

	local translated
	translated = pattern(text, "^Walk Speed:%s*(.+)$", "Vitesse de marche : %1")
		or pattern(text, "^Capacity:%s*(.+)$", "Capacité : %1")
		or pattern(text, "^Friend Boost:%s*(.+)$", "Bonus d'amis : %1")
		or pattern(text, "^ONLY%s+(.+)$", "SEULEMENT %1")
		or pattern(text, "^([%d%.]+x)%s+Speed$", "%1 Vitesse")
		or pattern(text, "^([%d%.]+x)%s+Strength$", "%1 Force")
		or pattern(text, "^(%d+)%s+Minute$", "%1 minute")
		or pattern(text, "^(%d+)%s+Minutes$", "%1 minutes")
		or pattern(text, "^(%d+)%s+MIN$", "%1 MIN")
		or pattern(text, "^(%d+)%s+MINS$", "%1 MIN")
		or pattern(text, "^Requires%s+(.+)%s+Pyramids$", "Nécessite %1 pyramides")
		or pattern(text, "^Requires%s+(.+)%s+Pyramid$", "Nécessite %1 pyramide")
		or pattern(text, "^%+(.-)%s+Coins!$", "+%1 pièces !")
		or pattern(text, "^%+(.-)%s+Coins$", "+%1 pièces")
		or pattern(text, "^%+(.-)%s+Coin$", "+%1 pièce")
		or pattern(text, "^%+(.-)%s+Blocks$", "+%1 blocs")
		or pattern(text, "^%+(.-)%s+Block$", "+%1 bloc")
		or pattern(text, "^(%d+)%s+Blocks Per Grab$", "%1 blocs par ramassage")
		or pattern(text, "^(%d+)%s+Block Per Grab$", "%1 bloc par ramassage")
		or pattern(text, "^(%d+)%s+Blocks Per Place$", "%1 blocs par placement")
		or pattern(text, "^(%d+)%s+Block Per Place$", "%1 bloc par placement")
		or pattern(text, "^%+(%d+)%%%s+Place Range$", "+%1%% de portée de placement")
		or pattern(text, "^(.+)%s+COMPLETE!$", "%1 TERMINÉE !")
		or pattern(text, "^(.+)%s+COMPLETE$", "%1 TERMINÉE")
		or pattern(text, "^(%d+)x TRAINING INSIDE$", "ENTRAÎNEMENT x%1 À L'INTÉRIEUR")
		or pattern(text, "^selected:%s*(.+)$", "sélectionné : %1")
		or pattern(text, "^ADMIN%s+•%s+(.+)$", "ADMIN • %1")
		or pattern(text, "^Kick%s+(.+)%s+from the server%?$", "Expulser %1 du serveur ?")
		or pattern(text, "^BAN%s+(.+)%? They will not be able to rejoin%.$", "BANNIR %1 ? Cette personne ne pourra plus rejoindre.")
		or pattern(text, "^(.+)%s+Robux$", "%1 Robux")
	if translated then
		return translated
	end

	return text
end

return L
