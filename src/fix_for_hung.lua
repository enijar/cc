local bridge = peripheral.find("me_bridge")
local monitor = peripheral.find("monitor")

if not bridge then
    print("Error: ME Bridge not found.")
    return
end

if not monitor then
    print("Error: Monitor not found.")
    return
end

monitor.setTextScale(1)

while true do
    local oldTerm = term.redirect(monitor)

    term.clear()
    term.setCursorPos(1, 1)

    print("=========================")
    print("    ME Network Status    ")
    print("=========================")

    local usedItemBytes = bridge.getUsedItemStorage()
    local totalItemBytes = bridge.getTotalItemStorage()

    print("")
    print("--- Item Storage ---")
    print("Bytes Used: " .. tostring(usedItemBytes))
    print("Bytes Total: " .. tostring(totalItemBytes))

    local items = bridge.getItems()
    local distinctCount = 0

    if items then
        for _, _ in pairs(items) do
            distinctCount = distinctCount + 1
        end
    end

    print("")
    print("--- System Content ---")
    print("Distinct Item Types: " .. tostring(distinctCount))

    print("")
    print("=========================")
    print("Updates every 30s...")

    term.redirect(oldTerm)

    term.clear()
    term.setCursorPos(1, 1)
    print("ME Status Monitor is actively running.")
    print("Press and hold Ctrl+T to terminate the script.")

    os.sleep(30)
end
