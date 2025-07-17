local vehicleMileage_orginal = {}
local vehicleMileage = {}

CreateThread(function()
    local resp = MySQL.query.await("SELECT plate, mileage FROM " .. Framework.VehiclesTable)
    if resp then
        for _, vehicle in ipairs(resp) do
            vehicleMileage_orginal[vehicle.plate] = vehicle.mileage
            vehicleMileage[vehicle.plate] = vehicle.mileage
        end
    end
end)

lib.cron.new(Config.DatabaseUpdateInterval, function()
    local count = 0
    for plate, mileage in pairs(vehicleMileage) do
        if vehicleMileage_orginal[plate] and vehicleMileage_orginal[plate] ~= mileage then
            MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = @mileage WHERE plate = @plate", {
                ["@mileage"] = mileage,
                ["@plate"] = plate
            })

            vehicleMileage_orginal[plate] = mileage
            count = count + 1

            if count % 10 == 0 then
                Wait(500)
            end
                
            elseif not vehicleMileage_orginal[plate] then
                vehicleMileage_orginal[plate] = mileage
            -- insert
            end
        end
    end

    if count > 0 then
        print("[JG-Scripts]: Updated " .. count .. " vehicle mileages in the database.")
    end
end)


--// Callbacks
lib.callback.register("jg-vehiclemileage:server:get-mileage", function(_, plate)
    if vehicleMileage[plate] then
        return { mileage = vehicleMileage[plate], unit = Config.Unit }
    else
        return { error = true }
    end
end)

--// Events
RegisterNetEvent("jg-vehiclemileage:server:set-mileage", function(plate, mileage)
    if vehicleMileage[plate] then
        vehicleMileage[plate] = mileage
    end
end)

--// Exports
exports("GetMileage", function(plate)
    if vehicleMileage[plate] then
        return vehicleMileage[plate], Config.Unit
    else
        return false
    end
end)
