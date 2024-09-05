if Config.AutoRunSQL then
  if not pcall(function()
    local fileName = (Config.Framework == "QBCore" or Config.Framework == "Qbox") and "run-qb.sql" or "run-esx.sql" 
    
    -- Open & read file
    local file = assert(io.open(GetResourcePath(GetCurrentResourceName()) .. "/install/" .. fileName, "rb"))
    local sql = file:read("*all")
    file:close()

    MySQL.query.await(sql)
  end) then
    print("^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file for your framework, found in the 'install' folder manually. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
  end
end