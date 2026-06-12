local MODEM = "back"

local modem = peripheral.wrap(MODEM)

if not modem then
  error("No modem on " .. MODEM)
end

print("Local modem: " .. MODEM)
print("")

if modem.getNameLocal then
  print("Local name: " .. tostring(modem.getNameLocal()))
end

print("")
print("Remote peripherals:")

local names = modem.getNamesRemote()

if #names == 0 then
  print("NONE")
else
  for _, name in ipairs(names) do
    local types = { modem.getTypeRemote(name) }
    print(name .. " -> " .. table.concat(types, ", "))
  end
end
