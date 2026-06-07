local inv = peripheral.wrap("left")

if not inv then
  print("No inventory found")
  return
end

for slot, item in pairs(inv.list()) do
  local detail = inv.getItemDetail(slot)

  if detail and detail.displayName == "Hydroponic Simulation Processor" then
    print("Found processor in slot " .. slot)
    print("Name: " .. detail.name)
    print("Display: " .. detail.displayName)

    if detail.lore then
      print("Lore:")
      for _, line in ipairs(detail.lore) do
        print(line)
      end
    else
      print("No lore visible")
    end

    if detail.nbt then
      print("NBT hash: " .. detail.nbt)
    end
  end
end
