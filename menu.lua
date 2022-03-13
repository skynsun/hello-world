local display = require("display")
local component = require("component")
local kb = require("keyboard")
local filesystem = require("filesystem")
local event = require("event")
local run = require("run")
local sides = require("sides")
local gpu = component.gpu
local nav = component.navigation
local keys = kb.keys

local map = require("map")

local wRes, hRes = gpu.getResolution()

local menu = {
    selectionPos,
	selectionBoxNumber,
    screenPos,
    pages = {},
    currPage,
    editMode,
	selection = {x,y, absolutY},
    oldSelection = {x,y},
	fileName = "save.cfg"
}

function menu:titleToPage(title)
    for i, page in ipairs(self.pages) do
        if page.title == title then
	        return page
	    end
    end
end

function menu:saveInputBoxFile()
    local file = io.open(self.fileName, "w")
	
	for i, page in ipairs(self.pages) do
        m = 1
		for j, line in ipairs(page.body) do
		    if line.hasCoordbox and line.hasFacing then
		        for k=1, 4 do
				    file:write(page.inputBoxes[m].content.."\n")
					m = m + 1
				end
		    elseif line.hasCoordbox then
			    for k=1, 3 do
				    file:write(page.inputBoxes[m].content.."\n")
					m = m + 1
				end
			elseif line.hasFacing then
			    file:write(page.inputBoxes[m].content.."\n")
					m = m + 1
			elseif line.hasNumberBox then
			    file:write(page.inputBoxes[m].content.."\n")
					m = m + 1
			end
		end
    end
	file:close()
end

function menu:refreshDisplay()
    self.selectionBoxNumber = {}
	self.selectionPos = {}
	self.currPage:display(self.screenPos, self.selectionPos, self.selectionBoxNumber)
end

function menu:refreshCursor()
	gpu.set(self.selectionPos[self.oldSelection.y][self.oldSelection.x],self.selectionPos[self.oldSelection.y].y, "  ")
    gpu.set(self.selectionPos[self.selection.y][self.selection.x],self.selectionPos[self.selection.y].y, "->")
end

function menu:getPosition()
    local x, y, z = nav.getPosition()
	local f = nav.getFacing()
	
	if x ~= nil then
		
		x = tostring(math.floor(x))
		y = tostring(math.floor(y))
		z = tostring(math.floor(z))
		
		if     f == sides.north then
		    f = "N"
		elseif f == sides.south then
		    f = "S"
		elseif f == sides.west then
		    f = "W"
		else
		    f = "E"
		end
		
        if self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasCoordbox and self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasFacing then
	        self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 1]].content = x
			self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 2]].content = y
			self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 3]].content = z
			self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 4]].content = f
	    elseif self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasCoordbox then
		    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 1]].content = x
			self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 2]].content = y
			self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 3]].content = z
	    elseif self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasFacing then
		    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x + 1]].content = f
	    end
	end
end

function menu:enter()
	if self.currPage.body[self.currPage.realY[self.selection.absolutY]].isSubMenu then
	    self:setPage(self.currPage.body[self.currPage.realY[self.selection.absolutY]].text)
	elseif self.currPage.body[self.currPage.realY[self.selection.absolutY]].isReturn then
        if self.currPage.title == "Auto Crops" then
		    return false
		end
		self:saveInputBoxFile()
		self:setPage("Auto Crops")
	elseif self.currPage.body[self.currPage.realY[self.selection.absolutY]].isStarting then
	    display.eraseRegion(1, 1, wRes,hRes)
		run:main(self:titleToPage("Set Farmland Coordinates").inputBoxes,self:titleToPage("Set Items Coordinates").inputBoxes, self.selection.absolutY, self:titleToPage("Run").inputBoxes[1].content)
		display.eraseRegion(1, 1, wRes,hRes)
		display.framedText(1, 1, wRes, hRes, self.currPage.title)
	    self:refreshDisplay()
		self:refreshCursor()
	elseif (self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasCoordbox or self.currPage.body[self.currPage.realY[self.selection.absolutY]].hasFacing) and self.selection.x == 1 then
	    menu:getPosition()
		self:refreshDisplay()
		self:refreshCursor()
	elseif self.currPage.body[self.currPage.realY[self.selection.absolutY]].isScan then
	    display.eraseRegion(1, 1, wRes,hRes)
		display.framedText(1, 1, wRes, hRes, "Scan Environement")
		map:generateMap(self.currPage.inputBoxes[1].content, self.currPage.inputBoxes[2].content, self:titleToPage("Set Farmland Coordinates").inputBoxes)
		display.eraseRegion(1, 1, wRes,hRes)
		display.framedText(1, 1, wRes, hRes, self.currPage.title)
	    self:refreshDisplay()
		self:refreshCursor()
	else
	    if not self.editMode then
		    if self.selectionBoxNumber[self.selection.y][self.selection.x] ~= nil then
	            self.editMode=true
	            if self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]].isNumberBox then
			        self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:openEditing(self.selectionPos[self.selection.y][self.selection.x]+3+#self.currPage.body[self.currPage.realY[self.selection.absolutY]].text,self.selectionPos[self.selection.y].y)
			    else
			        self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:openEditing(self.selectionPos[self.selection.y][self.selection.x]+4,self.selectionPos[self.selection.y].y)
			    end
	        end
	    else
	        self.editMode = false
		    if self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]].isNumberBox then
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:closeEditing(self.selectionPos[self.selection.y][self.selection.x]+3+#self.currPage.body[self.currPage.realY[self.selection.absolutY]].text,self.selectionPos[self.selection.y].y)
		        if self.currPage.isDynamicPage and self.selectionBoxNumber[self.selection.y][self.selection.x] == 1 then
			        self.currPage:changeSize()
				    display.eraseRegion(2, 2, wRes-2,hRes-2)
				    self:refreshDisplay()
				    self:refreshCursor()
			    end
		    else
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:closeEditing(self.selectionPos[self.selection.y][self.selection.x]+4,self.selectionPos[self.selection.y].y)
		    end
	    end
	end
	return true
end

function menu:left()
    if self.selection.x > 1 then
        self.oldSelection.x = self.selection.x
	    self.oldSelection.y = self.selection.y
		self.selection.x = self.selection.x -1
	    self:refreshCursor()
    end
end

function menu:right()
    if self.selectionPos[self.selection.y][self.selection.x+1] ~= nil then
        self.oldSelection.x = self.selection.x
		self.oldSelection.y = self.selection.y
        self.selection.x = self.selection.x + 1
	    self:refreshCursor()
    end
end

function menu:Home()
	if self.screenPos > 0 then
	    self.screenPos = 0
		self.selection.absolutY = 1
		self.selection.x = 1
	    self.oldSelection.x = 1
	    self.oldSelection.y = 1
	    self.selection.y = 1
		self:refreshDisplay()
	else
	    self.selection.absolutY = 1
	    self.oldSelection.x = self.selection.x
	    self.oldSelection.y = self.selection.y
	    self.selection.x = 1
	    self.selection.y = 1
	end
	self:refreshCursor()
end

function menu:keyEnd()
    if self.screenPos < #self.currPage.body - (hRes - 8) then
	    self.screenPos = #self.currPage.body - (hRes - 8)
		self.selection.absolutY=#self.currPage.realY
		self:refreshDisplay()
		self.selection.y = #self.selectionPos
		self.oldSelection.y = self.selection.y
		self.selection.x = #self.selectionPos[self.selection.y]
		self.oldSelection.x = self.selection.x
	else
	    self.selection.absolutY=#self.currPage.realY
		self.oldSelection.y = self.selection.y
		self.selection.y = #self.selectionPos
		self.oldSelection.x = self.selection.x
		self.selection.x = #self.selectionPos[self.selection.y]
	end
	self:refreshCursor()
end

function menu:up()
    if self.selection.y > 1 then
	    self.oldSelection.y = self.selection.y
		self.oldSelection.x = self.selection.x
		if self.selectionPos[self.selection.y-1][self.selection.x] == nil then
			self.selection.x = 1
		end
		self.selection.y = self.selection.y - 1
	    self.selection.absolutY = self.selection.absolutY - 1
		
	elseif self.selection.absolutY > 1 then
	    if self.currPage.realY[self.selection.absolutY - 1] < self.screenPos+1 then
			self.selection.absolutY = self.selection.absolutY - 1
		    self.screenPos = self.currPage.realY[self.selection.absolutY] - 1
			self:refreshDisplay()
		    if self.selectionPos[self.selection.y][self.selection.x] == nil then
		        self.selection.x = 1
				self.oldSelection.x = 1
		    else
			    self.oldSelection.x = self.selection.x
			end
		end
	elseif self.screenPos > 0 then
	    self.screenPos = self.screenPos -1
		self:refreshDisplay()
	end
	self:refreshCursor()
end

function menu:down()
	if (self.selection.y + 1) <= #self.selectionPos then
	    if self.selection.x > #self.selectionPos[self.selection.y + 1] then
		    self.oldSelection.x = self.selection.x
		    self.selection.x = 1
		    self.oldSelection.y = self.selection.y 
		    self.selection.y = self.selection.y + 1
		    self.selection.absolutY = self.selection.absolutY + 1
		else
		    self.oldSelection.y = self.selection.y
		    self.oldSelection.x = self.selection.x
		    self.selection.y = self.selection.y + 1
		    self.selection.absolutY = self.selection.absolutY +1
		end
	elseif self.currPage.realY[self.selection.absolutY + 1] ~= nil then
		self.selection.absolutY = self.selection.absolutY  + 1
		self.screenPos = self.currPage.realY[self.selection.absolutY] - (hRes - 8)
		self:refreshDisplay()
		self.selection.y = #self.selectionPos
		self.oldSelection.y = self.selection.y
		if self.selectionPos[self.selection.y][self.selection.x] == nil then
		    self.selection.x = 1
			self.oldSelection.x = 1
		else
			    self.oldSelection.x = self.selection.x
		end
	elseif self.screenPos + (hRes - 8) < #self.currPage.body then
	    self.screenPos = self.screenPos + 1
		self:refreshDisplay()
		self.selection.y = #self.selectionPos
		self.oldSelection.y = self.selection.y
		self.oldSelection.x = self.selection.x
	end
	self:refreshCursor()
end


function menu:setPage(title)
    self.screenPos = 0
	self.currPage = self:titleToPage(title)
    display.eraseRegion(1, 1, wRes,hRes)
    display.framedText(1, 1, wRes, hRes, self.currPage.title)
	self:refreshDisplay()
	self.selection.x = 1
	self.selection.y = 1
	self.selection.absolutY = 1
	self.oldSelection.x = 1
	self.oldSelection.y = 1
	self:refreshCursor()
end

function menu:input(chara, keyPress)
    local running = true
	if keyPress == keys.enter then
        running = self:enter()
	elseif self.editMode then
	    if (chara >= 32 and chara <= 127) or chara == 8 or keyPress == keys.delete then
		    if self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]].isNumberBox then
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:editing(self.selectionPos[self.selection.y][self.selection.x]+3+#self.currPage.body[self.currPage.realY[self.selection.absolutY]].text,self.selectionPos[self.selection.y].y, chara, keyPress)
			else
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:editing(self.selectionPos[self.selection.y][self.selection.x]+4,self.selectionPos[self.selection.y].y, chara, keyPress)
			end
		elseif keyPress == keys.left then 
		    if self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]].isNumberBox then
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:moveCursorLeft(self.selectionPos[self.selection.y][self.selection.x]+3+#self.currPage.body[self.currPage.realY[self.selection.absolutY]].text,self.selectionPos[self.selection.y].y)
			else
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:moveCursorLeft(self.selectionPos[self.selection.y][self.selection.x]+4,self.selectionPos[self.selection.y].y)
			end
		elseif keyPress == keys.right then
		    if self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]].isNumberBox then
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:moveCursorRight(self.selectionPos[self.selection.y][self.selection.x]+3+#self.currPage.body[self.currPage.realY[self.selection.absolutY]].text,self.selectionPos[self.selection.y].y)
			else
			    self.currPage.inputBoxes[self.selectionBoxNumber[self.selection.y][self.selection.x]]:moveCursorRight(self.selectionPos[self.selection.y][self.selection.x]+4,self.selectionPos[self.selection.y].y)
			end
		end
	else
	    if keyPress == keys.left then 
		    self:left()
        elseif keyPress == keys.right then
		    self:right()
        elseif keyPress == keys.up then
		    self:up()
        elseif keyPress == keys.down then
		    self:down()
	    elseif keyPress == keys.home then
		    self:Home()
		elseif keyPress == keys["end"] then
		    self:keyEnd()
		end
	end
	return running
end

function menu:init(...)
    local file
	local l
	self.pages = {...}
	if filesystem.exists("/home/"..self.fileName) then
        file = io.open(self.fileName, "r")
	end
    self.editMode = false
	for i , page in ipairs(self.pages) do
		page:init()
		if file ~= nil then
		    l = 1
			for j = 1, #page.inputBoxes do
				page.inputBoxes[l].content = file:read("*l")
				l = l + 1
		    end
		end
		-- copy variable from file
		if page.isDynamicPage then
		    page:changeDynamicPart()
			if file ~= nil then
			    for k = l, #page.inputBoxes do
			        page.inputBoxes[k].content = file:read("*l")
			    end
			end
			-- copy variable from file
		end
	end
	if file ~= nil then
	    file:close()
	end
    self:setPage("Auto Crops")
end


return menu