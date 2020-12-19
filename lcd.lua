require("wx")
require("turtle")
require("otx")

--lcd
LCD_W = 128
LCD_H = 64

--font
SMLSIZE = 1
MIDSIZE = 2
DBLSIZE = 4
INVERS = 8
BLINK = 16
LEFT = 64
RIGHT = 128
PREC1 = 256
PREC2 = 512

--pattern
SOLID = 0
FORCE = 1
ERASE = 2
DOTTED = 4

--[[
local function pt2px(sizept) return sizept * 1.3281472327365 end
local function px2pt(sizepx) return sizept * 0.7529285724893 end
]]--

local turtles = {}

local lcdHalfScale = 3
local lcdScale = 2 * lcdHalfScale
local function scale(x) return x * lcdScale end

local lcdFont = {}
lcdFont.sml = {}
lcdFont.sml.w = nil
lcdFont.sml.h = 7
lcdFont.sml.pt = 5
lcdFont.nml= {}
lcdFont.nml.w = nil
lcdFont.nml.h = 7
lcdFont.nml.pt = 6
lcdFont.mid = {}
lcdFont.mid.w = nil
lcdFont.mid.h = 11
lcdFont.mid.pt = 7
lcdFont.dbl = {}
lcdFont.dbl.w = nil
lcdFont.dbl.h = 15
lcdFont.dbl.pt = 10

local function getFont(flags)
  local f = lcdFont.nml
  if flags ~= nil then
    if bit.band(flags, SMLSIZE) == SMLSIZE then
      f = lcdFont.sml
    elseif bit.band(flags, MIDSIZE) == MIDSIZE then
      f = lcdFont.mid
    elseif bit.band(flags, DBLSIZE) == DBLSIZE then
      f = lcdFont.dbl
    end
  end
  return f
end

lcd = {}

lcd.init = function()
  local fw = dofile("fontwidth.lua")
  lcdFont.sml.w = fw.sml
  lcdFont.nml.w = fw.nml
  lcdFont.mid.w = fw.mid
  lcdFont.dbl.w = fw.dbl
  open("XPilot")
  size(scale(LCD_W)+lcdScale, scale(LCD_H)+lcdScale)
  updt(false)
  dx = math.floor(lcdHalfScale)
  zero(dx, dx)
end

lcd.clear = function()
  wipe()
  turtles = otx.clearTable(turtles)
end

lcd.drawPoint = function(x, y)
  local t = trtl()
  table.insert(turtles, t)
  if lcdScale > 1 then
    pnsz(lcdScale)
  else
    pixl(lcd.scale(x), lcd.scale(y))
  end
end

lcd.drawLine = function(x1, y1, x2, y2, pattern, flags)
  local s = lcdScale;
  local t = trtl()
  local dx = scale(x2 - x1)
  local dy = scale(y2 - y1)
  local len = math.sqrt(dx * dx + dy * dy)
  local angle = ( dx == 0 ) and ( ( dy > 0 and 90 ) or ( dy < 0 and -90 ) or 0 ) or ( math.atan2(dy, dx) * 180 / math.pi )
  table.insert(turtles, t)
  pnsz(s)
  if bit.band(flags, ERASE) == ERASE then
    pncl("white")
  end
  posn(scale(x1), scale(y1))
  turn(angle)
  if pattern and (bit.band(pattern, DOTTED) == DOTTED) then
    local stride = scale(1)
    local N = math.floor(len / stride)
    local ds = len / N
    local up = bit.band(flags, ERASE) == ERASE
    for i=1,N do
      if up then pnup() else pndn() end
      up = not up
      move(ds)
    end
  else
    move(len)
  end
end

lcd.drawRectangle = function(x, y, w, h, flags)
  local s = lcdScale;
  local t = trtl()
  table.insert(turtles, t)
  pnsz(s)
  rect(scale(x), scale(y), scale(w), scale(h))
end

lcd.drawFilledRectangle = function(x, y, w, h, flags)
  local t = trtl()
  table.insert(turtles, t)
  local ws = scale(w) + lcdHalfScale
  local hs = scale(h) + lcdHalfScale
  posn(scale(x) - lcdHalfScale, scale(y) - lcdHalfScale)
  for i = 1, 4 do
    move(((i % 2) == 0) and hs or ws)
    turn(90)
  end
  local cl = flags and bit.band(flags, ERASE) and "white" or "gray"
  fill(cl, lcdHalfScale, lcdHalfScale)
end

lcd.drawText = function(x,y,str,flags)
  local tbox = trtl();
  table.insert(turtles, tbox)
  local f = getFont(flags)
  local len = 0
  for i = 1, string.len(str) do
    len = len + f.w[string.byte(string.sub(str, i, i))]
  end
  if flags and bit.band(flags, RIGHT) == RIGHT then
    x = x - len
  end
  if flags and bit.band(flags, INVERS) == INVERS then
    posn(scale(x) - lcdHalfScale, scale(y) - lcdHalfScale)
    for i = 1, 4 do
      move(((i % 2) == 0) and scale(f.h) or scale(len))
      turn(90)
    end
    fill("gray", lcdHalfScale, lcdHalfScale)
    pncl("white")
  else
    rect(scale(x), scale(y), scale(len), scale(f.h))
  end
  posn(scale(x), scale(y) - f.h)
  font(scale(f.pt))
  text(str)
end

