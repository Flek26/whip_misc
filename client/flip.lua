-- ============================================
-- whip_misc — client: flip a vehicle back onto its wheels
-- ============================================
--
-- Look at a car lying on its side or roof (whip's aim-box prompt on vehicles): "Flip vehicle". The server runs the
-- bar (server/flip.lua: a pushing animation, timed there, walking off cancels it), then this game takes control of
-- the car and stands it on its wheels, facing the way it lay.

local F = Config.Flip
if not F or not F.enabled then return end

local SKIP = {}
for _, c in ipairs(F.skipClasses or {}) do SKIP[c] = true end

--- On its side or roof, nearly stopped, nobody inside, and a class that flips.
local function flippable(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return false end
    if SKIP[GetVehicleClass(veh)] then return false end
    local roll, pitch = GetEntityRoll(veh), GetEntityPitch(veh)
    local over = math.abs(roll) > F.minRoll or math.abs(pitch) > F.minRoll or IsVehicleStuckOnRoof(veh)
    if not over then return false end
    if GetEntitySpeed(veh) > 1.0 then return false end
    if not IsVehicleSeatFree(veh, -1) then return false end
    return true
end

Whip.register(function()
    Whip.core:AddAction({
        id = 'flip', at = { aimBox = 'vehicle' },
        label = 'Flip vehicle', reach = F.reach,
        canInteract = function(ctx) return flippable(ctx.entity) end,
        onSelect = function(ctx)
            local veh = ctx.entity
            if not NetworkGetEntityIsNetworked(veh) then return ctx.refuse('You can\'t flip that') end
            TriggerServerEvent('whip_misc:flip', VehToNet(veh))
        end,
    })
end)

-- The bar ran: stand it up.
RegisterNetEvent('whip_misc:flipNow', function(netId)
    local veh = NetToVeh(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local ok = exports.whip_core:TakeVehicleControl({ entity = veh })
    if not ok then return Whip.core:Notify('Could not get hold of it: try again', 'error') end
    local heading = GetEntityHeading(veh)
    local at = GetEntityCoords(veh)
    SetEntityRotation(veh, 0.0, 0.0, heading, 2, true)
    SetEntityCoords(veh, at.x, at.y, at.z + 0.5, false, false, false, false)
    SetVehicleOnGroundProperly(veh)
end)
