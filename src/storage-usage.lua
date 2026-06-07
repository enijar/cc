local bridge = peripheral.wrap("right")
local mon = peripheral.wrap("left")

if not bridge then
  print("No ME Bridge/peripheral found on right")
  return
end

if not mon then
  print("No monitor found on left")
  return
end

mon.setTextScale(0.5)
mon.clear()

local function fmt(n)
  if n >= 1000000000 then
    return string.format("%.2fB", n / 1000000000)
  elseif n >= 1000000 then
    return string.format("%.2fM", n / 1000000)
  elseif n >= 1000 then
    return string.format("%.2fK", n / 1000)
  else
    return tostring(n)
  end
end

local function safeCall(fn)
  local ok, result = pcall(fn)
  if not ok then return nil, result end
  return result, nil
end

local function center(y, text)
  local w, _ = mon.getSize()
  mon.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
  mon.write(text)
end

local function drawBar(y, pct)
  local w, _ = mon.getSize()
  local barWidth = math.max(10, w - 2)
  local filled = math.floor(barWidth * pct)

  mon.setCursorPos(1, y)
  mon.write("[")
  mon.write(string.rep("#", filled))
  mon.write(string.rep("-", barWidth - filled))
  mon.write("]")
end

while true do
  local used, usedErr = safeCall(function() return bridge.getUsedItemStorage() end)
  local total, totalErr = safeCall(function() return bridge.getTotalItemStorage() end)
  local free, freeErr = safeCall(function() return bridge.getAvailableItemStorage() end)

  mon.clear()

  center(1, "AE2 Storage Monitor")
  center(2, "-------------------")

  if not used or not total or total == 0 then
    mon.setCursorPos(1, 4)
    mon.write("Could not read storage")
    mon.setCursorPos(1, 5)
    mon.write(tostring(usedErr or totalErr or freeErr))
  else
    local usedPct = used / total
    local freePct = 1 - usedPct

    center(4, string.format("Used: %.1f%%", usedPct * 100))
    center(5, string.format("Free: %.1f%%", freePct * 100))

    drawBar(7, usedPct)

    mon.setCursorPos(1, 10)
    mon.write("Used:  " .. fmt(used))

    mon.setCursorPos(1, 11)
    mon.write("Free:  " .. fmt(free or (total - used)))

    mon.setCursorPos(1, 12)
    mon.write("Total: " .. fmt(total))
  end

  sleep(5)
end
