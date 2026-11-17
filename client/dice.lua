-- ============================================
-- whip_misc — client: the throw for /roll (server/dice.lua rolls and shows the result)
-- ============================================

local D = Config.Dice
if not D or not D.enabled then return end

RegisterNetEvent('whip_misc:diceThrow', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or exports.whip_core:IsPlayerDead() then return end
    local a = D.anim
    if not exports.whip_core:LoadAnimDict(a.dict) then return end
    -- Upper body only (49): they can keep walking.
    TaskPlayAnim(ped, a.dict, a.clip, 8.0, -8.0, a.ms, 49, 0, false, false, false)
    RemoveAnimDict(a.dict)
end)
