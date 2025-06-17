local lastLocation = nil
local currentMileage = 0
local fetchedExistingMileage = false
local lastUpdatedMileage = nil
local serverUpdateMileageThreshold, lastUpdatedMileageServer = 3, nil

local function sendToNui(data)
  if GetResourceState("jg-hud") == "started" then
    SendNUIMessage({ type = "hide" })
    return
  end

  if Config.ShowMileage then
    SendNUIMessage(data)
  end
end

local function getVehiclePlate(vehicle)
  return string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1")
end

local function distanceCheck()
  if not cache.vehicle then
    sendToNui({ type = "hide" })
    return false
  end

  local vehClass = GetVehicleClass(cache.vehicle)

  if cache.seat ~= -1 or vehClass == 13 or vehClass == 14 or vehClass == 15 or vehClass == 16 or vehClass == 17 or vehClass == 21 then
    sendToNui({ type = "hide" })
    return false
  end

  if not lastLocation then
    lastLocation = GetEntityCoords(cache.vehicle)
  end

  local plate = getVehiclePlate(cache.vehicle)

  if not fetchedExistingMileage then
    currentMileage = Entity(cache.vehicle).state.vehicleMileage

    if not currentMileage then
      local data = lib.callback.await("jg-vehiclemileage:server:get-mileage", false, plate)
      if data.error then return false end

      currentMileage = data.mileage
    end
    
    fetchedExistingMileage = true
    return true
  end

  local dist = 0
  if IsVehicleOnAllWheels(cache.vehicle) and not IsEntityInWater(cache.vehicle) then
    dist = #(lastLocation - GetEntityCoords(cache.vehicle))
  end

  local distKm = dist / 1000
  currentMileage = currentMileage + distKm
  lastLocation = GetEntityCoords(cache.vehicle)
  local roundedMileage = tonumber(string.format("%.1f", currentMileage))

  sendToNui({
    type = "show",
    value = roundedMileage,
    unit = Config.Unit,
    position = Config.Position
  })

  if roundedMileage ~= lastUpdatedMileage then
    Entity(cache.vehicle).state:set("vehicleMileage", roundedMileage, true)
    lastUpdatedMileage = roundedMileage
  end

  if not lastUpdatedMileageServer or math.abs(roundedMileage - lastUpdatedMileageServer) >= serverUpdateMileageThreshold then
    Entity(cache.vehicle).state:set("vehicleMileage", roundedMileage, true)
    TriggerServerEvent("jg-vehiclemileage:server:update-mileage", plate, roundedMileage)
    lastUpdatedMileageServer = roundedMileage
  end

  return true
end

local vehicleThreadStarted = false
local function startVehicleThread()
  if vehicleThreadStarted then return end
  vehicleThreadStarted = true

  CreateThread(function()
    while cache.vehicle do
      Wait(1000)

      if not distanceCheck() then
        break
      end
    end

    vehicleThreadStarted = false
    fetchedExistingMileage = false
    lastUpdatedMileage = nil
  end)
end

lib.onCache("vehicle", function(vehicle)
  local prevVehicle = cache.vehicle
  
  if not vehicle and prevVehicle and currentMileage then
    TriggerServerEvent("jg-vehiclemileage:server:update-mileage", getVehiclePlate(prevVehicle), currentMileage)
    return
  end

  startVehicleThread()
end)

-- Handle restarts when ped is already in vehicle
CreateThread(function()
  if cache.vehicle then startVehicleThread() end
end)

exports("GetUnit", function() return Config.Unit end)