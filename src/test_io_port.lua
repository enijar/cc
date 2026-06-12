local ioPortSide = "left"
local monitorSide = "right"

local nativeTerm = term.current()
local mon = peripheral.wrap(monitorSide)

if mon then
  mon.setTextScale(0.5)
  term.redirect(mon)
end

local function resetScreen()
  term.clear()
  term.setCursorPos(1, 1)
end

local function writeLine(text)
  print(text)
end

local function pause()
  writeLine("")
  writeLine("Press any key...")
  os.pullEvent("key")
end

local function dump(value)
  if textutils and textutils.serialize then
    return textutils.serialize(value)
  end

  return tostring(value)
end

local function hasMethod(methods, name)
  for _, method in ipairs(methods) do
    if method == name then
      return true
    end
  end

  return false
end

local function call(name, method, ...)
  writeLine("CALL " .. method)

  local ok, result = pcall(peripheral.call, name, method, ...)

  if ok then
    writeLine("OK: " .. dump(result))
  else
    writeLine("ERR: " .. tostring(result))
  end

  writeLine("")
end

resetScreen()

if not peripheral.isPresent(ioPortSide) then
  writeLine("No peripheral found on left.")
  writeLine("")
  writeLine("Detected peripherals:")

  for _, name in ipairs(peripheral.getNames()) do
    local types = { peripheral.getType(name) }
    writeLine("- " .. name .. ": " .. table.concat(types, ", "))
  end

  return
end

local types = { peripheral.getType(ioPortSide) }
local methods = peripheral.getMethods(ioPortSide) or {}

writeLine("ME Extended IO Port test")
writeLine("=======================")
writeLine("")
writeLine("Side: " .. ioPortSide)
writeLine("Types: " .. table.concat(types, ", "))
writeLine("")
writeLine("Methods:")

for _, method in ipairs(methods) do
  writeLine("- " .. method)
end

pause()
resetScreen()

writeLine("Relevant methods:")
writeLine("=================")
writeLine("")

for _, method in ipairs(methods) do
  local m = string.lower(method)

  if string.find(m, "direction")
  or string.find(m, "mode")
  or string.find(m, "io")
  or string.find(m, "transfer")
  or string.find(m, "cell") then
    writeLine("- " .. method)
  end
end

pause()
resetScreen()

writeLine("About to test setters.")
writeLine("")
writeLine("Press Y to continue.")
writeLine("Press anything else to stop.")

local _, key = os.pullEvent("key")

if key ~= keys.y then
  resetScreen()
  writeLine("Stopped without changing anything.")
  return
end

resetScreen()

local testCalls = {
  { "getDirection" },
  { "getMode" },
  { "getTransferMode" },
  { "getCellTransferMode" },
  { "getCellDirection" },

  { "setDirection", "cell_to_network" },
  { "setDirection", "network_to_cell" },
  { "setDirection", "CELL_TO_NETWORK" },
  { "setDirection", "NETWORK_TO_CELL" },
  { "setDirection", true },
  { "setDirection", false },
  { "setDirection", 0 },
  { "setDirection", 1 },

  { "setMode", "cell_to_network" },
  { "setMode", "network_to_cell" },
  { "setMode", true },
  { "setMode", false },
  { "setMode", 0 },
  { "setMode", 1 },

  { "setTransferMode", "cell_to_network" },
  { "setTransferMode", "network_to_cell" },
  { "setCellTransferMode", "cell_to_network" },
  { "setCellTransferMode", "network_to_cell" },

  { "toggleDirection" },
  { "toggleMode" },
}

local callsMade = 0

for _, test in ipairs(testCalls) do
  local method = test[1]

  if hasMethod(methods, method) then
    local params = {}

    for i = 2, #test do
      table.insert(params, test[i])
    end

    call(ioPortSide, method, table.unpack(params))
    callsMade = callsMade + 1
    sleep(0.5)
  end
end

if callsMade == 0 then
  writeLine("No matching setter/getter methods found.")
  writeLine("")
  writeLine("Likely result: CC cannot switch IO Port direction directly.")
else
  writeLine("Done.")
  writeLine("")
  writeLine("Check the IO Port GUI.")
  writeLine("Did the arrow direction change?")
end

term.redirect(nativeTerm)
