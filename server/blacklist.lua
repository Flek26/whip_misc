-- ============================================
-- whip_misc — server: blacklisted models never exist
-- ============================================
--
-- OneSync asks the server before any client-made entity enters the world (entityCreating); cancelling it means the
-- entity is never made, on anyone's game. One table lookup per entity: the lists are turned into hash sets once.
--
-- Ambient models are refused only when GTA itself made them (traffic, parked cars, scenario and street peds: the
-- "random" population types), so a script, a garage or an admin can still spawn one. Always models are refused from
-- anyone.

-- GTA's population types: 1 random permanent, 2 random parked, 3 random patrol, 4 random scenario, 5 random ambient.
-- (6 permanent, 7 mission / script, 0 unknown: not GTA's own, so not ambient.)
local AMBIENT_POP = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }

local RULE = {}        -- [model hash] = 'ambient' | 'always'
local NAMES = {}       -- [model hash] = name, for the report

local function add(list, rule)
    for _, name in ipairs(list or {}) do
        local hash = type(name) == 'number' and name or GetHashKey(name)
        -- 'always' wins over 'ambient' if a model is in both.
        if RULE[hash] ~= 'always' then RULE[hash] = rule end
        NAMES[hash] = tostring(name)
    end
end

local bl = Config.Blacklist or {}
for _, kind in ipairs({ 'vehicles', 'peds' }) do
    add(bl[kind] and bl[kind].ambient, 'ambient')
    add(bl[kind] and bl[kind].always, 'always')
end

local refused = {}     -- [model hash] = how many, since the last report

AddEventHandler('entityCreating', function(entity)
    local rule = RULE[GetEntityModel(entity)]
    if not rule then return end
    if rule == 'ambient' and not AMBIENT_POP[GetEntityPopulationType(entity)] then return end
    CancelEvent()
    if Config.ReportMinutes > 0 then
        local m = GetEntityModel(entity)
        refused[m] = (refused[m] or 0) + 1
    end
end)

if Config.ReportMinutes > 0 then
    CreateThread(function()
        while true do
            Wait(Config.ReportMinutes * 60000)
            local parts = {}
            for hash, n in pairs(refused) do parts[#parts + 1] = ('%s x%d'):format(NAMES[hash] or hash, n) end
            if #parts > 0 then
                table.sort(parts)
                print('[whip_misc] refused: ' .. table.concat(parts, ', '))
            end
            refused = {}
        end
    end)
end

--- For other resources: is this model blacklisted, and how? 'ambient', 'always' or nil.
exports('IsBlacklisted', function(model)
    local hash = type(model) == 'number' and model or GetHashKey(tostring(model))
    return RULE[hash]
end)

Whip.sayStarted()
