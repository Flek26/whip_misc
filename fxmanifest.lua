fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'whip_misc'
description 'Small world fixes for whip: blacklisted cars and peds never spawn, no random cops or police scenarios, no parked cars at the stations and hospitals.'
version '0.1.0'
author 'Flek'

shared_script '@whip_core/lib/satellite.lua'
shared_script 'config.lua'
client_scripts {
    'client/world.lua',
    'client/crouch.lua',
    'client/enterseat.lua',
    'client/dice.lua',
}
server_scripts {
    'server/blacklist.lua',
    'server/dice.lua',
}

dependency 'whip_core'
whip_requires '1.0'
