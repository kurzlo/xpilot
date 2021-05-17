
local tab = {
  { ["hdr"] = "Battery" },
  { ["itm"] =   "Cells",        ["grp"] = "batt", ["val"] = "cells", ["unit"] = nil,   ["num"] = { ["min"] =   1, ["max"] =    10, ["inc"] =   1 } },
  { ["itm"] =   "Capacity",     ["grp"] = "batt", ["val"] = "capa",  ["unit"] = "mAh", ["num"] = { ["min"] = 500, ["max"] = 10000, ["inc"] = 100 } },
  { ["itm"] =   "Avg C-Value",  ["grp"] = "batt", ["val"] = "cval",  ["unit"] = nil,   ["num"] = { ["min"] =  10, ["max"] =   500, ["inc"] =   5 } },
  { ["itm"] =   "Max C-Value",  ["grp"] = "batt", ["val"] = "cmax",  ["unit"] = nil,   ["num"] = { ["min"] =  10, ["max"] =   500, ["inc"] =   5 } },
  { ["hdr"] = "Telemetry" },
  { ["itm"] =   "Update Rate",  ["grp"] = "telem", ["val"] = "updRate", ["unit"] = "Hz",  ["num"] = { ["min"] = 1, ["max"] = 10, ["inc"] = 1 } },
  { ["itm"] =   "Logging",      ["grp"] = "telem", ["val"] = "rec",     ["unit"] = nil,   ["combo"] = { [1] = "Disabled", [2] = "Enabled" } },
  { ["itm"] =   "Logging Rate", ["grp"] = "telem", ["val"] = "logRate", ["unit"] = "Hz",  ["num"] = { ["min"] = 1, ["max"] = 10, ["inc"] = 1 } },
  { ["itm"] =   "Notify loss",  ["grp"] = "telem", ["val"] = "notify",  ["unit"] = nil,   ["combo"] = { [1] = "Disabled", [2] = "Enabled" } },
}

local config = {
  ["batt"] = {
    ["cells"] = 4,
    ["capa" ] = 1800,
    ["cval" ] = 75,
    ["cmax" ] = 135,
  },
  ["telem"] = {
    ["updRate"] = 1,
    ["rec"] = 1,
    ["logRate"] = 1,
    ["notify"] = 1,
  },
}

local ctl = nil

local function firstItem()
  local first = 1
  while tab[first].itm == nil and first <= #tab do
    first = first + 1
  end
  return first <= #tab and first
end

local function updnEvent(xpilot, ...)
  local evt = xpilot.env.evt
  if (... == evt.dn.rel) then
    local last = ctl.first + ctl.pageSize
    while ctl.sel < #tab do
      ctl.sel = ctl.sel + 1
      if ctl.sel >= last then
        ctl.first = ctl.first + 1
      end
      if tab[ctl.sel].itm then
        break
      end
    end
  end
  if (... == evt.up.rel) then
    local first = firstItem()
    while ctl.sel > first do
      ctl.sel = ctl.sel - 1
      if ctl.sel < ctl.first then
        ctl.first = ctl.first - 1
      end
      if ctl.sel == first then
        ctl.first = first - 1
      end
      if tab[ctl.sel].itm then
        break
      end
    end
  end
end

local function verifyEntry(v, grp, val)
  if grp == "batt" then
    local batt = config.batt
    if val == "cval" then
      return v <= batt.cmax
    elseif val == "cmax" then
      return v >= batt.cval
    end
  end
  return true
end

local function enterEvent(xpilot, ...)
  local env = xpilot.env
  local lib = xpilot.lib
  local evt = env.evt
  local writeConfig = false
  if (... == evt.entr.rel) then
    xpilot.evt.handle = ctl.enter
    writeConfig = ctl.enter
    ctl.enter = not ctl.enter
  end
  if ctl.enter then
    local v = tab[ctl.sel]
    if v.grp and v.val then
      local cfgGrp = config[v.grp]
      local val = cfgGrp[v.val]
      if val then
        if v.num or v.combo then
          local inc = v.num and v.num.inc or 1
          local newVal = val
          if (... == evt.rght.rel) then
            local vmax = v.num and v.num.max or #v.combo
            newVal = val + inc
            newVal = lib.math.min(newVal, vmax)
          end
          if (... == evt.left.rel) then
            local vmin = v.num and v.num.min or 1
            newVal = val - inc
            newVal = lib.math.max(newVal, vmin)
          end
          if verifyEntry(newVal, v.grp, v.val) then
            cfgGrp[v.val] = newVal;
          end
        end
      end
    end
  end
  if writeConfig then
    local xio = lib.io
    local file = env.cfg.file
    local fid = xio.open(env.dir.cfg..file..".cfg", "w")
    if fid then
      for i,vi in pairs(config) do
        xio.write(fid, i.."={")
        for j,vj in pairs(vi) do
          xio.write(fid, j.."="..vj..";")
        end
        xio.write(fid, "}\n")
      end
      xio.close(fid)
    else
      lib.print("Failed to write configuration \""..file.."\"")
    end
    collectgarbage()
    collectgarbage()
  end
end

local function readConfig(xpilot, fid, ...)
  local xio = xpilot.lib.io
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
      vi[i] = readConfig(xpilot, fid, vi)
    elseif c == "}" then
      break
    elseif c ~= "\n" then
      buf = buf..c
    end
  end
  collectgarbage()
  collectgarbage()
  return vi
end

local function init(xpilot, ...)
  local env = xpilot.env
  local lib = xpilot.lib
  ctl = {
    ["sel"] = firstItem(),
    ["first"] = 1,
    ["pageSize"] = 0,
    ["enter"] = false,
  }
  local xio = lib.io
  local file = env.cfg.file
  local fid = xio.open(env.dir.cfg..file..".cfg", "r")
  if fid then
    local newCfg = readConfig(xpilot, fid)
    xio.close(fid)
    for i,vi in pairs(config) do
      for m,vm in pairs(newCfg) do
        if m == i then
          for j,_ in pairs(vi) do
            for n,vn in pairs(vm) do
              if n == j then
                config[i][j] = tonumber(vn)
              end
            end
          end
        end
      end
    end
  else
    lib.print("Failed to open configuration \""..file.."\"")
  end
end

local function exit(xpilot, ...)
  ctl = xpilot.lib.clearTable(ctl)
end

local function run(xpilot, x, y, w, h, ...)
  local stride = xpilot.env.font.sml.h
  local pageSize = math.floor(h / stride)
  ctl.pageSize = pageSize
  enterEvent(xpilot, ...)
  if not ctl.enter then
    updnEvent(xpilot, ...)
  end
  local env = xpilot.env
  local lib = xpilot.lib
  local xmath = lib.math
  local drawText = lcd.drawText
  local stride = stride
  local x0 = x
  local x1 = x0 + 4
  local x2 = x0 + math.floor(w / 2)
  local y = y + 1
  local last = xmath.min(#tab, ctl.first + pageSize)
  for i = ctl.first, last do
    local v = tab[i]
    if v.hdr then
      drawText(x0, y, v.hdr, SMLSIZE)
      y = y + stride
    end
    if v.itm then
      local val = v.grp and v.val and config[v.grp][v.val]
      if val then
        local flags = SMLSIZE
        drawText(x1, y, v.itm, flags)
        if i == ctl.sel then
          flags = flags + INVERS
          if ctl.enter then
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
        y = y + stride
      end
    end
  end
end

local function getConfig(grp,val)
  return (val and config[grp][val]) or (grp and config[grp]) or config
end

local function setConfig(grp,val, v)
  if val then
    config[grp][val] = v
  elseif grp then
    config[grp] = v
  else
    config = v
  end
end

local cfg = {
  ["get"] = getConfig,
  ["set"] = setConfig,
}

return {
  init = init,
  exit = exit,
  run = run,
  cfg = cfg,
}