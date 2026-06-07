local inv = peripheral.wrap("left")
local mon = peripheral.find("monitor")

if not inv then
  print("No inventory found on left")
  return
end

if not mon then
  print("No monitor found")
  return
end

mon.setTextScale(0.5)
mon.clear()
mon.setCursorPos(1, 1)

local function writeLine(text)
  local _, y = mon.getCursorPos()
  local w, h = mon.getSize()

  if y > h then
    sleep(3)
    mon.clear()
    mon.setCursorPos(1, 1)
  end

  mon.write(tostring(text))
  mon.setCursorPos(1, y + 1)
end

while true do
  mon.clear()
  mon.setCursorPos(1, 1)

  writeLine("Hydroponic Bed Monitor")
  writeLine("----------------------")

  local found = false

  for slot, item in pairs(inv.list()) do
    local detail = inv.getItemDetail(slot)

    if detail then
      writeLine("Slot " .. slot .. ": " .. (detail.displayName or detail.name))
      writeLine("Count: " .. detail.count)

      if detail.displayName == "Hydroponic Simulation Processor" then
        found = true
        writeLine("")
        writeLine("Processor found in slot " .. slot)

        if detail.lore then
          writeLine("Lore:")
          for _, line in ipairs(detail.lore) do
            writeLine(line)
          end
        else
          writeLine("No lore visible")
        end

        if detail.nbt then
          writeLine("NBT: " .. detail.nbt)
        end
      end

      writeLine("")
    end
  end

  if not found then
    writeLine("No processor found")
  end

  sleep(5)
end
