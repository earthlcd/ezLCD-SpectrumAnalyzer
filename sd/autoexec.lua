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

function titleScreen(fn, filename) -- Show a title sequence for the program
	local result
	-- ez.Cls(ez.RGB(0,0,0))

	ez.SetAlpha(255)
	ez.SetXY(0, 0)
	result = ez.PutPictFile(0, 0, filename)
	ez.SerialTx("Loading " .. filename .. " result=".. tostring(result) .. "\r\n", 80, debug_port) -- doesn't work
end

function renderSpectrum(audio, dft)
	local result

	local x_delta = 18
	local y_min = 20
	local y_max = 156
	local peak = y_max - y_min
	--f72585 -> 3a0ca3 -> 4cc9f0

	for f = 1, #spectrum, 1 do
		-- local left = ez.dft_getReal(dft, index) + .0

		local x = f * x_delta
		local c = math.floor( ( f + .0) / #spectrum * 255)
		spectrum[f] = spectrum[f] + math.random(-5,5)
		if(spectrum[f] > peak) then spectrum[f] = peak end
		if(spectrum[f] < 0) then spectrum[f] = 0 end

		ez.BoxFill(x, y_min, x + x_delta , y_max - spectrum[f], ez.RGB(0, 0, 0)) -- X1, Y1, X2, Y2, Color
		ez.BoxFill(x, y_max - spectrum[f], x + x_delta , y_max, ez.RGB(c, spectrum[f], 255-c)) -- X1, Y1, X2, Y2, Color
	end

end

detected_peak1 = 0
detected_peak2 = 0
function renderOscope(audio, gain)
	local result

	local x_min = 11
	local x_max = ez.Width-x_min
	local y_min = 10
	local y_max = 156
	local y_mid = (y_max - y_min) / 2 + y_min
	local y_max = 156
	local peak_to_peak = y_max - y_min
	local peak = peak_to_peak / 2
	

	-- erase previous scope
	ez.BoxFill(x_min, y_min, x_max+1, y_max+1, ez.RGB(0, 0, 40)) -- X1, Y1, X2, Y2, Color

	-- ez.SerialTx("ez.audio_size()=" .. string.format("%d", ez.audio_size(audio)) .. "\r\n", 80, debug_port)

	-- ez.SerialTx("left[" .. string.format("%d", x) .. "]=" .. string.format("%08x", left) .. "    ", 80, debug_port)
	-- ez.SerialTx("left[" .. string.format("%d", x) .. "]=" .. string.format("%0.0f", left) .. "\r\n", 80, debug_port)

	last_y = y_mid
	last_x = x_min
	local index = 1
	detected_peak1 = detected_peak1 * 0.85
	detected_peak2 = detected_peak2 * 0.99
	for x = x_min, x_max, 1 do
		local left = ez.audio_getLeft(audio, index) + .0
		index = index + 1
		left = left / gain * (peak)
		if(left > peak) then left = peak end
		if(left < -peak) then left = -peak end

		if math.abs(left) > detected_peak1 then detected_peak1 = math.abs(left) end
		if math.abs(left) > detected_peak2 then detected_peak2 = math.abs(left) end

		left = math.floor(left + y_mid)

		-- ez.Plot( x, left, ez.RGB(99 + left, 0xff - left, 0) )
		ez.Line(last_x, last_y, x, left, ez.RGB(0xff - left, 99 + left, 0))
		last_y = left
		last_x = x
	end

	y_min = y_max + 5
	y_max = y_max + 20

	local graph_peak1 = math.floor(detected_peak1 * 3)
	local graph_peak2 = math.floor(detected_peak2 * 3)
	if(graph_peak1 > ez.Width) then graph_peak1 = ez.Width end
	if(graph_peak2 > ez.Width) then graph_peak2 = ez.Width end

	-- ez.SerialTx("x_min=" .. tostring(x_min) .. "\r\n", 80, debug_port)
	-- ez.SerialTx("y_max=" .. tostring(y_max) .. "\r\n", 80, debug_port)
	-- ez.SerialTx("graph_peak=" .. string.format("%0.2f", graph_peak) .. "\r\n", 80, debug_port)

	ez.BoxFill(0, y_min, graph_peak1, y_max, ez.RGB(0, 0xff, 0)) -- X1, Y1, X2, Y2, Color
	ez.BoxFill(graph_peak1, y_min, x_max, y_max, ez.RGB(0, 0, 0)) -- X1, Y1, X2, Y2, Color
	ez.BoxFill(graph_peak2-3, y_min, graph_peak2+3, y_max, ez.RGB(graph_peak2, 0xff - graph_peak2, 0)) -- X1, Y1, X2, Y2, Color

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
	if id == 0 and event == 1 then
		screen_change = true
		screen = screen + 1
		if screen > screen_max then
			screen = 0
		end
		str = "screen=" .. tostring(screen)
		ez.SerialTx(str .. "\r\n", 80, debug_port)
		end
	if id == 1 then
	end

	ez.Button(id, event)
	str = "id=" .. tostring(id) ..  ", event=" .. tostring(event)
	ez.SerialTx(str .. "\r\n", 80, debug_port)
end 

fn = 14
font_height = 240 / 8 -- = 30
screen = 0
screen_max = 2
screen_change = true

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
ez.Button(0, 1, -1, -11, -1, 0,  0, 319, 156) -- Scope button
-- ez.Button(1, 1, -1, -11, -1, 210, 35, 110, 35) -- Clear button
-- ez.Button(2, 1, -1, -11, -1, 0, 0, 50, 40)     -- Menu
-- ez.Button(3, 1, -1, -11, -1, 0, 80, 320, 150)  -- Plot Area


-- Start to receive button events
ez.SetButtonEvent("ProcessButtons")

-- Main

----------------------------------------------------------------------------
-- Set two GPIO pins to power the microphone (it only draw 2.5mA at 3.3V) --
----------------------------------------------------------------------------
ez.SetPinOut(1, 0, false, false, false, 0) -- PinNo [, InitialState [, OpenDrain [, PullUp [, PullDn [, Speed]]]]]
ez.SetPinOut(3, 1, false, false, false, 0) -- PinNo [, InitialState [, OpenDrain [, PullUp [, PullDn [, Speed]]]]]
ez.SetPinOut(5, 1, false, false, false, 0) -- PinNo [, InitialState [, OpenDrain [, PullUp [, PullDn [, Speed]]]]]
ez.Pin(1, 0) -- PinNo, Value
ez.Pin(3, 1) -- PinNo, Value

-- allocate memory for the samples
audio_global = ez.audio_new(300)
dft_global = ez.dft_new(300)
ez.I2SopenMaster(1, 2)

spectrum = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 140}

while 1 do
	ez.Pin(5, 0) -- PinNo, Value
	ez.I2Sread(audio_global)
	ez.Pin(5, 1) -- PinNo, Value
	if screen_change == true then
		if screen == 0 then titleScreen(fn, "/SA/oscilloscope.bmp") end
		if screen == 1 then titleScreen(fn, "/SA/background.bmp") end
		if screen == 2 then titleScreen(fn, "/Images/EarthLCD_320x240_Splash.bmp") end
		if screen == 2 then
			local x1 = 20
			local y1 = 15
			local x2 = x1 + 50
			local y2 = y1 + 50
			local margin = 8
			ez.BoxFill(x1 - margin, y1 - margin, x2 + margin, y2 + margin, ez.RGB(0xff, 0xff, 0xff)) -- X1, Y1, X2, Y2, Color
			ez.SetColor(ez.RGB(0, 0, 0))
			ez.SetBgColor(ez.RGB(0, 0, 0))
			ez.SetXY(x1,y1)
			ez.PutQRCode("http://earthlcd.com/")
		end
		screen_change = false
	end
	if screen == 0 then
		-- renderOscope(a, 2147483648) -- 2^31 = 2147483648
		-- renderOscope(a, 1073741824) -- 2^30 = 1073741824
		renderOscope(audio_global, 536870912) -- 2^29 = 536870912
	elseif screen == 1 then
		renderSpectrum(audio_global, dft_global)
	elseif screen == 2 then
	elseif screen == 3 then
	end
end

