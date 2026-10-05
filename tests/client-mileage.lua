--[[
  Description:
    Execute the real client with replicated state writes forbidden, including stale callbacks.
]]--
local threads, listeners, messages, requests, exported = {}, {}, {}, {}, {}
local function run(thread) local ok, err = coroutine.resume(thread) assert(ok, err) end
cache = {vehicle = 10, seat = -1}
Config = {Unit = "miles", Position = "bottom-right", ShowMileage = true}
local mileage = {[10] = 10, [11] = 20}
lib = {
  onCache = function(key, callback) listeners[key] = callback end,
  callback = {await = function(name, _, netId, grounded)
    requests[#requests + 1] = {name, netId, grounded}
    if name:find(":sample", 1, true) then coroutine.yield("callback") return mileage[netId] end
  end}
}
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end
function Wait() coroutine.yield("wait") end
function TriggerServerEvent(name) assert(name == "jg-vehiclemileage:server:stop-sampling") end
function SendNUIMessage(message) messages[#messages + 1] = message end
function GetResourceState() return "stopped" end
function GetVehicleClass() return 0 end
function VehToNet(id) return id end
function IsVehicleOnAllWheels() return true end
function IsEntityInWater() return false end
function GetCurrentResourceName() return "jg-vehiclemileage" end
function DoesEntityExist() return true end
function IsEntityAVehicle() return true end
function Entity(id) return {state = {vehicleMileage = mileage[id], set = function() error("client must not write shared state") end}} end
local stop
function AddEventHandler(_, fn) stop = fn end
exports = function(name, fn) exported[name] = fn end
local file = assert(io.open("client/client.lua")):read("*a"):gsub("state%?%.", "state.")
assert(load(file, "client/client.lua"))()
run(threads[1])
local first = threads[2]
run(first) run(first) -- awaits first server sample
listeners.vehicle(11)
cache.vehicle = 11
run(first) -- old response must not show old car
assert(#messages == 0)
local second = threads[3]
run(second) run(second) run(second)
assert(messages[#messages].value == 20)
listeners.seat(0) cache.seat = 0
local passenger = threads[4]
run(passenger) run(passenger)
assert(messages[#messages].type == "hide")
listeners.seat(-1) cache.seat = -1
local driver = threads[5]
run(driver) run(driver) run(driver)
assert(messages[#messages].value == 20, "same-vehicle passenger-to-driver restarts sampler")
stop("jg-vehiclemileage")
run(driver)
assert(coroutine.status(driver) == "dead")
assert(exported.getMileage() == 20 and exported.getMileageByEntity(10) == 10)
assert(exported.getUnit() == "miles" and exported.GetUnit() == "miles")
print("PASS client strict-mode sampler: no replicated writes, vehicle/seat changes, stale replies, stop and exports")
