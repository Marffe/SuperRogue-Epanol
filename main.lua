SuperRogue = SMODS.current_mod
SuperRogue_config = SMODS.current_mod.config

assert(SMODS.load_file('src/functions.lua'))()
assert(SMODS.load_file('src/objects.lua'))()
assert(SMODS.load_file('src/overrides.lua'))()
assert(SMODS.load_file('src/ui.lua'))()

--#region Config
SuperRogue.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "m", r = 0.1, padding = 0.1, colour = G.C.BLACK, minw = 8, minh = 6 },
        nodes = {
            { n = G.UIT.R, config = { align = "cl", padding = 0, minh = 0.1 }, nodes = {} },

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
                                label = localize('b_sr_trigger_type'),
                                current_option = SuperRogue_config.trigger_type,
                                options = localize('sr_trigger_type_options'),
                                ref_table = SuperRogue_config,
                                ref_value = 'trigger_type',
                                info = localize('sr_trigger_type_desc'),
                                colour = G.C.RED,
                                opt_callback = 'sr_cycle_update'
                            })
                        }
                    },
                }
            },

            -- Activation Threashold Cycle
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cm", padding = 0.05 },
                        nodes = {
                            create_option_cycle({
                                label = localize('b_sr_activation_threashold'),
                                current_option = SuperRogue_config.activation_threashold,
                                options = { 1, 2, 3, 4, 5, 6, 7, 8 },
                                ref_table = SuperRogue_config,
                                ref_value = 'activation_threashold',
                                info = localize('sr_activation_threashold_desc'),
                                colour = G.C.RED,
                                opt_callback = 'sr_cycle_update'
                            })
                        }
                    },
                }
            },

            -- Activation Mode Cycle
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cm", padding = 0.05 },
                        nodes = {
                            create_option_cycle({
                                label = localize('b_sr_activation_mode'),
                                current_option = SuperRogue_config.activation_mode,
                                options = localize('sr_activation_mode_options'),
                                ref_table = SuperRogue_config,
                                ref_value = 'activation_mode',
                                info = localize('sr_activation_mode_desc'),
                                colour = G.C.RED,
                                opt_callback = 'sr_cycle_update'
                            })
                        }
                    },
                }
            },

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

            -- Boosters in shop toggle
            {
                n = G.UIT.R,
                config = { align = "cl", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.05 },
                        nodes = {
                            create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = SuperRogue_config, ref_value = "boosters_in_shop" },
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "c", padding = 0 },
                        nodes = {
                            { n = G.UIT.T, config = { text = localize('b_sr_boosters_in_shop'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
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

-- Blacklist and Starting Mods tabs
SMODS.current_mod.extra_tabs = function()
    return {
        {
            label = localize('b_sr_blacklist'),
            tab_definition_function = function()
                local silent = false
                local keys_used = {}
                local mod_areas = {}
                local mod_tables = {}
                local mod_table_rows = {}
                for k, v in pairs(SMODS.Mods) do
                    if not SuperRogue_config.core_mods[v.id] and v.can_load and not v.disabled then
                        keys_used[v.id] = v.id
                    end
                end
                for k, v in pairs(keys_used) do
                    if v then
                        if #mod_areas == 0 then
                            mod_areas[#mod_areas + 1] = CardArea(
                                G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                                5.33 * G.CARD_W,
                                0.53 * G.CARD_H,
                                { card_limit = 7, type = 'title_2', highlight_limit = 0 })
                            table.insert(mod_tables,
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0, no_fill = true },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = mod_areas[#mod_areas] } }
                                    }
                                }
                            )
                        elseif #mod_areas >= 1 and #mod_areas[#mod_areas].cards == 7 then
                            table.insert(mod_table_rows,
                                { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
                            )
                            mod_tables = {}
                            mod_areas[#mod_areas + 1] = CardArea(
                                G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                                5.33 * G.CARD_W,
                                0.53 * G.CARD_H,
                                { card_limit = 7, type = 'title_2', highlight_limit = 0 })
                            table.insert(mod_tables,
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0, no_fill = true },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = mod_areas[#mod_areas] } }
                                    }
                                }
                            )
                        end
                        local center = G.P_CENTERS['c_sr_mod_cons']
                        local card = Card(mod_areas[#mod_areas].T.x + mod_areas[#mod_areas].T.w / 2,
                            mod_areas[#mod_areas].T.y,
                            G.CARD_W, G.CARD_H, nil, center,
                            { bypass_discovery_center = true, bypass_discovery_ui = true, bypass_lock = true })
                        card.ability.extra.mod_id = k
                        card.ability.extra.blacklist_obj = true
                        SuperRogue.set_modcons_vars(card)
                        if SuperRogue_config.activation_blacklist[card.ability.extra.mod_id] then
                            card.debuff = true
                        end
                        card:start_materialize(nil, silent)
                        silent = true
                        mod_areas[#mod_areas]:emplace(card)
                    end
                end
                table.insert(mod_table_rows,
                    { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
                )

                local t = silent and {
                        n = G.UIT.ROOT,
                        config = { align = "cm", colour = G.C.CLEAR },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_mods_blacklist') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_crossed_blacklist') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.4 }) } }
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", minh = 0.5 },
                                nodes = {
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", colour = G.C.BLACK, r = 1, padding = 0.15, emboss = 0.05 },
                                nodes = {
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = mod_table_rows },
                                }
                            }
                        }
                    } or
                    {
                        n = G.UIT.ROOT,
                        config = { align = "cm", colour = G.C.CLEAR },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_no_mods_available') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                                }
                            },
                        }
                    }
                return t
            end
        },
        {
            label = localize('b_sr_starting_mods'),
            tab_definition_function = function()
                local silent = false
                local keys_used = {}
                local mod_areas = {}
                local mod_tables = {}
                local mod_table_rows = {}
                for k, v in pairs(SMODS.Mods) do
                    if not SuperRogue_config.core_mods[v.id] and v.can_load and not v.disabled then
                        keys_used[v.id] = v.id
                    end
                end
                for k, v in pairs(keys_used) do
                    if v then
                        if #mod_areas == 0 then
                            mod_areas[#mod_areas + 1] = CardArea(
                                G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                                5.33 * G.CARD_W,
                                0.53 * G.CARD_H,
                                { card_limit = 7, type = 'title_2', highlight_limit = 0 })
                            table.insert(mod_tables,
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0, no_fill = true },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = mod_areas[#mod_areas] } }
                                    }
                                }
                            )
                        elseif #mod_areas >= 1 and #mod_areas[#mod_areas].cards == 7 then
                            table.insert(mod_table_rows,
                                { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
                            )
                            mod_tables = {}
                            mod_areas[#mod_areas + 1] = CardArea(
                                G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                                5.33 * G.CARD_W,
                                0.53 * G.CARD_H,
                                { card_limit = 7, type = 'title_2', highlight_limit = 0 })
                            table.insert(mod_tables,
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0, no_fill = true },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = mod_areas[#mod_areas] } }
                                    }
                                }
                            )
                        end
                        local center = G.P_CENTERS['c_sr_mod_cons']
                        local card = Card(mod_areas[#mod_areas].T.x + mod_areas[#mod_areas].T.w / 2,
                            mod_areas[#mod_areas].T.y,
                            G.CARD_W, G.CARD_H, nil, center,
                            { bypass_discovery_center = true, bypass_discovery_ui = true, bypass_lock = true })
                        card.ability.extra.mod_id = k
                        card.ability.extra.starter_obj = true
                        SuperRogue.set_modcons_vars(card)
                        if not SuperRogue_config.starting_mods[card.ability.extra.mod_id] then
                            card.debuff = true
                        end
                        card:start_materialize(nil, silent)
                        silent = true
                        mod_areas[#mod_areas]:emplace(card)
                    end
                end
                table.insert(mod_table_rows,
                    { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
                )

                local t = silent and {
                        n = G.UIT.ROOT,
                        config = { align = "cm", colour = G.C.CLEAR },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_mods_starting') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_crossed_starting') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.4 }) } }
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", minh = 0.5 },
                                nodes = {
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", colour = G.C.BLACK, r = 1, padding = 0.15, emboss = 0.05 },
                                nodes = {
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = mod_table_rows },
                                }
                            }
                        }
                    } or
                    {
                        n = G.UIT.ROOT,
                        config = { align = "cm", colour = G.C.CLEAR },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_no_mods_available') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                                }
                            },
                        }
                    }
                return t
            end
        },
    }
end

--#endregion
