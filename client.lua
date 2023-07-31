local lastLocation = nil
local currentVehMileage = 0
local currentVehPlate = ""
local currentVehOwned = false
local lastUpdatedMileage = nil

function triggerCallback(cbRef, cb, ...)
  if Config.Framework == "QBCore" then
    return QBCore.Functions.TriggerCallback(cbRef, function(res)
      cb(res)
    end, ...)
  elseif Config.Framework == "ESX" then
    return ESX.TriggerServerCallback(cbRef, function(res)
      cb(res)
    end, ...)
  end
end

function getVehicleCoords()
  return GetEntityCoords(GetVehiclePedIsIn(PlayerPedId()))
end

function distanceCheck()
  if not IsPedInAnyVehicle(PlayerPedId()) then
    SendNUIMessage({ type = "hide" })
    return
  end

  if not lastLocation then
    lastLocation = getVehicleCoords()
  end

  local plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId()))
  if plate == currentVehPlate and not currentVehOwned then return end

  if not currentVehPlate or plate ~= currentVehPlate then
    triggerCallback('jg-vehiclemileage:server:get-mileage', function(data)
      if data.error then
        currentVehOwned = false
        return
      end
      print('resetting vals')
      currentVehOwned = true
      currentVehPlate = plate
      currentVehMileage = data.mileage
    end, plate)
    return
  end

  local dist = #(lastLocation - getVehicleCoords())
  local distKm = dist / 1000

  currentVehMileage = currentVehMileage + distKm
  lastLocation = getVehicleCoords()

  local roundedMileage = tonumber(string.format("%.1f", currentVehMileage))
  SendNUIMessage({ type = "show", value = roundedMileage, unit = Config.Unit })
  if roundedMileage ~= lastUpdatedMileage then
    TriggerServerEvent('jg-vehiclemileage:server:update-mileage', currentVehPlate, roundedMileage)
    lastUpdatedMileage = roundedMileage
  end
end

Citizen.CreateThread(function()
  while true do
    distanceCheck()
    Wait(1000)
  end
end)