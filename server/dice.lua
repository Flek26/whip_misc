-- ============================================
-- whip_misc — server: /roll, dice in whip's /me capsule
-- ============================================
--
-- /roll [dice] [sides]: the server rolls (a client can't pick its numbers), then the result floats above the roller's
-- head in whip's own /me capsule (whip_core client/bubbles.lua, its whip_core:client:bubble event), for every player
-- within Config.Dice.range in the same routing bucket, as a /me is. The roller plays a short throw.

local D = Config.Dice
if not D or not D.enabled then return end

local function say(source, msg, kind)
    exports.whip_core:NotifyPlayer(source, msg, kind or 'error')
end

Whip.command(D.command, { rateLimit = { burst = 2, everyMs = D.cooldownMs } }, function(source, args)
    local dice = math.tointeger(tonumber(args[1] or D.defaultDice))
    local sides = math.tointeger(tonumber(args[2] or D.defaultSides))
    if not dice or not sides or dice < 1 or dice > D.maxDice or sides < 2 or sides > D.maxSides then
        return say(source, ('Usage: /%s [dice 1-%d] [sides 2-%d]'):format(D.command, D.maxDice, D.maxSides))
    end

    local rolls, total = {}, 0
    for i = 1, dice do
        local r = math.random(1, sides)
        rolls[i] = tostring(r)
        total = total + r
    end
    local text
    if dice == 1 then
        text = ('Roll: %s'):format(rolls[1])
    else
        text = ('Roll: %s (total %d)'):format(table.concat(rolls, ', '), total)
    end

    TriggerClientEvent('whip_misc:diceThrow', source)
    -- A moment for the throw before the number shows.
    SetTimeout(D.revealMs, function()
        local ped = GetPlayerPed(source)
        if not ped or ped == 0 then return end
        local at, bucket = GetEntityCoords(ped), GetPlayerRoutingBucket(source)
        for _, idStr in ipairs(GetPlayers()) do
            local id = tonumber(idStr)
            if GetPlayerRoutingBucket(id) == bucket and #(GetEntityCoords(GetPlayerPed(id)) - at) <= D.range then
                TriggerClientEvent('whip_core:client:bubble', id, source, text, 2, nil, D.range)
            end
        end
    end)
end)

-- The chat's suggestion, for everyone.
local function suggest(src)
    TriggerClientEvent('chat:addSuggestion', src, '/' .. D.command, 'Roll dice for everyone near to see', {
        { name = 'dice', help = ('how many, 1-%d (default %d)'):format(D.maxDice, D.defaultDice) },
        { name = 'sides', help = ('sides each, 2-%d (default %d)'):format(D.maxSides, D.defaultSides) },
    })
end
AddEventHandler('whip_core:player:loaded', function(e) if type(e) == 'table' and e.source then suggest(e.source) end end)
CreateThread(function() suggest(-1) end)
