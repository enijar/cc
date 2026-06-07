local inv = peripheral.wrap("left")

if not inv then
  print("No peripheral found on left")
  return
end

for slot, item in pairs(inv.list()) do
  print(slot, item.name, item.displayName or "")
  print(textutils.serialize(inv.getItemDetail(slot)))
end
