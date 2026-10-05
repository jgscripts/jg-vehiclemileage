--[[
  Description:
    Server-owned mileage sampled from the current driver's replicated vehicle position.
    Client messages never contain a mileage total or a writable plate.
  Exports:
    getMileageByEntity, getMileageByPlate, getUnit, GetMileage
]]--
local records, loading, drivers = {}, {}, {}

local function validPlate(plate)
  return type(plate) == "string" and #plate > 0 and #plate <= 32
end

local function entityPlate(vehicle)
  local plate = GetVehicleNumberPlateText(vehicle)
  return type(plate) == "string" and plate:match("^%s*(.-)%s*$") or nil
end

local function validDriver(src, netId)
  if type(netId) ~= "number" or netId % 1 ~= 0 or netId < 1 or netId > 2147483647 then return nil end
  local vehicle, ped = NetworkGetEntityFromNetworkId(netId), GetPlayerPed(src)
  if vehicle == 0 or ped == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return nil end
  if GetVehiclePedIsIn(ped, false) ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= ped then return nil end
  local vehicleType = GetVehicleType(vehicle)
  if vehicleType ~= "automobile" and vehicleType ~= "bike" and vehicleType ~= "quadbike" then return nil end
  return vehicle
end

local function save(record)
  if not record or record.mileage <= record.saved then return end
  local mileage = record.mileage
  record.saved = mileage
  MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = GREATEST(COALESCE(mileage, 0), ?) WHERE plate = ?", {mileage, record.plate}, function(changed)
    if changed == nil then record.saved = math.min(record.saved, record.initial) end
  end)
end

local function getMileageInKmByPlate(plate)
  if not validPlate(plate) then return false end
  local mileage = tonumber(MySQL.scalar.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})) or 0
  for _, record in pairs(records) do
    if record.plate == plate then mileage = math.max(mileage, record.mileage) end
  end
  return mileage
end

lib.callback.register("jg-vehiclemileage:server:get-mileage", function(_, plate)
  return getMileageInKmByPlate(plate)
end)

lib.callback.register("jg-vehiclemileage:server:sample", function(src, netId, grounded)
  if type(grounded) ~= "boolean" then return false end
  local vehicle = validDriver(src, netId)
  if not vehicle then return false end
  local plate, model = entityPlate(vehicle), GetEntityModel(vehicle)
  if not validPlate(plate) then return false end
  local record = records[vehicle]
  if record and (record.plate ~= plate or record.model ~= model) then
    save(record)
    records[vehicle], record = nil, nil
  end
  if not record then
    if loading[vehicle] then return false end
    loading[vehicle] = true
    local ok, mileage = pcall(getMileageInKmByPlate, plate)
    loading[vehicle] = nil
    if not ok or validDriver(src, netId) ~= vehicle or entityPlate(vehicle) ~= plate or GetEntityModel(vehicle) ~= model then return false end
    mileage = math.max(0, tonumber(mileage) or 0)
    record = {plate = plate, model = model, mileage = mileage, initial = mileage, saved = mileage}
    records[vehicle] = record
  end

  local now, coords = GetGameTimer(), GetEntityCoords(vehicle)
  if record.src == src and record.time and now - record.time < 500 then return record.rounded or record.mileage end
  if record.src == src and record.time and grounded and record.grounded then
    local elapsed = (now - record.time) / 1000
    local distance = #(coords - record.coords)
    local speed = math.max(0, math.min(400, GetEntitySpeed(vehicle)))
    if elapsed > 0 and elapsed <= 5 and distance <= math.max(25, speed * elapsed * 2 + 10) and distance <= 400 * elapsed then
      record.mileage = record.mileage + distance / 1000
    end
  end
  local previousVehicle = drivers[src]
  local previous = previousVehicle and records[previousVehicle]
  if previous and previousVehicle ~= vehicle and previous.src == src then
    save(previous)
    previous.src, previous.time, previous.coords = nil, nil, nil
  end
  if record.src and record.src ~= src and drivers[record.src] == vehicle then drivers[record.src] = nil end
  record.src, record.time, record.coords, record.grounded = src, now, coords, grounded
  drivers[src] = vehicle
  local rounded = math.floor(record.mileage * 10 + 0.5) / 10
  if rounded ~= record.rounded then
    record.rounded = rounded
    Entity(vehicle).state:set("vehicleMileage", rounded, true)
  end
  if record.mileage - record.saved >= 3 then save(record) end
  return rounded
end)

local function closeDriver(src)
  local vehicle = drivers[src]
  drivers[src] = nil
  local record = vehicle and records[vehicle]
  if not record or record.src ~= src then return end
  save(record)
  record.src, record.time, record.coords = nil, nil, nil
end

RegisterNetEvent("jg-vehiclemileage:server:stop-sampling", function() closeDriver(source) end)
AddEventHandler("playerDropped", function() closeDriver(source) end)
AddEventHandler("entityRemoved", function(entity)
  save(records[entity])
  records[entity], loading[entity] = nil, nil
end)
AddEventHandler("onResourceStop", function(resource)
  if resource ~= GetCurrentResourceName() then return end
  for _, record in pairs(records) do save(record) end
end)

CreateThread(function()
  while true do
    Wait(5000)
    for vehicle, record in pairs(records) do
      if not DoesEntityExist(vehicle) then
        save(record)
        records[vehicle] = nil
      elseif record.src and (GetGameTimer() - record.time > 10000 or GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(record.src)) then
        if drivers[record.src] == vehicle then drivers[record.src] = nil end
        save(record)
        record.src, record.time, record.coords = nil, nil, nil
      end
    end
  end
end)

exports("getMileageByEntity", function(ent)
  if not ent or ent == 0 or not DoesEntityExist(ent) then return false end
  return Entity(ent).state.vehicleMileage or 0
end)
exports("getMileageByPlate", getMileageInKmByPlate)
exports("getUnit", function() return Config.Unit end)
exports("GetMileage", function(plate) return getMileageInKmByPlate(plate), Config.Unit end)
