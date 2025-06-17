lib.callback.register("jg-vehiclemileage:server:get-mileage", function(_, plate)
  local vehicle = MySQL.single.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if not vehicle then return { error = true } end
  return { mileage = vehicle.mileage }
end)

RegisterNetEvent("jg-vehiclemileage:server:update-mileage", function(plate, mileage)
  MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = ? WHERE plate = ?", {mileage, plate})
end)

---@param plate string
---@return number, string
exports("GetMileage", function(plate)
  local vehicle = MySQL.single.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if not vehicle then return false end
  return vehicle.mileage, Config.Unit
end)