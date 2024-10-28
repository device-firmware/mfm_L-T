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

------------------------- Read Function End -----------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/mnt/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()
end

if not(settings.PLANT.dcCapacity and settings.PLANT.prRealRadSetpoint) then
 --print ("Data loading")
 settings.PLANT.dcCapacity = settings.PLANT.dcCapacity or settings.PLANT.dcCapacity or 198.0
 settings.PLANT.prRealRadSetpoint = settings.PLANT.prRealRadSetpoint or settings.PLANT.prRealRadSetpoint or 250.0
 CHECKDATATIME(dev, now, "PR_DAY")
 CHECKDATATIME(dev, now, "EXP_GEN_CUM_1")
 CHECKDATATIME(dev, now, "EXP_GEN_CUM_2")
 CHECKDATATIME(dev, now, "GEN_LOSS_CUM")
 CHECKDATATIME(dev, now, "EAE_DAY_NO_RAD")
 CHECKDATATIME(dev, now, "START_TIME")
 CHECKDATATIME(dev, now, "STOP_TIME")
 CHECKDATATIME(dev, now, "OPERATIONAL_TIME")
end

--print ("dcCapacity = ", settings.BLOCK.dcCapacity)

------------------------ Read Setpoints End -----------------------------------

------------------------ Read Required Data Start -----------------------------

local pac = WR.read(dev, "PAC")
local eaeDay = WR.read(dev, "EAE_DAY")
local eae = WR.read(dev, "EAE")
local radiationCum = WR.read(dev, "SOLAR_RADIATION_CUM")
local radiation = WR.read(dev, "RADIATION")
local prDay = WR.read(dev, "PR_DAY")
local pr = WR.read(dev, "PR")
local dg01PacM = WR.read(dev, "DG01_PAC")
local dg02PacM = WR.read(dev, "DG02_PAC")
local expGen1Now = 0
local expGen2Now = 0
local gridOut = 0

if is_nan(pr) then pr = 0 end
if is_nan(pac) then pac = 0 end
if is_nan(prDay) then prDay = 0 end
if is_nan(dg01PacM) then dg01PacM = 0 end
if is_nan(dg02PacM) then dg02PacM = 0 end

commStatus = commStatus or {}
commStatus[dev] = commStatus[dev] or {DayOn=WR.read(dev, "COMMUNICATION_DAY_ONLINE"), DayOff=WR.read(dev, "COMMUNICATION_DAY_OFFLINE"), HourOn=0, HourOff=0, ts=now}
if is_nan(commStatus[dev].DayOn) then commStatus[dev].DayOn = 0 end
if is_nan(commStatus[dev].DayOff) then commStatus[dev].DayOff = 0 end
local pac = WR.read(dev, "PAC")
startTime = startTime or {}
startTime[dev] = startTime[dev] or {ts=WR.read(dev, "START_TIME")}
if is_nan(startTime[dev].ts) then startTime[dev].ts = 0 end
stopTime = stopTime or {}
stopTime[dev] = stopTime[dev] or {ts=WR.read(dev, "STOP_TIME"), againStart=0}
if is_nan(stopTime[dev].ts) then stopTime[dev].ts = 0 end
if is_nan(stopTime[dev].againStart) then stopTime[dev].againStart = 0 end
gridAvailability = gridAvailability or {}
gridAvailability[dev] = gridAvailability[dev] or {ts=now, tson=WR.read(dev, "GRID_ON"), tsoff=WR.read(dev, "GRID_OFF")}
if is_nan(gridAvailability[dev].tson) then gridAvailability[dev].tson = 0 end
if is_nan(gridAvailability[dev].tsoff) then gridAvailability[dev].tsoff = 0 end
opTime = opTime or {}
opTime[dev] = opTime[dev] or {ts=now, tson=WR.read(dev, "OPERATIONAL_TIME")}
if is_nan(opTime[dev].tson) then opTime[dev].tson = 0 end


------------------------ Meter Calculation Start ------------------------------

local pac = WR.read(dev, "PAC")
local uac1 = WR.read(dev, "UAC1")
local uac2 = WR.read(dev, "UAC2")
local uac3 = WR.read(dev, "UAC3")
local uac12 = WR.read(dev, "UAC12")
local uac23 = WR.read(dev, "UAC23")
local uac31 = WR.read(dev, "UAC31")
local iac_1 = WR.read(dev, "IAC1")
local iac_2 = WR.read(dev, "IAC2")
local iac_3 = WR.read(dev, "IAC3")


if is_nan(uac1) then uac1 = 0 end
if is_nan(uac2) then uac2 = 0 end
if is_nan(uac3) then uac3 = 0 end
if is_nan(uac12) then uac12 = 0 end
if is_nan(uac23) then uac23 = 0 end
if is_nan(uac31) then uac31 = 0 end
if is_nan(iac_1) then iac_1 = 0 end
if is_nan(iac_2) then iac_2 = 0 end
if is_nan(iac_3) then iac_3 = 0 end

WR.setProp(dev, "UACLN", (uac1+uac2+uac3)/3)
WR.setProp(dev, "UAC", (uac12+uac23+uac31)/3)
WR.setProp(dev, "IAC", (iac_1+iac_2+iac_3))

local Gridpac = WR.read(dev, "GRID_PAC")
local Dg1pac = WR.read(dev, "DG1_PAC")
local Dg2pac = WR.read(dev, "DG2_PAC")
local GrideaiDay = WR.read(dev, "GRID_EAI_DAY")
local Dg1eaeDay = WR.read(dev, "DG1_EAE_DAY")
local Dg2eaeDay = WR.read(dev, "DG2_EAE_DAY")
local Grideai = WR.read(dev, "GRID_EAI")
local Grideae = WR.read(dev, "GRID_EAE")
local GrideaeDay = WR.read(dev, "GRID_EAE_DAY")
local Dg1eae = WR.read(dev, "DG1_EAE")
local Dg2eae = WR.read(dev, "DG2_EAE")

if is_nan(Gridpac) then Gridpac = 0 end
if is_nan(Dgpac) then Dgpac = 0 end
if is_nan(Dg1pac) then Dg1pac = 0 end
if is_nan(Dg1eaeDay) then Dg1eaeDay = 0 end
if is_nan(Dg1eae) then Dg1eae = 0 end
if is_nan(GrideaiDay) then GrideaiDay = 0 end
if is_nan(DgeaeDay) then DgeaeDay = 0 end
if is_nan(Grideai) then Grideai = 0 end
if is_nan(Grideae) then Grideae = 0 end
if is_nan(GrideaeDay) then GrideaeDay = 0 end
if is_nan(Dgeae) then Dgeae = 0 end

local PlantLoad = (pac + Gridpac + Dg1pac+Dg2pac)
local PlantLoadDay = (eaeDay + (GrideaiDay-GrideaeDay) + Dg1eaeDay+Dg2eaeDay)
local PlantLoadLifetime = (eae + (Grideai-Grideae) + Dg1eae+Dg2eae)

WR.setProp(dev, "PLANT_LOAD", PlantLoad)
WR.setProp(dev, "PLANT_LOAD_DAY", PlantLoadDay)
WR.setProp(dev, "PLANT_LIFETIME_LOAD", PlantLoadLifetime)
------------------------ Meter Calculation End --------------------------------

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


--------------------- Plant Operational Time Calculation Start ----------------

local uac1 = WR.read("SN:GRID_EM", "UAC1")
if (uac1 > 200) then
 opTime[dev].tson = opTime[dev].tson + (now - opTime[dev].ts)
 if (startTime[dev].ts == 0) then
  startTime[dev].ts = ((hour * 60 * 60) + (min * 60) + sec)
 end
 stopTime[dev].againStart = 1
elseif ((uac1 <= 200) and  (startTime[dev].ts ~= 0) and ((stopTime[dev].againStart == 1) or (stopTime[dev].ts == 0))) then
 stopTime[dev].ts = ((hour * 60 * 60) + (min * 60) + sec)
 stopTime[dev].againStart = 0
end
opTime[dev].ts = now
WR.setProp(dev, "START_TIME", startTime[dev].ts)
WR.setProp(dev, "STOP_TIME", stopTime[dev].ts)
WR.setProp(dev, "OPERATIONAL_TIME", opTime[dev].tson)
local operationaltime = WR.read(dev, "OPERATIONAL_TIME")
WR.setProp(dev, "OPERATIONAL_HOUR", (operationaltime/3600))

--------------------- Plant Operational Time Calculation End ------------------

------------------------ PR Calculation Start ---------------------------------

local prDayNow = (((eaeDay) / settings.PLANT.dcCapacity) / radiationCum) * 100
if ((is_nan(prDayNow)) or (prDayNow < 0) or (prDayNow > 100)) then
 prDayNow = prDay
end
WR.setProp(dev, "PR_DAY", prDayNow)

if(radiation >= (settings.PLANT.prRealRadSetpoint)) then   -- if 250 & ABOVE
 local prNow = (((pac * 1000) / settings.PLANT.dcCapacity) / radiation) * 100
 if((is_nan(prNow)) or (prNow < 0) or (prNow > 100)) then
  prNow = pr
 end
 WR.setProp(dev, "PR", prNow)
else
 WR.setProp(dev, "PR", 0/0)
end

------------------------ PR Calculation End -----------------------------------

--------------------- Generation Loss Calculation ------------------------------

eaeDayNoRad = eaeDayNoRad or {}
eaeDayNoRad[dev] = eaeDayNoRad[dev] or {day=WR.read(dev, "EAE_DAY_NO_RAD"), last=eaeDay}
if (is_nan(eaeDayNoRad[dev].day)) then eaeDayNoRad[dev].day = 0 end

if is_nan(radiation) then
 radiation = 0
 eaeDayNoRad[dev].day = eaeDayNoRad[dev].day + (eaeDay - eaeDayNoRad[dev].last)
end
eaeDayNoRad[dev].last = eaeDay
WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)

expGen1Now = ((settings.PLANT.dcCapacity * radiation) / 1000)
expGen1Cum = expGen1Cum or {}
expGen1Cum[dev] = expGen1Cum[dev] or {ts=now, day=WR.read(dev, "EXP_GEN_CUM_1")}
if (is_nan(expGen1Cum[dev].day)) then expGen1Cum[dev].day = 0 end

expGen1Cum[dev].day = expGen1Cum[dev].day + (((now-expGen1Cum[dev].ts) * expGen1Now) / (60 * 60))
expGen1Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
WR.setProp(dev, "EXP_GEN", expGen1Now)

expGen2Now = ((settings.PLANT.dcCapacity * radiation) / 1000)
expGen2Cum = expGen2Cum or {}
expGen2Cum[dev] = expGen2Cum[dev] or {ts=now, day=WR.read(dev, "EXP_GEN_CUM_2")}
if (is_nan(expGen2Cum[dev].day)) then expGen2Cum[dev].day = 0 end

genLossCum = genLossCum or {}
genLossCum[dev] = genLossCum[dev] or {ts=now, day=WR.read(dev, "GEN_LOSS_CUM")}
if (is_nan(genLossCum[dev].day)) then genLossCum[dev].day = 0 end

local expGen80 = 0
local genLoss = 0

if (((radiation > 260) and (pac < 1)) or ((dg01PacM > 1) or (dg02PacM > 1))) then
 expGen80 = (((settings.PLANT.dcCapacity * radiation) / 1000) * 0.8)
 genLoss = (expGen80 - pac)
 gridOut = 1
 if (genLoss < 0) then genLoss = 0 end

 genLossCum[dev].day = genLossCum[dev].day + (((now-genLossCum[dev].ts) * genLoss) / (60 * 60))

 expGen2Now = 0
end

genLossCum[dev].ts = now
WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
WR.setProp(dev, "GEN_LOSS", genLoss)

expGen2Cum[dev].day = expGen2Cum[dev].day + (((now-expGen2Cum[dev].ts) * expGen2Now) / (60 * 60))
expGen2Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)

------------------------ Generation Loss Calculation ---------------------------------

------------------ PV Generation calculation while DG run start --------------

local dgstart = WR.read (dev, "DG_START")
if (is_nan(dgstart)) then dgstart = 0 end
WR.setProp(dev, "DG_START", dgstart)

if (((dg01PacM > 1) or (dg02PacM > 1)) and (dgstart ~= 1) and (not(is_nan(eae)))) then         ----- PV EAE START DURING DG ON
  eaedg = eae                                                                ----- PV EAE
  dgstart = 1
  WR.setProp(dev, "PVDG_GEN_START", eaedg)
  elseif (((dg01PacM < 1) or (dg02PacM < 1)) and (dgstart == 1)) then
    dgstart = 0
  elseif (((dg01PacM < 1) or (dg02PacM < 1)) and (dgstart ~= 1)) then
    dgstart = 0
  elseif (dgstart == 1) then
    local pvdggenstart = WR.read(dev, "PVDG_GEN_START")
        pvdggenstart = pvdggenstart
        WR.setProp(dev, "PVDG_GEN_START", pvdggenstart)
        dgstart = dgstart
  end
WR.setProp(dev, "DG_START", dgstart)

if (((dg01PacM > 1) or (dg02PacM > 1 )) and (not(is_nan(eae)))) then               -------- PV Gen While Dg ON
   local pvdggenref = WR.read (dev, "PVDG_GEN_REF")
   if (is_nan(pvdggenref)) then pvdggenref = 0 end
   WR.setProp(dev, "PVDG_GEN_REF", pvdggenref)
   local pveaestart = WR.read(dev, "PVDG_GEN_START")
   actualeae = eae
   pvdgtotalgen = actualeae - pveaestart
   WR.setProp(dev, "PVDG_TOTAL_GEN", (pvdgtotalgen + pvdggenref))
else
   local pvdgtotalgen1 = WR.read(dev, "PVDG_TOTAL_GEN")
   pvdgtotalgen1 = pvdgtotalgen1
   WR.setProp(dev, "PVDG_TOTAL_GEN", pvdgtotalgen1)
   pvdggenref = pvdgtotalgen1
   WR.setProp(dev, "PVDG_GEN_REF", pvdggenref)
end

local pvdgeae = WR.read(dev, "PVDG_TOTAL_GEN")
if pvdgeae ~= 0 then WR.setProp(dev, "PVDG_GEN", pvdgeae) end

------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 startTime[dev].ts = 0
 stopTime[dev].ts = 0
 opTime[dev].tson = 0
end
checkMidnight[dev].ts = now 

------------------------ Check Midnight End -----------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 prDay = 0
 expGen1Cum[dev].day = 0
 expGen2Cum[dev].day = 0
 genLossCum[dev].day = 0
 eaeDayNoRad[dev].day = 0
 eaeDayNoRad[dev].last = 0
 startTime[dev].ts = 0
 stopTime[dev].ts = 0
 gridAvailability[dev].tson = 0
 gridAvailability[dev].tsoff = 0
 opTime[dev].tson = 0
 pacOld = 0
 prDay = 0
 prMin = 0
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
 commStatus[dev].DayOn = 0
 commStatus[dev].DayOff = 0
 WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
 WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)
 WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
 WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)
end
if (os.date("*t", checkMidnight[dev].ts).hour < os.date("*t", now).hour) then
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
 end
checkMidnight[dev].ts = now

--if ((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) then
if (((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) or ((os.date("*t", now).hour == 0) and (os.date("*t", now).min < 01))) then
 WR.setProp(dev, "START_TIME", 0)
 WR.setProp(dev, "STOP_TIME", 0)
 WR.setProp(dev, "OPERATIONAL_TIME", 0)
 WR.setProp(dev, "OPERATIONAL_HOUR", 0)
end

------------------------ Check Midnight End -----------------------------------


