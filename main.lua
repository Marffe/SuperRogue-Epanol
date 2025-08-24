SuperRogue = SMODS.current_mod
SuperRogue_config = SMODS.current_mod.config

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

assert(SMODS.load_file('src/functions.lua'))()
assert(SMODS.load_file('src/objects.lua'))()
assert(SMODS.load_file('src/overrides.lua'))()
assert(SMODS.load_file('src/ui.lua'))()