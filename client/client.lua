local lastLocation = nil
local currentVehMileage = 0
local currentVehPlate = ""
local recheckCurrentVeh = 10000
local currentVehOwned = false
local lastUpdatedMileage = nil
local Position = Config.Position

local function distanceCheck()
  local ped = PlayerPedId()

  if not IsPedInAnyVehicle(PlayerPedId(), false) then
    sendToNui({ type = "hide" })
    return
  end

  local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
  local vehClass = GetVehicleClass(vehicle)

  if GetPedInVehicleSeat(vehicle, -1) ~= ped or vehClass == 13 or vehClass == 14 or vehClass == 15 or vehClass == 16 or vehClass == 17 or vehClass == 21 then
    sendToNui({ type = "hide" })
    return
  end

  if not lastLocation then
    lastLocation = GetEntityCoords(vehicle)
  end

  local plate = string.gsub(GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)), "^%s*(.-)%s*$", "%1")

  if plate == currentVehPlate and not currentVehOwned and recheckCurrentVeh > 0 then
    recheckCurrentVeh -= 1000
    return
  end

  if not currentVehPlate or plate ~= currentVehPlate or recheckCurrentVeh <= 0 then
    recheckCurrentVeh = 10000

    local data = lib.callback.await("jg-vehiclemileage:server:get-mileage", false, plate)
    if data.error then
      currentVehOwned = false
      currentVehPlate = plate
      return
    end

    currentVehOwned = true
    currentVehPlate = plate
    currentVehMileage = data.mileage
    return
  end

  sendToNui({ type = "show", value = currentVehMileage, unit = Config.Unit, position = Position })

  local dist = 0
  if IsVehicleOnAllWheels(vehicle) and not IsEntityInWater(vehicle) then
    dist = #(lastLocation - GetEntityCoords(vehicle))
  end

  local distKm = dist / 1000
  currentVehMileage = currentVehMileage + distKm
  lastLocation = GetEntityCoords(vehicle)
  local roundedMileage = tonumber(string.format("%.1f", currentVehMileage))
  sendToNui({ type = "show", value = roundedMileage, unit = Config.Unit, position = Position })

  if roundedMileage ~= lastUpdatedMileage then
    Entity(vehicle).state:set("vehicleMileage", roundedMileage)
    TriggerServerEvent("jg-vehiclemileage:server:update-mileage", currentVehPlate, roundedMileage)
    lastUpdatedMileage = roundedMileage
  end
end

CreateThread(function()
  Wait(2000)

  while true do
    distanceCheck()
    Wait(1000)
  end
end)

function sendToNui(data)
  if Config.ShowMileage then
    SendNUIMessage(data)
  end
end

exports("GetUnit", function() return Config.Unit end)