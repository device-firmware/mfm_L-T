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

-------------------------- Read Setpoints Start -------------------------------

if not(settings) then
 settings = ""
 --print ("Inside file loading")
 filePath = "/mnt/jffs2/dglog"
 fileName = filePath.."/"..anlagen_id.."_DG_LOG_EM_"..string.sub(now, 1, 10).."_4.csv"
 filePackts = now
end

--------------------------- Read setpoints End --------------------------------

------------------------ Define Function Start --------------------------------

-- function to log events in file
function logEvent(file, msg)
 file = io.open(file,"a")
 now = socket.gettime()
 if file~=nil then
  file:write(os.date("%a %b %d %Y %X",currTime)..":"..string.sub(now*1000, 11, 13).." "..msg.."\n")
 end
 file:close()
end

function logCsv(file, msg)
 file1 = io.open(file,"r")
 if file1 == nil then
  fileName = filePath.."/"..anlagen_id.."_DG_LOG_EM_"..string.sub(now, 1, 10).."_4.csv"
  file = fileName
  file1 = io.open(file,"a")
  file1:write(anlagen_id..",SN:DG_LOG_EM,DG_LOG,0.0.0.0,4".."\n")
  -- log format ts, ts_ms, case, dg01Pac, pvPac, inv1Pac, inv2Pac, inv3Pac, pacLimit, gridConnSt, pacLimitSet, gridConnSet
  file1:write("TS,TS_MS,CASE,DG,DG01_PAC,DG02_PAC,PV_PAC,PAC_LIMIT,GRID_CONNECT,PAC_LIMIT_WRITE,GRID_CONNECT_WRITE".."\n")
 end
 file1:close()

 file = io.open(file,"a")
 now = socket.gettime()
 if file~=nil then
  file:write(string.sub(now, 1, 10)..","..now..","..msg.."\n")
 end
 file:close()
end

------------------------- Define Function End ---------------------------------

------------------------- Pack CSV For Portal Start ---------------------------

if (now > (filePackts + 300)) then
 os.execute("cd "..filePath.."; for f in *.csv; do mv -- \"$f\" \"${f%}.unsent\"; done")
 fileName = filePath.."/"..anlagen_id.."_DG_LOG_EM_"..string.sub(now, 1, 10).."_4.csv"
 filePackts = now
end

-------------------------- Pack CSV For Portal End ----------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

local pac = WR.read(dev, "PAC")

dgEmPac = dgEmPac or {}
dgEmPac[dev] = dgEmPac[dev] or {v=pac}

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
 local pacRound = pac --tonumber(string.format("%.0f", pac))
 if (is_nan(pac)) then pacRound = "" end
 if (dgEmPac[dev].v ~= pacRound) then
  dgEmPac[dev].v = pacRound
  -- log format case, dg01Pac, dg02Pac, pvPac, pacLimit, gridConnSt, pacLimitSet, gridConnSet
  if (dev == "SN:DG1_EM") then
   logCsv(fileName,"0"..",".."1"..","..pacRound..",,,,,,")
  elseif (dev == "SN:DG2_EM") then
   logCsv(fileName,"0"..",".."2"..","..""..","..pacRound..",,,,,")
  end
 end
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------



