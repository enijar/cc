local side = "top" -- change to side with wireless modem

rednet.open(side)

print("Listening on ID " .. os.getComputerID())

while true do
  local senderId, message = rednet.receive()
  print("From " .. senderId .. ": " .. tostring(message))
end
