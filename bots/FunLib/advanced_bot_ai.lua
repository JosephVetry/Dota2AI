local AdvancedBotAI = {}

--[[
Advanced Dota 2 bot logic with explicit patch profile support.
Designed for patch 7.40c adaptation while remaining engine-agnostic.
]]

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function safeGet(tbl, key, default)
    if tbl == nil then return default end
    local value = tbl[key]
    if value == nil then return default end
    return value
end

local function normalizeKey(value)
    if value == nil then return "" end
    local key = tostring(value):lower()
    key = key:gsub("%s+", "_")
    return key
end


AdvancedBotAI.RankProfiles = {
    bot_immortal_6k = {
        name = "bot_immortal_6k",
        label = "Default Bot (≈6000 MMR)",
        aggressionBias = 6,
        threatBias = 8,
        mapDiscipline = 1.2,
        objectiveDiscipline = 1.25,
        retreatThreshold = 4,
        predictionHorizonBonus = 0,
        outplayRiskTolerance = 80,
        clutchCommitBonus = 12,
        jukeRetreatBonus = 14,
        trapCommitBonus = 8,
        jukeThreshold = 55,
        trapAdvantageThreshold = 4,
        macroPunishFactor = 1.0,
        tempoDiscipline = 1.05,
        resourceDiscipline = 1.05,
        itemAdaptation = 1.0,
        wavePredictionDiscipline = 1.0,
    },
    fretbots_10k = {
        name = "fretbots_10k",
        label = "Fretbots High Immortal (≈10000 MMR)",
        aggressionBias = 10,
        threatBias = 6,
        mapDiscipline = 1.35,
        objectiveDiscipline = 1.4,
        retreatThreshold = 2,
        predictionHorizonBonus = 1,
        outplayRiskTolerance = 86,
        clutchCommitBonus = 16,
        jukeRetreatBonus = 18,
        trapCommitBonus = 12,
        jukeThreshold = 48,
        trapAdvantageThreshold = 2,
        macroPunishFactor = 1.4,
        tempoDiscipline = 1.25,
        resourceDiscipline = 1.3,
        itemAdaptation = 1.35,
        wavePredictionDiscipline = 1.3,
    },

    -- Backward compatibility aliases
    legend = {
        name = "legend",
        label = "Legacy Legend",
        aggressionBias = 0,
        threatBias = 0,
        mapDiscipline = 1.0,
        objectiveDiscipline = 1.0,
        retreatThreshold = 0,
        predictionHorizonBonus = 0,
        outplayRiskTolerance = 70,
        clutchCommitBonus = 8,
        jukeRetreatBonus = 10,
        trapCommitBonus = 6,
        jukeThreshold = 60,
        trapAdvantageThreshold = 5,
        macroPunishFactor = 0.9,
        tempoDiscipline = 0.95,
        resourceDiscipline = 0.9,
        itemAdaptation = 0.85,
        wavePredictionDiscipline = 0.85,
    },
    immortal = {
        name = "immortal",
        label = "Legacy Immortal",
        aggressionBias = 6,
        threatBias = 8,
        mapDiscipline = 1.2,
        objectiveDiscipline = 1.25,
        retreatThreshold = 4,
        predictionHorizonBonus = 0,
        outplayRiskTolerance = 80,
        clutchCommitBonus = 12,
        jukeRetreatBonus = 14,
        trapCommitBonus = 8,
        jukeThreshold = 55,
        trapAdvantageThreshold = 4,
        macroPunishFactor = 1.0,
        tempoDiscipline = 1.05,
        resourceDiscipline = 1.05,
        itemAdaptation = 1.0,
        wavePredictionDiscipline = 1.0,
    },
}

AdvancedBotAI.ActiveRankProfile = AdvancedBotAI.RankProfiles.bot_immortal_6k

AdvancedBotAI.RoleProfiles = {
    carry = {
        name = "carry",
        farmBias = 1.35,
        fightBias = 0.95,
        objectiveBias = 1.2,
        mapRiskTolerance = 0.9,
        lanePriority = 1.35,
        spikeAmplifier = 1.2,
    },
    mid = {
        name = "mid",
        farmBias = 1.05,
        fightBias = 1.35,
        objectiveBias = 1.2,
        mapRiskTolerance = 1.15,
        lanePriority = 1.1,
        spikeAmplifier = 1.35,
    },
    offlane = {
        name = "offlane",
        farmBias = 0.95,
        fightBias = 1.25,
        objectiveBias = 1.35,
        mapRiskTolerance = 1.1,
        lanePriority = 1.0,
        spikeAmplifier = 1.2,
    },
    soft_support = {
        name = "soft_support",
        farmBias = 0.8,
        fightBias = 1.3,
        objectiveBias = 1.15,
        mapRiskTolerance = 1.2,
        lanePriority = 0.9,
        spikeAmplifier = 1.15,
    },
    hard_support = {
        name = "hard_support",
        farmBias = 0.7,
        fightBias = 1.15,
        objectiveBias = 1.1,
        mapRiskTolerance = 1.0,
        lanePriority = 0.85,
        spikeAmplifier = 1.05,
    },
}

AdvancedBotAI.ActiveRoleProfile = AdvancedBotAI.RoleProfiles.carry

AdvancedBotAI.RoleHeroPools = {
    carry = {
        "juggernaut", "phantom_assassin", "faceless_void", "terrorblade", "medusa",
        "morphling", "slark", "ursa", "luna", "drow_ranger",
    },
    mid = {
        "storm_spirit", "queenofpain", "puck", "invoker", "ember_spirit",
        "void_spirit", "tiny", "shadow_fiend", "death_prophet", "templar_assassin",
    },
    offlane = {
        "centaur", "axe", "mars", "tidehunter", "dark_seer",
        "beastmaster", "underlord", "doom", "slardar", "brewmaster",
    },
    soft_support = {
        "earth_spirit", "tusk", "hoodwink", "mirana", "nyx_assassin",
        "rubick", "grimstroke", "snapfire", "clockwerk", "batrider",
    },
    hard_support = {
        "crystal_maiden", "lich", "oracle", "warlock", "dazzle",
        "shadow_demon", "jakiro", "treant", "vengefulspirit", "winter_wyvern",
    },
}

AdvancedBotAI.HeroRoleHints = {
    axe = "offlane",
    brewmaster = "offlane",
    clinkz = "carry",
    dark_seer = "offlane",
    doom = "offlane",
    drow_ranger = "carry",
    earthshaker = "soft_support",
    ember_spirit = "mid",
    grimstroke = "soft_support",
    gyrocopter = "carry",
    jakiro = "hard_support",
    ursa = "carry",
    viper = "mid",
    bloodseeker = "carry",
    broodmother = "offlane",
    abaddon = "hard_support",
}

AdvancedBotAI.ReflexProfiles = {
    human = {
        name = "human",
        reactionMs = 240,
        predictionFrames = 10,
        inputPrecision = 0.9,
        dodgeBias = 1.0,
        comboExecution = 1.0,
    },
    pro = {
        name = "pro",
        reactionMs = 140,
        predictionFrames = 16,
        inputPrecision = 1.15,
        dodgeBias = 1.2,
        comboExecution = 1.25,
    },
    superhuman = {
        name = "superhuman",
        reactionMs = 90,
        predictionFrames = 22,
        inputPrecision = 1.35,
        dodgeBias = 1.35,
        comboExecution = 1.4,
    },
}

AdvancedBotAI.ActiveReflexProfile = AdvancedBotAI.ReflexProfiles.pro

function AdvancedBotAI.SetReflexProfile(profileName)
    local key = normalizeKey(profileName)
    local aliasMap = {
        ["normal"] = "human",
        ["manusia"] = "human",
        ["pro_player"] = "pro",
        ["proplayer"] = "pro",
        ["high_reflex"] = "superhuman",
        ["godlike"] = "superhuman",
    }
    key = safeGet(aliasMap, key, key)

    local profile = AdvancedBotAI.ReflexProfiles[key]
    if profile == nil then
        return false, "Unknown reflex profile: " .. tostring(profileName)
    end

    AdvancedBotAI.ActiveReflexProfile = profile
    return true
end

function AdvancedBotAI.GetReflexProfile()
    return safeGet(AdvancedBotAI.ActiveReflexProfile, "name", "human")
end

function AdvancedBotAI.SetSkillBracket(bracketName)
    local key = normalizeKey(bracketName)
    local aliasMap = {
        ["default"] = "bot_immortal_6k",
        ["bot"] = "bot_immortal_6k",
        ["bot_biasa"] = "bot_immortal_6k",
        ["immortal_6k"] = "bot_immortal_6k",
        ["fretbot"] = "fretbots_10k",
        ["fretbots"] = "fretbots_10k",
        ["high_immortal"] = "fretbots_10k",
        ["high_immortal_10k"] = "fretbots_10k",
    }
    key = safeGet(aliasMap, key, key)

    local profile = AdvancedBotAI.RankProfiles[key]
    if profile == nil then
        return false, "Unknown skill bracket: " .. tostring(bracketName)
    end

    AdvancedBotAI.ActiveRankProfile = profile
    if key == "fretbots_10k" then
        AdvancedBotAI.SetReflexProfile("superhuman")
    else
        AdvancedBotAI.SetReflexProfile("pro")
    end
    return true
end

function AdvancedBotAI.GetSkillBracket()
    return safeGet(AdvancedBotAI.ActiveRankProfile, "name", "legend")
end

function AdvancedBotAI.EnableFretbotsMode()
    return AdvancedBotAI.SetSkillBracket("fretbots")
end

function AdvancedBotAI.EnableDefaultBotMode()
    return AdvancedBotAI.SetSkillBracket("bot_immortal_6k")
end

function AdvancedBotAI.ResolveSkillBracketFromDifficulty(difficulty)
    local d = tonumber(difficulty) or 0

    if d >= 8 then
        return "fretbots_10k"
    elseif d >= 3 then
        return "bot_immortal_6k"
    end

    return "legend"
end

function AdvancedBotAI.SetRole(roleName)
    local key = normalizeKey(roleName)
    local aliasMap = {
        ["pos1"] = "carry",
        ["safe_lane"] = "carry",
        ["midlaner"] = "mid",
        ["pos2"] = "mid",
        ["offlaner"] = "offlane",
        ["pos3"] = "offlane",
        ["softsupport"] = "soft_support",
        ["roamer"] = "soft_support",
        ["pos4"] = "soft_support",
        ["hardsupport"] = "hard_support",
        ["babysitter"] = "hard_support",
        ["pos5"] = "hard_support",
    }
    key = safeGet(aliasMap, key, key)

    local profile = AdvancedBotAI.RoleProfiles[key]
    if profile == nil then
        return false, "Unknown role: " .. tostring(roleName)
    end

    AdvancedBotAI.ActiveRoleProfile = profile
    return true
end

function AdvancedBotAI.GetRole()
    return safeGet(AdvancedBotAI.ActiveRoleProfile, "name", "carry")
end

function AdvancedBotAI.EnableRolePreset(skillBracket, roleName, reflexProfile)
    local okBracket = true
    if skillBracket ~= nil then
        okBracket = AdvancedBotAI.SetSkillBracket(skillBracket)
    end
    local okRole = AdvancedBotAI.SetRole(roleName)
    local okReflex = true
    if reflexProfile ~= nil then
        okReflex = AdvancedBotAI.SetReflexProfile(reflexProfile)
    end
    return okBracket and okRole and okReflex
end

function AdvancedBotAI.GetRoleHeroPool(roleName)
    local role = normalizeKey(roleName)
    return safeGet(AdvancedBotAI.RoleHeroPools, role, {})
end

function AdvancedBotAI.IsHeroSuitableForRole(heroName, roleName)
    local hero = normalizeKey(heroName)
    local role = normalizeKey(roleName)

    local hinted = safeGet(AdvancedBotAI.HeroRoleHints, hero, nil)
    if hinted ~= nil then
        return hinted == role
    end

    local pool = AdvancedBotAI.GetRoleHeroPool(role)
    for _, h in ipairs(pool) do
        if normalizeKey(h) == hero then
            return true
        end
    end

    return false
end

function AdvancedBotAI.RecommendHeroPick(draftState)
    local state = draftState or {}
    local role = normalizeKey(safeGet(state, "role", AdvancedBotAI.GetRole()))
    local banned = safeGet(state, "bannedHeroes", {})
    local picked = safeGet(state, "pickedHeroes", {})
    local pool = AdvancedBotAI.GetRoleHeroPool(role)

    local unavailable = {}
    for _, h in ipairs(banned) do unavailable[normalizeKey(h)] = true end
    for _, h in ipairs(picked) do unavailable[normalizeKey(h)] = true end

    local candidates = {}
    for _, hero in ipairs(pool) do
        local key = normalizeKey(hero)
        if not unavailable[key] then
            local patchSignal = safeGet(safeGet(safeGet(AdvancedBotAI.ActivePatch, "balanceSignals", {}), "heroPower", {}), key, 0)
            table.insert(candidates, {
                hero = key,
                role = role,
                score = 50 + (patchSignal * 3),
                patchSignal = patchSignal,
            })
        end
    end

    table.sort(candidates, function(a, b)
        if a.score == b.score then return a.hero < b.hero end
        return a.score > b.score
    end)

    return {
        role = role,
        best = safeGet(candidates, 1, nil),
        candidates = candidates,
    }
end

AdvancedBotAI.PatchProfiles = {
    ["7.40c"] = {
        version = "7.40c",
        objectives = {
            wisdomRuneFirst = 420,
            wisdomRuneInterval = 420,
            tormentorFirst = 1200,
            tormentorRespawn = 600,
            lotusFirst = 180,
            lotusInterval = 180,
        },
        economy = {
            coreItemPowerSpikeWeight = 12,
            levelPowerSpikeWeight = 2,
            networthPowerSpikeDivisor = 1500,
        },
        entityRegistry = {
            items = {
                item_khanda = true,
                item_phylactery = true,
            },
            neutralItems = {
                item_trusty_shovel = true,
                item_faded_broach = true,
                item_grove_bow = true,
                item_vambrace = true,
                item_quicksilver_amulet = true,
                item_mind_breaker = true,
                item_ninja_gear = true,
                item_penta_edged_sword = true,
                item_desolator_2 = true,
                item_mirror_shield = true,
                item_force_boots = true,
            },
            abilities = {
                abaddon_curse_of_avernus = true,
                axe_battle_hunger = true,
                bloodseeker_bloodrage = true,
                broodmother_spin_web = true,
                clinkz_skeleton_walk = true,
                doom_bringer_infernal_blade = true,
                earthshaker_fissure = true,
                ember_spirit_searing_chains = true,
                grimstroke_ink_swell = true,
                jakiro_ice_path = true,
                ursa_fury_swipes = true,
                viper_corrosive_skin = true,
            },
            talents = {
                axe = { talent_lvl_15 = true },
                bloodseeker = { talent_lvl_10 = true, talent_lvl_20 = true },
                broodmother = { talent_lvl_15 = true, talent_lvl_25 = true },
                clinkz = { talent_lvl_15 = true, talent_lvl_25 = true },
                drow_ranger = { talent_lvl_25 = true },
                grimstroke = { talent_lvl_15 = true },
                gyrocopter = { talent_lvl_25 = true },
                viper = { talent_lvl_20 = true },
            },
            aliases = {
                ["fury_swipes"] = "ursa_fury_swipes",
                ["corrosive_skin"] = "viper_corrosive_skin",
                ["ice_path"] = "jakiro_ice_path",
                ["curse_of_avernus"] = "abaddon_curse_of_avernus",
                ["battle_hunger"] = "axe_battle_hunger",
                ["skeleton_walk"] = "clinkz_skeleton_walk",
                ["infernal_blade"] = "doom_bringer_infernal_blade",
                ["ink_swell"] = "grimstroke_ink_swell",
                ["searing_chains"] = "ember_spirit_searing_chains",
                ["fissure"] = "earthshaker_fissure",
                ["khanda"] = "item_khanda",
                ["phylactery"] = "item_phylactery",
            },
        },
        itemUpdates = {
            khanda = "Dapat dibongkar (disassembled).",
            phylactery = {
                allAttributesBonus = "7 -> 6",
                manaRegen = "2.5 -> 2.25",
            },
        },
        heroUpdates = {
            abaddon = { curseOfAvernus = "Tidak lagi dipicu oleh ilusi" },
            axe = { strengthGain = "2.8 -> 2.7", talent15 = "Battle Hunger DPS +10 -> +8" },
            batrider = { agilityGain = "1.8 -> 2.0", damageGainPerLevel = "3.4 -> 3.5" },
            bloodseeker = {
                bloodrage = "Max HP DPS 1.4% -> 1.2%",
                talent10 = "+175 Health -> +200",
                talent20 = "Agi +20 -> +15, Rupture cast range +425 -> +400",
            },
            brewmaster = {
                liquidCourage = "Shard max HP regen/s 2% -> 2.5%",
                drunkenBrawler = "Earth armor 2/4/6/8 -> 3/5/7/9",
            },
            broodmother = {
                necroticWebsFacet = "Restoration reduction 10/30/50/70 -> 10/25/40/55",
                spinWeb = "Max charges 4/6/8/10 -> 3/5/7/9",
                incapacitatingBite = "Tidak lagi diterapkan ilusi",
                talent15 = "Incapacitating Bite attack bonus +8 -> +6",
                talent25 = "Insatiable Hunger max attacks +1 -> +0.5",
            },
            clinkz = {
                skeletonWalk = "Durasi 35/40/45/50 -> 30/35/40/45",
                talent15 = "Burning Barrage cooldown -1s -> -0.5s",
                talent25 = "Strafe uses +1 -> +0.5",
            },
            dark_seer = { normalPunch = "Damage multiplier 1.4x -> 1.3x" },
            doom = { infernalBlade = "DPS 20/30/40/50 -> 18/27/36/45" },
            drow_ranger = { talent25 = "Multishot arrows +12 -> +10" },
            earthshaker = { fissure = "Cooldown 18/17/16/15 -> 19/18/17/16" },
            ember_spirit = { searingChains = "Damage 75/150/225/300 -> 70/140/210/280" },
            grimstroke = {
                inkSwell = "Cast range 500/550/600/650 -> 475/525/575/625",
                talent15 = "Ink Swell radius +75 -> +60",
            },
            gyrocopter = { talent25 = "Flak Cannon attacks +4 -> +3" },
            jakiro = { icePath = "Stun duration 1.25/1.5/1.75/2.0 -> 1.2/1.4/1.6/1.8" },
            ursa = { furySwipes = "Damage per stack 14/24/34/44 -> 12/22/32/42" },
            viper = {
                corrosiveSkin = "Magic resistance 10/15/20/25 -> 8/13/18/23",
                talent20 = "Poison Attack DPS +25 -> +20",
            },
        },
        balanceSignals = {
            heroPower = {
                abaddon = -1,
                axe = -1,
                bloodseeker = -1,
                broodmother = -2,
                clinkz = -1,
                drow_ranger = -1,
                earthshaker = 1,
                grimstroke = 3,
                gyrocopter = 1,
            },
            itemPower = {
                item_phylactery = -1,
                item_khanda = 1,
            },
        },
    },
}

AdvancedBotAI.ActivePatch = AdvancedBotAI.PatchProfiles["7.40c"]

function AdvancedBotAI.SetPatchProfile(version)
    if AdvancedBotAI.PatchProfiles[version] == nil then
        return false, "Unknown patch profile: " .. tostring(version)
    end

    AdvancedBotAI.ActivePatch = AdvancedBotAI.PatchProfiles[version]
    return true
end

function AdvancedBotAI.GetPatchSummary()
    local p = AdvancedBotAI.ActivePatch
    local role = AdvancedBotAI.GetRole()
    return {
        version = safeGet(p, "version", "unknown"),
        skillBracket = AdvancedBotAI.GetSkillBracket(),
        role = role,
        reflexProfile = AdvancedBotAI.GetReflexProfile(),
        recommendedHero = safeGet(safeGet(AdvancedBotAI.RecommendHeroPick({ role = role }), "best", {}), "hero", nil),
        itemUpdates = safeGet(p, "itemUpdates", {}),
        heroUpdates = safeGet(p, "heroUpdates", {}),
    }
end

function AdvancedBotAI.GetEntityPatchNotes(entityName, entityType)
    local p = AdvancedBotAI.ActivePatch
    if entityType == "hero" then
        return safeGet(safeGet(p, "heroUpdates", {}), entityName, nil)
    end

    if entityType == "item" then
        return safeGet(safeGet(p, "itemUpdates", {}), entityName, nil)
    end

    return nil
end

-- PHASE 1 — Audit Patch Compatibility
function AdvancedBotAI.AuditPatchCompatibility(api, auditInput)
    local input = auditInput or {}
    local report = {
        patch = safeGet(AdvancedBotAI.ActivePatch, "version", "unknown"),
        abilities = { missing = {}, valid = {} },
        items = { missing = {}, valid = {} },
        neutralItems = { missing = {}, valid = {} },
        talents = { missing = {}, valid = {} },
    }

    local registry = safeGet(AdvancedBotAI.ActivePatch, "entityRegistry", {})

    local function resolveAlias(name)
        local aliases = safeGet(registry, "aliases", {})
        local normalized = normalizeKey(name)
        return safeGet(aliases, normalized, name)
    end

    local function inRegistry(name, category)
        if category == "neutral_item" then
            return safeGet(safeGet(registry, "neutralItems", {}), name, false)
        end
        return safeGet(safeGet(registry, category .. "s", {}), name, false)
    end

    local function auditNames(nameList, target, category)
        for _, name in ipairs(nameList or {}) do
            local canonical = resolveAlias(name)
            local exists = false
            if api and api.exists then
                exists = api.exists(canonical, category)
            end
            exists = exists or inRegistry(canonical, category)

            if exists then
                table.insert(target.valid, canonical)
            else
                table.insert(target.missing, canonical)
            end
        end
    end

    local function auditTalents(talentList, target)
        local talentRegistry = safeGet(registry, "talents", {})
        for _, talentRef in ipairs(talentList or {}) do
            local hero, talent = talentRef:match("([^:]+):([^:]+)")
            hero = normalizeKey(hero)
            talent = normalizeKey(talent)

            local exists = false
            if hero ~= "" and talent ~= "" then
                exists = safeGet(safeGet(talentRegistry, hero, {}), talent, false)
                if api and api.exists then
                    exists = exists or api.exists(hero .. ":" .. talent, "talent")
                end
            end

            if exists then
                table.insert(target.valid, hero .. ":" .. talent)
            else
                table.insert(target.missing, talentRef)
            end
        end
    end

    auditNames(input.abilities, report.abilities, "ability")
    auditNames(input.items, report.items, "item")
    auditNames(input.neutralItems, report.neutralItems, "neutral_item")
    auditTalents(input.talents, report.talents)

    return report
end

function AdvancedBotAI.ApplyPatchBalanceAdjustments(state)
    local patch = AdvancedBotAI.ActivePatch
    local signals = safeGet(patch, "balanceSignals", {})
    local heroSignalMap = safeGet(signals, "heroPower", {})
    local itemSignalMap = safeGet(signals, "itemPower", {})

    local hero = safeGet(state, "heroName", "")
    local inventory = safeGet(state, "items", {})

    local heroSignal = safeGet(heroSignalMap, hero, 0)
    local itemSignal = 0

    for _, itemName in ipairs(inventory) do
        itemSignal = itemSignal + safeGet(itemSignalMap, itemName, 0)
    end

    return {
        heroSignal = heroSignal,
        itemSignal = itemSignal,
        netSignal = heroSignal + itemSignal,
    }
end

-- PHASE 2 — Modernize Decision Logic
function AdvancedBotAI.GetRoleWeights(state)
    local roleProfile = AdvancedBotAI.ActiveRoleProfile
    local roleName = safeGet(state, "role", safeGet(roleProfile, "name", "carry"))
    local normalized = normalizeKey(roleName)
    local selected = safeGet(AdvancedBotAI.RoleProfiles, normalized, roleProfile)

    return {
        farmBias = safeGet(selected, "farmBias", 1.0),
        fightBias = safeGet(selected, "fightBias", 1.0),
        objectiveBias = safeGet(selected, "objectiveBias", 1.0),
        mapRiskTolerance = safeGet(selected, "mapRiskTolerance", 1.0),
        lanePriority = safeGet(selected, "lanePriority", 1.0),
        spikeAmplifier = safeGet(selected, "spikeAmplifier", 1.0),
        roleName = safeGet(selected, "name", "carry"),
    }
end

function AdvancedBotAI.DetectPowerSpike(state)
    local cfg = safeGet(AdvancedBotAI.ActivePatch, "economy", {})
    local rank = AdvancedBotAI.ActiveRankProfile
    local role = AdvancedBotAI.GetRoleWeights(state)

    local level = safeGet(state, "level", 1)
    local networth = safeGet(state, "networth", 0)
    local coreItems = safeGet(state, "coreItemsOnline", 0)
    local ultimateReady = safeGet(state, "ultimateReady", false)
    local shardOwned = safeGet(state, "shardOwned", false)
    local bkbTiming = safeGet(state, "bkbTimingReady", false)
    local blinkTiming = safeGet(state, "blinkTimingReady", false)
    local keyTalentOnline = safeGet(state, "keyTalentOnline", false)
    local enemyCoreDead = safeGet(state, "enemyCoreDead", 0)
    local spikeWindowSeconds = safeGet(state, "spikeWindowSeconds", 0)
    local farmDelaySeconds = safeGet(state, "farmDelaySeconds", 0)
    local resourceDiscipline = AdvancedBotAI.EvaluateResourceDiscipline(state)

    local levelWeight = safeGet(cfg, "levelPowerSpikeWeight", 2)
    local itemWeight = safeGet(cfg, "coreItemPowerSpikeWeight", 12)
    local networthDivisor = safeGet(cfg, "networthPowerSpikeDivisor", 1500)

    local score = 0
    score = score + clamp((level - 6) * levelWeight, 0, 20)
    score = score + clamp(networth / networthDivisor, 0, 25)
    score = score + (coreItems * itemWeight)
    score = score + (ultimateReady and 15 or 0)
    score = score + (shardOwned and 8 or 0)
    score = score + (bkbTiming and 12 or 0)
    score = score + (blinkTiming and 7 or 0)
    score = score + (keyTalentOnline and 9 or 0)
    score = score + clamp(enemyCoreDead * 7, 0, 14)
    score = score + clamp(spikeWindowSeconds / 8, 0, 12)
    score = score - clamp(farmDelaySeconds / 6, 0, 10)
    score = score + (resourceDiscipline * 0.08)

    local patchSignal = AdvancedBotAI.ApplyPatchBalanceAdjustments(state)
    score = score + (patchSignal.netSignal * 1.5)
    score = score + safeGet(rank, "aggressionBias", 0) * 0.6
    score = score * safeGet(role, "spikeAmplifier", 1.0)

    return clamp(score, 0, 100)
end

function AdvancedBotAI.CalculateMapAwareness(state)
    local rank = AdvancedBotAI.ActiveRankProfile
    local role = AdvancedBotAI.GetRoleWeights(state)
    local visibleEnemies = safeGet(state, "visibleEnemies", 0)
    local enemyMissingSeconds = safeGet(state, "enemyMissingSeconds", 0)
    local wardsNearby = safeGet(state, "wardsNearby", 0)
    local alliesNearby = safeGet(state, "alliesNearby", 0)
    local recentObjectiveVision = safeGet(state, "recentObjectiveVision", false)
    local enemyTpSeen = safeGet(state, "enemyTpSeen", 0)
    local laneEquilibriumDanger = safeGet(state, "laneEquilibriumDanger", 0)
    local observerExpired = safeGet(state, "observerExpired", false)
    local scanReady = safeGet(state, "scanReady", true)
    local missingWaveSignals = safeGet(state, "missingWaveSignals", 0)
    local likelySmokePathDetected = safeGet(state, "likelySmokePathDetected", false)

    local safety = 50
    safety = safety - (visibleEnemies * 7)
    safety = safety - clamp(enemyMissingSeconds / 5, 0, 15)
    safety = safety + (wardsNearby * 8)
    safety = safety + (alliesNearby * 5)
    safety = safety + (recentObjectiveVision and 8 or 0)
    safety = safety - clamp(enemyTpSeen * 4, 0, 16)
    safety = safety - clamp(laneEquilibriumDanger * 10, 0, 20)
    safety = safety - (observerExpired and 8 or 0)
    safety = safety + (scanReady and 3 or -4)
    safety = safety - clamp(missingWaveSignals * 4, 0, 16)
    safety = safety + (likelySmokePathDetected and 8 or 0)
    safety = safety * safeGet(rank, "mapDiscipline", 1.0) * safeGet(rank, "wavePredictionDiscipline", 1.0)
    safety = safety * safeGet(role, "mapRiskTolerance", 1.0)

    return clamp(safety, 0, 100)
end

function AdvancedBotAI.EvaluateResourceDiscipline(state)
    local rank = AdvancedBotAI.ActiveRankProfile
    local hpPercent = safeGet(state, "hpPercent", 100)
    local manaPercent = safeGet(state, "manaPercent", 100)
    local spellsUsedWithoutOutcome = safeGet(state, "spellsUsedWithoutOutcome", 0)
    local wastedSpellCasts = safeGet(state, "wastedSpellCasts", 0)

    local score = 50
    score = score + clamp((hpPercent - 45) / 3, -20, 15)
    score = score + clamp((manaPercent - 35) / 3, -15, 20)
    score = score - clamp(spellsUsedWithoutOutcome * 8, 0, 24)
    score = score - clamp(wastedSpellCasts * 7, 0, 21)
    score = score * safeGet(rank, "resourceDiscipline", 1.0)

    return clamp(score, 0, 100)
end

function AdvancedBotAI.ScorePunishWindow(state)
    local rank = AdvancedBotAI.ActiveRankProfile
    local enemyOutOfPosition = safeGet(state, "enemyOutOfPosition", 0)
    local enemyCoreNoBuyback = safeGet(state, "enemyCoreNoBuyback", 0)
    local enemyBigSpellOnCooldown = safeGet(state, "enemyBigSpellOnCooldown", 0)
    local waveNearEnemyTower = safeGet(state, "waveNearEnemyTower", false)

    local punish = 0
    punish = punish + clamp(enemyOutOfPosition * 18, 0, 36)
    punish = punish + clamp(enemyCoreNoBuyback * 20, 0, 40)
    punish = punish + clamp(enemyBigSpellOnCooldown * 12, 0, 24)
    punish = punish + (waveNearEnemyTower and 10 or 0)
    punish = punish * safeGet(rank, "macroPunishFactor", 1.0)

    return clamp(punish, 0, 100)
end

function AdvancedBotAI.ScoreSpecialObjectives(gameState)
    local cfg = safeGet(AdvancedBotAI.ActivePatch, "objectives", {})

    local now = safeGet(gameState, "time", 0)
    local tormentorAlive = safeGet(gameState, "tormentorAlive", false)
    local wisdomRuneAvailable = safeGet(gameState, "wisdomRuneAvailable", false)
    local isHighGroundPushWindow = safeGet(gameState, "highGroundWindow", false)
    local advantage = safeGet(gameState, "teamAdvantage", 0)
    local lotusAvailable = safeGet(gameState, "lotusAvailable", false)
    local enemyCoreDead = safeGet(gameState, "enemyCoreDead", 0)
    local enemyHasBuyback = safeGet(gameState, "enemyHasBuyback", 0)

    local tormentorFirst = safeGet(cfg, "tormentorFirst", 1200)
    local tormentorScore = 0
    if tormentorAlive and now >= tormentorFirst then
        tormentorScore = 40 + clamp(advantage * 10, 0, 20)
    end

    local wisdomFirst = safeGet(cfg, "wisdomRuneFirst", 420)
    local wisdomInterval = safeGet(cfg, "wisdomRuneInterval", 420)
    local wisdomScore = 0
    if wisdomRuneAvailable and now >= wisdomFirst then
        local untilNext = wisdomInterval - (now % wisdomInterval)
        wisdomScore = 25 + clamp(untilNext / 30, 0, 10)
    end

    local highGroundScore = 0
    if isHighGroundPushWindow then
        highGroundScore = 35 + clamp(advantage * 15, 0, 35) + clamp(enemyCoreDead * 10, 0, 20) - clamp(enemyHasBuyback * 8, 0, 24)
    end

    local lotusFirst = safeGet(cfg, "lotusFirst", 180)
    local lotusInterval = safeGet(cfg, "lotusInterval", 180)
    local lotusScore = 0
    if lotusAvailable and now >= lotusFirst then
        local untilLotusRefresh = lotusInterval - (now % lotusInterval)
        lotusScore = 15 + clamp(untilLotusRefresh / 30, 0, 10)
    end

    return {
        tormentor = clamp(tormentorScore, 0, 100),
        wisdomRune = clamp(wisdomScore, 0, 100),
        highGround = clamp(highGroundScore, 0, 100),
        lotus = clamp(lotusScore, 0, 100),
    }
end

-- PHASE 3 — Upgrade AI System
function AdvancedBotAI.GlobalAggressionScore(teamState)
    local rank = AdvancedBotAI.ActiveRankProfile
    local role = AdvancedBotAI.GetRoleWeights(teamState)
    local lead = safeGet(teamState, "networthLead", 0)
    local ultReadyCount = safeGet(teamState, "ultReadyCount", 0)
    local deathballReady = safeGet(teamState, "deathballReady", false)
    local enemyBuybackRisk = safeGet(teamState, "enemyBuybackRisk", 0)
    local enemyBigUltReady = safeGet(teamState, "enemyBigUltReady", 0)
    local objectiveMomentum = safeGet(teamState, "objectiveMomentum", 0)
    local smokeReady = safeGet(teamState, "smokeReady", false)
    local currentPowerSpikeActive = safeGet(teamState, "currentPowerSpikeActive", false)
    local idleFarmDuringSpike = safeGet(teamState, "idleFarmDuringSpike", 0)
    local resourceDiscipline = AdvancedBotAI.EvaluateResourceDiscipline(teamState)

    local aggression = 45
    aggression = aggression + clamp(lead / 1500, -20, 30)
    aggression = aggression + (ultReadyCount * 5)
    aggression = aggression + (deathballReady and 12 or 0)
    aggression = aggression - clamp(enemyBuybackRisk * 20, 0, 25)
    aggression = aggression - clamp(enemyBigUltReady * 6, 0, 18)
    aggression = aggression + clamp(objectiveMomentum * 10, -10, 20)
    aggression = aggression + (smokeReady and 6 or 0)
    aggression = aggression + (currentPowerSpikeActive and 10 or 0)
    aggression = aggression - clamp(idleFarmDuringSpike * 6, 0, 18)
    aggression = aggression + (resourceDiscipline * 0.06)
    aggression = aggression + safeGet(rank, "aggressionBias", 0)
    aggression = aggression * safeGet(rank, "tempoDiscipline", 1.0)
    aggression = aggression * safeGet(role, "fightBias", 1.0)

    return clamp(aggression, 0, 100)
end

function AdvancedBotAI.PredictCombatWindow(localState, teamState)
    local rank = AdvancedBotAI.ActiveRankProfile
    local horizon = safeGet(localState, "predictionSeconds", 4) + safeGet(rank, "predictionHorizonBonus", 0)
    local myDps = safeGet(localState, "nearbyAllyDps", 0)
    local enemyDps = safeGet(localState, "nearbyEnemyDps", 0)
    local myHp = safeGet(localState, "hp", 0)
    local enemyHp = safeGet(localState, "targetHp", 0)
    local burstReady = safeGet(localState, "burstDamageReady", 0)
    local allyFollow = safeGet(teamState, "allyFollowup", 0)

    local myProjectedDamage = (myDps * horizon) + burstReady + clamp(allyFollow * 120, 0, 600)
    local enemyProjectedDamage = (enemyDps * horizon)

    local enemyKillPotential = (myProjectedDamage >= enemyHp) and 1 or 0
    local selfDieRisk = (enemyProjectedDamage >= myHp) and 1 or 0

    return {
        horizon = horizon,
        myProjectedDamage = myProjectedDamage,
        enemyProjectedDamage = enemyProjectedDamage,
        enemyKillPotential = enemyKillPotential,
        selfDieRisk = selfDieRisk,
        advantage = clamp((myProjectedDamage - enemyProjectedDamage) / 200, -20, 20),
    }
end

function AdvancedBotAI.EstimateJukeSuccess(localState)
    local treesNearby = safeGet(localState, "treesNearby", 0)
    local escapeRoutes = safeGet(localState, "escapeRoutes", 0)
    local mobilityReady = safeGet(localState, "mobilitySpellReady", false)
    local enemyDetection = safeGet(localState, "enemyDetection", 0)
    local enemyDisableCount = safeGet(localState, "enemyDisableCount", 0)
    local nightTime = safeGet(localState, "nightTime", false)

    local score = 20
    score = score + clamp(treesNearby * 5, 0, 30)
    score = score + clamp(escapeRoutes * 8, 0, 24)
    score = score + (mobilityReady and 20 or 0)
    score = score + (nightTime and 8 or 0)
    score = score - clamp(enemyDetection * 12, 0, 36)
    score = score - clamp(enemyDisableCount * 7, 0, 21)

    return clamp(score, 0, 100)
end

function AdvancedBotAI.DecideHumanLikeOutplay(localState, teamState)
    local rank = AdvancedBotAI.ActiveRankProfile
    local hpPercent = safeGet(localState, "hpPercent", 100)
    local threat = AdvancedBotAI.EvaluateThreat(localState)
    local prediction = AdvancedBotAI.PredictCombatWindow(localState, teamState)
    local jukeChance = AdvancedBotAI.EstimateJukeSuccess(localState)

    if hpPercent <= 35 then
        local clutchKillWindow = prediction.enemyKillPotential == 1 and prediction.selfDieRisk == 0
        if clutchKillWindow and threat <= safeGet(rank, "outplayRiskTolerance", 80) then
            return "commit_clutch_kill", {
                reason = "Low HP but lethal window in next seconds",
                prediction = prediction,
                jukeChance = jukeChance,
            }
        end

        if jukeChance >= safeGet(rank, "jukeThreshold", 55) then
            return "juke_escape", {
                reason = "Low HP with good juke probability",
                prediction = prediction,
                jukeChance = jukeChance,
            }
        end
    end

    if prediction.enemyKillPotential == 1 and prediction.advantage >= safeGet(rank, "trapAdvantageThreshold", 4) then
        return "set_trap_then_kill", {
            reason = "Positive short-horizon combat projection",
            prediction = prediction,
            jukeChance = jukeChance,
        }
    end

    return "standard", {
        reason = "No special outplay window",
        prediction = prediction,
        jukeChance = jukeChance,
    }
end

function AdvancedBotAI.EvaluateReactionWindow(localState)
    local reflex = AdvancedBotAI.ActiveReflexProfile
    local incomingProjectileTime = safeGet(localState, "incomingProjectileTime", 999)
    local incomingDisableTime = safeGet(localState, "incomingDisableTime", 999)
    local dodgeSpellReady = safeGet(localState, "dodgeSpellReady", false)
    local instantItemReady = safeGet(localState, "instantItemReady", false)

    local reactionMs = safeGet(reflex, "reactionMs", 240)
    local safetyFrames = safeGet(reflex, "predictionFrames", 10)
    local earliestThreatMs = math.min(incomingProjectileTime, incomingDisableTime) * 1000

    local canReact = earliestThreatMs > reactionMs
    local dodgePotential = (dodgeSpellReady and 20 or 0) + (instantItemReady and 16 or 0)
    dodgePotential = dodgePotential * safeGet(reflex, "dodgeBias", 1.0)

    return {
        reactionMs = reactionMs,
        earliestThreatMs = earliestThreatMs,
        canReact = canReact,
        predictionFrames = safetyFrames,
        dodgePotential = clamp(dodgePotential, 0, 100),
    }
end

function AdvancedBotAI.DecideInstantReflexAction(localState)
    local reflex = AdvancedBotAI.ActiveReflexProfile
    local reaction = AdvancedBotAI.EvaluateReactionWindow(localState)
    local hpPercent = safeGet(localState, "hpPercent", 100)
    local burstIncoming = safeGet(localState, "enemyBurstReady", 0)

    if reaction.canReact and reaction.dodgePotential >= 24 and burstIncoming >= 1 then
        return "frame_dodge", {
            reason = "Fast reaction + dodge tools available",
            reaction = reaction,
            precision = safeGet(reflex, "inputPrecision", 1.0),
        }
    end

    if hpPercent <= 25 and reaction.canReact and reaction.dodgePotential >= 16 then
        return "instant_disengage", {
            reason = "Critical HP with executable instant defensive input",
            reaction = reaction,
            precision = safeGet(reflex, "inputPrecision", 1.0),
        }
    end

    return "none", {
        reason = "No immediate reflex action required",
        reaction = reaction,
        precision = safeGet(reflex, "inputPrecision", 1.0),
    }
end

function AdvancedBotAI.EvaluateThreat(localState)
    local rank = AdvancedBotAI.ActiveRankProfile
    local nearbyEnemyDps = safeGet(localState, "nearbyEnemyDps", 0)
    local nearbyAllyDps = safeGet(localState, "nearbyAllyDps", 0)
    local hpPercent = safeGet(localState, "hpPercent", 100)
    local disabled = safeGet(localState, "disabled", false)
    local underEnemyVision = safeGet(localState, "underEnemyVision", false)
    local enemyBurstReady = safeGet(localState, "enemyBurstReady", 0)
    local defensiveCooldownReady = safeGet(localState, "defensiveCooldownReady", false)

    local threat = 30
    threat = threat + clamp((nearbyEnemyDps - nearbyAllyDps) / 20, -15, 40)
    threat = threat + clamp((60 - hpPercent) / 2, 0, 30)
    threat = threat + (disabled and 20 or 0)
    threat = threat + (underEnemyVision and 10 or 0)
    threat = threat + clamp(enemyBurstReady * 10, 0, 20)
    threat = threat - (defensiveCooldownReady and 8 or 0)
    threat = threat + safeGet(rank, "threatBias", 0)

    return clamp(threat, 0, 100)
end

function AdvancedBotAI.DecideChaseOrRetreat(localState, teamState)
    local role = AdvancedBotAI.GetRoleWeights(localState)
    local threat = AdvancedBotAI.EvaluateThreat(localState)
    local aggression = AdvancedBotAI.GlobalAggressionScore(teamState)
    local powerSpike = AdvancedBotAI.DetectPowerSpike(localState)
    local mapSafety = AdvancedBotAI.CalculateMapAwareness(localState)
    local outplayAction, outplayInfo = AdvancedBotAI.DecideHumanLikeOutplay(localState, teamState)
    local reflexAction, reflexInfo = AdvancedBotAI.DecideInstantReflexAction(localState)

    local chaseScore = ((aggression * 0.35) + (powerSpike * 0.35) + (mapSafety * 0.2) - (threat * 0.2)) * safeGet(role, "fightBias", 1.0)
    local retreatScore = ((threat * 0.55) - (aggression * 0.2) - (mapSafety * 0.1)) * (2 - safeGet(role, "mapRiskTolerance", 1.0))

    if reflexAction == "frame_dodge" then
        chaseScore = chaseScore + (8 * safeGet(AdvancedBotAI.ActiveReflexProfile, "comboExecution", 1.0))
        retreatScore = retreatScore - 6
    elseif reflexAction == "instant_disengage" then
        retreatScore = retreatScore + 14
    end

    if outplayAction == "commit_clutch_kill" then
        return "chase", chaseScore + safeGet(AdvancedBotAI.ActiveRankProfile, "clutchCommitBonus", 12), retreatScore, { outplay = outplayInfo, reflex = reflexInfo }
    end

    if outplayAction == "juke_escape" then
        return "retreat", chaseScore, retreatScore + safeGet(AdvancedBotAI.ActiveRankProfile, "jukeRetreatBonus", 14), { outplay = outplayInfo, reflex = reflexInfo }
    end

    if outplayAction == "set_trap_then_kill" then
        return "chase", chaseScore + safeGet(AdvancedBotAI.ActiveRankProfile, "trapCommitBonus", 8), retreatScore, { outplay = outplayInfo, reflex = reflexInfo }
    end

    if retreatScore + safeGet(AdvancedBotAI.ActiveRankProfile, "retreatThreshold", 0) > chaseScore then
        return "retreat", chaseScore, retreatScore, { outplay = outplayInfo, reflex = reflexInfo }
    end

    return "chase", chaseScore, retreatScore, { outplay = outplayInfo, reflex = reflexInfo }
end

function AdvancedBotAI.ScoreObjectives(state)
    local rank = AdvancedBotAI.ActiveRankProfile
    local role = AdvancedBotAI.GetRoleWeights(state)
    local tower = safeGet(state, "towerPressure", 0)
    local roshan = safeGet(state, "roshanWindow", 0)
    local pickoff = safeGet(state, "pickoffChance", 0)
    local farm = safeGet(state, "farmEfficiency", 0)
    local special = AdvancedBotAI.ScoreSpecialObjectives(state)
    local punish = AdvancedBotAI.ScorePunishWindow(state)
    local tempoMomentum = safeGet(state, "tempoMomentum", 0)
    local buildAdaptation = safeGet(state, "itemBuildAdaptation", 0) * safeGet(rank, "itemAdaptation", 1.0)

    local objectiveDiscipline = safeGet(rank, "objectiveDiscipline", 1.0)

    return {
        pushTower = clamp((tower + special.highGround * 0.4 + punish * 0.35 + tempoMomentum * 8) * objectiveDiscipline * safeGet(role, "objectiveBias", 1.0), 0, 100),
        roshan = clamp((roshan + safeGet(state, "teamAdvantage", 0) * 20 + punish * 0.4 + tempoMomentum * 10) * objectiveDiscipline * safeGet(role, "objectiveBias", 1.0), 0, 100),
        pickoff = clamp((pickoff + safeGet(state, "visionControl", 0) * 10 + punish * 0.3 + buildAdaptation * 5) * objectiveDiscipline * safeGet(role, "fightBias", 1.0), 0, 100),
        farm = clamp((farm - safeGet(state, "urgency", 0) * 10 + special.lotus * 0.25) * safeGet(role, "farmBias", 1.0), 0, 100),
        tormentor = special.tormentor,
        wisdomRune = special.wisdomRune,
        lotus = special.lotus,
        punish = punish,
    }
end

function AdvancedBotAI.ScoreObjectivePriority(state)
    local scored = AdvancedBotAI.ScoreObjectives(state)
    local ranked = {}
    for objective, score in pairs(scored) do
        table.insert(ranked, { objective = objective, score = score, role = AdvancedBotAI.GetRole() })
    end

    table.sort(ranked, function(a, b)
        if a.score == b.score then
            return a.objective < b.objective
        end
        return a.score > b.score
    end)

    return ranked
end

return AdvancedBotAI
