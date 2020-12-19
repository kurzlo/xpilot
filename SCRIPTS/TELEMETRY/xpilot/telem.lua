
local flightModeStr = {
  -- APM Flight Modes
  --[[
  [ 0] = "Stabilize",
  [ 1] = "Acro",
  [ 2] = "Alt Hold",
  [ 3] = "Auto",
  [ 4] = "Guided",
  [ 5] = "Loiter",
  [ 6] = "RTL",
  [ 7] = "Circle",
  [ 8] = "Invalid Mode",
  [ 9] = "Landing",
  [10] = "Optic Loiter",
  [11] = "Drift",
  [12] = "Invalid Mode",
  [13] = "Sport",
  [14] = "Flip",
  [15] = "Auto Tune",
  [16] = "Pos Hold",
  [17] = "Brake",
  ]]
  -- PX4 Flight Modes
  [18] = "Manual",
  [19] = "Acro",
  [20] = "Stabilized",
  [21] = "RAttitude",
  [22] = "Position",
  [23] = "Altitude",
  [24] = "Offboard",
  [25] = "Takeoff",
  [26] = "Pause",
  [27] = "Mission",
  [28] = "RTL",
  [29] = "Landing",
  [30] = "Follow",
  -- N/A
  [31] = "No Telemetry",
}

local navStateStr = {
  [ 0] = "Manual",
  [ 1] = "Altitude",
  [ 2] = "Position",
  [ 3] = "Mission",
  [ 4] = "Loiter",
  [ 5] = "Return",
  [ 6] = "RC recover",
  [ 7] = "Return GS", --return ground station
  [ 8] = "Engine fail", --landing failed due to engine
  [ 9] = "GPS fail",
  [10] = "Acro",
  [11] = "Unused",
  [12] = "Descend",
  [13] = "Term",
  [14] = "Offboard",
  [15] = "Stabilze",
  [16] = "RAttitude",
  [17] = "Takeoff",
  [18] = "Auto land",
  [19] = "Auto follow",
  [20] = "Prec land",
  [21] = "Orbit",
}

local gpsStateStr = {
  [1] = "N/A",
  [2] = "2D",
  [3] = "3D",
  [4] = "DG", --differential GPS
}

local battTable = {
  { ["v"] = 3.3, ["p"] =   0, ["d"] = nil, },
  { ["v"] = 3.6, ["p"] =   5, ["d"] = nil, },
  { ["v"] = 3.7, ["p"] =  15, ["d"] = nil, },
  { ["v"] = 4.0, ["p"] =  85, ["d"] = nil, },
  { ["v"] = 4.2, ["p"] = 100, ["d"] = nil, },
}

local idxRxBt =  1;
local idxRSSI =  2;
local idxVSpd =  3;
local idxGPS  =  4;
local idxTmp2 =  5;
local idxCurr =  6;
local idxAlt  =  7;
local idxVFAS =  8;
local idxTmp1 =  9;
local idxGSpd = 10;
local idxGAlt = 11;
local idxDate = 12;
local idxFuel = 13;
local idxHdg  = 14;
local idxDist = 15;
local idxPtch = 16;
local idxRoll = 17;
local idxYaw  = 18;
local idx5000 = 19;
local idx5001 = 20;

local tic = nil
local telemTab = nil

local function init(xpilot, ...)
  local cfg = xpilot.cfg
  local getConfig = cfg and cfg.get
  local telemCfg = getConfig and getConfig("telem")
  local lib = xpilot.lib
  local ticInit = lib.tic.init
  local tics = {
    ["upd"] = telemCfg and telemCfg.updRate or 1,
    ["cfg"] = 1--[[Hz]],
  }
  tic = {}
  for i,v in pairs(tics) do
    tic[i] = ticInit(xpilot.tic, v)
  end
  idRxBt = getFiled
  local tag = {
    [idxRxBt] = "RxBt",
    [idxRSSI] = "RSSI",
    [idxVSpd] = "VSpd",
    [idxGPS ] = "GPS",
    [idxTmp2] = "Tmp2", --gps number of satellites/fix
    [idxCurr] = "Curr",
    [idxAlt ] = "Alt",
    [idxVFAS] = "VFAS", --battery voltage (sum)
    [idxTmp1] = "Tmp1", --flight mode
    [idxGSpd] = "GSpd",
    [idxGAlt] = "GAlt",
    [idxDate] = "Date",
    [idxFuel] = "Fuel",
    [idxHdg ] = "Hdg",
    [idxDist] = "Dist", --distance from home
    [idxPtch] = "Ptch", --pitch
    [idxRoll] = "Roll", --roll
    [idxYaw ] = "Yaw", --yaw
    --"5000", --Nav state (+128)
    --"5001", --GPS fix (same as TMP2)
  }
  local getFieldInfo = lib.telem.getFieldInfo
  telemTab = {}
  for i,v in pairs(tag) do
    local f = getFieldInfo(v)
    if f then
      telemTab[i] = {
        --["tag"] = v,
        ["name"] = f.name,
        ["id"] = f.id,
        ["val"] = nil,
      }
    end
  end
  for i = 2, #battTable do
    local dv = battTable[i].v - battTable[i-1].v
    local dp = battTable[i].p - battTable[i-1].p
    battTable[i].d = dp / dv
  end
end

function exit(xpilot, ...)
  local clearTable = xpilot.lib.clearTable
  tic = clearTable(tic)
  telemTab = clearTable(telemTab)
end

local function background(xpilot, ...)
  local lib = xpilot.lib
  local xtic = lib.tic
  local now = xpilot.tic
  local update = xtic.update
  if update(tic.upd, now) then
    local getValue = lib.telem.getValue
    for _,v in pairs(telemTab) do
      v.val = v.id and getValue(v.id)
    end
  end
  local cfg = xpilot.cfg
  if cfg and update(tic.cfg, now) then
    tic.upd = xtic.setRate(tic.upd, cfg.get("telem", "updRate"))
  end
end

local function flightMode(idx)
  idx = idx or (idxTmp1 and telemTab[idxTmp1].val)
  return (idx and flightModeStr[idx] or "N/A"), idx
end

local function navState(idx)
  idx = idx or (idx5000 and telemTab[idx5000].val)
  return idx and idx >= 128 and navStateStr[idx - 128] or "N/A"
end

local function battVTotal()
  return idxVFAS and telemTab[idxVFAS].val or 0
end

local function battVCell(VTotal, cells)
  VTotal = VTotal or battVTotal()
  return cells and (cells > 0) and ((VTotal or 0) / cells) or 0
end

local function battVCellRel(VCell)
  VCell = VCell or battVCell()
  if VCell >= battTable[#battTable].v then
    VCell = battTable[#battTable].p
  elseif VCell <= battTable[1].v then
    VCell = battTable[1].p
  else
    for i = 2, #battTable do
      if VCell < battTable[i].v then
        VCell = battTable[i-1].p + (VCell - battTable[i-1].v) * battTable[i].d
        break
      end
    end
  end
  return VCell
end

local function battITotal()
  return idxCurr and telemTab[idxCurr].val or 0
end

local function battIRel(ITotal, capa, cmax)
  if capa and (capa > 0) and cmax and (cmax > 0) then
    ITotal = ITotal or current()
    ITotal = 100 * ITotal / (cmax * capa * 1e-3--[[mA->A]])
    ITotal = (ITotal < 0 and 0) or (ITotal > 100 and 100) or ITotal
    return ITotal
  else
    return 0
  end
end

local function battFuel()
  return idxFuel and telemTab[idxFuel].val or 0
end

local function gpsState()
  local state = idxTmp2 and telemTab[idxTmp2].val
  local sats = state and state / 10 or 0
  local fix = state and state % 10 or 0
  return fix, sats
end

local function gpsFix(state)
  state = state or gpsState()
  return state and gpsStateStr[state] or "N/A"
end

local function gpsFix3d(state)
  state = state or gpsState()
  return state > 2
end

local function gpsLatLon()
  local gps = idxGPS and telemTab[idxGPS].val
  if gps and type(gps) == "table" then
    return gps.lat or 0, gps.lon or 0
  else
    return 0, 0
  end
end

local function gpsAlt()
  return idxGAlt and telemTab[idxGAlt].val or 0
end

local function gpsSoG()
  local val = idxGSpd and telemTab[idxGSpd].val
  return val and val * 0.514444 --[[knots --> m/s]] or 0
end

local function gpsHead()
  return idxHdg and telemTab[idxHdg].val or 0
end

local function baroAlt() --meters
  return idxAlt and telemTab[idxAlt].val or 0
end

local function baroRoC() 
  return idxVSpd and telemTab[idxVSpd].val or 0
end

local function rssi()
  return idxRSSI and telemTab[idxRSSI].val or 0
end

local function dist() --meters
  return idxDist and telemTab[idxDist].val or 0
end

local telem = {
  ["flightMode"] = flightMode,
  ["navState"] = navState,
  ["batt"] = {
    ["VTotal"  ] = battVTotal,
    ["VCell"   ] = battVCell,
    ["VCellRel"] = battVCellRel,
    ["ITotal"  ] = battITotal,
    ["IRel"    ] = battIRel,
    ["fuel"    ] = battFuel,
  },
  ["gps"] = {
    ["state" ] = gpsState,
    ["fix"   ] = gpsFix,
    ["fix3d" ] = gpsFix3d,
    ["LatLon"] = gpsLatLon,
    ["alt"   ] = gpsAlt,
    ["SoG"   ] = gpsSoG,
    ["head"  ] = gpsHead,
  },
  ["baro"] = {
    ["alt"] = baroAlt,
    ["RoC"] = baroRoC,
  },
  ["rssi"] = rssi,
  ["dist"] = dist,
  ["tab"] = function () return telemTab end,
}

return {
  init = init,
  exit = exit,
  background = background,
  telem = telem,
}
