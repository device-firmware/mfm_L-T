local dev, good = ...
--print(dev)

if WR.isOnline(dev) then
WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

--[[---------------------- Read Required Data Start -----------------------------

local ze1_pac = WR.read(dev, "PAC_act")

if (ze1_pac >= 5) then
    WR.setProp(dev, "PAC", ze1_pac)
elseif(ze1_pac < 5) then
  socket.sleep (4)
    local ze1_pac1 = WR.read(dev, "PAC_act")
    if(ze1_pac1 < 5) then
      WR.setProp(dev, "PAC", ze1_pac1)
    end
end

------------------------ Read Required Data End -----------------------------]]--

------------------------ Sleep Start -----------------------------

local pacact = WR.read(dev, "PAC_act") ----  Comes from register -- ZE_PAC_act
local pac = WR.read(dev, "PAC")        ----  Comes from register -- ZE_PAC
local count = WR.read(dev, "COUNT")

if (is_nan(count)) then
WR.setProp(dev, "COUNT", 0)
end


if ((pacact < 1) and (count < 5)) then ------ 5 sec Sleep logic start
WR.setProp(dev, "PAC", pac)
count = count + 1
WR.setProp(dev, "COUNT", count)
elseif (pacact >= 1) then
WR.setProp(dev, "PAC", pacact)
WR.setProp(dev, "COUNT", 0)
elseif (count >= 5) then
WR.setProp(dev, "PAC", pacact)
end                                    ------ 5 sec Sleep logic End

------------------------ Sleep end -----------------------------

