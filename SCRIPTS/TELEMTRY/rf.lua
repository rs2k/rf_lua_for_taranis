-- The MIT License (MIT)
--
-- Copyright 2017 RaceFlight
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
-- modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local horizontalCharSpacing = 0
local verticalCharSpacing   = 0
local rxBuffer  = {}
local xyBuffer  = {}
local CMD_PRINT = 0x12
local CMD_ERASE = 0x13

local function isempty(s)
	return s == nil or s == ''
end

local function ReceiveSport()
	local sId, fId, daId, value = sportTelemetryPop()
	if sId == 0x0D and fId == 0x32 then
		rxBuffer = {}
		rxBuffer[0] = bit32.band(daId,0xFF)
		rxBuffer[1] = bit32.band(bit32.rshift(daId,8),0xFF)
		rxBuffer[2] = bit32.band(value,0xFF)
		rxBuffer[3] = bit32.band(bit32.rshift(value,8 ),0xFF)
		rxBuffer[4] = bit32.band(bit32.rshift(value,16),0xFF)
		rxBuffer[5] = bit32.band(bit32.rshift(value,24),0xFF)
		return true
	else
		return false
	end
end

local function ProcessSport()
	local x=0
	local y=0
	local z=0
	if (rxBuffer[0] == CMD_PRINT) then
		z = rxBuffer[1]
		y = math.floor(z / 24)
		x = (z - (y * 24))
		for i=0,3,1 do
			if isempty(xyBuffer[x+i]) then
				xyBuffer[x+i] = {}
			end
			xyBuffer[x+i][y] = string.char(rxBuffer[2+i])
		end
	elseif (rxBuffer[0] == CMD_ERASE) then
		xyBuffer = {}
	end
end

local function DrawBuffers()
	local textFeature = 0
	for x in pairs(xyBuffer) do
		for y in pairs(xyBuffer[x]) do
			if not isempty(xyBuffer[x][y]) then
				if y==0 then
					textFeature = INVERS
				else
					textFeature = 0
				end
				lcd.drawText(x*horizontalCharSpacing+1, y*verticalCharSpacing+1, xyBuffer[x][y], textFeature)
			end
		end
	end
end

local function DrawScreen()
	lcd.clear()
	lcd.drawFilledRectangle(0, 0, LCD_W, verticalCharSpacing)
	DrawBuffers()
	if getValue("RSSI") == 0 then
		lcd.drawText(5*horizontalCharSpacing,5*verticalCharSpacing,"No RX Detected", INVERS+BLINK)
	end
end

local function RunUi(event)
	if ReceiveSport() then
		ProcessSport()
	end
	DrawScreen()
	return 0
end

local function InitUi(event)
	local ver, radio, maj, minor, rev = getVersion()
	if radio=="x9d" or radio=="x9d+" or radio=="taranisx9e" or radio=="taranisplus" or radio=="taranis" or radio=="x9d-simu" or radio=="x9d+-simu" or radio=="taranisx9e-simu" or radio=="taranisplus-simu" or radio=="taranis-simu" then
		horizontalCharSpacing = 6
		verticalCharSpacing   = 10
	end
	xyBuffer[0] = {}
	xyBuffer[0][0] = "RaceFlight One Program Menu"
end

return {init=InitUi, run=RunUi}
