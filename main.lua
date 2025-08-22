SuperRogue = SMODS.current_mod
SuperRogue_config = SMODS.current_mod.config

SuperRogue.active_mod_pool = {}

--#region Config
SuperRogue.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "m", r = 0.1, padding = 0.1, colour = G.C.BLACK, minw = 8, minh = 6 },
        nodes = {
            { n = G.UIT.R, config = { align = "cl", padding = 0, minh = 0.1 }, nodes = {} },

            -- Start with mod toggle
            {
                n = G.UIT.R,
                config = { align = "cl", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.05 },
                        nodes = {
                            create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = SuperRogue_config, ref_value = "start_with_mod" },
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "c", padding = 0 },
                        nodes = {
                            { n = G.UIT.T, config = { text = localize('b_sr_start_with_mod'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
                        }
                    },
                }
            },

            -- Iterator Type Cycle
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cm", padding = 0.05 },
                        nodes = {
                            create_option_cycle({
                                label = localize('b_sr_iterator_type'),
                                current_option = SuperRogue_config.iterator_type,
                                options = localize('sr_iterator_type_options'),
                                ref_table = SuperRogue_config,
                                ref_value = 'iterator_type',
                                info = localize('sr_iterator_type_desc'),
                                colour = G.C.RED,
                                opt_callback = 'sr_cycle_update'
                            })
                        }
                    },
                }
            },

        }
    }
end

-- Taken from Galdur
G.FUNCS.sr_cycle_update = function(args)
    args = args or {}
    if args.cycle_config and args.cycle_config.ref_table and args.cycle_config.ref_value then
        args.cycle_config.ref_table[args.cycle_config.ref_value] = args.to_key
    end
end
--#endregion

-- Helper function to get a random inactive mod
function SuperRogue.get_rand_inactive()
    local inactive_pool = {}
    for k, v in pairs(SuperRogue.active_mod_pool) do
        if not v then
            inactive_pool[#inactive_pool + 1] = k
        end
    end
    if next(inactive_pool) then
        return pseudorandom_element(inactive_pool, pseudoseed('SRRandom'))
    else
        return nil
    end
end

-- Global calculate for activating mods at end of ante
SuperRogue.calculate = function(self, context)
    if context.ante_change and context.ante_end and SuperRogue_config.iterator_type == 1 then
        SuperRogue.iteration_steps = SuperRogue.iteration_steps + 1
        if SuperRogue.iteration_steps >= SuperRogue_config.activation_threashold then
            SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
            SuperRogue.iteration_steps = 0
        end
    end

    if context.end_of_round and not context.repetition and not context.individual and SuperRogue_config.iterator_type == 2 then
        SuperRogue.iteration_steps = SuperRogue.iteration_steps + 1
        if SuperRogue.iteration_steps >= SuperRogue_config.activation_threashold then
            SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
            SuperRogue.iteration_steps = 0
        end
    end
end

-- Helper function to activate mod
function SuperRogue.activate_mod(key)
    if key then
        SuperRogue.active_mod_pool[key] = true
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

    SuperRogue.iteration_steps = 0

    for k, v in pairs(SMODS.Mods) do
        local blacklisted = false
        for i = 1, #SuperRogue_config.activation_blacklist do
            if k == SuperRogue_config.activation_blacklist[i] or v.name == "Steamodded" then
                blacklisted = true
                break
            end
        end
        if not blacklisted then
            if SuperRogue_config.starting_mods[v.id] and v.can_load then
                SuperRogue.active_mod_pool[v.id] = true
            else
                SuperRogue.active_mod_pool[v.id] = false
            end
        end
    end

    if SuperRogue_config.start_with_mod then
        SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
    end
end
