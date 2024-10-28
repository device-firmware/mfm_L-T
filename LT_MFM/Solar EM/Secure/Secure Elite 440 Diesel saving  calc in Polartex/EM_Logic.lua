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
end

--print ("dcCapacity = ", settings.BLOCK.dcCapacity)

------------------------ Read Setpoints End -----------------------------------

------------------------ Read Required Data Start -----------------------------

local pac = WR.read(dev, "PAC")
local eaeDay = WR.read(dev, "EAE_DAY")
local radiationCum = WR.read(dev, "SOLAR_RADIATION_CUM")
local radiation = WR.read(dev, "RADIATION")
local prDay = WR.read(dev, "PR_DAY")
local pr = WR.read(dev, "PR")
local eae = WR.read(dev, "EAE")
--local dg01PacM = WR.read(dev,"DG01_PAC")
local Gridpac = WR.read(dev, "GRID_PAC")
local dgPacM = WR.read(dev, "DG_PAC")
local GrideaiDay = WR.read(dev, "GRID_EAI_DAY")
local dgeaeDay = WR.read(dev, "DG_EAE_DAY")
local Grideai = WR.read(dev, "GRID_EAI")
local dgeae = WR.read(dev, "DG_EAE")
local expGen1Now = 0
local expGen2Now = 0
local gridOut = 0
local zegenLosstotal = 0
local zegenLossCum = 0
local genLosstotal = 0
local genLossCum = 0



if is_nan(pr) then pr = 0 end
if is_nan(pac) then pac = 0 end
if is_nan(prDay) then prDay = 0 end
if is_nan(dgPacM) then dgPacM = 0 end
if is_nan(zegenLosstotal) then zegenLosstotal = 0 end
if is_nan(zegenLossCum) then zegenLossCum = 0 end
if is_nan(genLosstotal) then genLosstotal = 0 end
if is_nan(genLossCum) then genLossCum = 0 end


if is_nan(Gridpac) then Gridpac = 0 end
if is_nan(dgPacM) then dgPacM = 0 end
if is_nan(GrideaiDay) then GrideaiDay = 0 end
if is_nan(dgeaeDay) then dgeaeDay = 0 end
if is_nan(Grideai) then Grideai = 0 end
if is_nan(dgeae) then dgeae = 0 end

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


------------------------ Meter Calculation Start ------------------------------

local pac = WR.read(dev, "PAC")
local eaeDay = WR.read(dev, "EAE_DAY")
local eae  = WR.read(dev, "EAE")
local uac1 = WR.read(dev, "UAC1")
local uac2 = WR.read(dev, "UAC2")
local uac3 = WR.read(dev, "UAC3")
local uac12 = WR.read(dev, "UAC12")
local uac23 = WR.read(dev, "UAC23")
local uac31 = WR.read(dev, "UAC31")
local iac_1 = WR.read(dev, "IAC1")
local iac_2 = WR.read(dev, "IAC2")
local iac_3 = WR.read(dev, "IAC3")
local pvdgeaeDay = WR.read(dev, "PVDG_GEN")

if is_nan(uac1) then uac1 = 0 end
if is_nan(uac2) then uac2 = 0 end
if is_nan(uac3) then uac3 = 0 end
if is_nan(uac12) then uac12 = 0 end
if is_nan(uac23) then uac23 = 0 end
if is_nan(uac31) then uac31 = 0 end
if is_nan(iac_1) then iac_1 = 0 end
if is_nan(iac_2) then iac_2 = 0 end
if is_nan(iac_3) then iac_3 = 0 end
if is_nan(pvdgeaeDay) then pvdgeaeDay = 0 end


WR.setProp(dev, "UACLN", (uac1+uac2+uac3)/3)
WR.setProp(dev, "UAC", (uac12+uac23+uac31)/3)
WR.setProp(dev, "IAC", (iac_1+iac_2+iac_3))

WR.setProp(dev, "PLANT_LOAD", (pac + Gridpac + dgPacM))
WR.setProp(dev, "PLANT_LOAD_DAY", (eaeDay + GrideaiDay + dgeaeDay))
WR.setProp(dev, "PLANT_LIFETIME_LOAD", (eae + Grideai + dgeae))


------------------------ Meter Calculation End --------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------

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

--[[-------------------- Generation Loss Calculation ------------------------------

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

if (((radiation > 25) and (pac < 1)) or (dgPacM > 1) ) then
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

------------------------ Generation Loss Calculation ----------------------]]-----------

------------------ PV Generation calculation while DG run start --------------

local dgstart = WR.read (dev, "DG_START")
if (is_nan(dgstart)) then dgstart = 0 end
WR.setProp(dev, "DG_START", dgstart)

if ((dgPacM > 1) and (dgstart ~= 1) and (not(is_nan(eae)))) then         ----- PV EAE START DURING DG ON
  eaedg = eae                                                                ----- PV EAE
  dgstart = 1
  WR.setProp(dev, "PVDG_GEN_START", eaedg)
  elseif ((dgPacM < 1) and (dgstart == 1)) then
    dgstart = 0
  elseif ((dgPacM < 1) and (dgstart ~= 1)) then
    dgstart = 0
  elseif (dgstart == 1) then
    local pvdggenstart = WR.read(dev, "PVDG_GEN_START")
        pvdggenstart = pvdggenstart
        WR.setProp(dev, "PVDG_GEN_START", pvdggenstart)
        dgstart = dgstart
  end
WR.setProp(dev, "DG_START", dgstart)

if ((dgPacM > 1) and (not(is_nan(eae)))) then               -------- PV Gen While Dg ON
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

------------------- PV Generation calculation while DG run End ------------------

------------------- Svaings Calculation Start -----------------------------------
local dieselcost = 70            --------- 1 litre Diesel cost
local unitgendiesel = 3.3        --------- Unit generation from 1 litre Diesel
local unitcostpv = 6             --------- Per unit cost PV

WR.setProp(dev, "FUEL_CONSUMED", (dgeae / unitgendiesel))
WR.setProp(dev, "FUEL_CONSUMED_DAY", (dgeaeDay / unitgendiesel))
WR.setProp(dev, "FUEL_SAVED", (pvdgeae / unitgendiesel))
WR.setProp(dev, "FUEL_SAVED_DAY", (pvdgeaeDay / unitgendiesel))
local fuelsave = WR.read(dev, "FUEL_SAVED")
if is_nan(fuelsave) then fuelsave = 0 end
WR.setProp(dev, "FUEL_SAVINGS_RS", (fuelsave * dieselcost))
local fuelsaveday = WR.read(dev, "FUEL_SAVED_DAY")
if is_nan(fuelsaveday) then fuelsaveday = 0 end
WR.setProp(dev, "FUEL_SAVINGS_DAY_RS", (fuelsaveday * dieselcost))
--WR.setProp(dev, "DG_DEEMED_GEN_COST", (genLosstotal[dev].total * unitcostpv))
--WR.setProp(dev, "DG_DEEMED_GEN_COST_DAY", (genLossCum[dev].day * unitcostpv))
WR.setProp(dev, "PVDG_GEN_COST", (pvdgeae * unitcostpv))
WR.setProp(dev, "PVDG_GEN_COST_DAY", (pvdgeaeDay * unitcostpv))
WR.setProp(dev, "PVDG_SAVINGS", ((fuelsave * dieselcost)  + (pvdgeae * unitcostpv))) -- +(genLosstotal[dev].total * unitcostpv) )
WR.setProp(dev, "PVDG_SAVINGS_DAY", ((fuelsaveday * dieselcost) + (pvdgeaeDay * unitcostpv))) -- +(genLossCum[dev].day * unitcostpv) + ))

--WR.setProp(dev, "PENALTY_SAVINGS", (zegenLosstotal[dev].total * unitcostpv))
--WR.setProp(dev, "PENALTY_SAVINGS_DAY", (zegenLossCum[dev].day * unitcostpv))
WR.setProp(dev, "PVZE_GEN_COST", (eae * unitcostpv))
WR.setProp(dev, "PVZE_GEN_COST_DAY", (eaeDay * unitcostpv))
WR.setProp(dev, "PVZE_SAVINGS", ( ((eae - pvdgeae) * unitcostpv))) --+ (zegenLosstotal[dev].total * unitcostpv)))
WR.setProp(dev, "PVZE_SAVINGS_DAY", ((eaeDay - pvdgeaeDay) * unitcostpv)) --+ (zegenLossCum[dev].day * unitcostpv)))

local pvdgsavings = WR.read(dev, "PVDG_SAVINGS")
if is_nan(pvdgsavings) then pvdgsavings = 0 end
local pvdgsavingsday = WR.read(dev, "PVDG_SAVINGS_DAY")
if is_nan(pvdgsavingsday) then pvdgsavingsday = 0 end
local pvzesavings = WR.read(dev, "PVZE_SAVINGS")
if is_nan(pvzesavings) then pvzesavings = 0 end
local pvzesavingsday = WR.read(dev, "PVZE_SAVINGS_DAY")
if is_nan(pvzesavingsday) then pvzesavingsday = 0 end
WR.setProp(dev, "TOTAL_SAVINGS", (pvdgsavings + pvzesavings))
WR.setProp(dev, "TOTAL_SAVINGS_DAY", (pvdgsavingsday + pvzesavingsday)
)

------------------- Svaings Calculation END -----------------------------------
