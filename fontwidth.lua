--[[
  print("local sml = {}")
  for i=32, 126 do
    lcd.drawText(0,0,string.char(i),SMLSIZE)
    print(string.format("sml[%i] = %i", i, lcd.getLastRightPos()))
  end
  print("local nml = {}")
  for i=32, 126 do
    lcd.drawText(0,0,string.char(i),0)
    print(string.format("nml[%i] = %i", i, lcd.getLastRightPos()))
  end
  print("local mid = {}")
  for i=32, 126 do
    lcd.drawText(0,0,string.char(i),MIDSIZE)
    print(string.format("mid[%i] = %i", i, lcd.getLastRightPos()))
  end
  print("local dbl = {}")
  for i=32, 126 do
    lcd.drawText(0,0,string.char(i),DBLSIZE)
    print(string.format("dbl[%i] = %i", i, lcd.getLastRightPos()))
  end
]]

local sml = {}
sml[32] = 3
sml[33] = 2
sml[34] = 4
sml[35] = 6
sml[36] = 6
sml[37] = 5
sml[38] = 5
sml[39] = 2
sml[40] = 3
sml[41] = 3
sml[42] = 4
sml[43] = 6
sml[44] = 4
sml[45] = 5
sml[46] = 2
sml[47] = 5
sml[48] = 5
sml[49] = 5
sml[50] = 5
sml[51] = 5
sml[52] = 5
sml[53] = 5
sml[54] = 5
sml[55] = 5
sml[56] = 5
sml[57] = 5
sml[58] = 2
sml[59] = 4
sml[60] = 4
sml[61] = 5
sml[62] = 4
sml[63] = 4
sml[64] = 4
sml[65] = 5
sml[66] = 5
sml[67] = 5
sml[68] = 5
sml[69] = 5
sml[70] = 5
sml[71] = 5
sml[72] = 5
sml[73] = 4
sml[74] = 5
sml[75] = 5
sml[76] = 5
sml[77] = 6
sml[78] = 5
sml[79] = 5
sml[80] = 5
sml[81] = 5
sml[82] = 5
sml[83] = 5
sml[84] = 4
sml[85] = 5
sml[86] = 5
sml[87] = 6
sml[88] = 5
sml[89] = 4
sml[90] = 5
sml[91] = 4
sml[92] = 5
sml[93] = 4
sml[94] = 4
sml[95] = 5
sml[96] = 3
sml[97] = 5
sml[98] = 5
sml[99] = 4
sml[100] = 5
sml[101] = 5
sml[102] = 5
sml[103] = 5
sml[104] = 5
sml[105] = 4
sml[106] = 4
sml[107] = 5
sml[108] = 4
sml[109] = 6
sml[110] = 5
sml[111] = 5
sml[112] = 5
sml[113] = 5
sml[114] = 5
sml[115] = 5
sml[116] = 5
sml[117] = 5
sml[118] = 4
sml[119] = 6
sml[120] = 5
sml[121] = 5
sml[122] = 5
sml[123] = 4
sml[124] = 2
sml[125] = 4
sml[126] = 5
local nml = {}
nml[32] = 3
nml[33] = 2
nml[34] = 4
nml[35] = 6
nml[36] = 6
nml[37] = 6
nml[38] = 6
nml[39] = 3
nml[40] = 4
nml[41] = 4
nml[42] = 6
nml[43] = 6
nml[44] = 3
nml[45] = 5
nml[46] = 2
nml[47] = 6
nml[48] = 5
nml[49] = 5
nml[50] = 5
nml[51] = 5
nml[52] = 5
nml[53] = 5
nml[54] = 5
nml[55] = 5
nml[56] = 5
nml[57] = 5
nml[58] = 3
nml[59] = 3
nml[60] = 5
nml[61] = 6
nml[62] = 5
nml[63] = 6
nml[64] = 5
nml[65] = 6
nml[66] = 6
nml[67] = 6
nml[68] = 6
nml[69] = 6
nml[70] = 6
nml[71] = 6
nml[72] = 6
nml[73] = 4
nml[74] = 6
nml[75] = 6
nml[76] = 5
nml[77] = 6
nml[78] = 6
nml[79] = 6
nml[80] = 6
nml[81] = 6
nml[82] = 6
nml[83] = 6
nml[84] = 6
nml[85] = 6
nml[86] = 6
nml[87] = 6
nml[88] = 6
nml[89] = 6
nml[90] = 6
nml[91] = 4
nml[92] = 6
nml[93] = 4
nml[94] = 6
nml[95] = 5
nml[96] = 4
nml[97] = 6
nml[98] = 6
nml[99] = 6
nml[100] = 6
nml[101] = 6
nml[102] = 6
nml[103] = 6
nml[104] = 6
nml[105] = 4
nml[106] = 5
nml[107] = 5
nml[108] = 4
nml[109] = 6
nml[110] = 6
nml[111] = 6
nml[112] = 6
nml[113] = 6
nml[114] = 6
nml[115] = 6
nml[116] = 6
nml[117] = 6
nml[118] = 6
nml[119] = 6
nml[120] = 6
nml[121] = 6
nml[122] = 6
nml[123] = 5
nml[124] = 2
nml[125] = 5
nml[126] = 6
local mid = {}
mid[32] = 6
mid[33] = 4
mid[34] = 7
mid[35] = 9
mid[36] = 9
mid[37] = 10
mid[38] = 10
mid[39] = 4
mid[40] = 7
mid[41] = 7
mid[42] = 9
mid[43] = 7
mid[44] = 5
mid[45] = 7
mid[46] = 4
mid[47] = 10
mid[48] = 8
mid[49] = 8
mid[50] = 8
mid[51] = 8
mid[52] = 8
mid[53] = 8
mid[54] = 8
mid[55] = 8
mid[56] = 8
mid[57] = 8
mid[58] = 4
mid[59] = 6
mid[60] = 8
mid[61] = 8
mid[62] = 8
mid[63] = 9
mid[64] = 8
mid[65] = 10
mid[66] = 10
mid[67] = 10
mid[68] = 10
mid[69] = 9
mid[70] = 10
mid[71] = 10
mid[72] = 10
mid[73] = 8
mid[74] = 8
mid[75] = 10
mid[76] = 9
mid[77] = 10
mid[78] = 10
mid[79] = 10
mid[80] = 10
mid[81] = 10
mid[82] = 10
mid[83] = 10
mid[84] = 10
mid[85] = 10
mid[86] = 10
mid[87] = 10
mid[88] = 10
mid[89] = 10
mid[90] = 9
mid[91] = 7
mid[92] = 10
mid[93] = 7
mid[94] = 8
mid[95] = 10
mid[96] = 6
mid[97] = 9
mid[98] = 9
mid[99] = 9
mid[100] = 9
mid[101] = 9
mid[102] = 9
mid[103] = 9
mid[104] = 9
mid[105] = 8
mid[106] = 9
mid[107] = 8
mid[108] = 8
mid[109] = 9
mid[110] = 9
mid[111] = 9
mid[112] = 9
mid[113] = 9
mid[114] = 9
mid[115] = 9
mid[116] = 9
mid[117] = 9
mid[118] = 9
mid[119] = 9
mid[120] = 9
mid[121] = 9
mid[122] = 8
mid[123] = 7
mid[124] = 4
mid[125] = 7
mid[126] = 9
local dbl = {}
dbl[32] = 6
dbl[33] = 6
dbl[34] = 6
dbl[35] = 6
dbl[36] = 6
dbl[37] = 6
dbl[38] = 6
dbl[39] = 6
dbl[40] = 6
dbl[41] = 6
dbl[42] = 6
dbl[43] = 6
dbl[44] = 5
dbl[45] = 9
dbl[46] = 3
dbl[47] = 9
dbl[48] = 9
dbl[49] = 9
dbl[50] = 9
dbl[51] = 9
dbl[52] = 9
dbl[53] = 9
dbl[54] = 9
dbl[55] = 9
dbl[56] = 9
dbl[57] = 9
dbl[58] = 5
dbl[59] = 6
dbl[60] = 6
dbl[61] = 6
dbl[62] = 6
dbl[63] = 6
dbl[64] = 6
dbl[65] = 11
dbl[66] = 11
dbl[67] = 11
dbl[68] = 11
dbl[69] = 11
dbl[70] = 11
dbl[71] = 11
dbl[72] = 11
dbl[73] = 7
dbl[74] = 11
dbl[75] = 11
dbl[76] = 11
dbl[77] = 11
dbl[78] = 11
dbl[79] = 11
dbl[80] = 11
dbl[81] = 11
dbl[82] = 11
dbl[83] = 11
dbl[84] = 11
dbl[85] = 11
dbl[86] = 11
dbl[87] = 11
dbl[88] = 11
dbl[89] = 11
dbl[90] = 11
dbl[91] = 6
dbl[92] = 6
dbl[93] = 6
dbl[94] = 6
dbl[95] = 9
dbl[96] = 6
dbl[97] = 11
dbl[98] = 11
dbl[99] = 11
dbl[100] = 11
dbl[101] = 11
dbl[102] = 11
dbl[103] = 11
dbl[104] = 11
dbl[105] = 7
dbl[106] = 9
dbl[107] = 9
dbl[108] = 7
dbl[109] = 11
dbl[110] = 11
dbl[111] = 11
dbl[112] = 11
dbl[113] = 11
dbl[114] = 11
dbl[115] = 11
dbl[116] = 11
dbl[117] = 11
dbl[118] = 11
dbl[119] = 11
dbl[120] = 11
dbl[121] = 11
dbl[122] = 11
dbl[123] = 6
dbl[124] = 6
dbl[125] = 6
dbl[126] = 6

return {
  sml=sml,
  nml=nml,
  mid=mid,
  dbl=dbl,
}