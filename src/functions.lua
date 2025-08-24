-- Global calculate for activating mods whenever a threashold is met
SuperRogue.calculate = function(self, context)
    if G.GAME.sr_trigger_type == 1 and context.ante_change and context.ante_end
        or G.GAME.sr_trigger_type == 2 and context.end_of_round and not context.repetition and not context.individual then
        G.GAME.sr_iteration_steps = G.GAME.sr_iteration_steps + 1
        if G.GAME.sr_iteration_steps >= SuperRogue_config.activation_threashold and G.GAME.sr_activation_mode == 1 then
            SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
            G.GAME.sr_iteration_steps = 0
        end
    end

    if context.skipping_booster then
        G.GAME.choice_pool_blacklist = {}
    end
end

-- Helper function to get a random inactive mod
function SuperRogue.get_rand_inactive()
    local inactive_pool = {}
    for k, v in pairs(G.GAME.sr_active_mod_pool) do
        if not v and not G.GAME.choice_pool_blacklist[k] then
            inactive_pool[#inactive_pool + 1] = k
        end
    end
    if next(inactive_pool) then
        local key = pseudorandom_element(inactive_pool, pseudoseed('SRRandom'))
        if G.GAME.sr_activation_mode == 2 then
            G.GAME.choice_pool_blacklist[key] = key
        end
        return key
    elseif not next(inactive_pool) and next(G.GAME.choice_pool_blacklist) and G.GAME.sr_activation_mode == 2 then
        local key = pseudorandom_element(G.GAME.choice_pool_blacklist, pseudoseed('SRRandom'))
        return key
    else
        return nil
    end
end

-- Helper function to activate mod
function SuperRogue.activate_mod(key)
    if key then
        G.GAME.sr_active_mod_pool[key] = true
        local disp_text = (SMODS.Mods[key].display_name or SMODS.Mods[key].name) .. localize('k_sr_activation')
        local hold_time = G.SETTINGS.GAMESPEED * (#disp_text * 0.035 + 1.3)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            blockable = false,
            func = function()
                play_sound('whoosh1', 0.55, 0.62)
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

-- Helper function to set Mod Consumable attributes
function SuperRogue.set_modcons_vars(card, mod)
    if not mod then
        mod = SMODS.Mods[card.ability.extra.mod_id]
        if not mod then return end
    end
    card.children.center.atlas = mod.prefix and G.ASSET_ATLAS[mod.prefix .. '_modicon'] or G.ASSET_ATLAS['modicon'] or
        G.ASSET_ATLAS['tags']
    card.children.center:set_sprite_pos({ x = 0, y = 0 })
end
