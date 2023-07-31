function createCallback(cbRef, cb)
  if Config.Framework == "QBCore" then
    return QBCore.Functions.CreateCallback(cbRef, function(...)
      cb(...)
    end)
  elseif Config.Framework == "ESX" then
    ESX.RegisterServerCallback(cbRef, function(...)
      cb(...)
    end)
  end
end

createCallback('jg-vehiclemileage:server:get-mileage', function(src, cb, plate)
  local vehicle = MySQL.single.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if not vehicle then return cb({ error = true }) end
  cb({ mileage = vehicle.mileage })
end)

RegisterNetEvent('jg-vehiclemileage:server:update-mileage', function(plate, mileage)
  print(mileage, plate)
  MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = ? WHERE plate = ?", {mileage, plate})
end)