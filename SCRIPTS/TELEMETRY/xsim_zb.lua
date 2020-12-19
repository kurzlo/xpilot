require("otx")
require("lcd")

local evt = {
  ["shft"] = { ["prs"] =  96, ["rel"] = 32, ["lng"] = 128 },
  ["exit"] = { ["prs"] =  97, ["rel"] = 33, ["lng"] = 129 },
  ["entr"] = { ["prs"] =  98, ["rel"] = 34, ["lng"] = 130 },
  ["dn"  ] = { ["prs"] =  99, ["rel"] = 35, ["lng"] =  67 },
  ["up"  ] = { ["prs"] = 100, ["rel"] = 36, ["lng"] =  68 },
  ["rght"] = { ["prs"] = 101, ["rel"] = 37, ["lng"] =  69 },
  ["left"] = { ["prs"] = 102, ["rel"] = 38, ["lng"] =  70 },
}

local pause = false

local xsim = dofile("SCRIPTS/TELEMETRY/xsim.lua")

lcd.init()
xsim.init()

local dt = .1
local t = 0

while true do
  local evtno = 0
  local key = char()
  if key then
    if key == char('J') then evtno = evt.dn.rel end
    if key == char('K') then evtno = evt.up.rel end
    if key == char('H') then evtno = evt.left.rel end
    if key == char('L') then evtno = evt.rght.rel end
    if key == char('R') then evtno = evt.shft.lng end
    if key == char('X') then evtno = evt.exit.lng end
    if key == char('E') then evtno = evt.entr.rel end
    if key == char('P') then
      if pause then print("> resume") end
      pause = not pause
      if pause then print("> pause") end
    end
  end
  if not pause then
    if evtno ~= 0 then print("> event "..evtno) end
    if not xsim.background(evtno) then break end
    if not xsim.run(evtno) then break end
    if evtno == evt.exit.lng then break end
    updt()
  end
  wait(dt)
  t = t + dt
end

xsim.exit()
lcd.exit()
