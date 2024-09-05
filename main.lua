Framework = {}

if (Config.Framework == "auto" and (GetResourceState("qbx_core") == "started" or GetResourceState("qb-core") == "started")) or Config.Framework == "Qbox" or Config.Framework == "QBCore" then
  Config.Framework = "QBCore"
  Framework.VehiclesTable = "player_vehicles"
elseif (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then
  Config.Framework = "ESX"
  Framework.VehiclesTable = "owned_vehicles"
else
  error("You haven't set a valid framework. Valid options can be found in main.lua!")
end