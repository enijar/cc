local MODEM = "back"

local modem = peripheral.wrap(MODEM)

if not modem then
  error("No modem on " .. MODEM)
end

print("Local modem: " .. MODEM)
print("Type: " .. table.concat({ peripheral.getType(MODEM) }, ", "))
print("")
print("Remote peripherals:")

local ok, names = pcall(function()
  return modem.getNamesRemote()
end)

if not ok then
  print("Could not call getNamesRemote")
  print(names)
  return
end

if not names or #names == 0 then
  print("NONE")
  print("")
  print("Fix:")
  print("1. Right-click computer modem")
  print("2. Right-click ME Drive modem")
  print("3. Check cable connects both")
  return
end

for _, name in ipairs(names) do
  local okType, types = pcall(function()
    return { modem.getTypeRemote(name) }
  end)

  if okType then
    print(name .. " -> " .. table.concat(types, ", "))
  else
    print(name .. " -> type error")
  end
end
