local IO = "left"
local MONITOR = "right"
local BARREL = "top"
local DRIVE = "ae2:drive_0"

local GENERATE_SECONDS = 10 * 60
local PAUSE_SECONDS = 2

local USE_REDSTONE_CONTROL = false
local IO_REDSTONE_SIDE = "left"

local STATE_FILE = ".void_cell_rotator_state"

local nativeTerm = term.current()

local mon = peripheral.wrap(MONITOR)
if mon then
  mon.setTextScale(0.5)
  term.redirect(mon)
end

local function wrapInventory(name)
  local p = peripheral.wrap(name)

  if not p then
    error("Missing peripheral: " .. name)
  end

  if not p.list or not p.pushItems or not p.pullItems or not p.size then
    error(name .. " is not an inventory")
  end

  return p
end

local io = wrapInventory(IO)
local barrel = wrapInventory(BARREL)
local drive = wrapInventory(DRIVE)

local inventories = {
  [IO] = io,
  [BARREL] = barrel,
  [DRIVE] = drive,
}

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

local function getOccupiedSlots(inv)
  local slots = {}

  for slot, item in pairs(inv.list()) do
    table.insert(slots, slot)
  end

  table.sort(slots)
  return slots
end

local function getFirstOccupiedSlot(inv)
  local slots = getOccupiedSlots(inv)
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

local function getNextDriveSlot()
  local slots = getOccupiedSlots(drive)

  if #slots == 0 then
    return nil, 0
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

local function moveExact(fromName, toName, fromSlot, count, toSlot)
  local fromInv = inventories[fromName]
  local toInv = inventories[toName]

  if not fromInv then
    error("Unknown source inventory: " .. tostring(fromName))
  end

  if not toInv then
    error("Unknown target inventory: " .. tostring(toName))
  end

  local okPush, movedPush = pcall(function()
    return fromInv.pushItems(toName, fromSlot, count, toSlot)
  end)

  if okPush and movedPush == count then
    return movedPush
  end

  local okPull, movedPull = pcall(function()
    return toInv.pullItems(fromName, fromSlot, count, toSlot)
  end)

  if okPull and movedPull == count then
    return movedPull
  end

  local pushResult = okPush and tostring(movedPush) or tostring(movedPush)
  local pullResult = okPull and tostring(movedPull) or tostring(movedPull)

  error(
    "Move failed: "
      .. fromName
      .. " slot "
      .. tostring(fromSlot)
      .. " -> "
      .. toName
      .. "\nPush result: "
      .. pushResult
      .. "\nPull result: "
      .. pullResult
  )
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
  log("")
end

local function rotate()
  showHeader()
  log("Pausing...")
  setIoRunning(false)
  sleep(PAUSE_SECONDS)

  local ioSlot = getFirstOccupiedSlot(io)
  local driveSlot, driveCellCount = getNextDriveSlot()
  local barrelSlot = getEmptySlot(barrel)

  if not driveSlot then
    error("No cells found in ME Drive.")
  end

  if not barrelSlot then
    error("Barrel has no empty slot.")
  end

  log("Drive cells: " .. driveCellCount)
  log("IO slot: " .. tostring(ioSlot or "none"))
  log("Next drive slot: " .. driveSlot)
  log("Barrel slot: " .. barrelSlot)
  log("")

  if not ioSlot then
    log("No cell in IO Port.")
    log("Moving Drive -> IO Port")
    moveExact(DRIVE, IO, driveSlot, 1)
    setIoRunning(true)
    return
  end

  log("1. IO Port -> Barrel")
  moveExact(IO, BARREL, ioSlot, 1, barrelSlot)

  log("2. ME Drive -> IO Port")
  local okMove, errMove = pcall(function()
    moveExact(DRIVE, IO, driveSlot, 1, ioSlot)
  end)

  if not okMove then
    log("Failed. Returning old cell.")
    moveExact(BARREL, IO, barrelSlot, 1, ioSlot)
    error("Could not move new cell into IO Port.\n" .. tostring(errMove))
  end

  log("3. Barrel -> ME Drive")
  moveExact(BARREL, DRIVE, barrelSlot, 1, driveSlot)

  log("")
  log("Rotation complete.")
  setIoRunning(true)
end

setIoRunning(true)

while true do
  showHeader()
  log("Generating Singularities...")
  log("")

  for remaining = GENERATE_SECONDS, 1, -1 do
    term.setCursorPos(1, 9)
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
