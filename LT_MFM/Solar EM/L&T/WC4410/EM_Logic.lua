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
 CHECKDATATIME(dev, now, "ZE_GEN_LOSS_CUM")
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

local pac_EM = WR.read("SN:EM01", "PAC")
local pac_EM_2 = WR.read("SN:EM02", "PAC")
local eae_EM = WR.read("SN:EM01", "EAE_DAY")
local eae_EM_2 = WR.read("SN:EM02", "EAE_DAY")
local eae_1 = WR.read("SN:EM01", "EAE")
local eae_2 = WR.read("SN:EM02", "EAE")
local sac_1 = WR.read("SN:EM01", "SAC")
local sac_2 = WR.read("SN:EM02", "SAC")
local qac_1 = WR.read("SN:EM01", "QAC")
local qac_2 = WR.read("SN:EM02", "QAC")
local pf_1 = WR.read("SN:EM01", "PF")
local pf_2 = WR.read("SN:EM02", "PF")
local uac_1 = WR.read("SN:EM01", "UAC")
local uac_2 = WR.read("SN:EM02", "UAC")
local fac_1 = WR.read("SN:EM01", "FAC")
local fac_2 = WR.read("SN:EM02", "FAC")
local iac_1 = WR.read("SN:EM01", "IAC")
local iac_2 = WR.read("SN:EM02", "IAC")
local Pr_1 = WR.read("SN:EM01", "PR")
local Pr_2 = WR.read("SN:EM02", "PR")
local Prday_1 = WR.read("SN:EM01", "PR_DAY")
local Prday_2 = WR.read("SN:EM02", "PR_DAY")

if is_nan(pac_EM) then pac_EM = 0 end
if is_nan(pac_EM_2) then pac_EM_2 = 0 end
if is_nan(eae_EM) then eae_EM = 0 end
if is_nan(eae_EM_2) then eae_EM_2 = 0 end
if is_nan(sac_1) then sac_1 = 0 end
if is_nan(sac_2) then sac_2 = 0 end
if is_nan(eae_1) then eae_1 = 0 end
if is_nan(eae_2) then eae_2 = 0 end
if is_nan(qac_1) then qac_1 = 0 end
if is_nan(qac_2) then qac_2 = 0 end
if is_nan(pf_1) then pf_1 = 0 end
if is_nan(pf_2) then pf_2 = 0 end
if is_nan(fac_1) then fac_1 = 0 end
if is_nan(fac_2) then fac_2 = 0 end
if is_nan(Pr_1) then Pr_1 = 0 end
if is_nan(Pr_2) then Pr_2 = 0 end
if is_nan(uac_1) then uac_1 = 0 end
if is_nan(uac_2) then uac_2 = 0 end
if is_nan(iac_1) then iac_1 = 0 end
if is_nan(iac_2) then iac_2 = 0 end
if is_nan(Prday_1) then Prday_1 = 0 end
if is_nan(Prday_2) then Prday_2 = 0 end

WR.setProp(dev, "TOTAL_PR",  (Pr_1 + Pr_2)/2)
WR.setProp(dev, "TOTAL_PR_DAY",  (Prday_1 + Prday_2)/2)
WR.setProp(dev, "TOTAL_FAC",  (fac_1 + fac_2)/2)
WR.setProp(dev, "TOTAL_PF",  (pf_1 + pf_2)/2)
WR.setProp(dev, "TOTAL_PAC",  (pac_EM + pac_EM_2))
WR.setProp(dev, "TOTAL_EAE_DAY", (eae_EM + eae_EM_2))
WR.setProp(dev, "TOTAL_EAE", (eae_1 + eae_2))
WR.setProp(dev, "TOTAL_SAC", (sac_1 + sac_2))
WR.setProp(dev, "TOTAL_IAC", (iac_1 + iac_2))
WR.setProp(dev, "TOTAL_QAC", (qac_1 + qac_2))
WR.setProp(dev, "TOTAL_UAC",  (uac_1 + uac_2)/2)

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
local ze01PacM = WR.read(dev, "ZE01_PAC")
local ze02PacM = WR.read(dev, "ZE02_PAC")
local expGen1Now = 0
local expGen2Now = 0
local gridOut = 0

if is_nan(totalpac) then totalpac = 0 end
if is_nan(pr) then pr = 0 end
if is_nan(pac) then pac = 0 end
if is_nan(prDay) then prDay = 0 end
if is_nan(dg01PacM) then dg01PacM = 0 end
if is_nan(dg02PacM) then dg02PacM = 0 end

------------------------ Read Required Data End -------------------------------


------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 prDay = 0
 expGen1Cum[dev].day = 0
 expGen2Cum[dev].day = 0
 genLossCum[dev].day = 0
 eaeDayNoRad[dev].day = 0
 eaeDayNoRad[dev].last = 0
 WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
 WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)
 WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
 WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)
end
checkMidnight[dev].ts = now

------------------------ Check Midnight End -----------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------

------------------------ PR Calculation Start ---------------------------------

local prDayNow = (((eaeDay) / settings.EM[devS].dcCapacity) / radiationCum) * 100
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

zegenLossCum = zegenLossCum or {}
zegenLossCum[dev] = zegenLossCum[dev] or {ts=now, day=WR.read(dev, "ZE_GEN_LOSS_CUM")}
if (is_nan(zegenLossCum[dev].day)) then zegenLossCum[dev].day = 0 end

local expGen80 = 0
local genLoss = 0
local zegenLoss = 0

if (((radiation > 25) and (totalpac < 1)) or ((dg01PacM > 1) or (dg02PacM > 1))) then
 expGen80 = (((settings.PLANT.dcCapacity * radiation) / 1000) * 0.8)
 genLoss = (expGen80 - totalpac)
 gridOut = 1
 if (genLoss < 0) then genLoss = 0 end

 genLossCum[dev].day = genLossCum[dev].day + (((now-genLossCum[dev].ts) * genLoss) / (60 * 60))

 expGen2Now = 0
end

if (((radiation > 25) and (totalpac < 1)) or ((ze01PacM < 50) or (ze02PacM < 50))) then
 expGen80 = (((settings.PLANT.dcCapacity * radiation) / 1000) * 0.8)
 zegenLoss = (expGen80 - totalpac)
 gridOut = 1
 if (zegenLoss < 0) then zegenLoss = 0 end

 zegenLossCum[dev].day = zegenLossCum[dev].day + (((now-zegenLossCum[dev].ts) * zegenLoss) / (60 * 60))

 expGen2Now = 0
end

genLossCum[dev].ts = now
WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
WR.setProp(dev, "GEN_LOSS", genLoss)

zegenLossCum[dev].ts = now
WR.setProp(dev, "ZE_GEN_LOSS_CUM", zegenLossCum[dev].day)
WR.setProp(dev, "ZE_GEN_LOSS", zegenLoss)

expGen2Cum[dev].day = expGen2Cum[dev].day + (((now-expGen2Cum[dev].ts) * expGen2Now) / (60 * 60))
expGen2Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)

------------------------ Generation Loss Calculation ---------------------------------
