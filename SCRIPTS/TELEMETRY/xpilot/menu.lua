
local tic = nil

local function drawBackground(xpilot, ui)
  lcd.drawFilledRectangle(ui.x, ui.y, ui.w, ui.h, ui.f)
  lcd.drawRectangle(ui.x, ui.y, ui.w, ui.h, ui.f)
end

local function drawText(xpilot, ui, fm)
  lcd.drawText(ui.x, ui.y, fm, ui.f)
end

local function drawFuel(xpilot, ui, value)
  local drawFilledRectangle = lcd.drawFilledRectangle
  local dx = ui.w - 1
  drawFilledRectangle(ui.x, ui.y, dx, ui.h, ui.f)
  drawFilledRectangle(ui.x + dx, ui.y + 1, ui.w - dx, ui.h - 2, ui.f)
  dx = dx - 2
  drawFilledRectangle(ui.x + 1, ui.y + 1, math.floor((value * dx) / 100), ui.h - 2)
end

local function drawRSSIValue(xpilot, ui, value)
  local drawFilledRectangle = lcd.drawFilledRectangle
  local bars = ui.bars or 5
  local xmath = xpilot.lib.math
  local floor = math.floor
  if value > 100 then
    value = 100
  end
  local space = 1
  local dx = floor((ui.w - space * (bars - 1)) / bars)
  local n = xmath.round((value * bars) / 100)
  for i = 1, (n > bars and bars or n) do
    local dy = floor(i * ui.h / bars)
    drawFilledRectangle(ui.x + (i - 1) * (dx + space), ui.y + ui.h - dy, dx, dy, ui.f)
  end
end

local function drawAntenna(xpilot, ui)
  local floor = math.floor
  local w1 = ui.d - 1
  local w2 = floor(.5  * w1)
  local w3 = floor(.25 * w1)
  local w4 = floor(.75 * w1)
  for y = 0, w1-1 do
    local x = y < w2 and 0 or y - w2
    lcd.drawLine(ui.x + x, ui.y + y, ui.x + y, ui.y + y, SOLID, ui.f)
  end
  lcd.drawLine(ui.x, ui.y + w1, ui.x + w4, ui.y + w3, SOLID, ui.f)
  lcd.drawLine(ui.x, ui.y + w1, ui.x + w3, ui.y + w1, SOLID, ui.f)
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

local function layout(xpilot, frame)
  local top = frame.y + 1
  local bottom = frame.y + frame.h - 1
  local left = frame.x + 1
  local right = frame.x + frame.w - 1
  local ui = { ["bg"] = frame }
  ui.bg.f = SOLID
  local battWidth = 16
  local batt = {
    ["x"] = right - battWidth, ["y"] = top,
    ["w"] = battWidth, ["h"] = bottom - top,
    ["f"] = ERASE,
  }
  ui.batt = batt
  local rssiWidth = 10
  local rssi = {
    ["x"] = batt.x - rssiWidth - 1, ["y"] = top,
    ["w"] = rssiWidth, ["h"] = batt.h,
    ["f"] = ERASE,
    ["bars"] = 5,
  }
  ui.rssi = rssi
  local gpsWidth = 8
  local gps = {
    ["x"] = rssi.x - gpsWidth, ["y"] = top,
    ["d"] = xpilot.lib.math.min(batt.h, gpsWidth),
    ["f"] = ERASE,
  }
  ui.gps = gps
  ui.fix = {
    ["x"] = gps.x - 12, ["y"] = top,
    ["f"] = INVERS,
  }
  ui.fm = {
    ["x"] = left, ["y"] = top,
    ["f"] = INVERS,
  }
  return ui
end

local function run(xpilot, ui, ...)
  drawBackground(xpilot, ui.bg)
  local telem = xpilot.telem
  if telem then
    local lib = xpilot.lib
    drawText(xpilot, ui.fm, telem.flightMode())
    drawFuel(xpilot, ui.batt, telem.batt.fuel())
    drawRSSIValue(xpilot, ui.rssi, telem.rssi())
    local gps = telem.gps
    local fix = gps.state()
    if fix > 1 then
      drawAntenna(xpilot, ui.gps)
      drawText(xpilot, ui.fix, gps.fix(fix))
    else
      local blnk = tic.blnk
      lib.tic.update(blnk, xpilot.tic)
      if blnk.delta >= (blnk.period / 2) then
        drawAntenna(xpilot, ui.gps)
      end
    end
  end
end

return {
  init = init,
  exit = exit,
  layout = layout,
  run = run,
}
