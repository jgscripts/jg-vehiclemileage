Config = {}

Config.AutoRunSQL = true

---@type "auto" | "QBCore" | "Qbox" | "ESX"
Config.Framework = "auto"

-- This setting will not work if you are using jg-hud or tgiann-lumihud.
Config.ShowMileage = true

---@type "miles" | "kilometers"
Config.Unit = "miles"

---@type "bottom-right" | "bottom-left" | "top-right" | "top-left" | "bottom-center" | "top-center"
Config.Position = "bottom-right"

Config.ScriptCompatibility = {
    ["tgiann-lumihud"] = false, -- If you set this to true, you must also set the config.customMileageSystem setting to true in the tgiann-lumihud script.
    ["jg-hud"] = GetResourceState("jg-hud") == "started"
}
