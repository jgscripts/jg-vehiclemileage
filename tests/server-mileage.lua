--[[
  Description:
    Runtime regression for authoritative mileage; run with lua tests/server-mileage.lua.
]]--
local callbacks, events, exported, threads, writes = {}, {}, {}, {}, {}
local now, actors, vehicles, persisted = 0, {}, {}, {}
local vector = {}
vector.__sub = function(a, b) return setmetatable({x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}, vector) end
vector.__len = function(a) return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z) end
local function coords(x) return setmetatable({x = x, y = 0, z = 0}, vector) end
local function vehicle(id, plate, mileage)
  vehicles[id] = {plate = plate, model = 100, position = coords(0), speed = 50, state = {}}
  vehicles[id].state.set = function(self, key, value, replicated)
    assert(replicated == true, "mileage must be server-replicated")
    self[key] = value
  end
  persisted[plate] = mileage
end
local function driver(src, id) actors[src] = id vehicles[id].driver = src end
local function move(id, metres, ms)
  now = now + (ms or 1000)
  vehicles[id].position = coords(vehicles[id].position.x + metres)
end
local function equal(a, b, label) assert(a == b, (label or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a)) end
lib = {callback = {register = function(name, fn) callbacks[name] = fn end}}
Framework = {VehiclesTable = "player_vehicles"}
Config = {Unit = "miles"}
MySQL = {
  scalar = {await = function(_, args) return persisted[args[1]] end},
  update = function(query, args, cb)
    assert(query:find("GREATEST", 1, true))
    persisted[args[2]] = math.max(persisted[args[2]] or 0, args[1])
    writes[#writes + 1] = {plate = args[2], mileage = args[1]}
    cb(1)
  end
}
function NetworkGetEntityFromNetworkId(id) return vehicles[id] and id or 0 end
function GetPlayerPed(src) return actors[src] and src or 0 end
function DoesEntityExist(id) return vehicles[id] ~= nil end
function GetEntityType() return 2 end
function GetVehicleType(id) return vehicles[id].type or "automobile" end
function GetVehiclePedIsIn(src) return actors[src] or 0 end
function GetPedInVehicleSeat(id) return vehicles[id].driver or 0 end
function GetVehicleNumberPlateText(id) return vehicles[id].plate end
function GetEntityModel(id) return vehicles[id].model end
function GetEntityCoords(id) return vehicles[id].position end
function GetEntitySpeed(id) return vehicles[id].speed end
function GetGameTimer() return now end
function GetCurrentResourceName() return "jg-vehiclemileage" end
function Entity(id) return vehicles[id] end
function RegisterNetEvent(name, fn) events[name] = fn end
function AddEventHandler(name, fn) events[name] = fn end
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end
function Wait() coroutine.yield() end
exports = function(name, fn) exported[name] = fn end
assert(loadfile("server/server.lua"))()
local sample = callbacks["jg-vehiclemileage:server:sample"]
vehicle(10, "CAR1", 100)
driver(1, 10)
equal(sample(1, 10, true), 100)
equal(vehicles[10].state.vehicleMileage, 100)
move(10, 100)
equal(sample(1, 10, true), 100.1, "real displacement")
equal(sample(1, 10, true), 100.1, "duplicate tick")
move(10, 100)
equal(sample(1, 10, false), 100.1, "airborne")
move(10, 100)
equal(sample(1, 10, true), 100.1, "airborne transition")
move(10, 100)
equal(sample(1, 10, true), 100.2)
move(10, 10000)
equal(sample(1, 10, true), 100.2, "teleport rejected")
move(10, 100, 7000)
equal(sample(1, 10, true), 100.2, "stale interval rejected")
equal(sample(2, 10, true), false, "non-driver")
equal(sample(1, 999, true), false, "invalid entity")
vehicles[10].type = "boat"
equal(sample(1, 10, true), false, "excluded server vehicle type")
vehicles[10].type = nil
equal(sample(1, 10, 100000), false, "mileage value rejected")
equal(sample(1, 0/0, true), false, "NaN net ID rejected")
equal(events["jg-vehiclemileage:server:update-mileage"], nil, "legacy arbitrary setter removed")
source = 1
events["jg-vehiclemileage:server:stop-sampling"]()
assert(math.abs(persisted.CAR1 - 100.2) < 0.00001, "exit persists sub-three-km remainder")
vehicle(11, "CAR2", 2)
driver(1, 11)
equal(sample(1, 11, true), 2, "new car baseline")
move(11, 100)
equal(sample(1, 11, true), 2.1)
vehicle(12, "CAR3", 20)
driver(1, 12)
equal(sample(1, 12, true), 20)
assert(math.abs(persisted.CAR2 - 2.1) < 0.00001, "switch saves previous car")
move(12, 100)
equal(sample(1, 12, true), 20.1)
driver(2, 12)
equal(sample(2, 12, true), 20.1, "handover no double count")
source = 1
events.playerDropped()
move(12, 100)
equal(sample(2, 12, true), 20.2, "old driver disconnect cannot clear new owner")
source = 2
events.playerDropped()
assert(math.abs(persisted.CAR3 - 20.2) < 0.00001)
driver(2, 12)
sample(2, 12, true)
vehicles[12].plate = "CHANGED"
persisted.CHANGED = 7
equal(sample(2, 12, true), 7, "plate change reloads canonical mileage")
move(12, 100)
sample(2, 12, true)
events.onResourceStop("unrelated")
equal(persisted.CHANGED, 7)
events.onResourceStop("jg-vehiclemileage")
assert(math.abs(persisted.CHANGED - 7.1) < 0.00001)
equal(exported.getMileageByEntity(12), 7.1)
equal(exported.getMileageByPlate("CHANGED"), 7.1)
local km, unit = exported.GetMileage("CHANGED")
equal(km, 7.1) equal(unit, "miles", "deprecated export still returns raw km")
equal(exported.getMileageByEntity(999), false)
-- A hard brake must retain real displacement from the preceding high-speed sample.
vehicle(14, "BRAKING", 0)
driver(4, 14)
sample(4, 14, true)
move(14, 50)
vehicles[14].speed = 0
equal(sample(4, 14, true), 0.1, "pre-braking speed bounds real displacement")
-- Concurrent database restore must not create two samplers or apply a stale entity identity.
vehicle(13, "LOADING", 4)
driver(3, 13)
local originalRead = MySQL.scalar.await
MySQL.scalar.await = function(query, args) coroutine.yield() return originalRead(query, args) end
local restore = coroutine.create(function() equal(sample(3, 13, true), false, "stale driver after database yield") end)
assert(coroutine.resume(restore))
equal(sample(3, 13, true), false, "concurrent restore denied")
actors[3] = nil
assert(coroutine.resume(restore))
equal(vehicles[13].state.vehicleMileage, nil)
MySQL.scalar.await = originalRead
-- Periodic save is monotonic even if async writes complete out of order.
driver(3, 13)
sample(3, 13, true)
for _ = 1, 35 do move(13, 100) sample(3, 13, true) end
assert(persisted.LOADING >= 7 and persisted.LOADING <= 7.5)
actors[3] = nil
assert(coroutine.resume(threads[1]))
assert(coroutine.resume(threads[1]))
assert(math.abs(persisted.LOADING - 7.5) < 0.00001, "cleanup saves missed exit")
print("PASS authoritative mileage: movement, rejection, lifecycle, concurrency, exports and persistence")
