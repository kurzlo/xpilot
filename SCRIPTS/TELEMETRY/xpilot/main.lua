
local arrowScale = .894427191 --1/sqrt(.5^2+1^2)
local arrow = {
  [1] = { ["x"] =   0,              ["y"] =     -arrowScale },
  [2] = { ["x"] =  .5 * arrowScale, ["y"] =      arrowScale },
  [3] = { ["x"] =   0,              ["y"] = .5 * arrowScale },
  [4] = { ["x"] = -.5 * arrowScale, ["y"] =      arrowScale },
  [5] = { ["x"] =   0,              ["y"] =     -arrowScale },
}

local function drawArrow(libLCD, ui, angle)
  libLCD.drawPolygon(ui.x, ui.y, ui.arrow, SOLID, FORCE, angle)
end

local function drawVertBar(libLCD, ui, fill)
  libLCD.drawVertBar(ui.x, ui.y, ui.w, ui.h, fill, SOLID, FORCE)
end

local function drawVertBarTick(libLCD, ui, fill, tick)
  libLCD.drawVertBarTick(ui.x, ui.y, ui.w, ui.h, fill, tick, SOLID, FORCE)
end

local function drawText(libLCD, ui, txt)
  lcd.drawText(ui.x, ui.y, txt, ui.f)
end

local function drawValue(libLCD, ui, lab, val, unit)
  drawText(libLCD, ui.l, lab)
  drawText(libLCD, ui.v, val)
  drawText(libLCD, ui.u, unit)
end

local function layout(xpilot, frame)
  local font = xpilot.env.font
  local top = frame.y + 1
  local bottom = frame.y + frame.h
  local left = frame.x
  local right = frame.x + frame.w
  local ui = {}
  local voltageBar = {
    ["x"] = left, ["y"] = top,
    ["w"] = 9, ["h"] = bottom - top - 2 * font.sml.h,
  }
  ui.voltage = { ["bar"] = voltageBar }
  local currentBar = {
    ["x"] = voltageBar.x + voltageBar.w + 1, ["y"] = voltageBar.y,
    ["w"] = voltageBar.w, ["h"] = voltageBar.h,
  }
  ui.current = { ["bar"] = currentBar }
  local rssiBar = {
    ["x"] = right - voltageBar.w, ["y"] = voltageBar.y,
    ["w"] = voltageBar.w, ["h"] = voltageBar.h,
  }
  ui.rssi = { ["bar"] = rssiBar }
  local currentTxt = {
    ["x"] = currentBar.x + currentBar.w, ["y"] = bottom - font.sml.h + 1,
    ["f"] = SMLSIZE + RIGHT,
  }
  ui.current.txt = currentTxt
  local voltageTxt = {
    ["x"] = currentTxt.x, ["y"] = currentTxt.y - font.sml.h,
    ["f"] = currentTxt.f,
  }
  ui.voltage.txt = voltageTxt
  local dist = {
    ["x"] = right, ["y"] = currentTxt.y,
    ["f"] = currentTxt.f,
  }
  ui.dist = dist
  ui.rssi.txt = {
    ["x"] = dist.x, ["y"] = voltageTxt.y,
    ["f"] = voltageTxt.f,
  }
  local bar2txt = 3
  local sogLabel = {
    ["x"] = currentBar.x + currentBar.w + bar2txt, ["y"] = top + font.mid.h - font.sml.h,
    ["f"] = SMLSIZE,
  }
  local sogValue = {
    ["x"] = sogLabel.x + 47, ["y"] = top,
    ["f"] = MIDSIZE + RIGHT,
  }
  local sogUnit = {
    ["x"] = sogValue.x + 1, ["y"] = sogLabel.y,
    ["f"] = SMLSIZE
  }
  local sogUnitWidth = 20
  local sog = { ["l"] = sogLabel, ["v"] = sogValue, ["u"] = sogUnit }
  ui.sog = sog
  local roc = {
    ["l"] = { ["x"] = sog.l.x, ["y"] = sog.l.y + font.mid.h, ["f"] = sog.l.f },
    ["v"] = { ["x"] = sog.v.x, ["y"] = sog.v.y + font.mid.h, ["f"] = sog.v.f },
    ["u"] = { ["x"] = sog.u.x, ["y"] = sog.u.y + font.mid.h, ["f"] = sog.u.f },
  }
  ui.roc = roc
  ui.dalt = {
    ["l"] = { ["x"] = roc.l.x, ["y"] = roc.l.y + font.mid.h, ["f"] = roc.l.f },
    ["v"] = { ["x"] = roc.v.x, ["y"] = roc.v.y + font.mid.h, ["f"] = roc.v.f },
    ["u"] = { ["x"] = roc.u.x, ["y"] = roc.u.y + font.mid.h, ["f"] = roc.u.f },
  }
  local lat = {
    ["x"] = sogLabel.x, ["y"] = voltageTxt.y,
    ["f"] = SMLSIZE,
  }
  ui.lat = lat
  ui.lon = {
    ["x"] = lat.x, ["y"] = currentTxt.y,
    ["f"] = lat.f,
  }
  ui.alt = {
    ["x"] = sogUnit.x, ["y"] = lat.y,
    ["f"] = lat.f ,
  }
  local head = {
    ["l"] = sogUnit.x + sogUnitWidth, ["r"] = rssiBar.x,
    ["t"] = voltageBar.y, ["b"] = voltageBar.y + voltageBar.h,
  }
  head.w = head.r - head.l - 1
  head.h = head.b - head.t - 1
  a = {}
  local s = .5 * xpilot.lib.math.min(head.w, head.h)
  for i,v in pairs(arrow) do
    a[i] = { ["x"] = s * v.x, ["y"] = s * v.y }
  end
  ui.head = {
    ["x"] = (head.l + head.r) / 2, ["y"] = (head.t + head.b) / 2,
    ["arrow"] = a,
  }
  return ui
end

local function run(xpilot, ui, ...)
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
    --voltage
    local VTotal = telemBatt.VTotal()
    local VCell = nil
    local fill = telemBatt.fuel()
    if cfgBatt then
      VCell = telemBatt.VCell(VTotal, cfgBatt.cells)
      local tick = telemBatt.VCellRel(VCell)
      drawVertBarTick(libLCD, ui.voltage.bar, fill, tick)
      drawText(libLCD, ui.voltage.txt, round(VCell, 1).."V")
    else
      drawVertBar(libLCD, ui.voltage.bar, fill)
    end
    drawText(libLCD, ui.voltage.txt, round(VCell or VTotal, 1).."V")
    --current
    local ITotal = telemBatt.ITotal()
    if cfgBatt then
      local cmax = cfgBatt.cmax
      fill = telemBatt.IRel(ITotal, cfgBatt.capa, cmax)
      local tick = 100 * cfgBatt.cval / cmax
      drawVertBarTick(libLCD, ui.current.bar, fill, tick)
    else
      fill = 0
      drawVertBar(libLCD, ui.current.bar, fill)
    end
    drawText(libLCD, ui.current.txt, round(ITotal).."A")
    --rssi
    local rssi = telem.rssi()
    drawVertBar(libLCD, ui.rssi.bar, rssi < 100 and rssi or 100)
    drawText(libLCD, ui.rssi.txt, round(rssi).."dB")
    --dist
    local dist = telem.dist()
    drawText(libLCD, ui.dist, round(dist).."m")
    --speed-over-ground
    local sog = telemGPS.SoG() * 3.6
    sog = round(sog)
    drawValue(libLCD, ui.sog, "SoG", sog, "kmh")
    --rate-of-climb
    local roc = telemBaro.RoC()
    roc = round(roc, roc < 10 and 1 or 0)
    drawValue(libLCD, ui.roc, "RoC", roc, "m/s")
    --relative altitude
    local dalt = telemBaro.alt()
    dalt = round(dalt)
    drawValue(libLCD, ui.dalt, "Alt", dalt, "m")
    --altitude
    local alt = telemGPS.alt()
    drawText(libLCD, ui.alt, round(alt, 1).."m")
    --latitude/longitude
    local lat, lon = telemGPS.LatLon()
    drawText(libLCD, ui.lat, round(lat, 6))
    drawText(libLCD, ui.lon, round(lon, 6))
    --heading
    local hdg = telemGPS.head();
    drawArrow(libLCD, ui.head, hdg, 5);
  end
end

return {
  init = init,
  layout = layout,
  run = run,
}

--[[
local function run(xpilot, ui, ...)
  lcd.drawText(ui.x, ui.y, "Hello World")
end

return {
  layout = function(xpilot, l, ...) return { ["x"] = l.x, ["y"] = l.y } end,
  run = run,
}
]]