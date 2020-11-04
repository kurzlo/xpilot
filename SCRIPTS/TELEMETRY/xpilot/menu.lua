local xLib = nil

local floor = math.floor
local drawLine = lcd.drawLine
local drawFilledRectangle = lcd.drawFilledRectangle
local drawText = lcd.drawText

local settings = {
  ["tic"] = {
    ["blink"] = 1,
  },
  ["ui"] = {
    ["batt"] = { ["w"] = 14 },
    ["rssi"] = { ["w"] = 10, ["bars"] = 5 },
    ["gps" ] = { ["w"] = 8 },
    ["fix" ] = { ["w"] = 12 },
  },
}

local data = {}
data.tic = nil

local function drawBatteryPercent(x, y, w, h, value)
  local dx = w - 1
  drawFilledRectangle(x, y, dx, h, ERASE)
  drawFilledRectangle(x + dx, y + 1, w - dx, h - 2, ERASE)
  dx = dx - 2
  drawFilledRectangle(x + 1, y + 1, floor((value * dx) / 100), h - 2)
  return true
end

local function drawRSSIValue(x, y, w, h, value, bars)
  if not bars then bars = 5 end
  if value > 100 then
    value = 100
  end
  local space = 1
  local dx = floor((w - space * (bars - 1)) / bars)
  local n = xLib.round((value * bars) / 100)
  for i = 1, n do
    local dy = floor(i * h / bars)
    drawFilledRectangle(x + (i - 1) * (dx + space), y + h - dy, dx, dy, ERASE)
  end
  return true
end

local function drawAntenna(x0, y0, w, flags)
  local w1 = w - 1
  local w2 = floor(.5  * w1)
  local w3 = floor(.25 * w1)
  local w4 = floor(.75 * w1)
  for y = 0, w1-1 do
    local x = y < w2 and 0 or y - w2
    drawLine(x0+x, y0+y, x0+y, y0+y, SOLID, flags)
  end
  drawLine(x0, y0+w1, x0+w4, y0+w3, SOLID, flags)
  drawLine(x0, y0+w1, x0+w3, y0+w1, SOLID, flags)
end

local function init(...)
  xLib = xPilot.lib
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
  local exitTicker = xLib.ticker.exit
  local ticData = data.tic
  for i = 1, #ticData do
    exitTicker(ticData[i])
  end
  data.tic = nil
  return true
end

local function run(...)
  local xui = xPilot.ui.scr.menu
  local x0 = xui.x
  local y0 = xui.y
  local w = xui.w
  local h = xui.h
  drawFilledRectangle(x0, y0, w, h)
  local telem = xPilot.telem
  x0 = x0 + 1
  y0 = y0 + 1
  drawText(x0, y0, telem.flightMode(), INVERS)
  x0 = xui.x + w
  h = h - 2
  local ui = settings.ui
  local d = ui.batt.w
  x0 = x0 - d - 1
  drawBatteryPercent(x0, y0, d - 1, h, telem.batteryFuelPercent())
  d = ui.rssi.w
  x0 = x0 - d - 1
  drawRSSIValue(x0, y0, d - 1, h, telem.rssiValue(), ui.rssi.bars)
  d = xLib.min(ui.gps.w, h)
  x0 = x0 - d - 2
  local fix = telem.gpsState()
  local now = xPilot.tic
  local blinkTicker = data.tic.blink
  xLib.ticker.update(blinkTicker, now)
  if fix > 1 or blinkTicker.delta >= blinkTicker.period / 2 then
    drawAntenna(x0, y0, d, ERASE)
  end
  d = ui.fix.w
  x0 = x0 - d - 1
  if fix > 1 then
    drawText(x0, y0, telem.gpsFix(fix), INVERS)
  end
  return true
end

return {
  init=init,
  exit=exit,
  run=run,
}
