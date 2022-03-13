local component = require("component")
local display = require("display")
local event = require("event")
local gpu = component.gpu

local key = { left  = 203,
              right = 205,
			  up    = 200,
			  down  = 208,
			  enter = 28,
              delete = 211}
local character = {backspace = 8,
                   hyphen_minus = 45}

local InputBox = {
    isFacing = false,
	isNumberBox = false,
	isCoord = false,
	length,
	content = "",
	RealY,
	blinkingPos,
	textBoxPos
}

function InputBox:eraseBox(x, y)
    local space = ""
   
    for i = 0, self.length-1 do
        space = space.." "
    end
    gpu.set(x, y, space)
end

function InputBox:displayEditing(x, y, word)
    gpu.set(x, y, word)
end


function InputBox:display(x, y)
	gpu.set(x,y,string.sub(self.content,1,self.length))
end

function InputBox:openEditing(x, y)
	if(#self.content <= 2)then
      self.blinkingPos = #self.content + 1
    else
      self.blinkingPos = 3
    end
    if(#self.content <= 2) then
	  self.textBoxPos = 0
	else
	  self.textBoxPos = #self.content - 2
	end
    self:eraseBox(x,y)
    self:displayEditing(x,y, string.sub(self.content, -2))
	display.startBlinkingCursor(x+self.blinkingPos-1,y," ")
end

function InputBox:closeEditing(x,y)
	display.stopBlinkingCursor()
	self:display(x, y)
end

function InputBox:moveCursorRight(x,y)
    display.stopBlinkingCursor()
	
	if(self.blinkingPos < 3) then
	    if(#self.content < 1) then
	    elseif #self.content < 2 and self.blinkingPos > 1 then
	    elseif self.textBoxPos + self.blinkingPos <= #self.content then
	        self.blinkingPos = self.blinkingPos + 1
	    end
	elseif(self.textBoxPos < #self.content - 2)then
	    self.textBoxPos = self.textBoxPos + 1
	    self:eraseBox(x,y)
	    self:displayEditing(x,y, string.sub(self.content, self.textBoxPos+1, self.textBoxPos+3))
	end
	
	if(self.textBoxPos+self.blinkingPos > #self.content)then
	    display.startBlinkingCursor(x+self.blinkingPos-1,y," ")
	else
	    display.startBlinkingCursor(x+self.blinkingPos-1,y,string.sub(self.content,self.textBoxPos+self.blinkingPos,self.textBoxPos+self.blinkingPos))
	end
end

function InputBox:moveCursorLeft(x,y)
    display.stopBlinkingCursor()
	
	if(self.blinkingPos > 1) then
	  self.blinkingPos = self.blinkingPos - 1
	elseif(self.textBoxPos > 0)then
	  self.textBoxPos = self.textBoxPos - 1
	  self:eraseBox(x,y)
      self:displayEditing(x,y, string.sub(self.content, self.textBoxPos+1, self.textBoxPos+3))
	end
	
	if(string.sub(self.content,self.textBoxPos+self.blinkingPos,self.textBoxPos+self.blinkingPos) == "")then
	    display.startBlinkingCursor(x+self.blinkingPos-1,y," ")
	else
	    display.startBlinkingCursor(x+self.blinkingPos-1,y,string.sub(self.content,self.textBoxPos+self.blinkingPos,self.textBoxPos+self.blinkingPos))
	end
end

function InputBox:editing(x, y, chara, keyPress)
    local tempContent = ""
    local suppOffSet = 0
    local hasChanged = false

	-- Recopie l'avant cuseur de la coordonnée --
	if not self.isFacing then
        tempContent = string.sub(self.content,1,self.textBoxPos + self.blinkingPos-1)
    end
	-- Inclue l'édition sur la coordonée --
	if not self.isFacing and chara >= 48 and chara <= 57 then
	    tempContent = tempContent..string.char(chara)
	elseif chara == character.backspace then
	    tempContent = string.sub(tempContent,1,#tempContent-1) or ""
	elseif chara == character.hyphen_minus and self.isCoord then
		if self.textBoxPos == 0 and self.blinkingPos == 1 and string.sub(self.content,1,1) ~= string.char(character.hyphen_minus) then
		    tempContent = string.char(chara)
		end
	elseif self.isFacing and ((chara >= 65 and chara <= 90) or (chara >= 97 and chara <= 122)) then
	    if #self.content == 0 then
	        if(string.upper(string.char(chara)) == "E" or string.upper(string.char(chara)) == "W" or string.upper(string.char(chara)) == "S" or string.upper(string.char(chara)) == "N") then
	            tempContent = string.upper(string.char(chara))
	        end
		else
		    tempContent = self.content
		end
	end
	-- Inclue la fin de la coordonnée --
	if(keyPress == key.delete)then
	    suppOffSet = 1
	end
	if not self.isFacing then
        tempContent = tempContent..string.sub(self.content, self.textBoxPos + self.blinkingPos + suppOffSet)
	end
	-- Verify if its valid number--
	if not self.isFacing then
	    if(tempContent == "")then
	        self.content = tempContent
		    hasChanged = true
		elseif self.isNumberBox then
		    if #tempContent <= 3 then
			    if self.content ~= tempContent then
				     hasChanged = true
				end
				self.content = tempContent
			end
	    elseif (#tempContent <= #tostring(math.maxinteger)) or (string.sub(tempContent,1,1) == string.char(character.hyphen_minus) and #tempContent <= #tostring(math.mininteger)) then
			if tempContent == string.char(character.hyphen_minus) then
				if self.content ~= tempContent then
				     hasChanged = true
				end
				self.content = tempContent
			elseif tonumber(tempContent) >= 0 then
		        if tonumber(tempContent) <= math.maxinteger then
				    if self.content ~= tempContent then
						    hasChanged = true
					end
		            self.content = tempContent
		        end
		    elseif string.sub(tempContent,1,1) == string.char(character.hyphen_minus) then
				if tonumber(tempContent) <= 0 then
				    if tonumber(tempContent) >= math.mininteger then
						if self.content ~= tempContent then
						    hasChanged = true
						end
						self.content = tempContent
					end
				end
			end
	    end
    elseif self.isFacing then
	    if self.content ~= tempContent then
			hasChanged = true
		end
		self.content = tempContent
	end
	display.stopBlinkingCursor()
	-- Adjust textBox and cursor position --
	if ((not self.isFacing) and ((chara >= 48 and chara <= 57) or (chara == character.hyphen_minus and self.isCoord)) and hasChanged) or ((self.isFacing and self.content ~= "" and hasChanged)) then
	    if self.blinkingPos < 3 then
	        self.blinkingPos = self.blinkingPos + 1
	    else
	        self.textBoxPos = self.textBoxPos + 1
	    end
	    self:eraseBox(x,y)
		self:displayEditing(x, y, string.sub(self.content, self.textBoxPos+1, self.textBoxPos+3))
	
	elseif ((not self.isFacing) and chara == character.backspace and hasChanged) or (self.isFacing and chara == character.backspace) then
		if self.textBoxPos < 1 then
            if self.blinkingPos > 1 then
	            self.blinkingPos = self.blinkingPos - 1
	        end
	    else
	    self.textBoxPos = self.textBoxPos - 1
	    end
	    self:eraseBox(x,y)
	    self:displayEditing(x, y, string.sub(self.content, self.textBoxPos+1, self.textBoxPos+3))
	elseif keyPress == key.delete then
	    self:eraseBox(x,y)
	    self:displayEditing(x, y, string.sub(self.content, self.textBoxPos+1, self.textBoxPos+3))
	end
	if(self.textBoxPos+self.blinkingPos > #self.content)then
	    display.startBlinkingCursor(x+self.blinkingPos-1, y," ")
	else
        display.startBlinkingCursor(x+self.blinkingPos-1,y,string.sub(self.content,self.textBoxPos+self.blinkingPos,self.textBoxPos+self.blinkingPos))
	end
end

function InputBox:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

return InputBox