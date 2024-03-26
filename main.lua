Framework = {}

if Config.Framework == "QBCore" then
  Framework.VehiclesTable = "player_vehicles"
elseif Config.Framework == "ESX" then
  Framework.VehiclesTable = "owned_vehicles"
else
  error("You haven't set a valid framework. Valid options can be found in main.lua!")
end