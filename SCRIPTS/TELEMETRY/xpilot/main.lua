
local arrowScale = 12.5 * .894427191 --1/sqrt(.5^2+1^2)
local arrow = {
  [1] = { ["x"] =   0,              ["y"] =     -arrowScale },
  [2] = { ["x"] =  .5 * arrowScale, ["y"] =      arrowScale },
  [3] = { ["x"] =   0,              ["y"] = .5 * arrowScale },
  [4] = { ["x"] = -.5 * arrowScale, ["y"] =      arrowScale },
  [5] = { ["x"] =   0,              ["y"] =     -arrowScale },
}

local function drawArrow(libLCD, x, y, angle)
  libLCD.drawPolygon(x, y, arrow, SOLID, FORCE, angle)
end

local function drawVertBar(libLCD, x, y, w, h, fill)
  libLCD.drawVertBar(x, y, w, h, fill, SOLID, FORCE)
end

local function drawVertBarTick(libLCD, x, y, w, h, fill, tick)
  libLCD.drawVertBarTick(x, y, w, h, fill, tick, SOLID, FORCE)
end

local function drawText(libLCD, x, y, txt, fmt)
  lcd.drawText(x, y, txt, fmt)
end

local function drawValue(libLCD, xl, yl, xv, yv, xu, yu, lab, val, unit)
  drawText(libLCD, xl, yl, lab, SMLSIZE)
  drawText(libLCD, xv, yv, val, MIDSIZE + RIGHT)
  drawText(libLCD, xu, yu, unit, SMLSIZE)
end

local function run(xpilot, x, y, w, h, ...)
  local telem = xpilot.telem
  if telem then
    local cfg = xpilot.cfg
    local lib = xpilot.lib
    local round = lib.math.round
    local libLCD = lib.lcd
    local telemBatt = telem.batt
    local telemGPS = telem.gps
    local telemBaro = telem.baro
    local cfgBatt = cfg and cfg.get("batt")

    --layout
    local font = xpilot.env.font
    local left = x
    local right = x + w
    local top = y + 1
    local bottom = y + h
    local height = bottom - top
    local barWidth = 9
    local barHeight = height - 2 * font.sml.h

    --voltage bar
    local VTotal = telemBatt.VTotal()
    local VCell = nil
    local fill = telemBatt.fuel()
    if cfgBatt then
      VCell = telemBatt.VCell(VTotal, cfgBatt.cells)
      local tick = telemBatt.VCellRel(VCell)
      drawVertBarTick(libLCD, left, top, barWidth, barHeight, fill, tick)
    else
      drawVertBar(libLCD, left, top, barWidth, barHeight, fill)
    end
    left = left + barWidth + 1
    --current bar
    local ITotal = telemBatt.ITotal()
    if cfgBatt then
      local cmax = cfgBatt.cmax
      fill = telemBatt.IRel(ITotal, cfgBatt.capa, cmax)
      local tick = 100 * cfgBatt.cval / cmax
      drawVertBarTick(libLCD, left, top, barWidth, barHeight, fill, tick)
    else
      fill = 0
      drawVertBar(libLCD, left, top, barWidth, barHeight, fill)
    end
    left = left + barWidth
    local topTxt = top + barHeight + 1
    --voltage text
    drawText(libLCD, left, topTxt, round(VCell or VTotal, 1).."V", SMLSIZE + RIGHT)
    --current text
    drawText(libLCD, left, topTxt + font.sml.h, round(ITotal).."A", SMLSIZE + RIGHT)

    --rssi bar
    local rssi = telem.rssi()
    rssi = ((rssi > 100) and 100) or ((rssi < 0) and 0) or rssi
    left = right - barWidth
    drawVertBar(libLCD, left, top, barWidth, barHeight, rssi)
    --rssi text
    drawText(libLCD, right, topTxt, round(rssi).."dB", SMLSIZE + RIGHT)

    collectgarbage()
    collectgarbage()

--[[
    --dist text
    local dist = telem.dist()
    drawText(libLCD, right, topTxt + font.sml.h, round(dist).."m", SMLSIZE + RIGHT)
]]
    left = x
    local topVal = top
    local topLabUnit = topVal + font.mid.h - font.sml.h
    local leftLab = left + 2 * barWidth + 3
    local leftVal = leftLab + 47
    local leftUnit = leftVal + 1
    local valHeight = font.mid.h + 1

    --speed-over-ground
    local sog = telemGPS.SoG() * 3.6
    sog = round(sog)
    drawValue(libLCD, leftLab, topLabUnit, leftVal, topVal, leftUnit, topLabUnit, "SoG", sog, "kmh")
    topVal = topVal + valHeight
    topLabUnit = topLabUnit + valHeight
    --rate-of-climb
    local roc = telemBaro.RoC()
    roc = round(roc, roc < 10 and 1 or 0)
    drawValue(libLCD, leftLab, topLabUnit, leftVal, topVal, leftUnit, topLabUnit, "RoC", roc, "m/s")
    topVal = topVal + valHeight
    topLabUnit = topLabUnit + valHeight
    --relative altitude
    local dalt = telemBaro.alt()
    dalt = round(dalt)
    drawValue(libLCD, leftLab, topLabUnit, leftVal, topVal, leftUnit, topLabUnit, "Alt", dalt, "m")
    topVal = topVal + valHeight
    topLabUnit = topLabUnit + valHeight

    --latitude/longitude
    local latLonWidth = 47
    local leftAlt = leftLab + latLonWidth + 3
    local lat, lon = telemGPS.LatLon()
    local alt = telemGPS.alt()
    if lat and lon and alt then
      drawText(libLCD, leftLab + latLonWidth, topTxt,              round(lat, 6), SMLSIZE + RIGHT)
      drawText(libLCD, leftLab + latLonWidth, topTxt + font.sml.h, round(lon, 6), SMLSIZE + RIGHT)
      drawText(libLCD, leftAlt, topTxt, round(alt, 1).."m", SMLSIZE)
    end

    --heading
    local hdg = telemGPS.head();
    local leftArrow = 102
    local topArrow = 30
    drawArrow(libLCD, leftArrow, topArrow, hdg, 5);

  end
end

return {
  init = init,
  run = run,
}

--[[
local function run(xpilot, x, y, w, h, ...)
  lcd.drawText(x, y, "Hello World")
end

return {
  run = run,
}
]]
