local dev, good = ...
--print(dev)

devS = string.sub(dev, 4, -1)
--print("devS = ", devS)

require ("socket")
local now = socket.gettime()
local date = os.date("*t")
local hour = date.hour
local min = date.min
local sec = date.sec

------------------------ Read Setpoints Start ---------------------------------

------------------------- Read Function Start ---------------------------------

function CHECKDATATIME(dev, now, field)
 local midNight = (now - ((hour * 60 * 60) + (min * 60) + sec))
 local dataTime = WR.ts(dev, field)
 if (dataTime < midNight) then
  WR.setProp(dev, field, 0)
 else
  local data = WR.read(dev, field)
  WR.setProp(dev, field, data)
 end
end

function EAI_CALCULATE(dev, ...)
 local result = 0
 local value = 0
 for i,v in ipairs(arg) do
  value = WR.read(dev, v)
  if is_nan(value) then value = 0 end
  result = result + value
 end
 return result
end

function SUM02(meter1, meter2, targetmeter, val, sumval)
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0 end
  
 WR.setProp(targetmeter, sumval, value1+value2)
end

function AVG02(meter1, meter2, targetmeter, val, avgval)
 local cnt = 2
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0; cnt = cnt - 1 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0; cnt = cnt - 1 end
 
 if cnt > 0 then
  WR.setProp(targetmeter, avgval, (value1+value2)/cnt)
 end  
end

function COM02(meter1, meter2, targetmeter, val, resval)
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 1 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 1 end
 local value = value1 + value2
 if value > 0 then value = 1 end
 WR.setProp(targetmeter, resval, value) 
end

------------------------- Read Function End -----------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/mnt/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()
end

if not(settings.EM[devS].dcCapacity and settings.EM[devS].prAlarmSetpoint and settings.EM[devS].prAlarmRadSetpoint and settings.EM[devS].prAlarmTimeSetpoint and settings.EM[devS].prRealRadSetpoint and settings.EM[devS].prMinRadSetpoint and settings.EM[devS].gridVoltSetpoint) then
 --print ("Data loading")
 settings.EM[devS].dcCapacity = settings.EM[devS].dcCapacity or settings.EM.dcCapacity or 53510
 settings.EM[devS].prAlarmSetpoint = settings.EM[devS].prAlarmSetpoint or settings.EM.prAlarmSetpoint or 75
 settings.EM[devS].prAlarmRadSetpoint = settings.EM[devS].prAlarmRadSetpoint or settings.EM.prAlarmRadSetpoint or 500
 settings.EM[devS].prAlarmTimeSetpoint = settings.EM[devS].prAlarmTimeSetpoint or settings.EM.prAlarmTimeSetpoint or 300
 settings.EM[devS].prRealRadSetpoint = settings.EM[devS].prRealRadSetpoint or settings.EM.prRealRadSetpoint or 100
 settings.EM[devS].prMinRadSetpoint = settings.EM[devS].prMinRadSetpoint or settings.EM.prMinRadSetpoint or 500
 settings.EM[devS].gridVoltSetpoint = settings.EM[devS].gridVoltSetpoint or settings.EM.gridVoltSetpoint or 50

 CHECKDATATIME(dev, now, "EAEN_DAY")
 CHECKDATATIME(dev, now, "PLANT_START_TIME")
 CHECKDATATIME(dev, now, "PLANT_STOP_TIME")
 CHECKDATATIME(dev, now, "OPERATIONAL_TIME")
 CHECKDATATIME(dev, now, "GRID_ON")
 CHECKDATATIME(dev, now, "GRID_OFF") 
 CHECKDATATIME(dev, now, "PR_MIN")
 CHECKDATATIME(dev, now, "PR_DAY")
 CHECKDATATIME(dev, now, "PR_DAY_GL")
 CHECKDATATIME(dev, now, "PAC_MAX_TIME")
 CHECKDATATIME(dev, now, "COMMUNICATION_DAY_ONLINE")
 CHECKDATATIME(dev, now, "COMMUNICATION_DAY_OFFLINE")
end

--print ("dcCapacity = ", settings.EM[devS].dcCapacity)
--print ("prAlarmSetpoint = ", settings.EM[devS].prAlarmSetpoint)
--print ("prAlarmRadSetpoint = ", settings.EM[devS].prAlarmRadSetpoint)
--print ("prAlarmTimeSetpoint = ", settings.EM[devS].prAlarmTimeSetpoint)
--print ("prRealRadSetpoint = ", settings.EM[devS].prRealRadSetpoint)
--print ("prMinRadSetpoint = ", settings.EM[devS].prMinRadSetpoint)
--print ("gridVoltSetpoint = ", settings.EM[devS].gridVoltSetpoint)

------------------------ Read Setpoints End -----------------------------------

------------------------ Read Required Data Start -----------------------------

commStatus = commStatus or {}
commStatus[dev] = commStatus[dev] or {DayOn=WR.read(dev, "COMMUNICATION_DAY_ONLINE"), DayOff=WR.read(dev, "COMMUNICATION_DAY_OFFLINE"), HourOn=0, HourOff=0, ts=now}
if is_nan(commStatus[dev].DayOn) then commStatus[dev].DayOn = 0 end
if is_nan(commStatus[dev].DayOff) then commStatus[dev].DayOff = 0 end
local radiation = WR.read(dev, "RADIATION")
local radiationDay = WR.read(dev, "RADIATION_DAY")
local pac = WR.read(dev, "PAC")
local pacMax = WR.read(dev, "PAC_MAX")
local pr = WR.read(dev, "PR")
if is_nan(pr) then pr = 0 end
local prMin = WR.read(dev, "PR_MIN")
if is_nan(prMin) then prMin = 0 end
local prDay = WR.read(dev, "PR_DAY")
if is_nan(prDay) then prDay = 0 end
local prDayGL = WR.read(dev, "PR_DAY_GL")
if is_nan(prDayGL) then prDayGL = 0 end
local pacn = pac / (settings.EM[devS].dcCapacity / 1000)
if is_nan(pacn) then pacn = 0 end
local eai = WR.read(dev, "EAI")
local eae = WR.read(dev, "EAE")
local eaiDay = WR.read(dev, "EAI_DAY")
local eaeDay = WR.read(dev, "EAE_DAY")
local uac = WR.read(dev, "UAC")
local uac1 = WR.read(dev, "UAC1")
local uac2 = WR.read(dev, "UAC2")
local uac3 = WR.read(dev, "UAC3")
local iac1 = WR.read(dev, "IAC1")
local iac2 = WR.read(dev, "IAC2")
local iac3 = WR.read(dev, "IAC3")
local yday1 = WR.read(dev, "EAE_YDAY1")
local yday2 = WR.read(dev, "EAE_YDAY2")
local yday3 = WR.read(dev, "EAE_YDAY3")
local eqiEai = WR.read(dev, "EQI_EAI")
local eqiEae = WR.read(dev, "EQI_EAE")
local eqeEai = WR.read(dev, "EQE_EAI")
local eqeEae = WR.read(dev, "EQE_EAE")
if not(pacOld) then pacOld = WR.read(dev, "PAC_MAX") end
startTime = startTime or {}
startTime[dev] = startTime[dev] or {ts=WR.read(dev, "PLANT_START_TIME")}
if is_nan(startTime[dev].ts) then startTime[dev].ts = 0 end
stopTime = stopTime or {}
stopTime[dev] = stopTime[dev] or {ts=WR.read(dev, "PLANT_STOP_TIME"), againStart=0}
if is_nan(stopTime[dev].ts) then stopTime[dev].ts = 0 end
if is_nan(stopTime[dev].againStart) then stopTime[dev].againStart = 0 end
gridAvailability = gridAvailability or {}
gridAvailability[dev] = gridAvailability[dev] or {ts=now, tson=WR.read(dev, "GRID_ON"), tsoff=WR.read(dev, "GRID_OFF")}
if is_nan(gridAvailability[dev].tson) then gridAvailability[dev].tson = 0 end
if is_nan(gridAvailability[dev].tsoff) then gridAvailability[dev].tsoff = 0 end
opTime = opTime or {}
opTime[dev] = opTime[dev] or {ts=now, tson=WR.read(dev, "OPERATIONAL_TIME")}
if is_nan(opTime[dev].tson) then opTime[dev].tson = 0 end
WR.setProp(dev, "PAC_MAX_TIME", WR.read(dev, "PAC_MAX_TIME"))
WR.setProp(dev, "EAE_YDAY", WR.read(dev, "EAE_YDAYC"))


------------------------ Read Required Data End -------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 startTime[dev].ts = 0
 stopTime[dev].ts = 0
 gridAvailability[dev].tson = 0
 gridAvailability[dev].tsoff = 0
 opTime[dev].tson = 0
 pacOld = 0
 prDay = 0
 prMin = 0
 WR.setProp(dev, "PAC_MAX_TIME", 0)
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
 commStatus[dev].DayOn = 0
 commStatus[dev].DayOff = 0
end
if (os.date("*t", checkMidnight[dev].ts).hour < os.date("*t", now).hour) then
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
end
checkMidnight[dev].ts = now

------------------------ Check Midnight End -----------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

local commChannel = 0
for d in WR.devices() do
 --print("d = ",d)
 if not(WR.isOnline(d)) then
  commChannel = commChannel + 1
  if (commChannel > 1) then commChannel = 1 end
 end
 --print("commChannel = ",commChannel)
end
file = io.open("/ram/"..masterid..".temp","w+")
if file ~= nil then
 file:write(commChannel) 
end
file:close()
os.remove("/ram/"..masterid.."")
os.rename("/ram/"..masterid..".temp","/ram/"..masterid.."")

if ((now-commStatus[dev].ts) >= 15) then
 --print("commStatus["..dev.."].commDayOnline = ", commStatus[dev].commDayOnline)
 --print("commStatus["..dev.."].commDayOffline = ", commStatus[dev].commDayOffline)
 --print("commStatus["..dev.."].commHourOnline = ", commStatus[dev].commHourOnline)
 --print("commStatus["..dev.."].commHourOffline = ", commStatus[dev].commHourOffline)
 --print("commStatus["..dev.."].ts = ", commStatus[dev].ts)
 if good then
  commStatus[dev].DayOn = commStatus[dev].DayOn + 1
  commStatus[dev].HourOn = commStatus[dev].HourOn + 1
 else
  commStatus[dev].DayOff = commStatus[dev].DayOff + 1
  commStatus[dev].HourOff = commStatus[dev].HourOff + 1
 end
 commStatus[dev].ts = now
 WR.setProp(dev, "COMMUNICATION_DAY_ONLINE", commStatus[dev].DayOn)
 WR.setProp(dev, "COMMUNICATION_DAY_OFFLINE", commStatus[dev].DayOff)
 WR.setProp(dev, "COMMUNICATION_DAY", (((commStatus[dev].DayOn) / (commStatus[dev].DayOn + commStatus[dev].DayOff)) * 100))
 WR.setProp(dev, "COMMUNICATION_HOUR", (((commStatus[dev].HourOn) / (commStatus[dev].HourOn + commStatus[dev].HourOff)) * 100))
end

---------------------- COMMUNICATION STATUS End -------------------------------

------------------------ CUF Calculation Start --------------------------------
if (devS == "EM02") then 
local B01cuf = ((eaeDay) / ((settings.EM[devS].dcCapacity / 1000) * 24)) * 100
if is_nan(B01cuf) then B01cuf = 0 end
WR.setProp(dev, "B01_CUF", B01cuf)
end

if (devS == "EM03") then 
local B02cuf = ((eaeDay) / ((settings.EM[devS].dcCapacity / 1000) * 24)) * 100
if is_nan(B02cuf) then B02cuf = 0 end
WR.setProp(dev, "B02_CUF", B02cuf)
end

if (devS == "EM02") then 
local B01TotalInvEDC_DAY = WR.read(dev, "B01_TOTAL_INV_EDC_DAY")
if is_nan(B01TotalInvEDC_DAY) then B01TotalInvEDC_DAY = 0 end
local B01cufDc = ((B01TotalInvEDC_DAY) / ((settings.EM[devS].dcCapacity) * 24)) * 100
if is_nan(B01cufDc) then B01cufDc = 0 end
WR.setProp(dev, "B01_CUF_DC", B01cufDc)
end

if (devS == "EM03") then 
local B02TotalInvEDC_DAY = WR.read(dev, "B01_TOTAL_INV_EDC_DAY")
if is_nan(B02TotalInvEDC_DAY) then B02TotalInvEDC_DAY = 0 end
local B02cufDc = ((B02TotalInvEDC_DAY) / ((settings.EM[devS].dcCapacity) * 24)) * 100
if is_nan(B02cufDc) then B02cufDc = 0 end
WR.setProp(dev, "B02_CUF_DC", B02cufDc)
end

------------------------ CUF Calculation End ----------------------------------

------------------------ PR Calculation Start ---------------------------------

plantAlarm = plantAlarm or {}
plantAlarm[dev] = plantAlarm[dev] or {tsp=now}

--print("now = ",now)
--print("plantAlarm["..dev.."].tsp = ",plantAlarm[dev].tsp)

local prNow = 0
local prAlarm = 0
if ((radiation > settings.EM[devS].prRealRadSetpoint) and (pac >= 0)) then
 prNow = (((pac * 1000) / settings.EM[devS].dcCapacity) / (radiation / 1000)) * 100
 if is_nan(prNow) then prNow = 0 end
 if (prNow > 100) then prNow = pr end
 if ((pr < settings.EM[devS].prAlarmSetpoint) and (radiation > settings.EM[devS].prAlarmRadSetpoint)) then
  prAlarm = 1
 end
end
if (prAlarm == 1) then
 if ((now-plantAlarm[dev].tsp) < settings.EM[devS].prAlarmTimeSetpoint) then prAlarm  = 0 end
else
 plantAlarm[dev].tsp = now
 prAlarm = 0
end
local prDayNow = 0
if (radiationDay > 0) then
 prDayNow = ((((eaeDay) * 1000) / settings.EM[devS].dcCapacity) / radiationDay) * 100
else
 prDayNow = prDay
end
if is_nan(prDayNow) then prDayNow = prDay end
if ((radiation > settings.EM[devS].prMinRadSetpoint) and ((pr < prMin) or (prMin == 0))) then
 prMin = pr
end

local genLoss = 0
genLossDay = genLossDay or {}
genLossDay[dev] = genLossDay[dev] or {ts=now, day=WR.read(dev, "GEN_LOSS_DAY")}
if (is_nan(genLossDay[dev].day)) then genLossDay[dev].day = 0 end

if (os.date("*t", genLossDay[dev].ts).hour > os.date("*t", now).hour) then
 genLossDay[dev].day = 0
end
--[[--
if (((not(is_nan(pacLimitCmd))) and (pacLimitCmd<200)) or ((not(is_nan(uac))) and (uac <= settings.EM[devS].gridVoltSetpoint))) then
 if ((not(is_nan(pac))) and (pac < (settings.EM[devS].dcCapacity * 0.8))) then
  genLoss = (settings.EM[devS].dcCapacity * 0.8) - pac
 end
end
genLossDay[dev].day = genLossDay[dev].day + (((now-genLossDay[dev].ts) * genLoss) / (60 * 60 * 1000))
genLossDay[dev].ts = now
WR.setProp(dev, "GEN_LOSS_DAY", genLossDay[dev].day)

local prDayGLNow = ((((eaeDay+genLoss) * 1000) / settings.EM[devS].dcCapacity) / radiationDay) * 100
if is_nan(prDayGLNow) then prDayGLNow = prDayGL end
--]]--
WR.setProp(dev, "PR", prNow)
WR.setProp(dev, "PR_MAX", prNow)
WR.setProp(dev, "PR_MIN", prMin)
WR.setProp(dev, "PR_ALARM", prAlarm)
WR.setProp(dev, "PR_DAY", prDayNow)
--WR.setProp(dev, "PR_DAY_GL", prDayGLNow)

------------------------ PR Calculation End -----------------------------------
