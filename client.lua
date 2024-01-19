local lastLocation = nil
local currentVehMileage = 0
local currentVehPlate = ""
local currentVehOwned = false
local lastUpdatedMileage = nil

local function triggerCallback(cbRef, cb, ...)
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

local function distanceCheck()
  local ped = PlayerPedId()

  if not IsPedInAnyVehicle(PlayerPedId()) then
    SendNUIMessage({ type = "hide" })
    return
  end

  local vehicle = GetVehiclePedIsIn(PlayerPedId())
  local vehClass = GetVehicleClass(vehicle)

  if GetPedInVehicleSeat(vehicle, -1) ~= ped or vehClass == 13 or vehClass == 14 or vehClass == 15 or vehClass == 16 or vehClass == 17 or vehClass == 21 then
    SendNUIMessage({ type = "hide" })
    return
  end

  if not lastLocation then
    lastLocation = GetEntityCoords(vehicle)
  end

  local plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId()))

  if plate == currentVehPlate and not currentVehOwned then
    return
  end

  print(currentVehPlate, currentVehOwned)

  if not currentVehPlate or plate ~= currentVehPlate then
    triggerCallback('jg-vehiclemileage:server:get-mileage', function(data)
      if data.error then
        currentVehOwned = false
        currentVehPlate = plate
        return
      end

      currentVehOwned = true
      currentVehPlate = plate
      currentVehMileage = data.mileage
    end, plate)
    return
  end

  local dist = 0
  if IsVehicleOnAllWheels(vehicle) then
    dist = #(lastLocation - GetEntityCoords(vehicle))
  end

  local distKm = dist / 1000
  currentVehMileage = currentVehMileage + distKm
  lastLocation = GetEntityCoords(vehicle)
  local roundedMileage = tonumber(string.format("%.1f", currentVehMileage))

  if roundedMileage ~= lastUpdatedMileage then
    SendNUIMessage({ type = "show", value = roundedMileage, unit = Config.Unit })
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