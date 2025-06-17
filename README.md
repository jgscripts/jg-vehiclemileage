# JG Scripts Vehicle Mileage v2 (QB/QBox/ESX/Custom)

<img src="https://github.com/user-attachments/assets/55065901-7859-4de3-bc75-1330d41128cb" alt="vehicle-mileage" style="width:200px;"/>

A simple script for QBCore, QBox & ESX to show your vehicle's mileage in-game. When driving a vehicle that is owned (stored in the database), you will see an odometer in the bottom right of your screen. You can configure it to use miles or kilometers.

## Installation

1. Download the zip, and move into your resources folder
2. Ensure the script in your server.cfg, by adding `ensure jg-vehiclemileage`. Make sure the script is ensured _after_ your `qb-core`, `qbx_core` or `es_extended` resource
3. Run either the QBCore/QBox or ESX line of SQL in `run.sql` within your database

## Dependencies

- QBCore/QBox/ESX (or pretty easy to use a custom framework)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)

## Custom Framework

Using a custom framework is fairly straightforward. All your framework needs to have is some sort of owned vehicles database table, and that table needs to have a `plate` column in it. Then all you need to do is:

1. Go to `main.lua`
2. Add another conditional for your framework, and point to the name of your vehicles table
3. In `config.lua`, set `Config.Framework = [your framework name]`

Example:

```
if Config.Framework == "QBCore" then
  Framework.VehiclesTable = "player_vehicles"
elseif Config.Framework == "ESX" then
  Framework.VehiclesTable = "owned_vehicles"
elseif Config.Framework == "MyFrameworkName" then
  Framework.VehiclesTable = "vehicles_table_name"
else
  error("You haven't set a valid framework. Valid options can be found in main.lua!")
end
```

## Exports

Use `GetMileage(plate)` to get the mileage of a vehicle. Returns

```lua
local distance, unit = exports["jg-vehiclemileage"]:GetMileage("PLATE")
```

Returns:

- **distance**: number
- **unit**: enum `"miles", "kilometers"`

_Will return `false` if the plate does not exist in the database_

## Our other work

Want to see your vehicle's mileage in your garage with no setup? Try our Advanced Garages script: https://jgscripts.com/scripts/advanced-garages
