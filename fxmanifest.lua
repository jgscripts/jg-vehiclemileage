fx_version "cerulean"
game "gta5"
lua54 "yes"

author "JG Scripts"
description "Tracks vehicle mileage with UI"
version "1.1.0"

client_script "client.lua"

shared_scripts {
  "@ox_lib/init.lua",
  "config.lua",
  "main.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "server.lua"
}

ui_page "web/index.html"

files {"web/*"}

escrow_ignore {"*/**"}
