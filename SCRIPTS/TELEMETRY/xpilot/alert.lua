
local wavFile = {
  ["percent"] = "percent",
  ["battery"] = "battery",
  ["curr"] = {
    ["ovrrng"] = "highcurr",
  },
  ["gps"] = {
    ["deg"] = "gpsdeg",
    ["fix"] = "gpsfix",
  },
  ["fm"] = {
    -- APM Flight Modes
    [ 0] = "fm0",
    [ 1] = "fm1",
    [ 2] = "fm2",
    [ 3] = "fm3",
    [ 4] = "fm4",
    [ 5] = "fm5",
    [ 6] = "fm6",
    [ 7] = "fm7",
    [ 8] = "fm8",
    [ 9] = "fm9",
    [10] = "fm10",
    [11] = "fm11",
    [12] = "fm12",
    [13] = "fm13",
    [14] = "fm14",
    [15] = "fm15",
    [16] = "fm16",
    [17] = "fm17",
    -- PX4 Flight Modes
    [18] = "fm18",
    [19] = "fm19",
    [20] = "fm20",
    [21] = "fm21",
    [22] = "fm22",
    [23] = "fm23",
    [24] = "fm24",
    [25] = "fm25",
    [26] = "fm26",
    [27] = "fm27",
    [28] = "fm28",
    [29] = "fm29",
    [30] = "fm30",
    [31] = "fm31",
    [32] = "fmchange",
  },
}

--local wavUnits = { ["percent"] = 13 }

local battAlertLevel = { [1] = 50, [2] = 30, [3] = 20, [4] = 15, [5] = 10, [6] = 5, [7] = 0 }

local tic = nil
local data = nil

local function battIndex(val)
  local idx
  for i,v in ipairs(battAlertLevel) do
    if val > v then
      idx = i
      break
    end
  end
  return idx
end

local function alertBatt(alertData, xpilot)
  local fuel = xpilot.telem.batt.fuel()
  if fuel and fuel > 0 then
    local idx = battIndex(fuel)
    alertData = alertData or { ["idx"] = idx }
    --print("Value: "..(fuel and fuel or -1).." Index: "..idx.." Prev: "..(alertData and alertData.idx or -1).." Thresh: "..(alertData and alertData.idx > 1 and (battLevels[alertData.idx-1] + 5) or -1))
    if idx > alertData.idx or (alertData.idx > 1 and fuel > (battAlertLevel[alertData.idx-1] + 5)) then
      if idx > alertData.idx then
        local dir = xpilot.env.dir.wav
        num = 5 * xpilot.lib.math.round(fuel / 5)
        playFile(dir..wavFile.battery..".wav")
        playFile(dir..num..".wav")
        playFile(dir..wavFile.percent..".wav")
        collectgarbage()
        collectgarbage()
      end
      alertData.idx = idx
    end
  end
  return alertData
end

local function alertCurr(alertData, xpilot)
  local ITotal = xpilot.telem.batt.ITotal()
  local cfg = xpilot.cfg
  local batt = cfg and cfg.get("batt")
  local IMax = batt and (batt.cval * batt.capa) or 0
  if ITotal and ITotal > IMax then
    playFile(xpilot.env.dir.wav..wavFile.curr.ovrrng..".wav")
    collectgarbage()
    collectgarbage()
  end
  return alertData
end

local function alertGPS(alertData, xpilot)
  local fix3d = xpilot.telem.gps.fix3d() 
  alertData = alertData or { ["fix3d"] = fix3d }
  if alertData.fix3d ~= fix3d then
    playFile(xpilot.env.dir.wav..(fix3d and wavFile.gps.fix or wavFile.gps.deg)..".wav")
    alertData.fix3d = fix3d
    collectgarbage()
    collectgarbage()
  end
  return alertData
end

local function alertFM(alertData, xpilot)
  local _,fm = xpilot.telem.flightMode()
  alertData = alertData or { ["fm"] = fm }
  if alertData.fm ~= fm then
    local f = fm >= 0 and fm ~= 31 and (wavFile.fm[fm] or wavFile.fm[32--[[change]]])
    if f then 
      playFile(xpilot.env.dir.wav..f..".wav")
      collectgarbage()
      collectgarbage()
    else
      local cfg = xpilot.cfg
      local notify = cfg and cfg.get("telem","notify")
      if not notify or notify > 1 then
        playFile(xpilot.env.dir.wav..wavFile.fm[31--[[no telem]]]..".wav")
        collectgarbage()
        collectgarbage()
      end
    end
    alertData.fm = fm
  end
  return alertData
end

local alertHandler = {
  alertBatt,
  alertCurr,
  alertGPS,
  alertFM,
}

local function init(xpilot, ...)
  local ticInit = xpilot.lib.tic.init
  local tics = {
    ["upd"] =  2--[[Hz]],
  }
  tic = {}
  local now = xpilot.tic
  for i,v in pairs(tics) do
    tic[i] = ticInit(v, now)
  end
  data = {}
end

local function exit(xpilot, ...)
  local clearTable = xpilot.lib.clearTable
  tic = clearTable(tic)
  data = clearTable(data)
end

local function background(xpilot, ...)
  if xpilot.telem and xpilot.cfg and xpilot.lib.tic.update(tic.upd, xpilot.tic) then
    for i,v in pairs(alertHandler) do
      data[i] = v(data[i], xpilot)
    end
  end
end

return {
  init = init,
  exit = exit,
  background = background,
}
