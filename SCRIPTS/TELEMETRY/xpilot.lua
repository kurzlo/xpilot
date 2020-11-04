local xEnv = {}
xEnv.sim = false
xEnv.dir = {
  --[[ ["mod"] = "/MODELS/xpilot/", ]]
  ["scr"] = "/SCRIPTS/TELEMETRY/xpilot/",
  ["cfg"] = "/SCRIPTS/TELEMETRY/xpilot/",
  ["wav"] = "/SOUNDS/xpilot/en/",
  --[[ ["img"] = "/SCRIPTS/BMP/", ]]
  ["log"] = "/LOGS/",
}
xEnv.file = {
  ["scr"] = { "lib", --[["msg",]] "cfg", "telem", "alert", "menu", "main" },
  ["cfg"] = "xpilot",
}
xEnv.scr = {
  ["ext"] = { ".luac", ".lua" },
}

local xio = {
  ["open" ] = io.open,
  ["close"] = io.close,
  ["read" ] = io.read,
  ["write"] = io.write,
}

xPilot = {}
xPilot.evt = {
  ["shft"] = { ["prs"] =  96, ["rel"] = 32, ["lng"] = 128 },
  ["exit"] = { ["prs"] =  97, ["rel"] = 33, ["lng"] = 129 },
  ["entr"] = { ["prs"] =  98, ["rel"] = 34, ["lng"] = 130 },
  ["dn"  ] = { ["prs"] =  99, ["rel"] = 35, ["lng"] =  67 },
  ["up"  ] = { ["prs"] = 100, ["rel"] = 36, ["lng"] =  68 },
  ["rght"] = { ["prs"] = 101, ["rel"] = 37, ["lng"] =  69 },
  ["left"] = { ["prs"] = 102, ["rel"] = 38, ["lng"] =  70 },
}
xPilot.evt.handle = true
xPilot.ui = {
  ["font"] = {
    ["sml"] = { ["h"] =  7 },
    ["nml"] = { ["h"] =  7 },
    ["mid"] = { ["h"] = 11 },
    ["dbl"] = { ["h"] = 15 },
  },
}
local menuHeight = xPilot.ui.font.nml.h + 2
local bodyHeight = LCD_H - menuHeight
xPilot.ui.scr = {
  --[[ ["msg" ] = { ["x"] =  0, ["y"] = menuHeight, ["h"] = bodyHeight, ["w"] = LCD_W, }, ]]
  ["cfg" ] = { ["x"] =  0, ["y"] = menuHeight, ["h"] = bodyHeight, ["w"] = LCD_W, },
  ["menu"] = { ["x"] =  0, ["y"] = 0,          ["h"] = menuHeight, ["w"] = LCD_W, },
  ["main"] = { ["x"] =  0, ["y"] = menuHeight, ["h"] = bodyHeight, ["w"] = LCD_W, },
}
xPilot.env = {
  ["dir"] = xEnv.dir,
  ["file"] = {
    ["cfg"] = xEnv.file.cfg,
  }
}
xPilot.tic = nil
xPilot.lib = nil
xPilot.telem = nil
--[[ xPilot.msg = nil ]]
xPilot.cfg = nil


local xApp = nil
local xScrn = nil
local xLib = nil

local function doScript(filename)
  local func = nil
  local emsg = nil
  local ext = xEnv.scr.ext
  for i = 1, #ext do
    local v = xEnv.sim and ext[#ext - i + 1] or ext[i]
    func, emsg = loadScript(filename..v)
    if func then break end
  end
  return func, emsg
end

local function init(...)
  local result = true
  local app = xApp
  if not app then
    local ver, radio = getVersion()
    if string.find(radio, "simu") then
      xEnv.sim = true
      xio = fio
    end
    local scrDir = xEnv.dir.scr
    local scrFile = xEnv.file.scr
    app = {}
    for i = 1, #scrFile do
      local fn = scrFile[i]
      local func, emsg = doScript(scrDir..fn)
      if not func then
        print("Failed to load script \""..fn.."\": "..emsg)
        return false
      end
      local scr = {
        ["name"] = fn,
        ["func"] = func(),
        ["menu"] = fn == "menu",
        ["main"] = fn ~= "lib" and fn ~= "telem" and fn ~= "menu" and fn ~= "alert",
      }
      app[i] = scr
      xScrn = (scr.main and i) or xScrn
    end
    for i = 1, #app do
      local name = app[i].name
      local func = app[i].func
--print("App#"..i..": "..app[i].name)
      if name == "lib" then
        xPilot.lib = func
        xPilot.lib.io = xio
        local telem = {
          ["getFieldInfo"] = xEnv.sim and simGetFieldInfo or getFieldInfo,
          ["getValue"    ] = xEnv.sim and simGetValue     or getValue,
        }
        xPilot.lib.telem = telem
        xLib = xPilot.lib
      elseif name == "telem" then
        xPilot.telem = func
      --[[ elseif name == "msg" then
        xPilot.msg = {
          ["push" ] = func.push,
          ["clear"] = func.clear,
          ["capa" ] = func.capa,
        } ]]
      elseif name == "cfg" then
        xPilot.cfg = {
          ["get"] = func.get,
          ["set"] = func.set,
        }
      end
    end
    xPilot.tic = getTime()
    collectgarbage()
  end
  for i = 1, #app do
    local f = app[i].func
--print("Init"..i)
    if f.init and not f.init(...) then
      xLib.clearTable(app[i])
      app[i] = nil
      result = false
      collectgarbage()
    end
  end
  xApp = app
  return result
end

local function exit(...)
  local result = true
  if xApp then
    local app = xApp
    xApp = nil
    xScrn = nil
    xLib = nil
    for i = 1, #app do
      local f = app[i] and app[i].func
--print("Exit"..i)
      if f and f.exit and not f.exit(...) then
        result = false
      end
    end
    xPilot.lib.clearTable(app)
    xPilot.lib = nil
    xPilot.telem = nil
    --[[ xPilot.msg = nil ]]
    xPilot.cfg = nil
    collectgarbage()
  end
  return result
end

local function background(...)
  if xApp then
    xPilot.tic = getTime()
    for i = 1, #xApp do
      local f = xApp[i] and xApp[i].func
--print("Background"..i)
      if f and f.background and not f.background(...) then
        xLib.clearTable(f.background)
        xApp[i].func = f
        collectgarbage()
      end
    end
  end
  return true
end

local function run(...)
  lcd.clear()
  local evt = xPilot.evt
  if evt.handle and (... == evt.shft.lng) then
    if not exit(...) then
      return false
    end
    if not init(...) then
      return false
    end
  end
  if xApp then
    xPilot.tic = getTime()
    if evt.handle then
      local incr = ((... == evt.rght.rel) and 1) or ((... == evt.left.rel) and -1) or 0
      if incr ~= 0 then
        for i = 1, #xApp do
          xScrn = xScrn + incr
          xScrn = (xScrn > #xApp and 1) or (xScrn < 1 and #xApp) or xScrn
          if xApp[xScrn] and xApp[xScrn].main then
            break
          end
        end
      end
    end
    for i = 1, #xApp do
      if xApp[i] and ((i == xScrn and xApp[i].main) or xApp[i].menu) then
        local f = xApp[i].func
        if f and f.run and not f.run(...) then
--print("Run#"..i)
          xLib.clearTable(f.run)
          xApp[i].func = f
          collectgarbage()
        end
      end
    end
  end
  return not (... == evt.exit.lng)
end

return {
  init=init,
  background=background,
  run=run,
}
