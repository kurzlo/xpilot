local xLib = nil

local data = {
  ["buf"] = nil,
  ["ui"] = nil,
}

local drawText = lcd.drawText

local function pageItems(ui)
  local xui = xPilot.ui.scr.msg
  return math.floor((xui.h - ui.hdr.h) / ui.itms.h)
end

local function init(...)
  xLib = xPilot.lib
  local buf = {}
  buf.cur = 1
  buf.itms = 0
  buf.cap = 64
  buf.msg = {}
  data.buf = buf
  local font = xPilot.ui.font
  local ui = {}
  ui.sel = 1
  ui.first = 1
  ui.hdr = {}
  ui.hdr.h = font.nml.h + 2
  ui.itms = {}
  ui.itms.h = font.sml.h
  ui.page = pageItems(ui)
  data.ui = ui
  return true
end

local function exit(...)
  xLib.clearTable(data.buf)
  data.buf = nil
  xLib.clearTable(data.ui)
  data.ui = nil
  return true
end

local function clear()
  xLib.clearTable(buf.msg)
  return true
end

local function capa(n)
  data.buf.cap = n
  local ui = data.ui
  ui.page = pageItems(ui)
  return true
end

local function push(msg)
  local buf = data.buf
  buf.msg[buf.cur] = msg
  buf.cur = ( buf.cur < buf.cap ) and buf.cur + 1 or 1
  buf.itms = ( buf.itms < buf.cap ) and buf.itms + 1 or buf.cap
  return true
end

local function run(...)
  local ui = data.ui
  local buf = data.buf
  local evt = xPilot.evt
  if (... == evt.dn.rel) and (ui.sel < buf.itms) then
    local last = ui.first + ui.page
    ui.sel = ui.sel + 1
    if ui.sel >= last then
      ui.first = ui.first + 1
    end
  end
  if (... == evt.up.rel) and (ui.sel > 1) then
    if ui.sel <= ui.first then
      ui.first = ui.first - 1
    end
    ui.sel = ui.sel - 1
  end
  local xui = xPilot.ui.scr.msg
  local x = xui.x
  local y = xui.y + 1
  drawText(x, y, "Message file:", 0)
  x = x + 1
  y = xui.y + ui.hdr.h + 1
  local itms = xLib.min(buf.itms, ui.page)
  local sel = ui.sel - ui.first + 1
  local j = buf.cur - ui.first
  if j < 1 then j = j + buf.cap end
  for i = 1, itms do
    local flags = SMLSIZE
    if i == sel then flags = flags + INVERS end
    --print(string.format("%i %i %i %i: %s", i, j, buf.cur, ui.sel, buf.msg[j]))
    drawText(x, y, buf.msg[j], flags)
    y = y + ui.itms.h
    j = ( j > 1 ) and ( j - 1 ) or buf.cap
  end
  return true
end

return {
  init=init,
  exit=exit,
  run=run,
  clear=clear,
  capa=capa,
  push=push,
}
