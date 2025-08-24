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
local atr = Back.apply_to_run
Back.apply_to_run = function(self)
    atr(self)

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
                                G.E_MANAGER:add_event(Event({
                                    func = function()
                                        if G.blind_select and not G.blind_select.alignment.offset.py then
                                            G.blind_select.alignment.offset.py = G.blind_select.alignment.offset.y
                                            G.blind_select.alignment.offset.y = G.ROOM.T.y + 39
                                        end
                                        return true;
                                    end
                                }))
                                local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
                                    G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27,
                                    G.P_CARDS.empty,
                                    G.P_CENTERS["p_sr_mod_booster"],
                                    { bypass_discovery_center = true, bypass_discovery_ui = true })
                                card.cost = 0
                                G.FUNCS.use_card({ config = { ref_table = card } })
                                card:start_materialize()
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
    for k, v in pairs(G.GAME.sr_active_mod_pool) do
        if not v then
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
