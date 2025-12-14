
local tic = nil

local function drawBackground(xpilot, x, y, w, h)
  lcd.drawFilledRectangle(x, y, w, h, SOLID)
  lcd.drawRectangle(x, y, w, h, SOLID)
end

local function drawText(xpilot, x, y, txt)
  lcd.drawText(x, y, txt, INVERS)
end

local function drawFuel(xpilot, x, y, w, h, val)
  local drawFilledRectangle = lcd.drawFilledRectangle
  local dx = w - 1
  drawFilledRectangle(x, y, dx, h, ERASE)
  drawFilledRectangle(x + dx, y + 1, w - dx, h - 2, ERASE)
  dx = dx - 2
  drawFilledRectangle(x + 1, y + 1, math.floor((val * dx) / 100), h - 2)
end

local function drawRSSIValue(xpilot, x, y, w, h, val)
  local drawFilledRectangle = lcd.drawFilledRectangle
  local bars = 5
  local xmath = xpilot.lib.math
  local floor = math.floor
  local space = 1
  local dx = floor((w - space * (bars - 1)) / bars)
  local n = xmath.round(((((val > 100) and 100) or ((val < 0) and 0) or val) * bars) / 100)
  for i = 1, (n > bars and bars or n) do
    local dy = floor(i * h / bars)
    drawFilledRectangle(x + (i - 1) * (dx + space), y + h - dy, dx, dy, ERASE)
  end
end

local function drawAntenna(xpilot, x, y, d)
  local floor = math.floor
  local w1 = d - 1
  local w2 = floor(.5  * w1)
  local w3 = floor(.25 * w1)
  local w4 = floor(.75 * w1)
  local drawLine = lcd.drawLine
  for y1 = 0, w1-1 do
    local x1 = y1 < w2 and 0 or y1 - w2
    drawLine(x + x1, y + y1, x + y1, y + y1, SOLID, ERASE)
  end
  drawLine(x, y + w1, x + w4, y + w3, SOLID, ERASE)
  drawLine(x, y + w1, x + w3, y + w1, SOLID, ERASE)
end

local function init(xpilot, ...)
  local ticInit = xpilot.lib.tic.init
  local tics = {
    ["blnk"] = 1--[[Hz]],
  }
  tic = {}
  for i,v in pairs(tics) do
    tic[i] = ticInit(xpilot.tic, v)
  end
end

local function exit(xpilot, ...)
  tic = xpilot.lib.clearTable(tic)
end

local function run(xpilot, frame, ...)
  local x = frame.x
  local y = frame.y
  local w = frame.w
  local h = frame.h
  drawBackground(xpilot, x, y, w, h)
  local telem = xpilot.telem
  local left = x + 1
  local right = x + w - 1
  local top = y + 1
  local bottom = y + h - 1
  local height = bottom - top
  if telem then
    local lib = xpilot.lib
    --flight mode
    drawText(xpilot, left, top, telem.flightMode())
    --fuel
    local battWidth = 16
    right = right - battWidth
    drawFuel(xpilot, right, top, battWidth, height, telem.batt.fuel())
    --rssi
    local rssiWidth = 10
    right = right - rssiWidth
    drawRSSIValue(xpilot, right, top, rssiWidth, height, telem.rssi())
    --gps/fix
    local gpsWidth = 8
    right = right - gpsWidth
    local d = xpilot.lib.math.min(height, gpsWidth)
    local gps = telem.gps
    local fix = gps.state() or 0
    if fix and fix > 1 then
      drawAntenna(xpilot, right, top, d)
      local fixWidth = 12
      right = right - fixWidth
      drawText(xpilot, right, top, gps.fix(fix))
    else
      local blnk = tic.blnk
      lib.tic.update(blnk, xpilot.tic)
      if blnk.delta >= (blnk.period / 2) then
        drawAntenna(xpilot, right, top, d)
      end
    end
  else
    drawText(xpilot, left, top, "No telemetry")
  end
end

return {
  init = init,
  exit = exit,
  run = run,
}
