local IO = "left"
local MONITOR = "right"
local BARREL = "top"

local GENERATE_SECONDS = 10 * 60
local PAUSE_SECONDS = 2

local USE_REDSTONE_CONTROL = true
local IO_REDSTONE_SIDE = "left"

local CELL_NAME_MATCH = "void"
local STATE_FILE = ".void_cell_rotator_state"

local nativeTerm = term.current()

local function getTypes(name)
  return { peripheral.getType(name) }
end

local function typeString(name)
  return table.concat(getTypes(name), ", ")
end

local function isInventory(name)
  local p = peripheral.wrap(name)
  return p and p.list and p.pushItems and p.size
end

local function wrapInventory(name)
  local p = peripheral.wrap(name)

  if not p then
    error("Missing peripheral: " .. name)
  end

  if not p.list or not p.pushItems or not p.size then
    error(name .. " is not an inventory. Type: " .. typeString(name))
  end

  return p
end

local function itemMatchesCell(item)
  if not item then
    return false
  end

  local name = string.lower(item.name or "")
  local displayName = string.lower(item.displayName or "")

  return string.find(name, CELL_NAME_MATCH, 1, true)
    or string.find(displayName, CELL_NAME_MATCH, 1, true)
end

local function detectDrive()
  local candidates = {}

  for _, name in ipairs(peripheral.getNames()) do
    if name ~= IO and name ~= MONITOR and name ~= BARREL and isInventory(name) then
      local inv = peripheral.wrap(name)

      for _, item in pairs(inv.list()) do
        if itemMatchesCell(item) then
          table.insert(candidates, name)
          break
        end
      end
    end
  end

  if #candidates == 1 then
    return candidates[1]
  end

  if #candidates > 1 then
    error("Multiple possible drives found: " .. table.concat(candidates, ", "))
  end

  error("Could not auto-detect ME Drive. Add a wired modem to the ME Drive, then run peripherals.")
end

local DRIVE = detectDrive()

local mon = peripheral.wrap(MONITOR)

if mon then
  mon.setTextScale(0.5)
  term.redirect(mon)
end

local io = wrapInventory(IO)
local barrel = wrapInventory(BARREL)
local drive = wrapInventory(DRIVE)

local function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

local function log(text)
  print(text)
end

local function readIndex()
  if not fs.exists(STATE_FILE) then
    return 1
  end

  local f = fs.open(STATE_FILE, "r")
  local value = tonumber(f.readAll())
  f.close()

  return value or 1
end

local function writeIndex(value)
  local f = fs.open(STATE_FILE, "w")
  f.write(tostring(value))
  f.close()
end

local function getCellSlots(inv)
  local slots = {}

  for slot, item in pairs(inv.list()) do
    if itemMatchesCell(item) then
      table.insert(slots, slot)
    end
  end

  table.sort(slots)
  return slots
end

local function getFirstCellSlot(inv)
  local slots = getCellSlots(inv)
  return slots[1]
end

local function getEmptySlot(inv)
  local items = inv.list()

  for slot = 1, inv.size() do
    if not items[slot] then
      return slot
    end
  end

  return nil
end

local function getNextDriveCellSlot()
  local slots = getCellSlots(drive)

  if #slots == 0 then
    return nil
  end

  local index = readIndex()

  if index > #slots then
    index = 1
  end

  local slot = slots[index]

  index = index + 1

  if index > #slots then
    index = 1
  end

  writeIndex(index)

  return slot, #slots
end

local function moveExact(fromInv, fromName, toName, fromSlot, count, toSlot)
  local moved = fromInv.pushItems(toName, fromSlot, count, toSlot)

  if moved ~= count then
    error("Move failed: " .. fromName .. " slot " .. fromSlot .. " -> " .. toName)
  end

  return moved
end

local function setIoRunning(running)
  if USE_REDSTONE_CONTROL then
    redstone.setOutput(IO_REDSTONE_SIDE, running)
  end
end

local function showHeader()
  clear()
  log("Void Cell Rotator")
  log("=================")
  log("")
  log("IO Port: " .. IO)
  log("Barrel: " .. BARREL)
  log("Drive: " .. DRIVE)
  log("Drive type: " .. typeString(DRIVE))
  log("")
end

local function rotate()
  showHeader()
  log("Pausing IO Port...")
  setIoRunning(false)
  sleep(PAUSE_SECONDS)

  local ioSlot = getFirstCellSlot(io)
  local driveSlot, driveCellCount = getNextDriveCellSlot()
  local barrelSlot = getEmptySlot(barrel)

  if not driveSlot then
    error("No Void Cell found in ME Drive.")
  end

  if not barrelSlot then
    error("Barrel has no empty slot.")
  end

  log("Drive cells: " .. tostring(driveCellCount))
  log("IO cell slot: " .. tostring(ioSlot or "none"))
  log("Next drive slot: " .. tostring(driveSlot))
  log("Barrel slot: " .. tostring(barrelSlot))
  log("")

  if not ioSlot then
    log("No cell in IO Port.")
    log("Moving Drive -> IO Port")
    moveExact(drive, DRIVE, IO, driveSlot, 1)
    setIoRunning(true)
    return
  end

  log("1. IO Port -> Barrel")
  moveExact(io, IO, BARREL, ioSlot, 1, barrelSlot)

  log("2. ME Drive -> IO Port")
  local movedToIo = drive.pushItems(IO, driveSlot, 1, ioSlot)

  if movedToIo ~= 1 then
    log("Failed. Returning old cell to IO Port.")
    barrel.pushItems(IO, barrelSlot, 1, ioSlot)
    error("Could not move new Void Cell into IO Port.")
  end

  log("3. Barrel -> ME Drive")
  moveExact(barrel, BARREL, DRIVE, barrelSlot, 1, driveSlot)

  log("")
  log("Rotation complete.")
  log("Resuming IO Port.")
  setIoRunning(true)
end

setIoRunning(true)

while true do
  showHeader()
  log("Generating Singularities...")
  log("")

  for remaining = GENERATE_SECONDS, 1, -1 do
    term.setCursorPos(1, 10)
    term.clearLine()
    write("Next swap: " .. remaining .. "s")
    sleep(1)
  end

  local ok, err = pcall(rotate)

  if not ok then
    showHeader()
    log("ERROR")
    log("=====")
    log(err)
    log("")
    log("IO Port stopped for safety.")
    setIoRunning(false)
    break
  end

  sleep(3)
end

term.redirect(nativeTerm)
