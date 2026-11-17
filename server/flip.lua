-- ============================================
-- whip_misc — server: flip a vehicle (the bar; client/flip.lua stands it up)
-- ============================================

local F = Config.Flip
if not F or not F.enabled then return end

local busy = {}   -- [netId] = true while someone is flipping it

Whip.register(function()
    Whip.core:SecureEvent('whip_misc:flip', {
        rateLimit = 2000,
        params = { { 'netId', 'int', 1, 65535 } },
        near = {
            at = function(_, _, netId)
                local veh = NetworkGetEntityFromNetworkId(netId)
                if veh and veh ~= 0 and DoesEntityExist(veh) then return GetEntityCoords(veh) end
            end,
            range = F.reach + 2.5, message = 'Get closer',
        },
    }, function(source, player, netId)
        local veh = NetworkGetEntityFromNetworkId(netId)
        if not veh or veh == 0 or GetEntityType(veh) ~= 2 then return false end
        if GetPedInVehicleSeat(veh, -1) ~= 0 then return false, 'Someone is in it' end
        if busy[netId] then return false, 'Someone is already flipping it' end
        busy[netId] = true
        local done, why = Whip.core:Progress(source, {
            label = 'Flipping the vehicle...', duration = F.time, anim = F.anim, canCancel = true,
            near = { coords = GetEntityCoords(veh), range = F.reach + 2.5 },
        })
        busy[netId] = nil
        if not done then return false, why ~= 'cancelled' and why or nil end
        if not exports.whip_core:IsSessionCurrent(source, player.session) or not DoesEntityExist(veh) then return false end
        TriggerClientEvent('whip_misc:flipNow', source, netId)
    end)
end)
