
local wavFile = {
  ["percent"] = "percent.wav",
  ["battery"] = "battery.wav",
  ["curr"] = {
    ["ovrrng"] = "highcurr.wav",
  },
  ["gps"] = {
    ["deg"] = "gpsdeg.wav",
    ["fix"] = "gpsfix.wav",
  },
  ["fm"] = {
    [18] = "fm18.wav",
    [19] = "fm19.wav",
    [20] = "fm20.wav",
    [21] = "fm21.wav",
    [22] = "fm22.wav",
    [23] = "fm23.wav",
    [24] = "fm24.wav",
    [25] = "fm25.wav",
    [26] = "fm26.wav",
    [27] = "fm27.wav",
    [28] = "fm28.wav",
    [29] = "fm29.wav",
    [30] = "fm30.wav",
    [31] = "fm31.wav",
    ["chg"] = "fmchange.wav",
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
        playFile(dir..wavFile.battery)
        playFile(dir..wavFile.dir..num..".wav")
        playFile(dir..wavFile.percent)
      end
      alertData.idx = idx
    end
  end
  return alertData
end

local function alertCurr(alertData, xpilot)
  local ITotal = xpilot.telem.batt.ITotal()
  local batt = xpilot.cfg.get("batt")
  if ITotal and ITotal > batt.cval * batt.capa then
    playFile(xpilot.env.dir.wav..wavFile.curr.ovrrng)
  end
  return alertData
end

local function alertGPS(alertData, xpilot)
  local fix3d = xpilot.telem.gps.fix3d() 
  alertData = alertData or { ["fix3d"] = fix3d }
  if alertData.fix3d ~= fix3d then
    playFile(xpilot.env.dir.wav..(fix3d and wavFile.gps.fix or wavFile.gps.deg))
    alertData.fix3d = fix3d
  end
  return alertData
end

local function alertFM(alertData, xpilot)
  local _,fm = xpilot.telem.flightMode()
  alertData = alertData or { ["fm"] = fm }
  if alertData.fm ~= fm then
    local f = fm > 0 and fm ~= 31 and (wavFile.fm[fm] or wavFile.fm.chg)
    if f then 
      playFile(xpilot.env.dir.wav..f)
    else
      local cfg = xpilot.cfg
      local notify = cfg and cfg.get("telem","notify")
      if not notify or notify > 1 then
        playFile(xpilot.env.dir.wav..wavFile.fm[31--[[no telem]]])
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
