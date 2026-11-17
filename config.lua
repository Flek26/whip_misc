Config = {}

-- ============================================
-- Blacklisted models (server: stopped before they exist)
-- ============================================
--
-- OneSync's entityCreating: a listed model is refused before it is ever made, so there is nothing to find and delete.
--
-- Ambient: only GTA's own traffic, parked cars, scenario and street peds. A script or an admin can still spawn one
--          (a garage taking out an owned Mule, /car rhino), and a player's own car is never stopped.
-- Always:  refused whoever makes it, scripts included. For what must never exist on the server.

Config.Blacklist = {
    vehicles = {
        ambient = {
            -- Police and emergency (the whip jobs are players)
            'police', 'police2', 'police3', 'police4', 'policeb', 'policet', 'sheriff', 'sheriff2', 'fbi', 'fbi2',
            'pranger', 'riot', 'polmav', 'predator', 'ambulance', 'firetruk', 'lguard',
            -- Military
            'rhino', 'barracks', 'barracks2', 'crusader', 'titan', 'lazer', 'buzzard', 'buzzard2', 'annihilator',
            'savage', 'valkyrie',
            -- Air and sea traffic that clutters the map
            'shamal', 'luxor', 'luxor2', 'jet', 'maverick', 'blimp', 'airtug', 'tug', 'cargoplane',
            -- Clutter
            'mule', 'camper',
        },
        always = {
            -- Weaponised and flying-car DLC: never on this server
            'hydra', 'oppressor', 'oppressor2', 'deluxo', 'scramjet', 'vigilante', 'ruiner2', 'voltic2',
            'technical3', 'insurgent3', 'apc', 'tampa3', 'trailersmall2', 'halftrack', 'hunter', 'akula', 'barrage',
            'khanjali', 'caracara', 'blimp3', 'menacer', 'strikeforce', 'cerberus', 'cerberus2', 'cerberus3',
            'scarab', 'scarab2', 'scarab3', 'rrocket', 'cargoplane2', 'paragon2',
        },
    },
    peds = {
        ambient = {
            's_m_y_cop_01', 's_f_y_cop_01', 's_m_y_sheriff_01', 's_f_y_sheriff_01', 's_m_y_hwaycop_01',
            's_m_y_ranger_01', 's_f_y_ranger_01', 's_m_m_snowcop_01', 's_m_y_swat_01', 's_m_y_marine_01',
            's_m_y_marine_02', 's_m_y_marine_03', 's_m_m_marine_01', 's_m_m_marine_02', 's_m_y_armymech_01',
        },
        always = {},
    },
}

-- ============================================
-- The world (each player's game, set once and kept)
-- ============================================

-- true: it happens in the world, as GTA has it. false: switched off. (Not a blacklist: models go in Config.Blacklist.)
Config.World = {
    randomCops       = false,   -- GTA's random cops (on foot, in cars, at scenarios)
    garbageTrucks    = tr,
    randomBoats      = true,
    randomTrains     = true,
    distantSirens    = false,   -- far-off sirens in the city's background sound
    policeScanner    = true,   -- the police radio chatter in police cars
    flightMusic      = true,   -- the music that plays when flying
    randomEvents     = true,   -- GTA's random events (muggings, chases, getaway drivers)
}

-- Scenarios GTA starts on its own: cops by their cars, military planes, ambulances, the street race at the start.
Config.Scenarios = {
    types = {
        'WORLD_VEHICLE_POLICE_NEXT_TO_CAR', 'WORLD_VEHICLE_POLICE_CAR', 'WORLD_VEHICLE_POLICE_BIKE',
        'WORLD_VEHICLE_AMBULANCE', 'WORLD_VEHICLE_FIRE_TRUCK',
        'WORLD_VEHICLE_MILITARY_PLANES_SMALL', 'WORLD_VEHICLE_MILITARY_PLANES_BIG',
        'WORLD_VEHICLE_STREETRACE', 'WORLD_VEHICLE_SALTON_DIRT_BIKE', 'WORLD_VEHICLE_SALTON',
        'WORLD_VEHICLE_BIKE_OFF_ROAD_RACE', 'WORLD_VEHICLE_BUSINESSMEN', 'WORLD_VEHICLE_MECHANIC',
        'WORLD_VEHICLE_EMPTY',
    },
    -- By name (SetScenarioGroupEnabled takes the name; an unknown one does nothing).
    groups = {
        'MP_POLICE', 'ARMY_GUARD', 'ARMY_HELI', 'LSA_Planes', 'SANDY_PLANES', 'GRAPESEED_PLANES', 'ALAMO_PLANES',
        'ng_planes', 'BLIMP',
    },
}

-- ============================================
-- Clear areas: no parked cars, no scenario peds
-- ============================================
--
-- GTA's parked-car spawners (vehicle generators) are switched off in each area, the cars they already made are taken
-- away, and scenario peds (people idling there) stop appearing. Traffic still drives through.
-- radius: metres. peds: also block scenario peds there (true by default).

Config.ClearAreas = {
    { label = 'Mission Row PD',       coords = vector3(441.85, -987.99, 30.68),   radius = 120.0 },
    { label = 'Vespucci PD',          coords = vector3(-1096.0, -820.0, 19.0),    radius = 90.0 },
    { label = 'Davis Sheriff',        coords = vector3(368.0, -1608.0, 29.3),     radius = 90.0 },
    { label = 'Sandy Shores Sheriff', coords = vector3(1854.82, 3679.4, 33.82),   radius = 90.0 },
    { label = 'Paleto Bay Sheriff',   coords = vector3(-448.0, 6012.0, 31.7),     radius = 90.0 },
    { label = 'Pillbox Medical',      coords = vector3(316.79, -592.36, 43.28),   radius = 120.0 },
    { label = 'Central LS Medical',   coords = vector3(335.26, -1432.46, 46.51),  radius = 120.0 },
    { label = 'Fort Zancudo',         coords = vector3(-2150.44, 3075.99, 32.8),  radius = 600.0, peds = false },
    { label = 'Vespucci helipad',     coords = vector3(-724.46, -1444.03, 5.0),   radius = 120.0 },
    { label = 'Nudist camp',          coords = vector3(-1108.35, 4920.64, 217.2), radius = 150.0 },
}

-- Say in the server console which blacklisted models were refused, every so many minutes (0: never).
Config.ReportMinutes = 1
