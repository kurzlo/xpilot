local xLib = nil
local xCfg = nil

local flightModeStr = {}
-- APM Flight Modes
--[[flightModeStr[ 0] = "Stabilize"
flightModeStr[ 1] = "Acro"
flightModeStr[ 2] = "Alt Hold"
flightModeStr[ 3] = "Auto"
flightModeStr[ 4] = "Guided"
flightModeStr[ 5] = "Loiter"
flightModeStr[ 6] = "RTL"
flightModeStr[ 7] = "Circle"
flightModeStr[ 8] = "Invalid Mode"
flightModeStr[ 9] = "Landing"
flightModeStr[10] = "Optic Loiter"
flightModeStr[11] = "Drift"
flightModeStr[12] = "Invalid Mode"
flightModeStr[13] = "Sport"
flightModeStr[14] = "Flip"
flightModeStr[15] = "Auto Tune"
flightModeStr[16] = "Pos Hold"
flightModeStr[17] = "Brake"]]
-- PX4 Flight Modes
flightModeStr[18] = "Manual"
flightModeStr[19] = "Acro"
flightModeStr[20] = "Stabilized"
flightModeStr[21] = "RAttitude"
flightModeStr[22] = "Position"
flightModeStr[23] = "Altitude"
flightModeStr[24] = "Offboard"
flightModeStr[25] = "Takeoff"
flightModeStr[26] = "Pause"
flightModeStr[27] = "Mission"
flightModeStr[28] = "RTL"
flightModeStr[29] = "Landing"
flightModeStr[30] = "Follow"
-- N/A
flightModeStr[31] = "No Telemetry"

local navStateStr = {
  [ 0] = "Manual",
  [ 1] = "Altitude",
  [ 2] = "Position",
  [ 3] = "Mission",
  [ 4] = "Loiter",
  [ 5] = "Return",
  [ 6] = "RC recover",
  [ 7] = "Return GS", --return ground station
  [ 8] = "Engine fail", --landing failed due to engine
  [ 9] = "GPS fail",
  [10] = "Acro",
  [11] = "Unused",
  [12] = "Descend",
  [13] = "Term",
  [14] = "Offboard",
  [15] = "Stabilze",
  [16] = "RAttitude",
  [17] = "Takeoff",
  [18] = "Auto land",
  [19] = "Auto follow",
  [20] = "Prec land",
  [21] = "Orbit",
}

local gpsStateStr = {
  [1] = "N/A",
  [2] = "2D",
  [3] = "3D",
  [4] = "DG", --differential GPS
}

local battTable = {
  { ["v"] = 3.3, ["p"] =   0, ["d"] = nil, },
  { ["v"] = 3.6, ["p"] =   5, ["d"] = nil, },
  { ["v"] = 3.7, ["p"] =  15, ["d"] = nil, },
  { ["v"] = 4.0, ["p"] =  85, ["d"] = nil, },
  { ["v"] = 4.2, ["p"] = 100, ["d"] = nil, },
}

local data = {}
data.tic = nil
data.logFile = nil
data.telem = {
  [ 1] = { ["tag"] = "RxBt", ["id"] = nil, ["val"] = nil },
  [ 2] = { ["tag"] = "RSSI", ["id"] = nil, ["val"] = nil },
  [ 3] = { ["tag"] = "VSpd", ["id"] = nil, ["val"] = nil },
  [ 4] = { ["tag"] = "GPS",  ["id"] = nil, ["val"] = nil },
  [ 5] = { ["tag"] = "Tmp2", ["id"] = nil, ["val"] = nil }, --gps number of satellites/fix
  [ 6] = { ["tag"] = "Curr", ["id"] = nil, ["val"] = nil },
  [ 7] = { ["tag"] = "Alt",  ["id"] = nil, ["val"] = nil },
  [ 8] = { ["tag"] = "VFAS", ["id"] = nil, ["val"] = nil }, --battery voltage (sum)
  [ 9] = { ["tag"] = "Tmp1", ["id"] = nil, ["val"] = nil }, --flight mode
  [10] = { ["tag"] = "GSpd", ["id"] = nil, ["val"] = nil },
  [11] = { ["tag"] = "GAlt", ["id"] = nil, ["val"] = nil },
  [12] = { ["tag"] = "Date", ["id"] = nil, ["val"] = nil },
  [13] = { ["tag"] = "Fuel", ["id"] = nil, ["val"] = nil },
  [14] = { ["tag"] = "Hdg",  ["id"] = nil, ["val"] = nil },
  [15] = { ["tag"] = "Dist", ["id"] = nil, ["val"] = nil }, --distance from home
  [16] = { ["tag"] = "Ptch", ["id"] = nil, ["val"] = nil }, --pitch
  [17] = { ["tag"] = "Roll", ["id"] = nil, ["val"] = nil }, --roll
  [18] = { ["tag"] = "Yaw",  ["id"] = nil, ["val"] = nil }, --yaw
  --[19] = { ["tag"] = "5000", ["id"] = nil, ["val"] = nil }, --Nav state (+128)
  --[20] = { ["tag"] = "5001", ["id"] = nil, ["val"] = nil }, --GPS fix (same as TMP2)
}

local function init(...)
  xLib = xPilot.lib
  xCfg = xPilot.cfg
  local now = xPilot.tic
  local ticker = xLib.ticker;
  local initTicker = ticker.initRate_Hz
  local tickers = { "upd", "log" }
  local ticData = {}
  for _,v in pairs(tickers) do
    local rate = xCfg.get("telem", v.."Rate")
    ticData[v] = initTicker(rate, now) 
  end
  data.tic = ticData
  local telem = data.telem
  local getFieldInfo = xLib.telem.getFieldInfo
  for i,v in pairs(telem) do
    local f = getFieldInfo(v.tag)
    if f then
      telem[i].tag = f.name
      telem[i].id = f.id
    end
  end
  for i = 2, #battTable do
    local dv = battTable[i].v - battTable[i-1].v
    local dp = battTable[i].p - battTable[i-1].p
    battTable[i].d = dp / dv
  end
  return true
end

function exit(...)
  local logFile = data.logFile
  if logFile then
    xLib.io.close(logFile)
    data.logFile = nil
  end
  local exitTicker = xLib.ticker.exit
  local ticData = data.tic
  for i = 1, #ticData do
    exitTicker(ticData[i])
  end
  data.tic = nil
  return true
end

local delim = ";"

local function appendHeader(str, tag)
  if tag then
    if tag == "Date" then
      str = str.."year"..delim.."mon"..delim.."day"..delim.."hour"..delim.."min"..delim.."sec"..delim
    elseif tag == "GPS" then
      str = str.."lat"..delim.."lon"..delim
      --str = str.."pilot-lat"..delim.."pilot-lon"..delim
    else
      str = str..(type(tag) == "number" or tostring(tag) or tag)..delim
    end
  else
    str = str..delim
  end
  return str
end

local function appendValue(str, tag, val)
  if type(val) == "number" then
    str = str..delim..tostring(val)
  elseif type(val) == "string" then
    str = str..delim..val
  elseif type(val) == "table" then
    if tag == "Date" then
      str = str..(val.year and tostring(val.year) or "")..delim..(val.mon and tostring(val.mon) or "")..delim..(val.day and tostring(val.day) or "")..delim
      str = str..(val.hour and tostring(val.hour) or "")..delim..(val.min and tostring(val.min) or "")..delim..(val.sec and tostring(val.sec) or "")..delim
    elseif tag == "GPS" then
      str = str..(val.lat and tostring(val.lat) or "")..delim..(val.lon and tostring(val.lon) or "")..delim
      --str = str..(val["pilot-lat"] and tostring(val["pilot-lat"]))..delim..(val["pilot-lon"] and tostring(val["pilot-lon"]) or "")..delim
    else
      for _,v in pairs(val) do
        str = appendValue(str, tag, v)
      end
    end
  else
    str = str..delim
  end
  return str
end

local function background(...)
  local xCfg = xPilot.cfg
  local now = xPilot.tic
  local xTicker = xLib.ticker
  local updateTicker = xTicker.update
  local tickerRate_Hz = xTicker.rate_Hz
  local ticData = data.tic
  local updTicker = ticData.upd
  local logTicker = ticData.log
  local telem = data.telem
  if updateTicker(updTicker, now) then
    local getValue = xLib.telem.getValue
    for i,v in pairs(telem) do
      telem[i].val = v.id and getValue(v.id)
    end
    updTicker = tickerRate_Hz(updTicker, xCfg.get("telem", "updRate"))
  end
  if updateTicker(logTicker, now) then
    --local xMsg = xPilot.msg
    local rec = xCfg.get("telem", "rec")
    local xio = xLib.io
    local logFile = data.logFile
    if rec and rec > 1 then
      local tickerRate = xTicker.rate
      if not logFile then
        local xDate = xLib.date
        local dat = getDateTime()
        local dir = xPilot.env.dir.log
        local file = xLib.date.toFileName(dat, "telem.log")
        logFile = xio.open(dir..file, "w")
        if logFile then
          --xMsg.push("Logging enabled")
          xTicker.reset(logTicker, now)
          local ln = "#Timestamp"..delim
          for i = 1, #telem do
            ln = appendHeader(ln, telem[i].tag)
          end
          xio.write(logFile, ln.."\n")
        else
          --xMsg.push("Failed enable logging")
          xCfg.set("telem", "rec", 1)
        end
      end
      if logFile then
        local ln = tostring(logTicker.total)..delim
        for i = 1, #telem do
          ln = appendValue(ln, telem[i].tag, telem[i].val)
        end
        xio.write(logFile, ln.."\n")
      end
      logTicker = tickerRate_Hz(logTicker, xCfg.get("telem", "logRate"))
    else
      if logFile then
        xio.close(logFile)
        logFile = nil
        --xMsg.push("Logging disabled")
      end
    end
    data.logFile = logFile
  end
  return true
end

local function getItem(telem, tag)
  for i,_ in pairs(telem) do
    if telem[i].tag == tag then
      return telem[i].val, i
    end
  end
  return nil, nil
end

local function flightMode(idx)
  idx = idx or getItem(data.telem, "Tmp1")
  return idx and flightModeStr[idx] or "N/A", idx
end

local function navState(idx)
  idx = idx or getItem(data.telem, "5000")
  return idx and idx >= 128 and navStateStr[idx - 128] or "N/A"
end

local function gpsState()
  local val = getItem(data.telem, "Tmp2")
  local sats = val and val / 10 or 0
  local fix = val and val % 10 or 0
  return fix, sats
end

local function gpsFix(idx)
  idx = idx or gpsState()
  return idx and gpsStateStr[idx] or "N/A"
end

local function gps3d(idx)
  idx = idx or gpsState()
  return idx > 2
end

local function battLookup(val, tab)
  if val >= tab[#tab].v then
    val = tab[#tab].p
  elseif val <= tab[1].v then
    val = tab[1].p
  else
    for i = 2, #tab do
      if val < tab[i].v then
        val = tab[i-1].p + (val - tab[i-1].v) * tab[i].d
        break
      end
    end
  end
  return val
end

local function batteryTotalVoltage()
  local val = getItem(data.telem, "VFAS")
  return val or 0
end

local function batteryCellVoltage(val, cells)
  val = val or batteryTotalVoltage()
  cells = cells or xPilot.cfg.get("batt","cells")
  return (val or 0) / cells
end

local function batteryFuelPercent()
  local val = getItem(data.telem, "Fuel")
  return val or 0
end

local function batteryVoltagePercent(val)
  val = val or batteryCellVoltage()
  return battLookup(val, battTable)
end

local function actualCurrent()
  local val = getItem(data.telem, "Curr")
  return val or 0
end

local function currentPercent(val, capa, cmax)
  local cfg = xPilot.cfg.get("batt")
  capa = capa or cfg.capa
  cmax = cmax or cfg.cmax
  val = val or actualCurrent()
  val = 100 * val / (cmax * capa * 1e-3--[[mA->A]])
  val = (val < 0 and 0) or (val > 100 and 100) or val
  return val
end

local function rssiValue()
  local val = getItem(data.telem, "RSSI")
  return val or 0
end

local function distFromHome() --meters
  local val = getItem(data.telem, "Dist")
  return val or 0
end

local function gpsLatLon()
  local gps = getItem(data.telem, "GPS")
  if gps and type(gps) == "table" then
    return gps.lat or 0, gps.lon or 0
  else
    return 0, 0
  end
end

local function gpsAltitude()
  local val = getItem(data.telem, "GAlt")
  return val or 0
end

local function gpsSpeedOverGround()
  local val = getItem(data.telem, "GSpd")
  return val and val * 0.514444 --[[knots --> m/s]] or 0
end

local function gpsHeading()
  local val = getItem(data.telem, "Hdg")
  return val or 0
end

local function baroAltitude() --meters
  local val = getItem(data.telem, "Alt")
  return val or 0
end

local function baroRateOfClimb() 
  local val = getItem(data.telem, "VSpd")
  return val or 0
end


return {
  init=init,
  exit=exit,
  background=background,
  flightMode=flightMode,
  navState=navState,
  gpsState=gpsState,
  gpsFix=gpsFix,
  gps3d=gps3d,
  batteryCellVoltage=batteryCellVoltage,
  batteryFuelPercent=batteryFuelPercent,
  batteryVoltagePercent=batteryVoltagePercent,
  actualCurrent=actualCurrent,
  currentPercent=currentPercent,
  rssiValue=rssiValue,
  distFromHome=distFromHome,
  gpsLatLon=gpsLatLon,
  gpsAltitude=gpsAltitude,
  gpsSpeedOverGround=gpsSpeedOverGround,
  gpsHeading=gpsHeading,
  baroAltitude=baroAltitude,
  baroRateOfClimb=baroRateOfClimb,
}
