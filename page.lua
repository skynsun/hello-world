local component = require ("component")
local gpu = component.gpu
local display = require("display")
local event = require("event")
local InputBox = require("inputbox")

local wRes, hRes = gpu.getResolution()
local coordBox ="  x=   ".."  y=   ".."  z=   "
local facing ="  f= "
local numberBox ="="

Page = {
    title = "",
    body = {},
    hasDynamicalBody = false,
    biggestTextSelectable = {text=""},
    biggestTextNotSelectable = {text=""},
    realY,
    inputBoxes
}

function Page:display(screenPos, selectionPos, selectionBoxNumber)
    local y, xPos,yPos
    local i
    local xSelectable, xNotSelectable
    local isAllTextDisplayed
    local isFound
	local InputBoxNumber
  
    display.eraseRegion(2, 2, wRes-2, hRes-2)
	
  
  -- Trouve le début du mot le plus gros et se sert pour centré le texte --
  if self.biggestTextSelectable.hasCoordbox and self.biggestTextSelectable.hasFacing then
    xSelectable = display.xCenterTxt(2, wRes-2, #(self.biggestTextSelectable.text..coordBox..facing))
  elseif self.biggestTextSelectable.hasCoordbox then
    xSelectable = display.xCenterTxt(2, wRes-2, #(self.biggestTextSelectable.text..coordBox))
  elseif self.biggestTextSelectable.hasFacing then
    xSelectable = display.xCenterTxt(2, wRes-2, #(self.biggestTextSelectable.text..facing))
  elseif self.biggestTextSelectable.hasNumberBox then
    xSelectable = display.xCenterTxt(2, wRes-2, #(self.biggestTextSelectable.text..numberBox))
  else
    xSelectable = display.xCenterTxt(2, wRes-2, #(self.biggestTextSelectable.text))
  end
  xNotSelectable = display.xCenterTxt(2, wRes-2, #self.biggestTextNotSelectable.text)
  
  
  -- Vérifie que tout le texte est affiché --
  if #self.body > hRes - 8 then
    y = 5
	isAllTextDisplayed = false
  else
    y = display.yCenterTxt(5, hRes - 8, #self.body)
	isAllTextDisplayed = true
  end

  
  -- Retrouve la première inputBox affichable --
  isFound = false
  InputBoxNumber = 0
  while (InputBoxNumber < #self.inputBoxes) and not isFound do
    InputBoxNumber = InputBoxNumber + 1
	if self.inputBoxes[InputBoxNumber].RealY >= screenPos + 1 then
	  isFound = true
	end
  end
  
  -- Affiche le texte --
    yPos = 1
    i = screenPos
    while i < #self.body and (isAllTextDisplayed or (i-screenPos) < (hRes-8)) do
        if self.body[i+1].isSelectable == true then
            gpu.set(xSelectable,y+i-screenPos,self.body[i+1].text)
	        selectionPos[yPos]= {}
			selectionBoxNumber[yPos]= {}
	        xPos = 1
	        selectionPos[yPos].y = y+i-screenPos
	        selectionPos[yPos][xPos]= xSelectable - 2
			selectionBoxNumber[yPos][xPos]= nil
	        xPos = xPos + 1
	  
	        if self.body[i+1].hasCoordbox and self.body[i+1].hasFacing  then
	            for j = 1, 3 do
					selectionPos[yPos][xPos]= xSelectable + #self.biggestTextSelectable.text + 7*(j-1)
					selectionBoxNumber[yPos][xPos] = InputBoxNumber
					self.inputBoxes[InputBoxNumber]:display(selectionPos[yPos][xPos] + 4,selectionPos[yPos].y)
					xPos = xPos + 1
					InputBoxNumber = InputBoxNumber + 1
		        end
		        selectionPos[yPos][xPos]= xSelectable + #self.biggestTextSelectable.text + 7* 3
				selectionBoxNumber[yPos][xPos] = InputBoxNumber
				self.inputBoxes[InputBoxNumber]:display(selectionPos[yPos][xPos] + 4,selectionPos[yPos].y)
				InputBoxNumber = InputBoxNumber + 1
		        display.coordBox(xSelectable+#self.biggestTextSelectable.text,y+i-screenPos)
				display.facing(xSelectable+#self.biggestTextSelectable.text + 7* 3, y+i-screenPos)
	        elseif self.body[i+1].hasCoordbox then
	            for j = 1, 3 do
	                selectionPos[yPos][xPos]= xSelectable + #self.biggestTextSelectable.text + 7*(j-1)
					selectionBoxNumber[yPos][xPos] = InputBoxNumber
					self.inputBoxes[InputBoxNumber]:display(selectionPos[yPos][xPos]+ 4,selectionPos[yPos].y)
		            xPos = xPos + 1
					InputBoxNumber = InputBoxNumber + 1
		        end
				display.coordBox(xSelectable+#self.biggestTextSelectable.text,y+i-screenPos)
	        elseif self.body[i+1].hasFacing then
	            selectionPos[yPos][xPos]= xSelectable + #self.biggestTextSelectable.text
				selectionBoxNumber[yPos][xPos] = InputBoxNumber
	            self.inputBoxes[InputBoxNumber]:display(selectionPos[yPos][xPos]+ 4,selectionPos[yPos].y)
				InputBoxNumber = InputBoxNumber + 1
				display.facing(xSelectable+#self.biggestTextSelectable.text, y+i-screenPos)
	        elseif self.body[i+1].hasNumberBox then
			    self.inputBoxes[InputBoxNumber]:display(selectionPos[yPos][1]+ #self.body[i+1].text+3,selectionPos[yPos].y)
				selectionBoxNumber[yPos][1] = InputBoxNumber
				InputBoxNumber = InputBoxNumber + 1
	            gpu.set(xSelectable+#self.body[i+1].text,y+i-screenPos, numberBox)
	        end
	        yPos = yPos + 1
	    elseif self.body[i+1].isDesc then
			gpu.set(xNotSelectable-math.ceil((wRes-2)/16),y+i-screenPos,self.body[i+1].text)
		--[[
		else
		    gpu.set(xSelectable,y+i-screenPos,self.body[i+1].text)
			if self.body[i+1].hasCoordbox then
			    selectionPos[yPos]= {}
				xPos = 1
				selectionPos[yPos].y = y+i-screenPos
				selectionPos[yPos][xPos]= xSelectable - 2
	            xPos = xPos + 1
				for j = 1, 3 do
	                selectionPos[yPos][xPos]= xSelectable + #self.biggestTextSelectable.text + 7*(j-1)
		            xPos = xPos + 1
		        end
		        gpu.set(xSelectable+#self.biggestTextSelectable.text, y+i-screenPos, coordBox)
				yPos = yPos + 1
			end
		]]
	  --[[
	  xPos = 1
	  if self.body[i+1].hasCoordbox and self.body[i+1].hasFacing  then
	    selectionPos[yPos].y = y+i
		for j = 1, 3 do
	      selectionPos[yPos][xPos]= xSelectable + #self.body[i+screenPos+1].text + 7*(j-1)
		  xPos = xPos + 1
		end
		selectionPos[yPos][xPos]= xSelectable + #self.body[i+screenPos+1].text + 7* 3
		gpu.set(xNotSelectable-math.ceil((wRes-2)/16),y+i,self.body[i+1+screenPos].text..coordBox..facing)
	    yPos = yPos +1
	  elseif self.body[i+1].hasCoordbox then
	    selectionPos[yPos].y = y+i
		for j = 1, 3 do
	      selectionPos[yPos][xPos]= xSelectable + #self.body[i+screenPos+1].text + 2 + 7*(j-1)
		  xPos = xPos + 1
		end
		gpu.set(xNotSelectable-math.ceil((wRes-2)/16),y+i,self.body[i+1+screenPos].text..coordBox)
	    yPos = yPos +1
	  elseif self.body[i+1].hasFacing then
	    selectionPos[yPos].y = y+i
		selectionPos[yPos][xPos]= xSelectable + #self.body[i+screenPos+1].text
		gpu.set(xNotSelectable-math.ceil((wRes-2)/16),y+i,self.body[i+1+screenPos].text..facing)
		yPos = yPos + 1
	  else
	    gpu.set(xNotSelectable-math.ceil((wRes-2)/16),y+i,self.body[i+1+screenPos].text..facing)
	  end]]
	    end
	    i = i + 1
    end
  -- Fleche faire clignotante --
  if screenPos > 0 then
     gpu.set(display.xCenterTxt(2, wRes-2, 1), 3,"⇧")
  end
  if (i ~= #self.body) and (not isAllTextDisplayed) then
      gpu.set(display.xCenterTxt(2, wRes-2, 1),y+i+1-screenPos,"⇩")
  end
  return selectionPos
end

function Page:init()
    local tempText
    local y = 1
    local boxNumber = 1
	
	self.inputBoxes = {}
    self.realY = {}
	
    for i, line in ipairs(self.body) do
    
	    tempText = line.text

	    if line.hasCoordbox then
	        tempText = tempText..coordBox
	    end
	    if line.hasFacing then
	        tempText = tempText..facing
	    end
	    if line.hasNumberBox then
	        tempText = tempText..numberBox
	    end
	
	    if line.isSelectable then
			self.realY[y] = i
		    y = y + 1
		    -- Crée les coordBox --
		    if line.hasCoordbox and line.hasFacing then
		        for j = 1, 3 do
			        self.inputBoxes[boxNumber] = InputBox:new({length = 3, isCoord = true, RealY=i})
				    boxNumber = boxNumber +1
			    end
			        self.inputBoxes[boxNumber] = InputBox:new({length = 2, isFacing = true, RealY=i})
				    boxNumber = boxNumber +1
		    elseif line.hasCoordbox then
		        for j = 1, 3 do
			        self.inputBoxes[boxNumber] = InputBox:new({length = 3, isCoord = true, RealY=i})
				    boxNumber = boxNumber +1
			    end
		    elseif line.hasFacing then
		        self.inputBoxes[boxNumber] = InputBox:new({length = 2, isFacing = true, RealY=i})
		        boxNumber = boxNumber +1
		    elseif line.hasNumberBox then
		        self.inputBoxes[boxNumber] = InputBox:new({length = 3, isNumberBox = true, RealY=i})
		        boxNumber = boxNumber +1
		    end
		
		    -- Cherche la plus grande ligne --
		    if self.biggestTextSelectable.hasCoordbox and self.biggestTextSelectable.hasFacing then
	            if #(self.biggestTextSelectable.text..coordBox..facing) < #tempText then
	                self.biggestTextSelectable = line
		        end
	        elseif self.biggestTextSelectable.hasCoordbox then
	            if #(self.biggestTextSelectable.text..coordBox) < #tempText then
	                self.biggestTextSelectable = line
		        end
	        elseif self.biggestTextSelectable.hasFacing then
	            if #(self.biggestTextSelectable.text..facing) < #tempText then
	                self.biggestTextSelectable = line
	            end
	        elseif self.biggestTextSelectable.hasNumberBox then
		        if #(self.biggestTextSelectable.text..numberBox) < #tempText then
		            self.biggestTextSelectable = line
		        end
		    else
	            if #(self.biggestTextSelectable.text) < #tempText then
	                self.biggestTextSelectable = line
	            end
	        end
	    elseif #(self.biggestTextNotSelectable.text) < #tempText and line.isDesc == true then
	        self.biggestTextNotSelectable = line
	    end
    end
end

function Page:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  return t
end