-- ============================================
-- whip_misc — client: no air control, no flipping back
-- ============================================
--
-- GTA lets a driver steer and tip a car in mid-air, and rock an upside-down car back onto its wheels. Off for the
-- classes in Config.NoAirControl: while the car is in the air, or lying on its side or roof and nearly stopped, the
-- steer and lean controls (59 left/right, 60 up/down) are held off.
--
-- A control is only off for the frame it was disabled in, so this runs every frame, but only while it matters:
--   on foot / a passenger / a class not listed:  every 500 ms (is that still so?)
--   driving, on the wheels:                       every 50 ms (left the ground yet?)
--   driving, in the air or flipped:               every frame (holding the controls off)

local A = Config.NoAirControl
if not A or not A.enabled then return end

local CLASSES = {}
for _, c in ipairs(A.classes or {}) do CLASSES[c] = true end

local function blocked(veh)
    if IsEntityInAir(veh) then return true end
    if A.antiFlip then
        local roll = GetEntityRoll(veh)
        if (roll > A.flipRoll or roll < -A.flipRoll) and GetEntitySpeed(veh) < A.flipSpeed then return true end
    end
    return false
end

CreateThread(function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and CLASSES[GetVehicleClass(veh)] then
            wait = 50
            if blocked(veh) then
                -- Every frame until it is back on its wheels (or they leave the seat).
                repeat
                    DisableControlAction(0, 59, true)   -- INPUT_VEH_MOVE_LR
                    DisableControlAction(0, 60, true)   -- INPUT_VEH_MOVE_UD
                    DisableControlAction(2, 59, true)   -- the same in the frontend group (a pad), as xrp had
                    DisableControlAction(2, 60, true)
                    Wait(0)
                until GetVehiclePedIsIn(ped, false) ~= veh or not blocked(veh)
                wait = 0
            end
        end
        Wait(wait)
    end
end)
