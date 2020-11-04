local xLib = nil
local xCfg = nil

local wavFiles = {
  ["dir"] = xPilot.env.dir.wav,
  ["percent"] = xPilot.env.dir.wav.."percent.wav",
  ["battery"] = xPilot.env.dir.wav.."battery.wav",
  ["curr"] = {
    ["ovrrng"] = xPilot.env.dir.wav.."highcurr.wav",
  },
  ["gps"] = {
    ["deg"] = xPilot.env.dir.wav.."gpsdeg.wav",
    ["fix"] = xPilot.env.dir.wav.."gpsfix.wav",
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
local wavUnits = { ["percent"] = 13 }

local settings = {
  ["tic"] = {
    ["upd"] = 1,
    ["curr"] = 2,
  },
  ["batt"] = {
    ["levels"] = { [1] = 50, [2] = 30, [3] = 20, [4] = 15, [5] = 10, [6] = 5, [7] = 0 },
  },
}

local data = {
  ["tic"] = nil,
  ["alert"] = {},
}

local function battIndex(val)
  local idx
  for i,v in pairs(settings.batt.levels) do
    if val > v then
      idx = i
      break
    end
  end
  return idx
end

local function alertBatt(alertData, telem, now)
  local idx = nil
  local battPercent = telem.batteryFuelPercent()
  if battPercent and battPercent > 0 then
    idx = battIndex(battPercent)
    if not alertData then
      alertData = { ["idx"] = idx }
    end
    --print("Value: "..(battPercent and battPercent or -1).." Index: "..idx.." Prev: "..(alertData and alertData.idx or -1).." Thresh: "..(alertData and alertData.idx > 1 and (battLevels[alertData.idx-1] + 5) or -1))
    if idx > alertData.idx or (alertData.idx > 1 and battPercent > (settings.batt.levels[alertData.idx-1] + 5)) then
      if idx > alertData.idx then
        num = 5 * xLib.round(battPercent / 5)
        playFile(wavFiles.battery)
        playFile(wavFiles.dir..num..".wav")
        playFile(wavFiles.percent)
      end
      alertData.idx = idx
    end
  end
  return alertData
end

local function alertCurr(alertData, telem, now)
  local current = telem.actualCurrent()
  if xLib.ticker.update(data.tic.curr, now) then
    local batt = xPilot.cfg.get("batt")
    local capa = batt.capa
    local cval = batt.cval
    if current and current > cval * capa then
      playFile(wavFiles.curr.ovrrng)
    end
  end
  return nil
end

local function alertGPS(alertData, telem, now)
  local gps3d = telem.gps3d() 
  if not alertData then
    alertData = { ["gps3d"] = gps3d }
  end
  if alertData.gps3d ~= gps3d then
    playFile(gps3d and wavFiles.gps.fix or wavFiles.gps.deg)
    alertData.gps3d = gps3d
  end
  return alertData
end

local function alertFM(alertData, telem, now)
  local _,fm = telem.flightMode()
  if not alertData then
    alertData = { ["fm"] = fm }
  end
  if alertData.fm ~= fm then
    local f = fm > 0 and wavFiles.fm[fm] or wavFiles.fm[31--[[no telem]]]
    playFile(wavFiles.dir..(f or wavFiles.fm.chg))
    alertData.fm = fm
  end
  return alertData
end

local handler = {
  [1] = { ["id"] = "batt", ["f"] = alertBatt, },
  [2] = { ["id"] = "curr", ["f"] = alertCurr, },
  [3] = { ["id"] = "gps",  ["f"] = alertGPS,  },
  [4] = { ["id"] = "fm",   ["f"] = alertFM,   },
}

local function init(...)
  xLib = xPilot.lib
  xCfg = xPilot.cfg
  local now = xPilot.tic
  local initTicker = xLib.ticker.initRate_Hz
  local ticSettings = settings.tic
  local ticData = {}
  for i,v in pairs(ticSettings) do
    ticData[i] = initTicker(v, now)
  end
  data.tic = ticData
  return true
end

local function exit(...)
  local ticData = data.tic
  for i = 1, #ticData do
    exitTicker(ticData[i])
  end
  data.tic = nil
  return true
end

local function background(...)
  local now = xPilot.tic
  local xTicker = xLib.ticker
  local updateTicker = xTicker.update
  if updateTicker(data.tic.upd, now) then
    local telem = xPilot.telem
    for i = 1,#handler do
      local h = handler[i]
      data.alert[h.id] = h.f(data.alert[h.id], telem, now)
    end
  end
  return true
end

return {
  init=init,
  exit=exit,
  background=background,
}
