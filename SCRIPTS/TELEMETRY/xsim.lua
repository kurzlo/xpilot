local xPilot
local xPilotFile = "/SCRIPTS/TELEMETRY/xpilot.lua"

local telemPeriod = 100
--local telemFile = "/LOGS/20200502_131341_telem.log"
local telemFile = "/LOGS/telem.log"

local telemTab = nil
local telemFid = nil
local telemTic = nil

local function telemOpen(fn)
  telemFid = fn and fio.open(fn, "r")
  if telemFid then
    local c = fio.read(telemFid, 1)
    if c ~= "#" then
      return nil
    end
    telemTab = {}
    local id = 1
    local idx = 1
    local buf = ""
    while true do
      c = fio.read(telemFid, 1)
      if not c or c == "" then
        fio.close(telemFid)
        telemFid = nil
        break
      elseif c == ";" then
        if buf == "lat" or buf == "lon" then
          local itm = telemTab.GPS
          if not itm then
            itm = { ["id"] = id, ["idx"] = {}, ["val"] = {} }
            id = id + 1
          end
          itm.idx[buf] = idx
          telemTab.GPS = itm
        elseif buf == "year" or buf == "mon" or buf == "day" or buf == "hour" or buf == "min" or buf == "sec" then
          local itm = telemTab.Date
          if not itm then
            itm = { ["id"] = id, ["idx"] = {}, ["val"] = {} }
            id = id + 1
          end
          itm.idx[buf] = idx
          telemTab.Date = itm
        else
          local itm = telemTab[buf]
          if not itm then
            itm = { ["id"] = id, ["idx"] = idx }
            id = id + 1
            telemTab[buf] = itm
          end
        end
        idx = idx + 1
        buf = ""
      elseif c == "\n" then
        break
      else
        buf = buf..c
      end
    end
    print("Telemetry table:")
    for i,v in pairs(telemTab) do
      v.name = i
      print("  "..v.name.." ("..v.id..")")
    end
  end
  return true
end

local function telemUpdate(now)
  local dt = now - telemTic
  if dt > telemPeriod then
    telemTic = now
    if telemFid then
      local idx = 1
      local buf = ""
      while true do
        local c = fio.read(telemFid, 1)
        if c == nil or c == "" then
          fio.close(telemFid)
          telemFid = nil
          break
        elseif c == ";" then
          for _,vi in pairs(telemTab) do
            if type(vi.idx) == "table" then
              for j,vj in pairs(vi.idx) do
                if vj == idx then
                  vi.val[j] = tonumber(buf)
                end
              end
            else
              if vi.idx == idx then
                vi.val = tonumber(buf)
                break
              end
            end
--if vi.tag == "Curr" then vi.val = 180000 end
          end
          idx = idx + 1
          buf = ""
        elseif c == "\n" then
          break
        else
          buf = buf..c
        end
      end
    end

print("Telemetry update:")
for i,vi in pairs(telemTab) do
  local str = "  "..i..": "
  if type(vi.val) == "table" then
    for j,vj in pairs(vi.val) do
      str = str..j.."="..vj..", "
    end
  else
    str = str..vi.val
  end
  print(str)
end

    telemTic = getTime()
  end
  return true
end

local function telemClose()
  if telemFid then
    fio.close(telemFid)
    telemFid = nil
  end
  return true
end

function simGetFieldInfo(source)
  local field
  for i,v in pairs(telemTab) do
    if i == source then
      field = { ["id"] = v.id, ["name"] = i, ["desc"] = "", ["unit"] = "" }
      break
    end
  end
  --print("Field info request: "..(field and field.name or "nil").." ("..(field and field.id or "nil")..")")
  return field
end

function simGetValue(source)
  local field
  local mtch = type(source) == "number" and "id" or "name"
  for _,v in pairs(telemTab) do
    if v[mtch] == source then
      field = v
      break
    end
  end
  --print("Field value request: "..(field and field.name or "nil").." ("..(field and field.id or "nil").."): "..(field and field.val or "nil"))
  return field and field.val
end

local function init(...)
  if not fio then
    fio = io
  end
  local func, emsg = loadScript(xPilotFile)
  if func then
    xPilot = func()
  else
    print("Failed to load xPilot script \""..xPilotFile.."\"")
    print("Error message: "..emsg)
    return false
  end
  if not telemOpen(telemFile) then
    print("Failed to open telemetry log file \""..telemFile.."\"")
  end
  if not xPilot.init(...) then
    print("Failed to initialize xPilot")
    return false
  end
  telemTic = getTime()
  return true
end

local function background(...)
  telemUpdate(getTime())
  return xPilot.background(...)
end

local function run(...)
  return xPilot.run(...)
end

return {
  init=init,
  background=background,
  run=run,
}
