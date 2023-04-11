----------------------------------------------------------------------
-- ezLCD Pull test application note example
--
-- Created  03/14/2023  -  Jacob Christ
----------------------------------------------------------------------


----------------------------------------------------------------------
-- Lua Enum Function documented here:
-- https://www.lexaloffle.com/bbs/?tid=29891
-- Code here:
-- https://github.com/sulai/Lib-Pico8/blob/master/lang.lua
----------------------------------------------------------------------
function enum(names, offset)
	offset=offset or 1
	local objects = {}
	local size=0
	for idr,name in pairs(names) do
		local id = idr + offset - 1
		local obj = {
			id=id,       -- id
			idr=idr,     -- 1-based relative id, without offset being added
			name=name    -- name of the object
		}
		objects[name] = obj
		objects[id] = obj
		size=size+1
	end
	objects.idstart = offset        -- start of the id range being used
	objects.idend = offset+size-1   -- end of the id range being used
	objects.size=size
	objects.all = function()
		local list = {}
		for _,name in pairs(names) do
			add(list,objects[name])
		end
		local i=0
		return function() i=i+1 if i<=#list then return list[i] end end
	end
	return objects
end




function printLine(font_height, line, str) -- Show a title sequence for the program
	local x1, y1, x2, y2
	-- Display Size -> 320x240 

	-- Erase Old Weight
	x1 = 0
	y1 = font_height * line
	x2 = 320
	y2 = font_height * line + font_height

	-- ez.BoxFill(x1,y1, x2,y2, ez.RGB(bg,bg,bg)) -- X, Y, Width, Height, Color
	ez.BoxFill(x1,y1, x2,y2, ez.RGB(0x17, 0x28, 0x15)) -- X, Y, Width, Height, Color

	-- Display Line
	-- ez.SetColor(ez.RGB(0,0,255))
	ez.SetColor(ez.RGB(0xee, 0xf2, 0xe8))
	ez.SetFtFont(fn, font_height * 0.70) -- Font Number, Height, Width
	ez.SetXY(x1, y1)
	print(str)
	-- ez.Wait_ms(200)
end

function printBox(x1, y1, x2, fg, bg, font_height, str) -- Show a title sequence for the program
	-- Erase Old Weight
	local y2 = y1 + font_height

	ez.BoxFill(x1,y1, x2,y2, bg) -- X1, Y1, X2, Y2, Color

	-- Display Line
	ez.SetColor(fg)
	ez.SetFtFont(fn, font_height * 0.70) -- Font Number, Height, Width
	ez.SetXY(x1, y1)
	print(str)
end

function titleScreen(fn) -- Show a title sequence for the program
	local result
	ez.Cls(ez.RGB(0,0,0))

	ez.SetAlpha(255)
	ez.SetXY(0, 0)
	result = ez.PutPictFile(0, 0, "/SA/background.bmp")
	ez.SerialTx("result=".. tostring(result) .. "\r\n", 80, debug_port) -- doesn't work
end

function renderSpectrum() -- Show a title sequence for the program
	local result

	local x_delta = 18
	local y_min = 20
	local y_max = 156
	local peak = y_max - y_min
	--f72585 -> 3a0ca3 -> 4cc9f0

	for f = 1, #spectrum, 1 do
		local x = f * x_delta
		local c = math.floor( ( f + .0) / #spectrum * 255)
		spectrum[f] = spectrum[f] + math.random(-5,5)
		if(spectrum[f] > peak) then spectrum[f] = peak end
		if(spectrum[f] < 0) then spectrum[f] = 0 end

		ez.BoxFill(x, y_min, x + x_delta , y_max - spectrum[f], ez.RGB(0, 0, 0)) -- X1, Y1, X2, Y2, Color
		ez.BoxFill(x, y_max - spectrum[f], x + x_delta , y_max, ez.RGB(c, spectrum[f], 255-c)) -- X1, Y1, X2, Y2, Color
	end

end


debug_port = 0
-- Event Handelers
-- Serial Port Event
function DebugPortReceiveFunction(byte)
	ez.SerialTx(byte, 1, debug_port)
end

-- Define the Button Event Handler
function ProcessButtons(id, event)
	-- TODO: Insert your button processing code here
	-- Display the image which corresponds to the event
	if id == 0 then
	end
	if id == 1 then
	end

	ez.Button(id, event)
	str = "id=" .. tostring(id) ..  ", event=" .. tostring(event)
	ez.SerialTx(str .. "\r\n", 80, debug_port)
end 

fn = 14
font_height = 240 / 8 -- = 30

-- Wait 10 seconds for USB to enumerate
-- ez.Wait_ms(10000)

-- open the RS-232 port
ez.SerialOpen("DebugPortReceiveFunction", debug_port)
ez.SerialTx("**********************************************************************\r\n", 80, debug_port)
ez.SerialTx("* EarthLCD Spectrum Analyzer\r\n", 80, debug_port)
ez.SerialTx("**********************************************************************\r\n", 80, debug_port)
ez.SerialTx(ez.FirmVer .. "\r\n", 80, debug_port)
ez.SerialTx(ez.LuaVer .. "\r\n", 80, debug_port)
ez.SerialTx("S/N: " .. ez.SerialNo .. "\r\n", 80, debug_port)
ez.SerialTx(ez.Width .. "x" .. ez.Height .. "\r\n", 80, debug_port)
ez.SerialTx("Frames: " .. ez.NoOfFrames .. "\r\n", 80, debug_port)

-- Setup button(s)
ez.Button(0, 1, -1, -11, -1, 210,  0, 110, 35) -- Tare button
ez.Button(1, 1, -1, -11, -1, 210, 35, 110, 35) -- Clear button
ez.Button(2, 1, -1, -11, -1, 0, 0, 50, 40)     -- Menu
ez.Button(3, 1, -1, -11, -1, 0, 80, 320, 150)  -- Plot Area


-- Start to receive button events
ez.SetButtonEvent("ProcessButtons")

-- Main
titleScreen(fn)
-- ez.Wait_ms(500)

ez.I2SopenMaster(1, 2)
I2Sread = ez.I2Sread(1,2)
ez.SerialTx("I2Sread: " .. I2Sread .. "\r\n", 80, debug_port)

local graph_xmin = 10
local graph_xmax = 310
local graph_x = graph_xmin

local graph_ymid = 150
local graph_ymin =  81
local graph_ymax = 230
local graph_y = graph_ymid

spectrum = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 140}
while 1 do
	renderSpectrum()
end

