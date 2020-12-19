
--[[
local function dateDateString(dat)
  return string.format("%02i.%02i.%04i", dat.day, dat.mon, dat.year)
end

local function dateTimeString(dat)
  return string.format("%02i:%02i:%02i", dat.hour, dat.min, dat.sec)
end

local function dateString(dat)
  return dateDateString(dat).." "..dateTimeString(dat)
end
]]

local function dateFileName(dat, fn)
  return string.format("%04i%02i%02i_%02i%02i%02i_%s", dat.year, dat.mon, dat.day, dat.hour, dat.min, dat.sec, fn)
end

local delim = ";"

local function appendHeader(str, name)
  if name then
    if name == "Date" then
      str = str.."year"..delim.."mon"..delim.."day"..delim.."hour"..delim.."min"..delim.."sec"..delim
    elseif name == "GPS" then
      str = str.."lat"..delim.."lon"..delim
      --str = str.."pilot-lat"..delim.."pilot-lon"..delim
    else
      str = str..(type(name) == "number" or tostring(name) or name)..delim
    end
  else
    str = str..delim
  end
  return str
end

local function appendValue(str, name, val)
  if type(val) == "number" then
    str = str..delim..tostring(val)
  elseif type(val) == "string" then
    str = str..delim..val
  elseif type(val) == "table" then
    if name == "Date" then
      str = str..(val.year and tostring(val.year) or "")..delim..(val.mon and tostring(val.mon) or "")..delim..(val.day and tostring(val.day) or "")..delim
      str = str..(val.hour and tostring(val.hour) or "")..delim..(val.min and tostring(val.min) or "")..delim..(val.sec and tostring(val.sec) or "")..delim
    elseif name == "GPS" then
      str = str..(val.lat and tostring(val.lat) or "")..delim..(val.lon and tostring(val.lon) or "")..delim
      --str = str..(val["pilot-lat"] and tostring(val["pilot-lat"]))..delim..(val["pilot-lon"] and tostring(val["pilot-lon"]) or "")..delim
    else
      for _,v in pairs(val) do
        str = appendValue(str, name, v)
      end
    end
  else
    str = str..delim
  end
  return str
end

local tic = nil
local logFile = nil

local function init(xpilot, ...)
  local cfg = xpilot.cfg
  local getConfig = cfg and cfg.get
  local telemCfg = getConfig and getConfig("telem")
  local lib = xpilot.lib
  local ticInit = lib.tic.init
  local tics = {
    ["log"] = telemCfg and telemCfg.logRate or 1,
    ["cfg"] = 1--[[Hz]],
  }
  tic = {}
  for i,v in pairs(tics) do
    tic[i] = ticInit(xpilot.tic, v)
  end
end

local function exit(xpilot, ...)
  local lib = xpilot.lib
  if logFile then
    lib.io.close(logFile)
    logFile = nil
  end
  local clearTable = lib.clearTable
  tic = clearTable(tic)
end

local function background(xpilot, ...)
  local cfg = xpilot.cfg
  if cfg then
    local lib = xpilot.lib
    local xtic = lib.tic
    local now = xpilot.tic
    local update = xtic.update
    local telemCfg = cfg.get("telem")
    if update(tic.log, now) then
      local rec = telemCfg.rec
      local xio = lib.io
      if rec and rec > 1 then
        local telemTab = xpilot.telem.tab()
        local xwrite = xio.write
        if not logFile then
          local dat = getDateTime()
          local file = dateFileName(dat, "telem.log")
          logFile = xio.open(xpilot.env.dir.log..file, "w")
          if logFile then
            local ln = "#Timestamp"..delim
            for _,v in pairs(telemTab) do
              ln = appendHeader(ln, v.name)
            end
            xwrite(logFile, ln.."\n")
          else
            cfg.set("telem", "rec", 0)
            lib.print("Failed to open logfile \""..file.."\"")
          end
          tic.log.total = 0
        end
        if logFile then
          local ln = tostring(tic.log.total)..delim
          for _,v in pairs(telemTab) do
            ln = appendValue(ln, v.name, v.val)
          end
          xwrite(logFile, ln.."\n")
        end
      else
        if logFile then
          xio.close(logFile)
          logFile = nil
        end
      end
    end
    if update(tic.cfg, now) then
      tic.log = xtic.setRate(tic.log, telemCfg.logRate)
    end
  end
end

return {
  init = init,
  exit = exit,
  background = background,
}
