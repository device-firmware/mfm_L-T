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

function SUM(meter1, meter2, targetmeter, targetmeter1, val, sumval)
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0 end

 WR.setProp(targetmeter, sumval, value1+value2)
 WR.setProp(targetmeter1, sumval, value1+value2)
end

function AVG(meter1, meter2, targetmeter, targetmeter1, val, avgval)
 local cnt = 2
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0; cnt = cnt - 1 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0; cnt = cnt - 1 end

 if cnt > 0 then
  WR.setProp(targetmeter, avgval, (value1+value2)/cnt)
  WR.setProp(targetmeter1, avgval, (value1+value2)/cnt)
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
 --CHECKDATATIME(dev, now, "ZE_GEN_LOSS_CUM")
 CHECKDATATIME(dev, now, "EAE_DAY_NO_RAD")
end
--print ("dcCapacity = ", settings.BLOCK.dcCapacity)

------------------------ Read Setpoints End -----------------------------------

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
local genlossDay = WR.read(dev, "GEN_LOSS_CUM")


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

if devS=="EM01" then
 local deviceIn1 = "SN:EM01"
 local deviceIn2 = "SN:EM02"
 local deviceOut = "SN:EM01"
 local deviceOut1 = "SN:EM02"
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "PAC",           "TOTAL_PAC")
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "QAC",           "TOTAL_QAC")
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "SAC",           "TOTAL_SAC")
 AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "FAC",           "TOTAL_FAC")
 AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "UAC",           "TOTAL_UAC")
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "IAC",           "TOTAL_IAC")
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "EAE",           "TOTAL_EAE")
 SUM(deviceIn1, deviceIn2, deviceOut, deviceOut1, "EAE_DAY",       "TOTAL_EAE_DAY")
 AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "PF",            "TOTAL_PF")
 --AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "SPECIFIC_YIELD","TOTAL_SPECIFIC_YIELD")
 AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "PR",            "TOTAL_PR")
 AVG(deviceIn1, deviceIn2, deviceOut, deviceOut1, "PR_DAY",        "TOTAL_PR_DAY")
end

------------------------ Meter Calculation End --------------------------------

------------------------ Read Required Data Start -----------------------------

local totalpac = WR.read(dev, "TOTAL_PAC")
local pac = WR.read(dev, "PAC")
local eaeDay = WR.read(dev, "EAE_DAY")
local radiationCum = WR.read(dev, "SOLAR_RADIATION_CUM")
local radiation = WR.read(dev, "RADIATION")
local prDay = WR.read(dev, "PR_DAY")
local pr = WR.read(dev, "PR")
local dg01PacM = WR.read(dev, "DG01_PAC")
local dg02PacM = WR.read(dev, "DG02_PAC")
local ze01PacM = WR.read(dev, "ZE_PAC")
local expGen1Now = 0
local expGen2Now = 0
local gridOut = 0

if is_nan(totalpac) then totalpac = 0 end
if is_nan(pr) then pr = 0 end
if is_nan(pac) then pac = 0 end
if is_nan(prDay) then prDay = 0 end
if is_nan(dg01PacM) then dg01PacM = 0 end
if is_nan(dg02PacM) then dg02PacM = 0 end
if is_nan(ze01PacM) then ze01PacM = 0 end

------------------------ Read Required Data End -------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------

------------------------ PR Calculation Start ---------------------------------

local prDayNow = (((eaeDay + (genlossDay/2)) / settings.EM[devS].dcCapacity) / radiationCum) * 100
if ((is_nan(prDayNow)) or (prDayNow < 0) or (prDayNow > 100)) then
 prDayNow = prDay
end
WR.setProp(dev, "PR_DAY", prDayNow)

if(radiation >= (settings.EM[devS].prRealRadSetpoint)) then   -- if 250 & ABOVE
 local prNow = (((pac * 1000) / settings.EM[devS].dcCapacity) / radiation) * 100
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

if (radiation > 25) then
expGen1Now = ((settings.PLANT.dcCapacity * radiation) / 1000)
end
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

zegenLossCum = zegenLossCum or {}
zegenLossCum[dev] = zegenLossCum[dev] or {ts=now, day=WR.read(dev, "ZE_GEN_LOSS_CUM")}
if (is_nan(zegenLossCum[dev].day)) then zegenLossCum[dev].day = 0 end

local expGen80 = 0
local genLoss = 0
local zegenLoss = 0

if ((radiation > 25) and ((dg01PacM > 1) or (dg02PacM > 1) or (ze01PacM < 20))) then
 expGen80 = (((settings.PLANT.dcCapacity * radiation) / 1000) * 0.8)
 genLoss = (expGen80 - totalpac)
 gridOut = 1
 if (genLoss < 0) then genLoss = 0 end

 genLossCum[dev].day = genLossCum[dev].day + (((now-genLossCum[dev].ts) * genLoss) / (60 * 60))

 expGen2Now = 0
end

--[[if ((radiation > 25) and (totalpac < 1) and ((dg01PacM < 1) or (dg02PacM < 1)) and ((ze01PacM < 50) or (ze02PacM < 50))) then
 expGen80 = (((settings.PLANT.dcCapacity * radiation) / 1000) * 0.8)
 zegenLoss = (expGen80 - totalpac)
 gridOut = 1
 if (zegenLoss < 0) then zegenLoss = 0 end

 zegenLossCum[dev].day = zegenLossCum[dev].day + (((now-zegenLossCum[dev].ts) * zegenLoss) / (60 * 60))

 expGen2Now = 0
end --]]--

genLossCum[dev].ts = now
WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
WR.setProp(dev, "GEN_LOSS", genLoss)

--zegenLossCum[dev].ts = now
--WR.setProp(dev, "ZE_GEN_LOSS_CUM", zegenLossCum[dev].day)
--WR.setProp(dev, "ZE_GEN_LOSS", zegenLoss)

expGen2Cum[dev].day = expGen2Cum[dev].day + (((now-expGen2Cum[dev].ts) * expGen2Now) / (60 * 60))
expGen2Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)

------------------------ Generation Loss Calculation ---------------------------------


------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 prDay = 0
 expGen1Cum[dev].day = 0
 expGen2Cum[dev].day = 0
 genLossCum[dev].day = 0
 zegenLossCum[dev].day = 0
 eaeDayNoRad[dev].day = 0
 eaeDayNoRad[dev].last = 0
 WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
 WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)
 WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
 --WR.setProp(dev, "ZE_GEN_LOSS_CUM", zegenLossCum[dev].day)
 WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)
end
checkMidnight[dev].ts = now

------------------------ Check Midnight End -----------------------------------

