-- ============================================
-- whip_misc — client: enter any seat (F at a door gets you into that door's seat)
-- ============================================
--
-- GTA's F always heads for the driver's seat (or the front passenger's, round the driver). whip_core already turns F
-- at the front passenger door of an empty car into "sit there, no slide" (client/seats.lua). This does the same for
-- every door: F at a back door gets you into that back seat.
--
-- How: GTA's own get-in starts as usual (F, its walk, its door). The moment it does, the door nearest the player is
-- found from the doors the car really has (door_dside_f, door_pside_f, door_dside_r, door_pside_r: -1, 0, 1, 2), and
-- if GTA is heading for a different seat and that door's seat is free, the get-in is told again: that seat, by that
-- door, with no sliding. The driver's own door, a seat someone is in, bikes, boats and aircraft are GTA's.
--
-- Cost: one native a tenth of a second on foot (is a get-in under way?), half a second in a vehicle. Only a get-in
-- that starts does any more.
--
-- Cancel: as whip's own, F again or pushing away from the car stops the walk.

local E = Config.EnterAnySeat
if not E or not E.enabled then
    print('[whip_misc] enter any seat is off (Config)')
    return
end
print('[whip_misc] enter any seat ready')

local DOORS = {
    { bone = 'door_dside_f', seat = -1, index = 0 },
    { bone = 'door_pside_f', seat = 0,  index = 1 },
    { bone = 'door_dside_r', seat = 1,  index = 2 },
    { bone = 'door_pside_r', seat = 2,  index = 3 },
}
local ENTER_RESUME, ENTER_NO_SLIDE = 1, 1048576
local CONTROL_ENTER, MOVE_LR, MOVE_UD = 23, 30, 31
local WATCH_MS = 10000

local SKIP = {}
for _, c in ipairs(E.skipClasses or {}) do SKIP[c] = true end

local handled = 0   -- the car this get-in was already told about (forgotten when the get-in ends)

--- The seat of the door nearest the ped, or nil.
local function nearestDoorSeat(ped, veh)
    local here = GetEntityCoords(ped)
    local maxSeat = GetVehicleMaxNumberOfPassengers(veh) - 1
    local best, bestD
    for _, d in ipairs(DOORS) do
        if d.seat <= maxSeat and GetEntityBoneIndexByName(veh, d.bone) ~= -1 then
            local at = GetEntryPositionOfDoor(veh, d.index)
            local dist = #(here - at)
            if not bestD or dist < bestD then best, bestD = d.seat, dist end
        end
    end
    if bestD and bestD <= E.maxDoorDistance then return best end
    return nil
end

--- F again, or a push away from the car: stop walking to it.
local function watchCancel(ped, veh)
    CreateThread(function()
        local deadline = GetGameTimer() + WATCH_MS
        while GetGameTimer() < deadline do
            Wait(0)
            if not DoesEntityExist(veh) or GetVehiclePedIsTryingToEnter(ped) ~= veh or IsPedInAnyVehicle(ped, true) then
                return
            end
            local stop = IsControlJustPressed(0, CONTROL_ENTER) or IsDisabledControlJustPressed(0, CONTROL_ENTER)
            if not stop then
                local lr, ud = GetControlNormal(0, MOVE_LR), GetControlNormal(0, MOVE_UD)
                if lr * lr + ud * ud >= 0.25 then
                    local h = math.rad(GetGameplayCamRot(2).z)
                    local wx = math.cos(h) * lr + math.sin(h) * ud
                    local wy = math.sin(h) * lr - math.cos(h) * ud
                    local p, v = GetEntityCoords(ped), GetEntityCoords(veh)
                    stop = wx * (v.x - p.x) + wy * (v.y - p.y) < 0
                end
            end
            if stop then ClearPedTasks(ped) return end
        end
    end)
end

local function check(ped)
    local veh = GetVehiclePedIsTryingToEnter(ped)
    if veh == 0 then handled = 0 return end
    if veh == handled then return end
    handled = veh
    if SKIP[GetVehicleClass(veh)] then return end

    local want = nearestDoorSeat(ped, veh)
    if not want or want == -1 then return end                       -- the driver's door: GTA's
    if GetSeatPedIsTryingToEnter(ped) == want then return end       -- already going there
    if not IsVehicleSeatFree(veh, want) then return end             -- taken: GTA settles it

    local speed = (IsPedRunning(ped) or IsPedSprinting(ped)) and 2.0 or 1.0
    TaskEnterVehicle(ped, veh, WATCH_MS, want, speed, ENTER_RESUME | ENTER_NO_SLIDE, 0)
    watchCancel(ped, veh)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            handled = 0
            Wait(500)
        else
            check(ped)
            Wait(100)
        end
    end
end)
