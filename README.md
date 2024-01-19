# JG Scripts Vehicle Mileage (QB/ESX)

<img src="https://github.com/jgscripts/jg-vehiclemileage/assets/3826279/a774d098-05ae-4d05-b167-f4c990d1f0b8" alt="vehicle-mileage" style="width:200px;"/>

A simple script for QBCore & ESX to show your vehicle's mileage in-game. When driving a vehicle that is owned (stored in the database), you will see an odometer in the bottom right of your screen. You can configure it to use miles or kilometers.

## Installation

1. Download the zip, and move into your resources folder
2. Ensure the script in your server.cfg, by adding `ensure jg-vehiclemileage`. Make sure the script is ensured _after_ your `qb-core` or `es_extended` resource
3. Run either the QBCore or ESX line of SQL in `run.sql` within your database

## Dependencies

- QBCore or ESX Legacy 1.3+
- [oxmysql](https://github.com/overextended/oxmysql)

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
