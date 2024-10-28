local dev, good = ...
--print(dev)

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

------------------------ Read Required Data Start -----------------------------

local dg1_pac = WR.read("SN:DG01_EM", "PAC")
if is_nan(dg1_pac) then dg1_pac = 0 end
--local dg2_pac = WR.read("SN:DG02_EM", "DG02_PAC")
if is_nan(dg2_pac) then dg2_pac = 0 end
--local dg3_pac = WR.read("SN:DG03_EM", "PAC")
if is_nan(dg3_pac) then dg3_pac = 0 end
--local dg4_pac = WR.read("SN:DG04_EM", "PAC")
if is_nan(dg4_pac) then dg4_pac = 0 end
local totaldgpac = (dg1_pac)
WR.setProp(dev, "TOTAL_DG_PAC", totaldgpac)

local number = 0
if dg1_pac > 1 then number = number + 1 end 
--if dg2_pac > 1 then number = number + 1 end
--if dg3_pac > 1 then number = number + 1 end 
--if dg4_pac > 1 then number = number + 1 end 

local totaldgonline = number 
WR.setProp(dev, "TOTAL_DG_ONLINE", totaldgonline) 

------------------------ Read Required Data End --------------------------------
