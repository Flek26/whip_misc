-- ============================================
-- whip_misc — client: point
-- ============================================
--
-- B (rebindable: Settings → Key Bindings → FiveM → "Point") points where the camera looks, with GTA Online's own
-- pointing move network (anim@mp_point / task_mp_pointing), which other players see. Config.Point.
--
-- The arm follows the camera every frame while pointing (the move network needs its signals each frame); nothing runs
-- otherwise. It stops on its own in a vehicle, swimming, ragdolled, down, or if the game drops the task.

local P = Config.Point
if not P or not P.enabled then return end

local DICT = 'anim@mp_point'
local pointing = false

local function canPoint(ped)
    return not IsPedInAnyVehicle(ped, true) and not IsPedSwimming(ped) and not IsPedRagdoll(ped)
        and not IsPedFalling(ped) and not IsEntityDead(ped) and not exports.whip_core:IsPlayerDead()
end

local function stop()
    if not pointing then return end
    pointing = false
    local ped = PlayerPedId()
    RequestTaskMoveNetworkStateTransition(ped, 'Stop')
    if not IsPedInjured(ped) then ClearPedSecondaryTask(ped) end
    if not IsPedInAnyVehicle(ped, true) then SetPedCurrentWeaponVisible(ped, true, true, true, true) end
    SetPedConfigFlag(ped, 36, false)
end

local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function start()
    if pointing then return end
    local ped = PlayerPedId()
    if not canPoint(ped) then return end
    if not exports.whip_core:LoadAnimDict(DICT) then return end
    pointing = true
    SetPedCurrentWeaponVisible(ped, false, true, true, true)
    SetPedConfigFlag(ped, 36, true)
    TaskMoveNetworkByName(ped, 'task_mp_pointing', 0.5, false, DICT, 24)
    RemoveAnimDict(DICT)

    CreateThread(function()
        local probe = nil   -- last frame's shape test: its answer is read a frame later (it is not instant)
        local blocked = false
        local started = GetGameTimer()
        while pointing do
            ped = PlayerPedId()
            -- Gone off on its own (the game dropped the task), or no longer able to point.
            if not canPoint(ped) or (GetGameTimer() - started > 500 and not IsTaskMoveNetworkActive(ped)) then
                stop()
                break
            end

            local pitch = clamp(GetGameplayCamRelativePitch(), -70.0, 42.0)
            local heading = clamp(GetGameplayCamRelativeHeading(), -180.0, 180.0)
            local c, s = math.cos(math.rad(heading)), math.sin(math.rad(heading))
            local h01 = (heading + 180.0) / 360.0

            -- Is something right in front of the hand (a wall)? The arm bends back if so.
            if probe then
                local status, hit = GetShapeTestResult(probe)
                if status ~= 1 then blocked = hit == 1; probe = nil end
            end
            if not probe then
                local at = GetOffsetFromEntityInWorldCoords(ped, (c * -0.2) - (s * (0.4 * h01 + 0.3)),
                    (s * -0.2) + (c * (0.4 * h01 + 0.3)), 0.6)
                probe = StartShapeTestCapsule(at.x, at.y, at.z - 0.2, at.x, at.y, at.z + 0.2, 0.4, 95, ped, 7)
            end

            SetTaskMoveNetworkSignalFloat(ped, 'Pitch', (pitch + 70.0) / 112.0)
            SetTaskMoveNetworkSignalFloat(ped, 'Heading', 1.0 - h01)
            SetTaskMoveNetworkSignalBool(ped, 'isBlocked', blocked)
            SetTaskMoveNetworkSignalBool(ped, 'isFirstPerson', GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
            Wait(0)
        end
    end)
end

local function inputFree()
    local ok, free = pcall(function() return exports.whip_core:IsGameInputFree() end)
    return not ok or free ~= false
end

RegisterCommand('+whippoint', function()
    if not inputFree() then return end
    if P.mode == 'hold' then start()
    elseif pointing then stop()
    else start() end
end, false)
RegisterCommand('-whippoint', function()
    if P.mode == 'hold' then stop() end
end, false)
RegisterKeyMapping('+whippoint', 'Point', 'keyboard', P.key or 'B')

AddEventHandler('whip_core:player:died', stop)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then stop() end end)

exports('IsPointing', function() return pointing end)
