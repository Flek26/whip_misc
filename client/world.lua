-- ============================================
-- whip_misc — client: a quieter world
-- ============================================
--
-- What the game does on its own that a roleplay server doesn't want: random cops, police scenarios, parked cars at
-- the stations and hospitals, sirens in the distance, the police scanner, random events. All of these are per game
-- and stay set once said, so they are said at start and again after each spawn (a respawn resurrects the player and
-- GTA can put some back), not every frame or every ten seconds.
--
-- Wanted level and AI dispatch (police, fire, ambulance responding) are whip_core's: it turns them off at each spawn.

local W = Config.World

local function worldFlags()
    SetCreateRandomCops(W.randomCops)
    SetCreateRandomCopsNotOnScenarios(W.randomCops)
    SetCreateRandomCopsOnScenarios(W.randomCops)
    SetGarbageTrucks(W.garbageTrucks)
    SetRandomBoats(W.randomBoats)
    SetRandomTrains(W.randomTrains)
    DistantCopCarSirens(W.distantSirens)
    SetAudioFlag('PoliceScannerDisabled', not W.policeScanner)
    SetAudioFlag('DisableFlightMusic', not W.flightMusic)
    SetRandomEventFlag(W.randomEvents)
end

local function scenarios()
    for _, t in ipairs(Config.Scenarios.types or {}) do SetScenarioTypeEnabled(t, false) end
    for _, g in ipairs(Config.Scenarios.groups or {}) do
        if DoesScenarioGroupExist(g) then SetScenarioGroupEnabled(g, false) end
    end
end

-- Clear areas: the parked-car spawners off (they stay off), what they made taken away, and scenario peds blocked.
-- Blocking areas are kept by handle and only added once (each AddScenarioBlockingArea call adds another).
local blocking = {}

local function clearAreas()
    for i, a in ipairs(Config.ClearAreas or {}) do
        local c, r = a.coords, a.radius or 100.0
        local x1, y1, z1 = c.x - r, c.y - r, c.z - r
        local x2, y2, z2 = c.x + r, c.y + r, c.z + r
        SetAllVehicleGeneratorsActiveInArea(x1, y1, z1, x2, y2, z2, false, false)
        RemoveVehiclesFromGeneratorsInArea(x1, y1, z1, x2, y2, z2)
        if a.peds ~= false and not blocking[i] then
            blocking[i] = AddScenarioBlockingArea(x1, y1, z1, x2, y2, z2, false, true, true, true)
        end
    end
end

-- Thermal vision (a helicopter's camera, thermal goggles): it sees through walls only up to this thick, so it finds
-- people behind a fence or a car door, not inside a building. GTA's own limit is far thicker.
local function thermal()
    local t = Config.Thermal
    if t and t.maxThickness then SeethroughSetMaxThickness(t.maxThickness + 0.0) end
end

local function apply()
    worldFlags()
    thermal()
    scenarios()
    clearAreas()
end

CreateThread(apply)
AddEventHandler('whip_core:player:spawned', apply)
AddEventHandler('whip_core:player:revived', apply)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, h in pairs(blocking) do RemoveScenarioBlockingArea(h, false) end
    for _, a in ipairs(Config.ClearAreas or {}) do
        local c, r = a.coords, a.radius or 100.0
        SetAllVehicleGeneratorsActiveInArea(c.x - r, c.y - r, c.z - r, c.x + r, c.y + r, c.z + r, true, true)
    end
end)
