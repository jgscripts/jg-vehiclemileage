QBCore, ESX = nil, nil
Framework = {}

if Config.Framework == "QBCore" then
  QBCore = exports['qb-core']:GetCoreObject()

  Framework.VehiclesTable = "player_vehicles"
elseif Config.Framework == "ESX" then
  ESX = exports["es_extended"]:getSharedObject()

  Framework.VehiclesTable = "owned_vehicles"
else
  error("You need to set the Config.Framework to either \"QBCore\" or \"ESX\"!")
end