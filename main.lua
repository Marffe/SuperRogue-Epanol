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


--#region Functions
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
            G.GAME.choice_pool_blacklist[key] = true
        end
        if not key and G.GAME.sr_activation_mode == 2 then
            key = pseudorandom_element(G.GAME.choice_pool_blacklist, pseudoseed('SRRandom'))
        end
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

-- Stolen from SMODS
function wrapText(text, maxChars)
    local wrappedText = { "" }
    local curr_line = 1
    local currentLineLength = 0

    for word in text:gmatch("%S+") do
        if currentLineLength + #word <= maxChars then
            wrappedText[curr_line] = wrappedText[curr_line] .. word .. ' '
            currentLineLength = currentLineLength + #word + 1
        else
            wrappedText[curr_line] = string.sub(wrappedText[curr_line], 0, -2)
            curr_line = curr_line + 1
            wrappedText[curr_line] = ""
            wrappedText[curr_line] = wrappedText[curr_line] .. word .. ' '
            currentLineLength = #word + 1
        end
    end

    wrappedText[curr_line] = string.sub(wrappedText[curr_line], 0, -2)
    return wrappedText
end

function ensureModDescriptions()
    if G.localization.descriptions.SuperRogue_Mod then return end
    local sr_mod = {}
    G.localization.descriptions.SuperRogue_Mod = sr_mod
    local mod = G.localization.descriptions.Mod or {}
    for k, v in pairs(SMODS.Mods) do
        if not mod[k] then
            sr_mod[k] = {
                name = v.name,
                text = wrapText(v.description or '', 30)
            }
        end
    end
    init_localization()
end

--#endregion


--#region Hooks
-- Prevent specific mod cards from spawning if not active in pool
local gcp = get_current_pool
function get_current_pool(_type, _rarity, _legendary, _append)
    local _pool, _pool_key = gcp(_type, _rarity, _legendary, _append)

    if G.STAGE == G.STAGES.RUN then
        if _type == 'Tag' then
            for i = 1, #_pool do
                local key = _pool[i]
                if G.P_TAGS[key] and G.P_TAGS[key].mod and not G.GAME.sr_active_mod_pool[G.P_TAGS[key].mod.id] then
                    _pool[i] = "UNAVAILABLE"
                else
                    _pool[i] = key
                end
            end
        else
            for i = 1, #_pool do
                local key = _pool[i]
                if G.P_CENTERS[key] and G.P_CENTERS[key].mod and not G.GAME.sr_active_mod_pool[G.P_CENTERS[key].mod.id] then
                    _pool[i] = "UNAVAILABLE"
                else
                    _pool[i] = key
                end
            end
        end
    end

    return _pool, _pool_key
end

local igo = Game.init_game_object
Game.init_game_object = function(self)
    local ret = igo(self)

    ret.sr_active_mod_pool = {}
    -- Load Mod Pool
    for k, v in pairs(SMODS.Mods) do
        local blacklisted = SuperRogue_config.activation_blacklist[k]
        if not blacklisted and v then
            if v.id == 'Balatro' or v.id == 'Steamodded' then
                ret.sr_active_mod_pool[v.id] = true
            elseif SuperRogue_config.starting_mods[v.id] and v.can_load and not v.disabled then
                ret.sr_active_mod_pool[v.id] = true
            elseif v.can_load and not v.disabled then
                ret.sr_active_mod_pool[v.id] = false
            end
        end
    end

    ret.sr_iteration_steps = 0
    ret.sr_activation_threashold = SuperRogue_config.activation_threashold
    ret.sr_activation_mode = SuperRogue_config.activation_mode
    ret.sr_trigger_type = SuperRogue_config.trigger_type
    ret.choice_pool_blacklist = {}

    return ret
end

-- Setup values on run start
local start_r = Game.start_run
Game.start_run = function(self, args)
    start_r(self, args)

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        func = function()
            -- Start run by activating mod if option is active
            if SuperRogue_config.start_with_mod then
                if G.GAME.sr_activation_mode == 1 then
                    SuperRogue.activate_mod(SuperRogue.get_rand_inactive())
                else
                    G.CONTROLLER.locks.use = true
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            if G.STATE_COMPLETE then
                                local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
                                    G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27,
                                    G.P_CARDS.empty,
                                    G.P_CENTERS["p_sr_mod_booster"],
                                    { bypass_discovery_center = true, bypass_discovery_ui = true })
                                card.cost = 0
                                G.FUNCS.use_card({ config = { ref_table = card } })
                                card:start_materialize()
                                G.E_MANAGER:add_event(Event({
                                    func = function()
                                        if G.blind_select and not G.blind_select.alignment.offset.py then
                                            G.blind_select.alignment.offset.py = G.blind_select.alignment.offset.y
                                            G.blind_select.alignment.offset.y = G.ROOM.T.y + 39
                                        end
                                        return true;
                                    end
                                }))
                                G.CONTROLLER.locks.use = nil
                                return true
                            end
                            return true;
                        end
                    }))
                end
            end
            return true;
        end
    }))
end

-- Spawn Mod Booster if threashold is met when entering shop
local update_shopref = Game.update_shop
function Game.update_shop(self, dt)
    update_shopref(self, dt)
    if not (G.GAME.sr_iteration_steps >= G.GAME.sr_activation_threashold) then return end

    G.GAME.sr_iteration_steps = 0

    local can_create_booster = false
    for i = 1, G.GAME.sr_active_mod_pool do
        if not G.GAME.sr_active_mod_pool[i] then
            can_create_booster = true
            break
        end
    end

    if can_create_booster then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            func = function()
                if G.STATE_COMPLETE then
                    local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
                        G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27,
                        G.P_CARDS.empty,
                        G.P_CENTERS["p_sr_mod_booster"],
                        { bypass_discovery_center = true, bypass_discovery_ui = true })
                    card.cost = 0
                    G.FUNCS.use_card({ config = { ref_table = card } })
                    card:start_materialize()
                    return true
                end
            end
        }))
    end
end

--#endregion


--#region Objects

SMODS.ConsumableType {
    key = 'Mod_Consumable',
    primary_colour = HEX('d90e00'),
    secondary_colour = HEX('ffad66'),
    shop_rate = 0.0
}

SMODS.Consumable {
    key = 'mod_cons',
    set = 'Mod_Consumable',
    pixel_size = { w = 34, h = 34 },
    display_size = { w = 46, h = 46 },
    config = {
        extra = {
            mod_id = nil
        }
    },
    cost = 0,
    discovered = true,
    no_collection = true,
    loc_vars = function(self, info_queue, card) -- Thank you Wilson for this!!
        ensureModDescriptions()
        local id = card.ability.extra.mod_id
        local mod = SMODS.Mods[id]
        if not G.localization.descriptions.SuperRogue_Mod[id] then
            local loc_vars = mod.description_loc_vars and mod:description_loc_vars() or {}
            return {
                key = loc_vars.key or id,
                set = 'Mod',
                vars = loc_vars.vars,
                scale = loc_vars.scale,
                text_colour = loc_vars.text_colour,
                background_colour = loc_vars.background_colour,
                shadow = loc_vars.shadow
            }
        end
        return {
            key = id,
            set = "SuperRogue_Mod"
        }
    end,
    in_pool = function(self, args)
        return true, { allow_duplicates = true }
    end,
    use = function(self, card, area, copier)
        SuperRogue.activate_mod(card.ability.extra.mod_id)
        G.GAME.choice_pool_blacklist = {}
    end,
    can_use = function(self, card)
        return true
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra.mod_id = SuperRogue.get_rand_inactive()

        local mod = SMODS.Mods[card.ability.extra.mod_id]
        card.children.center.atlas = mod.prefix and G.ASSET_ATLAS[mod.prefix .. '_modicon'] or G.ASSET_ATLAS['modicon'] or
            G.ASSET_ATLAS['tags']
        card.children.center:set_sprite_pos({ x = 0, y = 0 })
    end
}

SMODS.Booster {
    key = 'mod_booster',
    kind = 'Mod_Consumable',
    group_key = 'k_sr_mod_booster',
    config = {
        extra = 2,
        choose = 1
    },
    cost = 0,
    discovered = true,
    no_collection = true,
    weight = 0.0,
    create_card = function(self, card)
        return SMODS.create_card({ area = G.pack_cards, key = 'c_sr_mod_cons', key_append = "sr_modpack", no_edition = true, skip_materialize = true })
    end,
    ease_background_colour = function(self)
        ease_colour(G.C.DYN_UI.MAIN, HEX('d90e00'))
        ease_background_colour({ new_colour = HEX('ffad66'), special_colour = G.C.BLACK, contrast = 2 })
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.config.center.config.choose, card.ability.extra } }
    end
}

--#endregion
