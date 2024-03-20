fx_version "cerulean"
game "gta5"

author "JG Scripts"
description "Tracks vehicle mileage with UI"
version "1.1.0"

client_script "client.lua"

shared_script {"config.lua", "main.lua"}

server_scripts {"@oxmysql/lib/MySQL.lua", "server.lua"}

ui_page "web/index.html"

files {"web/*"}

escrow_ignore {"*/**"}

lua54 "yes"