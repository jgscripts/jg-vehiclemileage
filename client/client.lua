--[[
  Description:
    Mileage display and grounded-driving observations. All shared state is server-owned.
  Exports:
    getMileage, getMileageByEntity, getMileageByPlate, getUnit, GetUnit
]]--
local generation = 0

local function sendToNui(data)
  if GetResourceState("jg-hud") == "started" then
    SendNUIMessage({type = "hide"})
    return
  end
  if Config.ShowMileage then SendNUIMessage(data) end
end

local function startSampling()
  generation = generation + 1
  local current = generation
  TriggerServerEvent("jg-vehiclemileage:server:stop-sampling")
  CreateThread(function()
    -- ox_lib updates cache after invoking cache listeners.
    Wait(0)
    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 then sendToNui({type = "hide"}) return end
    local class = GetVehicleClass(vehicle)
    if class == 13 or class == 14 or class == 15 or class == 16 or class == 17 or class == 21 then
      sendToNui({type = "hide"})
      return
    end
    while current == generation and cache.vehicle == vehicle and cache.seat == -1 do
      local mileage = lib.callback.await("jg-vehiclemileage:server:sample", false, VehToNet(vehicle), IsVehicleOnAllWheels(vehicle) and not IsEntityInWater(vehicle))
      if current ~= generation then return end
      if type(mileage) == "number" then
        sendToNui({type = "show", value = mileage, unit = Config.Unit, position = Config.Position})
      end
      Wait(1000)
    end
    if current == generation then
      TriggerServerEvent("jg-vehiclemileage:server:stop-sampling")
      sendToNui({type = "hide"})
    end
  end)
end

lib.onCache("vehicle", startSampling)
lib.onCache("seat", startSampling)
CreateThread(function() if cache.vehicle then startSampling() end end)
AddEventHandler("onResourceStop", function(resource)
  if resource ~= GetCurrentResourceName() then return end
  generation = generation + 1
  TriggerServerEvent("jg-vehiclemileage:server:stop-sampling")
end)

--------------------
-- CLIENT EXPORTS --
--------------------

---@return number|false mileageKm
exports("getMileage", function()
  if not cache.vehicle then return false end

  return Entity(cache.vehicle).state?.vehicleMileage or 0
end)

---@param ent integer
---@return number|false mileageKm
exports("getMileageByEntity", function(ent)
  if not ent or ent == 0 then return false end
  if not DoesEntityExist(ent) or not IsEntityAVehicle(ent) then return false end

  return Entity(ent).state?.vehicleMileage or 0
end)

---@param plate string
---@return number|false mileageKm
exports("getMileageByPlate", function(plate)
  if not plate or plate == "" then return false end

  return lib.callback.await("jg-vehiclemileage:server:get-mileage", false, plate)
end)

---@return "miles"|"kilometers"
exports("getUnit", function() return Config.Unit end)
exports("GetUnit", function() return Config.Unit end) --!! DEPRECATED alias of getUnit
