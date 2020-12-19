--[[
EVT_MENU_BREAK = 0
EVT_PAGE_BREAK = 1
EVT_PAGE_LONG = 2
EVT_ENTER_BREAK	= 4
EVT_ENTER_LONG = 8
EVT_EXIT_BREAK = 16
EVT_PLUS_BREAK = 32
EVT_MINUS_BREAK	= 64
EVT_PLUS_FIRST = 128
EVT_MINUS_FIRST	= 256
EVT_PLUS_REPT	= 512
EVT_MINUS_REPT = 1024]]

local function clearTable(t)
  if type(t)=="table" then
    for i,v in pairs(t) do
      if type(v) == "table" then
        clearTable(v)
      end
      t[i] = nil
    end
  end
  collectgarbage()
  return t
end

local function round(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

local function fileOpen(fn,...)
  return io.open(string.sub(fn,2),...)
end

local function fileClose(fid)
  fid:close()
end

local function fileRead(fid, ...)
  return fid:read(...)
end

local function fileWrite(fid, ...)
  return fid:write(...)
end

simIO = {}
simIO.open = fileOpen
simIO.close = fileClose
simIO.read = fileRead
simIO.write = fileWrite

otx = {}
otx.clearTable = clearTable
otx.round = round

function loadScript(scr)
  return loadfile(string.sub(scr,2))
end

function getVersion()
  return 0, "zerobrane-simu", 0, 0, 0
end

function getTime()
  return os.clock()--[[in seconds]] * 100
end

function getRtcTime()
  return os.time()
end

local sec = {
  ["y2k"  ] = 946684800,
  ["year" ] = 31536000, --365 days
  ["month"] = {
    [ 1] = 2678400, --31 days
    [ 2] = 2419200, --28 days
    [ 3] = 2678400, --31 days
    [ 4] = 2592000, --30 days
    [ 5] = 2678400, --31 days
    [ 6] = 2592000, --30 days
    [ 7] = 2678400, --31 days
    [ 8] = 2678400, --31 days
    [ 9] = 2592000, --30 days
    [10] = 2678400, --31 days
    [11] = 2592000, --30 days
    [12] = 2678400, --31 days
  },
  ["day"  ] = 86400,
  ["hour" ] = 3600,
}

function getDateTime()
  local floor = math.floor
  local year = sec.year
  local month = sec.month
  local day = sec.day
  local hour = sec.hour
  --refer to 2k
  local t = getRtcTime() - sec.y2k
  if t < 0 then t = t + 2^32 end
  --year
  local isleap
  local yy = 0
  while t >= 4 * year do
    yy = yy + 4
    t = t - 4 * year
    isleap = (yy % 100 ~= 0) or (yy % 400 == 0)
    if isleap then t = t - day end
  end
  local y = floor(t / year)
  if y ~= 0 then isleap = false end
  yy = yy + y
  t = t - y * year
  --month
  local mm = 1
  while t >= (month[mm] + (mm == 2 and isleap and day or 0)) do
    mm = mm + 1
    t = t - month[mm] - (mm == 2 and isleap and day or 0)
  end
  --day, hour, min, sec
  local dd = floor(t / day)
  t = t - dd * day
  local HH = floor(t / hour)
  t = t - HH * hour
  local MM = floor(t / 60)
  t = t - MM * 60
  local SS = floor(t)
  yy = yy + 2000
  dd = dd + 1
  return { ["year"] = yy, ["mon"] = mm, ["day"] = dd, ["hour"] = HH, ["min"] = MM, ["sec"] = SS }
  --[[hour24,suffix]]
end


function playFile(fn)
  print("Play file: "..fn)
end

function playNumber(num, unit, prec)
  print("Play number: "..num.." (unit: "..unit..", prec: "..prec..")")
end
