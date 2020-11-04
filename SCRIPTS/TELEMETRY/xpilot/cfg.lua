local xLib = nil

local settings = {}
settings.table = {
  { ["hdr"] = "Battery" },
  { ["itm"] =   "Cells",        ["grp"] = "batt", ["val"] = "cells", ["unit"] = nil,   ["num"] = { ["min"] =   1, ["max"] =    10, ["inc"] =   1 } },
  { ["itm"] =   "Capacity",     ["grp"] = "batt", ["val"] = "capa",  ["unit"] = "mAh", ["num"] = { ["min"] = 500, ["max"] = 10000, ["inc"] = 100 } },
  { ["itm"] =   "Avg C-Value",  ["grp"] = "batt", ["val"] = "cval",  ["unit"] = nil,   ["num"] = { ["min"] =  10, ["max"] =   500, ["inc"] =   5 } },
  { ["itm"] =   "Max C-Value",  ["grp"] = "batt", ["val"] = "cmax",  ["unit"] = nil,   ["num"] = { ["min"] =  10, ["max"] =   500, ["inc"] =   5 } },
  { ["hdr"] = "Telemetry" },
  { ["itm"] =   "Logging",      ["grp"] = "telem", ["val"] = "rec",     ["unit"] = nil,   ["combo"] = { [1] = "Disabled", [2] = "Enabled" } },
  { ["itm"] =   "Update Rate",  ["grp"] = "telem", ["val"] = "updRate", ["unit"] = "Hz",  ["num"] = { ["min"] = 1, ["max"] = 10, ["inc"] = 1 }  },
  { ["itm"] =   "Logging Rate", ["grp"] = "telem", ["val"] = "logRate", ["unit"] = "Hz",  ["num"] = { ["min"] = 1, ["max"] = 10, ["inc"] = 1 }  },
}

local data = {}
data.ui = nil
data.cfg = {
  ["batt"] = {
    ["cells"] = 4,
    ["capa" ] = 1800,
    ["cval" ] = 75,
    ["cmax" ] = 135,
  },
  ["telem"] = {
    ["rec"] = 1,
    ["updRate"] = 5,
    ["logRate"] = 1,
  }
}


local function firstItem()
  local tab = settings.table
  local first = 1
  while tab[first].itm == nil and first <= #tab do
    first = first + 1
  end
  return first <= #tab and first
end

local function updnEvent(...)
  local evt = xPilot.evt
  local ui = data.ui
  local tab = settings.table
  if (... == evt.dn.rel) then
    local last = ui.first + ui.pageSize
    while ui.sel < #tab do
      ui.sel = ui.sel + 1
      if ui.sel >= last then
        ui.first = ui.first + 1
      end
      if tab[ui.sel].itm then
        break
      end
    end
  end
  if (... == evt.up.rel) then
    local first = firstItem()
    while ui.sel > first do
      ui.sel = ui.sel - 1
      if ui.sel < ui.first then
        ui.first = ui.first - 1
      end
      if ui.sel == first then
        ui.first = first - 1
      end
      if tab[ui.sel].itm then
        break
      end
    end
  end
end

function verifyEntry(v, grp, val)
  if grp == "batt" then
    local batt = data.cfg.batt
    if val == "cval" then
      return v <= batt.cmax
    elseif val == "cmax" then
      return v >= batt.cval
    end
  end
  return true
end

local function enterEvent(...)
  local evt = xPilot.evt
  local ui = data.ui
  local writeConfig = false
  if (... == evt.entr.rel) then
    evt.handle = ui.enter
    writeConfig = ui.enter
    ui.enter = not ui.enter
  end
  if ui.enter then
    local tab = settings.table
    local v = tab[ui.sel]
    if v.grp and v.val then
      local cfg = data.cfg
      local cfgGrp = cfg[v.grp]
      local val = cfgGrp[v.val]
      local right = (... == evt.rght.rel)
      local left = (... == evt.left.rel)
      if val then
        if v.num or v.combo then
          local inc = v.num and v.num.inc or 1
          local min = v.num and v.num.min or 1
          local max = v.num and v.num.max or #v.combo
          local newVal = val
          if right then
            newVal = val + inc
            newVal = xLib.min(newVal, max)
          end
          if left then
            newVal = val - inc
            newVal = xLib.max(newVal, min)
          end
          if verifyEntry(newVal, v.grp, v.val) then
            cfgGrp[v.val] = newVal;
          end
        end
      end
    end
  end
  if writeConfig then
    local xEnv = xPilot.env
    local xio = xLib.io
    local cfgDir = xEnv.dir.cfg
    local cfgFile = xEnv.file.cfg
    local fid = xio.open(cfgDir..cfgFile..".cfg", "w")
    if fid then
      local cfg = data.cfg
      for i,vi in pairs(cfg) do
        xio.write(fid, i.."={")
        for j,vj in pairs(vi) do
          xio.write(fid, j.."="..vj..";")
        end
        xio.write(fid, "}\n")
      end
      xio.close(fid)
    end
  end
end

local function readConfig(fid, ...)
  local xio = xLib.io
  local buf = ""
  local vi, i
  if not vi then vi = {} end
  while true do
    local c = xio.read(fid, 1)
    if c == "" or not c then
      break
    elseif c == "=" then
      i = buf
      buf = ""
    elseif c == ";" then
      vi[i] = buf
      buf = ""
    elseif c == "{" then
      vi[i] = readConfig(fid, vi)
    elseif c == "}" then
      break
    elseif c ~= "\n" then
      buf = buf..c
    end
  end
  return vi
end

local function init(...)
  local xui = xPilot.ui.scr.cfg
  local font = xPilot.ui.font
  xLib = xPilot.lib
  local ui = {}
  ui.sel = firstItem()
  ui.first = 1
  ui.pageSize = math.floor(xui.h / font.sml.h)
  ui.enter = false
  data.ui = ui
  local xEnv = xPilot.env
  local xio = xLib.io
  local cfgDir = xEnv.dir.cfg
  local cfgFile = xEnv.file.cfg
  local fid = xio.open(cfgDir..cfgFile..".cfg", "r")
  if fid then
    local newCfg = readConfig(fid)
    xio.close(fid)
    local cfg = data.cfg
    for i,vi in pairs(cfg) do
      for m,vm in pairs(newCfg) do
        if m == i then
          for j,_ in pairs(vi) do
            for n,vn in pairs(vm) do
              if n == j then
                cfg[i][j] = tonumber(vn)
              end
            end
          end
        end
      end
    end
    data.cfg = cfg
  end
  return true
end

local function run(...)
  local ui = data.ui
  enterEvent(...)
  if not ui.enter then
    updnEvent(...)
  end
  local tab = settings.table
  local cfg = data.cfg
  local xui = xPilot.ui.scr.cfg
  local fontSize = xPilot.ui.font.sml.h
  local x0 = xui.x
  local x1 = x0 + 4
  local x2 = x0 + math.floor(xui.w / 2)
  local y = xui.y + 1
  local last = xLib.min(#tab, ui.first + ui.pageSize)
  local drawText = lcd.drawText
  for i = ui.first, last do
    local v = tab[i]
    if v.hdr then
      drawText(x0, y, v.hdr, SMLSIZE)
      y = y + fontSize
    end
    if v.itm then
      local val = v.grp and v.val and cfg[v.grp][v.val]
      if val then
        local flags = SMLSIZE
        drawText(x1, y, v.itm, flags)
        if i == ui.sel then
          flags = flags + INVERS
          if ui.enter then
            flags = flags + BLINK
          end
        end
        local vstr = ""
        if v.num then
          vstr = val
        elseif v.combo then
          vstr = v.combo[val]
        end
        drawText(x2, y, vstr..(v.unit and " "..v.unit or ""), flags)
        y = y + fontSize
      end
    end
  end
  return true
end

function get(grp,val)
  return (val and data.cfg[grp][val]) or (grp and data.cfg[grp]) or data.cfg
end

function set(grp,val, v)
  if val then
    data.cfg[grp][val] = v
  elseif grp then
    data.cfg[grp] = v
  else
    data.cfg = v
  end
end

return {
  init=init,
  run=run,
  get=get,
  set=set,
}
