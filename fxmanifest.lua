fx_version "cerulean"
game "gta5"
lua54 "yes"

author "JG Scripts"
description "Tracks vehicle mileage with UI"
version "2.0"

shared_scripts {
  "@ox_lib/init.lua",
  "config.lua",
  "main.lua"
}

client_script "client/*.lua"

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "server/*.lua"
}

ui_page "web/index.html"

files {"web/*"}

escrow_ignore {"**/*"}
