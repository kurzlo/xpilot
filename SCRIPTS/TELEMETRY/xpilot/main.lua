local xLib = nil

local xui = xPilot.ui.scr.main
local font = xPilot.ui.font
local wbar = 9
local xlab = 2 * wbar + 5
local wlab = 10
local wval = 35
local xllh = 2 * wbar + 5
local xalt = xllh + 55
local xhdg = 100
local yhdg = 30

local cos = math.cos;
local sin = math.sin;
local deg2rad = math.pi / 180;

local settings = {
  ["ui"] = {
    ["vbar"] = {
      ["x"] = 1, ["y"] = 1, 
      ["h"] = xui.h - 2 * (font.sml.h + 1), ["w"] = wbar, },
    ["vtxt"] = {
      ["x"] =  2 * wbar + 3, ["y"] = xui.h - 2 * font.sml.h },
    ["cbar"] = {
      ["x"] = wbar + 3, ["y"] = 1,
      ["h"] = xui.h - 2 * (font.sml.h + 1), ["w"] = wbar, },
    ["ctxt"] = {
      ["x"] = 2 * wbar + 3, ["y"] = xui.h - font.sml.h },
    ["rbar"] = {
      ["x"] = xui.w - wbar - 1, ["y"] = 1,
      ["h"] = xui.h - 2 * (font.sml.h + 1), ["w"] = wbar, },
    ["rtxt"] = {
      ["x"] = xui.w - 1, ["y"] = xui.h - 2 * font.sml.h },
    ["dtxt"] = {
      ["x"] = xui.w - 1, ["y"] = xui.h - font.sml.h },
    ["sog"] = {
      ["lab" ] = { ["x"] = xlab,                   ["y"] = 1 + font.mid.h - font.sml.h },
      ["val" ] = { ["x"] = xlab + wlab + wval,     ["y"] = 1 },
      ["unit"] = { ["x"] = xlab + wlab + wval + 1, ["y"] = 1 + font.mid.h - font.sml.h } },
    ["roc"] = {
      ["lab" ] = { ["x"] = xlab,                   ["y"] = 1 + 2 * font.mid.h - font.sml.h },
      ["val" ] = { ["x"] = xlab + wlab + wval,     ["y"] = 1 + font.mid.h },
      ["unit"] = { ["x"] = xlab + wlab + wval + 1, ["y"] = 1 + 2 * font.mid.h - font.sml.h } },
    ["dalt"] = {
      ["lab" ] = { ["x"] = xlab,                   ["y"] = 1 + 3 * font.mid.h - font.sml.h },
      ["val" ] = { ["x"] = xlab + wlab + wval,     ["y"] = 1 + 2 * font.mid.h },
      ["unit"] = { ["x"] = xlab + wlab + wval + 1, ["y"] = 1 + 3 * font.mid.h - font.sml.h } },
    ["alt"] = { ["x"] = xalt, ["y"] = xui.h - font.sml.h },
    ["lat"] = { ["x"] = xllh, ["y"] = xui.h - 2 * font.sml.h },
    ["lon"] = { ["x"] = xllh, ["y"] = xui.h - font.sml.h },
  },
}

local drawLine = lcd.drawLine
local drawRectangle = lcd.drawRectangle
local drawFilledRectangle = lcd.drawFilledRectangle
local drawText = lcd.drawText

local round = nil

local arrow = {
  [1] = { ["x"] =  0, ["y"] = -2 },
  [2] = { ["x"] =  1, ["y"] =  2 },
  [3] = { ["x"] =  0, ["y"] =  1 },
  [4] = { ["x"] = -1, ["y"] =  2 },
  [5] = { ["x"] =  0, ["y"] = -2 },
}

local function drawArrow(x0, y0, angle, scl)
  local s = scl or 2
  local phi = angle * deg2rad
  local cosphi = cos(phi)
  local sinphi = sin(phi)
  for i = 1, #arrow - 1 do
    local x1 = s * (cosphi * arrow[i  ].x - sinphi * arrow[i  ].y)
    local y1 = s * (sinphi * arrow[i  ].x + cosphi * arrow[i  ].y)
    local x2 = s * (cosphi * arrow[i+1].x - sinphi * arrow[i+1].y)
    local y2 = s * (sinphi * arrow[i+1].x + cosphi * arrow[i+1].y)
    drawLine(x0 + x1, y0 + y1, x0 + x2, y0 + y2, SOLID, FORCE)
  end
end

local function drawVertBar(x0, y0, w, h, fill)
  local hFill = round(fill * h / 100)
  local yFill = y0 + h - hFill
  drawFilledRectangle(x0, yFill, w, hFill, FORCE)
  drawRectangle(x0, y0, w, h, SOLID)
end

local function drawVertBarTick(x0, y0, w, h, fill, tick)
  local hFill = round(fill * h / 100)
  local yFill = y0 + h - hFill
  local hTick = round(tick * h / 100)
  if hFill == hTick then
    drawFilledRectangle(x0, yFill, w, hFill, FORCE)
  else
    local yTick = y0 + h - hTick
    if hFill < hTick then
      drawFilledRectangle(x0, yFill, w, hFill, FORCE)
      drawLine(x0 + 1, yTick, x0 + w - 2, yTick, SOLID, FORCE)
    else
      drawFilledRectangle(x0, yTick + 1, w, hTick - 1, FORCE)
      hFill = hFill - hTick
      drawFilledRectangle(x0, yFill, w, hFill, FORCE)
    end
  end
  drawRectangle(x0, y0, w, h, SOLID)
end

local function drawValue(x0, y0, lab, val, digits, unit, cfg)
  local x = x0 + cfg.lab.x
  local y = y0 + cfg.lab.y
  drawText(x, y, lab, SMLSIZE)
  x = x0 + cfg.val.x
  y = y0 + cfg.val.y
  drawText(x, y, round(val, digits), MIDSIZE + RIGHT)
  x = x0 + cfg.unit.x
  y = y0 + cfg.unit.y
  drawText(x, y, unit, SMLSIZE)
end

local function init(...)
  xLib = xPilot.lib
  round = xLib.round
  --xPilot.msg.push("XPilot ready")
  return true
end

local function run(...)

  local telem = xPilot.telem
  local xui = xPilot.ui.scr.main
  local x0 = xui.x
  local y0 = xui.y
  local ui = settings.ui

  --voltage bar
  local voltage = telem.batteryCellVoltage()
  --[[local vbar = ui.vbar
  local x = x0 + vbar.x
  local y = y0 + vbar.y
  local fill = telem.batteryFuelPercent()
  drawVertBar(x, y, vbar.w, vbar.h, fill) ]]
  local vbar = ui.vbar
  x = x0 + vbar.x
  y = y0 + vbar.y
  local fill = telem.batteryFuelPercent()
  local tick = telem.batteryVoltagePercent(voltage)
  drawVertBarTick(x, y, vbar.w, vbar.h, fill, tick)
  --voltage text
  local vtxt = ui.vtxt
  x = x0 + vtxt.x
  y = y0 + vtxt.y
  drawText(x, y, round(voltage, 1).."V", SMLSIZE + RIGHT)
  --current bar
  local cbar = ui.cbar
  x = x0 + cbar.x
  y = y0 + cbar.y
  local batt = xPilot.cfg.get("batt")
  local capa = batt.capa
  local cval = batt.cval
  local cmax = batt.cmax
  local current = telem.actualCurrent()
  fill = telem.currentPercent(current, capa, cmax)
  tick = 100 * cval / cmax
  drawVertBarTick(x, y, cbar.w, cbar.h, fill, tick)
  --current text
  local ctxt = ui.ctxt
  x = x0 + ctxt.x
  y = y0 + ctxt.y
  drawText(x, y, round(current).."A", SMLSIZE + RIGHT)
  --rssi bar
  local rbar = ui.rbar
  x = x0 + rbar.x
  y = y0 + rbar.y
  rssi = telem.rssiValue()
  drawVertBar(x, y, rbar.w, rbar.h, rssi)
  --rssi text
  local rtxt = ui.rtxt
  x = x0 + rtxt.x
  y = y0 + rtxt.y
  drawText(x, y, round(rssi).."dB", SMLSIZE + RIGHT)
  --dist text
  local dtxt = ui.dtxt
  x = x0 + dtxt.x
  y = y0 + dtxt.y
  local dist = telem.distFromHome()
  drawText(x, y, round(dist).."m", SMLSIZE + RIGHT)

  --speed-over-ground
  local sog = telem.gpsSpeedOverGround() * 3.6
  drawValue(x0, y0, "SoG", sog, nil, "kmh", ui.sog)
  --rate-of-climb
  local roc = telem.baroRateOfClimb()
  drawValue(x0, y0, "RoC", roc, roc < 10 and 1 or nil, "m/s", ui.roc)
  local dalt = telem.baroAltitude()
  drawValue(x0, y0, "Alt", dalt, nil, "m", ui.dalt)

  --altitude
  local altTxt = ui.alt
  x = x0 + altTxt.x
  y = y0 + altTxt.y
  local alt = telem.gpsAltitude()
  drawText(x, y, round(alt, 1).."m", SMLSIZE)
  --latitude/longitude
  local latTxt = ui.lat
  x = x0 + latTxt.x
  y = y0 + latTxt.y
  local lat, lon = telem.gpsLatLon()
  drawText(x, y, round(lat, 8), SMLSIZE)
  local lonTxt = ui.lon
  x = x0 + lonTxt.x
  y = y0 + lonTxt.y
  drawText(x, y, round(lon, 8), SMLSIZE)

  --heading
  local hdg = telem.gpsHeading();
  drawArrow(xhdg, yhdg, hdg, 5);

  return true
end

return {
  init=init,
  run=run,
}
