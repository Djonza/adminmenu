fx_version 'bodacious'
lua54 'yes'
game 'gta5'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua'
}


server_scripts {
	'@oxmysql/lib/MySQL.lua', 
	'config.lua',
	'server/main.lua',
	'server/adminduty.lua',
	'server/staffchat.lua',
	'server/admincommands.lua',
	'server/playtime.lua',
	'server/reports.lua'
}

client_scripts {
	'config.lua',
	'client/main.lua',
	'client/adminduty.lua'
}

files {
	'locales/*.json',
}

exports {
    'IsPlayerAdminAndOnDuty'
}

version '1.2'


