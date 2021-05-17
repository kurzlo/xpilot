
local function clearTable(t)
  if t and (type(t) == "table") then
    for i,v in pairs(t) do
      if v and (type(v) == "table") then
        clearTable(v)
      end
      t[i] = nil
    end
    collectgarbage()
    collectgarbage()
  end
  return nil
end


local function mathRound(x, digits)
  local s = digits and 10^digits or 1
  return x < 0 and math.ceil(x * s - 0.5) / s or math.floor(x * s + 0.5) / s
end

local function mathMin(x,y)
  return x < y and x or y
end

local function mathMax(x,y)
  return x > y and x or y
end

local libMath = {
  ["round"] = mathRound,
  ["min"] = mathMin,
  ["max"] = mathMax,
  ["deg2rad"] = function (d) return d * math.pi / 180 end,
  ["rad2deg"] = function (r) return r * 180 / math.pi end,
}


local function lcdDrawPolygon(x0, y0, poly, pat, flags, angle)
  local a = angle or 0
  local phi = libMath.deg2rad(a)
  local cosphi = math.cos(phi)
  local sinphi = math.sin(phi)
  local drawLine = lcd.drawLine
  for i = 1, #poly - 1 do
    local x1 = cosphi * poly[i  ].x - sinphi * poly[i  ].y
    local y1 = sinphi * poly[i  ].x + cosphi * poly[i  ].y
    local x2 = cosphi * poly[i+1].x - sinphi * poly[i+1].y
    local y2 = sinphi * poly[i+1].x + cosphi * poly[i+1].y
    drawLine(x0 + x1, y0 + y1, x0 + x2, y0 + y2, pat, flags)
  end
end

local function lcdDrawVertBar(x0, y0, w, h, fill, pat, flags)
  local hFill = libMath.round(fill * h / 100)
  local yFill = y0 + h - hFill
  lcd.drawFilledRectangle(x0, yFill, w, hFill, flags)
  lcd.drawRectangle(x0, y0, w, h, pat)
end

local function lcdDrawVertBarTick(x0, y0, w, h, fill, tick, pat, flags)
  local round = libMath.round
  local drawFilledRectangle = lcd.drawFilledRectangle
  local hFill = round(fill * h / 100)
  local yFill = y0 + h - hFill
  local hTick = round(tick * h / 100)
  if hFill == hTick then
    drawFilledRectangle(x0, yFill, w, hFill, flags)
  else
    local yTick = y0 + h - hTick
    if hFill < hTick then
      drawFilledRectangle(x0, yFill, w, hFill, flags)
      lcd.drawLine(x0 + 1, yTick, x0 + w - 2, yTick, pat, flags)
    else
      drawFilledRectangle(x0, yTick + 1, w, hTick - 1, flags)
      hFill = hFill - hTick
      drawFilledRectangle(x0, yFill, w, hFill, flags)
    end
  end
  lcd.drawRectangle(x0, y0, w, h, pat)
end

local libLCD = {
  ["drawPolygon"] = lcdDrawPolygon,
  ["drawVertBar"] = lcdDrawVertBar,
  ["drawVertBarTick"] = lcdDrawVertBarTick,
}


local libTelem = {
  ["getFieldInfo"] = getFieldInfo,
  ["getValue"] = getValue,
}


local function ticSetRate(t, rate_Hz)
  t.period = rate_Hz and rate_Hz > 0 and 100 / rate_Hz or 0
  return t
end

local function ticInit(now, rate_Hz)
  local t = {
    ["period"] = 0,
    ["delta" ] = 0,
    ["total" ] = 0,
    ["tic"   ] = now,
  }
  return rate_Hz and ticSetRate(t, rate_Hz) or t
end

local function ticUpdate(t, now)
  local dt = t.tic and (now - t.tic) or 0
  t.delta = t.delta + dt
  t.total = t.total + dt
  t.tic = now
  local upd = t.delta >= t.period
  if upd then
    t.delta = t.delta - t.period
  end
  return upd
end

local libTic = {
  ["init"] = ticInit,
  ["setRate"] = ticSetRate,
  ["update"] = ticUpdate,
}


local lib = {
  ["clearTable"] = clearTable,
  ["print"] = print,
  ["io"] = io,
  ["math"] = libMath,
  ["lcd"] = libLCD,
  ["telem"] = libTelem,
  ["tic"] = libTic,
  ["date"] = libDate,
}

local function init(xpilot, ...)
  if xpilot.env.sim then
    if simIO then
      lib.io = simIO
    end
    if simGetFieldInfo then
      libTelem.getFieldInfo = simGetFieldInfo
    end
    if simGetValue then
      libTelem.getValue = simGetValue
    end
  else
    lib.print = function(...) end
    lib.io = io
  end
end

return {
  init = init,
  lib = lib,
}
