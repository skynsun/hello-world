local component = require("component")
local gpu = component.gpu
local colours = require("colours")

local display = {}

local wRes, hRes = gpu.getResolution()
local isCursorShow
local blinkingEventID
local CursorX
local CursorY
local CursorChara
local xBar, yBar
local barWide

function display.xCenterTxt(x, w, textLength)
    return x + math.floor(w/2 - textLength/2)
end

function display.yCenterTxt(y, h, lineNumber)
    return y + math.floor(h/2 - lineNumber/2)
end

function display.eraseRegion(xStart,yStart, w,h)
  gpu.fill(xStart, yStart, w, h, " ")
end

function display.coordBox(x,y)
    gpu.set(x +2,y,"x=")
    gpu.set(x +9,y,"y=")
    gpu.set(x +16,y,"z=")
end

function display.facing(x,y)
    gpu.set(x + 2,y, "f=")
end

function display.framedText(x, y, w, h, text)
    xTextStart = display.xCenterTxt(x, w, #text)
    gpu.set(xTextStart,y, text)
    gpu.set(x,y,"╭")
    gpu.set(x+w-1,y,"╮")
    gpu.set(x,y+h-1,"╰")
    gpu.set(x+w-1,y+h-1,"╯")
    for i = 1, w-2 do
        if((x+i < xTextStart) or (x+i > (xTextStart+#text-1)))then
	        gpu.set(x+i,y,"─")
	    end
	    gpu.set(x+i,y+h-1,"─")
    end
    for i=1, h-2 do
        gpu.set(x,y+i,"│")
	    gpu.set(x+w-1,y+i,"│")
    end
end

function display.blinkingCursorUpdate()
    local currentForeground = gpu.getForeground()
    local currentBackground = gpu.getBackground()

    isCursorShow = not isCursorShow
    if(isCursorShow) then
        gpu.setForeground(currentBackground)
        gpu.setBackground(currentForeground)
    end
    gpu.set(CursorX, CursorY, CursorChara)
    if(isCursorShow) then
        gpu.setForeground(currentForeground)
        gpu.setBackground(currentBackground)
    end
end

function display.startBlinkingCursor(x, y, chara)
    CursorX = x
	CursorY = y
	CursorChara = chara
	isCursorShow = false
	display.blinkingCursorUpdate()
    blinkingEventID = event.timer(0.5, display.blinkingCursorUpdate, math.huge)
end

function display.isBlinking()
    return blinkingEventID ~= nil
end

function display.stopBlinkingCursor()
    if(blinkingEventID ~= nil)then
        event.cancel(blinkingEventID)
		if(isCursorShow) then
	        gpu.set(CursorX, CursorY, CursorChara)
        end
        blinkingEventID = nil
    else 
	    gpu.set(1,1,"try to close an event with blinkingEventID but its nil value") 
	end
end

function display.scanLoading()
    local xText = display.xCenterTxt(2, wRes-2, 10)
	barWide = 0
	xBar = display.xCenterTxt(2, wRes-2, 22)
	yBar = display.yCenterTxt(2, hRes-2, 2) + 1

    gpu.set(xText, yBar - 1,"Scanning...")
	gpu.set(xBar, yBar,"[                    ]")
end

function display.updateScanLoading(percent)
    local loadingBar = ""
	
	
	if barWide < math.floor(percent/5) then
	    barWide = math.floor(percent/5)
	    for i = 1, barWide do
	        loadingBar = loadingBar.."-"
	    end
	    gpu.set(xBar+1, yBar, loadingBar)
	end
end

return display