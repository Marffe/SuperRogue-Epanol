SuperRogue = SMODS.current_mod
SuperRogue_config = SMODS.current_mod.config

SuperRogue.active_mod_pool = {}

-- Helper function to get a random inactive mod
function SuperRogue.get_rand_inactive()
    local inactive_pool = {}
    for k, v in pairs(SuperRogue.active_mod_pool) do
        local blacklisted = false
        for i = 1, #SuperRogue_config.activation_blacklist do
            if k == SuperRogue_config.activation_blacklist[i] then
                blacklisted = true
                break
            end
        end
        if not v and not blacklisted then
            sendDebugMessage(k .. ' added to inactive pool', 'SuperRouge')
            inactive_pool[#inactive_pool + 1] = k
        end
    end
    return pseudorandom_element(inactive_pool, pseudoseed('SRRandom'))
end

-- Global calculate for activating mods at end of ante
SuperRogue.calculate = function(self, context)
    if context.ante_change and context.ante_end then
        SuperRogue.antes = SuperRogue.antes + 1
        if SuperRogue.antes >= SuperRogue_config.ante_activation then
            SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
            SuperRogue.antes = 0
        end
    end
end

-- Helper function to activate mod
function SuperRogue.activate_mod(key)
    if not SuperRogue_config.activation_blacklist[key] then
        SuperRogue.active_mod_pool[key] = true
        local disp_text = (SMODS.Mods[key].display_name or SMODS.Mods[key].name) .. localize('k_sr_activation')
        local hold_time = G.SETTINGS.GAMESPEED * (#disp_text * 0.035 + 1.3)
        G.E_MANAGER:add_event(Event({
            func = function()
                attention_text({
                    scale = 0.7,
                    text = disp_text,
                    maxw = 12,
                    hold = hold_time,
                    align = 'cm',
                    offset = { x = 0, y = -1 },
                    major = G.play
                })
                return true;
            end
        }))
    end
end

-- Prevent specific mod cards from spawning if not active in pool
local gcp = get_current_pool
function get_current_pool(_type, _rarity, _legendary, _append)
    local _pool, _pool_key = gcp(_type, _rarity, _legendary, _append)

    if G.STAGE == G.STAGES.RUN then
        if _type == 'Tag' then
            for i = 1, #_pool do
                local key = _pool[i]
                if G.P_TAGS[key] and G.P_TAGS[key].mod and not SuperRogue.active_mod_pool[G.P_TAGS[key].mod.id] then
                    _pool[i] = "UNAVAILABLE"
                end
            end
        else
            for i = 1, #_pool do
                local key = _pool[i]
                if G.P_CENTERS[key] and G.P_CENTERS[key].mod and not SuperRogue.active_mod_pool[G.P_CENTERS[key].mod.id] then
                    _pool[i] = "UNAVAILABLE"
                end
            end
        end
    end

    return _pool, _pool_key
end

-- Setup values on run start
local start_r = Game.start_run
Game.start_run = function(self, args)
    start_r(self, args)

    SuperRogue.antes = 0

    for k, v in pairs(SMODS.Mods) do
        if SuperRogue_config.starting_mods[v.id] and v.can_load then
            SuperRogue.active_mod_pool[v.id] = true
        else
            SuperRogue.active_mod_pool[v.id] = false
        end
    end
end
