
local xpilot = {
  ["env"] = {
    ["sim"] = false,
    ["dir"] = {
      --[[ ["mod"] = "/MODELS/xpilot/", ]]
      ["scr"] = "/SCRIPTS/TELEMETRY/xpilot/",
      ["cfg"] = "/SCRIPTS/TELEMETRY/xpilot/",
      ["wav"] = "/SOUNDS/xpilot/en/",
      --[[ ["img"] = "/SCRIPTS/BMP/", ]]
      ["log"] = "/LOGS/",
    },
    ["cfg"] = {
      ["file"] = "xpilot",
    },
    ["evt"] = {
      ["shft"] = { ["prs"] =  96, ["rel"] = 32, ["lng"] = 128 },
      ["exit"] = { ["prs"] =  97, ["rel"] = 33, ["lng"] = 129 },
      ["entr"] = { ["prs"] =  98, ["rel"] = 34, ["lng"] = 130 },
      ["dn"  ] = { ["prs"] =  99, ["rel"] = 35, ["lng"] =  67 },
      ["up"  ] = { ["prs"] = 100, ["rel"] = 36, ["lng"] =  68 },
      ["rght"] = { ["prs"] = 101, ["rel"] = 37, ["lng"] =  69 },
      ["left"] = { ["prs"] = 102, ["rel"] = 38, ["lng"] =  70 },
    },
    ["font"] = {
      ["sml"] = { ["h"] =  7 },
      ["nml"] = { ["h"] =  7 },
      ["mid"] = { ["h"] = 11 },
      ["dbl"] = { ["h"] = 15 },
    },
  },
  ["tic"  ] = nil,
  ["evt"  ] = nil,
  ["lib"  ] = nil,
  ["cfg"  ] = nil,
  ["telem"] = nil,
}

local app = nil
local scrn = nil

local function init(...)
  local env = xpilot.env
  app = {}
  local ver, radio = getVersion()
  local sim = string.find(radio, "simu") ~= nil
  env.sim = sim
  local scr = {
    { ["file"] = "lib",   ["type"] = nil    },
    { ["file"] = "cfg",   ["type"] = "main" },
    { ["file"] = "telem", ["type"] = nil,   },
    { ["file"] = "alert", ["type"] = nil,   },
    --{ ["file"] = "log",   ["type"] = nil,   },
    { ["file"] = "menu",  ["type"] = "menu" },
    { ["file"] = "main",  ["type"] = "main" },
  }
  local fxt = (sim and ".lua" or ".luac")
  local k = 1
  xpilot.tic = getTime()
  xpilot.evt = { ["handle"] = true }
  for _,v in ipairs(scr) do
    local file = v.file
    local name = file
    local lib = xpilot.lib
    local xprint = lib and lib.print or print
    local func, emsg = loadScript(env.dir.scr..file..fxt)
    if func then
      local result = func()
      local a = {
        ["type"] = v.type,
        ["name"] = name,
        ["exit"] = result.exit,
        ["background"] = result.background,
        ["layout"] = result.layout,
        ["run"] = result.run,
      }
      if result.init and result.init(xpilot, ...) then
        xprint("Failed to execute \""..name..".init()\"")
      else
        xpilot[name] = result[name]
        if a.run then
          scrn = k
        end
        app[k] = a
        k = k + 1
      end
    else
      xprint("Failed to load \""..file.."\": "..emsg)
    end
  end
  collectgarbage()
  return true
  --return xpilot.lib and xpilot.cfg and xpilot.telem
end

local function exit(...)
  local clearTable = xpilot.lib.clearTable
  xpilot.tic = getTime()
  for i,v in ipairs(app) do
    if v and v.exit and v.exit(xpilot, ...) then
      local lib = xpilot.lib
      local xprint = lib and lib.print or print
      xprint("Failed to execute \""..v.name..".exit()\"")
    end
    app[i] = clearTable(v)
  end
  app = clearTable(app)
  xpilot.tic = clearTable(xpilot.tic)
  xpilot.evt = clearTable(xpilot.evt)
  scrn = nil
  collectgarbage()
  return true
end

local function background(...)
  xpilot.tic = getTime()
  for _,v in ipairs(app) do
    if v and v.background and v.background(xpilot, ...) then
      local lib = xpilot.lib
      lib.print("Failed to execute \""..v.name..".background()\"")
      v.background = lib.clearTable(v.background)
    end
  end
  return true
end

local function run(...)
  local evt = xpilot.env.evt
  local handle = xpilot.evt.handle
  if handle and (... == evt.shft.lng) then
    if not exit(...) then
      return false
    end
    if not init(...) then
      return false
    end
  end
  xpilot.tic = getTime()
  if app and scrn then
    local menuHeight = 9
    local frame = {
      ["menu"] = { ["x"] = 0, ["y"] = 0,          ["w"] = LCD_W, ["h"] =         menuHeight },
      ["main"] = { ["x"] = 0, ["y"] = menuHeight, ["w"] = LCD_W, ["h"] = LCD_H - menuHeight },
    }
    local lib = xpilot.lib
    lcd.clear()
    if handle then
      local incr = ((... == evt.rght.rel) and 1) or ((... == evt.left.rel) and -1) or 0
      if incr ~= 0 then
        for i = 1, #app do
          scrn = scrn + incr
          scrn = (scrn > #app and 1) or (scrn < 1 and #app) or scrn
          if app[scrn] and (app[scrn].type == "main") then
            break
          end
        end
      end
    end
    for i,v in ipairs(app) do
      if v and v.run then
        if (((i == scrn) and (v.type == "main")) or (v.type == "menu")) and v.run(xpilot, v.layout and v.layout(xpilot, frame[v.type]), ...) then
          lib.print("Failed to execute \""..v.name..".run()\"")
          app[i].run = lib.clearTable(v)
        end
      end
    end
  end
  return not (... == evt.exit.lng)
end

return {
  init = init,
  background = background,
  run = run,
}