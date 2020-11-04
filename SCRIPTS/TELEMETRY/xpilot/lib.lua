local function clearTable(t)
  if type(t) == "table" then
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

local floor = math.floor
local ceil = math.ceil

local function round(x, digits)
  local s = digits and 10^digits or 1
  return x < 0 and ceil(x * s - 0.5) / s or floor(x * s + 0.5) / s
end

local function min(x,y)
  return x < y and x or y
end

local function max(x,y)
  return x > y and x or y
end

local function tickerInit(now)
  return {
    ["period"] = 0,
    ["delta" ] = 0,
    ["total" ] = 0,
    ["tic"   ] = now,
  }
end

local function tickerPeriod_ms(t, period_ms)
  t.period = period_ms / 10
  return t
end

local function tickerInitPeriod_ms(period_ms, now)
  local t = tickerInit(now)
  t = tickerPeriod_ms(t, period_ms)
  return t
end

local function tickerRate_Hz(t, rate_Hz)
  t.period = rate_Hz and rate_Hz > 0 and 100 / rate_Hz or 0
  return t
end

local function tickerInitRate_Hz(rate_Hz, now)
  local t = tickerInit(now)
  t = tickerRate_Hz(t, rate_Hz)
  return t
end

local function tickerReset(t, now)
  t.delta = 0
  t.total = 0
  t.tic = now
  return true
end

local function tickerUpdate(t, now)
  local dt = now - t.tic
  t.delta = t.delta + dt
  t.total = t.total + dt
  t.tic = now
  local upd = t.delta >= t.period
  if upd then
    t.delta = t.delta - t.period
  end
  return upd
end

local ticker = {
  initPeriod_ms=tickerInitPeriod_ms,
  initRate_Hz=tickerInitRate_Hz,
  exit=clearTable,
  reset=tickerReset,
  update=tickerUpdate,
  period_ms=tickerPeriod_ms,
  rate_Hz=tickerRate_Hz,
}

local function dateToDateString(dat)
  return string.format("%02i.%02i.%04i", dat.day, dat.mon, dat.year)
end

local function dateToTimeString(dat)
  return string.format("%02i:%02i:%02i", dat.hour, dat.min, dat.sec)
end

local function dateToString(dat)
  return dateToDateString(dat).." "..dateToTimeString(dat)
end

local function dateToFileName(dat, fn)
  return string.format("%04i%02i%02i_%02i%02i%02i_%s", dat.year, dat.mon, dat.day, dat.hour, dat.min, dat.sec, fn)
end

local dat = {
  toDateString=dateToDateString,
  toTimeString=dateToTimeString,
  toString=dateToString,
  toFileName=dateToFileName,
}

return {
  clearTable=clearTable,
  round=round,
  min=min,
  max=max,
  ticker=ticker,
  date=dat,
  time2date=time2date,
}
