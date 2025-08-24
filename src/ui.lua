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

-- Create Run Info Mods tab
function G.UIDEF.sr_activated_mods()
    local silent = false
    local keys_used = {}
    local mod_areas = {}
    local mod_tables = {}
    local mod_table_rows = {}
    for k, v in pairs(G.GAME.sr_active_mod_pool) do
        if k ~= 'Balatro' and k ~= 'Steamodded' then
            keys_used[k] = G.GAME.sr_active_mod_pool[k]
        end
    end
    for k, v in pairs(keys_used) do
        if v then
            if #mod_areas == 0 then
                mod_areas[#mod_areas + 1] = CardArea(
                    G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                    5.33 * G.CARD_W,
                    1.07 * G.CARD_H,
                    { card_limit = 5, type = 'joker', highlight_limit = 0 })
                table.insert(mod_tables,
                    {
                        n = G.UIT.C,
                        config = { align = "cm", padding = 0, no_fill = true },
                        nodes = {
                            { n = G.UIT.O, config = { object = mod_areas[#mod_areas] } }
                        }
                    }
                )
            elseif #mod_areas == 1 and #mod_areas[1].cards == 5 or #mod_areas == 2 and #mod_areas[2].cards == 5 then
                table.insert(mod_table_rows,
                    { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
                )
                mod_tables = {}
                mod_areas[#mod_areas + 1] = CardArea(
                    G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                    5.33 * G.CARD_W,
                    1.07 * G.CARD_H,
                    { card_limit = 5, type = 'joker', highlight_limit = 0 })
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
            local card = Card(mod_areas[#mod_areas].T.x + mod_areas[#mod_areas].T.w / 2, mod_areas[#mod_areas].T.y,
                G.CARD_W, G.CARD_H, nil, center,
                { bypass_discovery_center = true, bypass_discovery_ui = true, bypass_lock = true })
            card.ability.extra.mod_id = k
            SuperRogue.set_modcons_vars(card)
            card:start_materialize(nil, silent)
            silent = true
            mod_areas[#mod_areas]:emplace(card)
        end
    end
    table.insert(mod_table_rows,
        { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true }, nodes = mod_tables }
    )

    local trigger_string
    if G.GAME.sr_activation_mode == 1 then
        trigger_string = localize('k_ante') .. 's'
    elseif G.GAME.sr_activation_mode == 2 then
        trigger_string = localize('k_round') .. 's'
    end

    local t = silent and {
            n = G.UIT.ROOT,
            config = { align = "cm", colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm" },
                    nodes = {
                        { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_mods_activated') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                    }
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm" },
                    nodes = {
                        { n = G.UIT.O, config = { object = DynaText({ string = { trigger_string .. localize('b_sr_until_next_mod') .. G.GAME.sr_activation_threashold - G.GAME.sr_iteration_steps }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.4 }) } }
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
                        { n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_sr_no_mods') }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.6 }) } }
                    }
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm" },
                    nodes = {
                        { n = G.UIT.O, config = { object = DynaText({ string = { trigger_string .. localize('b_sr_until_next_mod') .. G.GAME.sr_activation_threashold - G.GAME.sr_iteration_steps }, colours = { G.C.UI.TEXT_LIGHT }, bump = true, scale = 0.4 }) } }
                    }
                },
            }
        }
    return t
end
