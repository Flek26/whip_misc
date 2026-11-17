-- ============================================
-- whip_misc — client: crouch
-- ============================================
--
-- Ctrl (rebindable: Settings → Key Bindings → FiveM → "Crouch") crouches and stands. Config.Crouch.
--
-- The walk goes through whip's walk override (SetWalkOverride), so standing up gives back the player's own walk style
-- (an emote menu walk, a limp from whip_ems) with no bookkeeping here. GTA's own stealth mode, which Ctrl normally
-- toggles, is kept off while on foot.
--
-- Nothing runs every frame while standing on foot except the one disable of GTA's stealth key; while crouched, one
-- loop keeps sprint and jump off and stands them up if they get in a car, fall, swim, ragdoll or go down.

local C = Config.Crouch
if not C or not C.enabled then
    print('[whip_misc] crouch is off (Config)')
    return
end
print('[whip_misc] crouch ready')

local CLIPSET, STRAFE = 'move_ped_crouched', 'move_ped_crouched_strafing'
local crouched = false

local function load(set)
    if HasAnimSetLoaded(set) then return true end
    RequestAnimSet(set)
    local t = GetGameTimer() + 2000
    while not HasAnimSetLoaded(set) do
        if GetGameTimer() > t then return false end
        Wait(10)
    end
    return true
end

--- Can they crouch right now?
local function canCrouch(ped)
    if IsPedInAnyVehicle(ped, true) or IsPedFalling(ped) or IsPedSwimming(ped) or IsPedRagdoll(ped)
        or IsPedClimbing(ped) or IsPedJumping(ped) or IsPedGettingIntoAVehicle(ped) or IsEntityDead(ped) then
        return false
    end
    if exports.whip_core:IsPlayerDead() then return false end
    return true
end

local function stand()
    if not crouched then return end
    crouched = false
    local ped = PlayerPedId()
    exports.whip_core:SetWalkOverride(nil)
    ResetPedWeaponMovementClipset(ped, 0.5)
    ResetPedStrafeClipset(ped)
    SetPedMoveRateOverride(ped, 1.0)
end

local function crouch()
    if crouched then return end
    local ped = PlayerPedId()
    if not canCrouch(ped) then return end
    if not load(CLIPSET) or not load(STRAFE) then return end
    crouched = true
    SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
    exports.whip_core:SetWalkOverride(CLIPSET)
    SetPedWeaponMovementClipset(ped, CLIPSET, 0.5)
    SetPedStrafeClipset(ped, STRAFE)
    if C.speed ~= 1.0 then SetPedMoveRateOverride(ped, C.speed) end

    CreateThread(function()
        local check = 0
        while crouched do
            local p = PlayerPedId()
            if C.noSprint then DisableControlAction(0, 21, true) end   -- sprint
            if C.noJump then DisableControlAction(0, 22, true) end     -- jump
            -- First person, standing still: GTA's crouched strafe set tilts the camera. Back to the plain one until
            -- they move.
            if GetFollowPedCamViewMode() == 4 then
                if GetEntitySpeed(p) < 0.5 then ResetPedStrafeClipset(p) else SetPedStrafeClipset(p, STRAFE) end
            end
            -- A few times a second, not every frame: still able to crouch?
            local now = GetGameTimer()
            if now >= check then
                check = now + 250
                if not canCrouch(p) then stand() break end
                if C.speed ~= 1.0 then SetPedMoveRateOverride(p, C.speed) end
            end
            Wait(0)
        end
    end)
end

-- Not over a whip screen, a typed prompt or a placing mode (whip's placer uses Ctrl for fine moves).
local function inputFree()
    local ok, free = pcall(function() return exports.whip_core:IsGameInputFree() end)
    return not ok or free ~= false
end

RegisterCommand('+whipcrouch', function()
    if not inputFree() then return end
    if C.mode == 'hold' then crouch()
    elseif crouched then stand()
    else crouch() end
end, false)
RegisterCommand('-whipcrouch', function()
    if C.mode == 'hold' then stand() end
end, false)
RegisterKeyMapping('+whipcrouch', 'Crouch', 'keyboard', C.key or 'LCONTROL')

-- GTA's stealth walk (also on Ctrl) stays off on foot; only one native a frame, and none in a car.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            Wait(500)
        else
            DisableControlAction(0, 36, true)   -- INPUT_DUCK: GTA's stealth toggle
            Wait(0)
        end
    end
end)

AddEventHandler('whip_core:player:died', stand)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then stand() end
end)

exports('IsCrouched', function() return crouched end)
exports('SetCrouched', function(on) if on then crouch() else stand() end return crouched end)
