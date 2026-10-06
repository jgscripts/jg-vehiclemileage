local function getMileageInKmByPlate(plate)
  if not plate or plate == "" then return false end
  
  local mileageKm = MySQL.scalar.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  return mileageKm or 0
end

lib.callback.register("jg-vehiclemileage:server:get-mileage", function(_, plate)
  return getMileageInKmByPlate(plate)
end)

RegisterNetEvent("jg-vehiclemileage:server:update-mileage", function(plate, mileage)
  -- only the current network owner of a spawned vehicle with this plate may
  -- write its odometer, and only forwards (no client-side tampering, no rollback)
  mileage = tonumber(mileage)
  if not mileage or mileage < 0 or mileage > 10000000 then return end
  local src = source
  local ok = false
  local vehicles = GetAllVehicles()
  for i = 1, #vehicles do
    local vehPlate = GetVehicleNumberPlateText(vehicles[i]):match("^%s*(.-)%s*$")
    if vehPlate == plate then
      if NetworkGetEntityOwner(vehicles[i]) == src then ok = true end
      break
    end
  end
  if not ok then return end
  local current = MySQL.scalar.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if current and mileage < current then return end
  MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = ? WHERE plate = ?", {mileage, plate})
end)

--------------------
-- SERVER EXPORTS --
--------------------

---@param ent integer
---@return number|false mileageKm
exports("getMileageByEntity", function(ent)
  if not ent or ent == 0 then return false end
  if not DoesEntityExist(ent) then return false end

  return Entity(ent).state?.vehicleMileage or 0
end)

---@param plate string
---@return number|false mileageKm
exports("getMileageByPlate", function(plate)
  return getMileageInKmByPlate(plate)
end)

---@return "miles"|"kilometers"
exports("getUnit", function() return Config.Unit end)

---!! DEPRECATED, use getMileageByPlate
---@deprecated
---@param plate string
---@return number|false, string
exports("GetMileage", function(plate)
  local vehicle = MySQL.single.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if not vehicle then return false end
  return vehicle.mileage, Config.Unit
end)
