fx_version 'cerulean'
game 'gta5'

author 'BasseBank'
description 'Système bancaire complet pour ESX'
version '1.0.0'

shared_scripts {
    '@es_extended/locale.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png'
}

dependencies {
    'es_extended',
    'oxmysql'
}
