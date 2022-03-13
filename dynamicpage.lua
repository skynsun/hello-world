event = require("event")
require("page")

local coordBox =" ç x=   ".."  y=   ".."  z=   "
local facing ="  f= "
local numberBox ="=   "
--local repeatNumber = 6

DynamicPage = Page:new({
    baseBody = {},
	repeatedBody = {},
	body = {},
	endBody = {},
	isDynamicPage = true
})

function DynamicPage:generateBaseBody()
   local i
   self.body = {}
   i = 1
   for j = 1, #self.baseBody do
        self.body[i] = {}
	    for k, v in pairs(self.baseBody[j]) do
	       self.body[i][k] = v
		end
		i = i + 1
   end
end

function DynamicPage:generateDynamicBody()
    local i
    local m
    local n
    local spaceBeforeEnd = ""

    if self.inputBoxes[1] ~= nil and self.inputBoxes[1].content ~= "" then
	    repeatNumber = tonumber(self.inputBoxes[1].content)
	else
	    repeatNumber = 0
		self.inputBoxes[1].content = 0
	end
	
    i = #self.body + 1
    m = 1
    for l = 1, repeatNumber do
        for j = 1, #self.repeatedBody do
            self.body[i] = {}
	        for k, v in pairs(self.repeatedBody[j]) do
				if k == "text" then
				    spaceBeforeEnd = "  "
					if(string.find(v, "%%s")) then
				        v = string.format(v,m)
					    m = m +1
					else 
					    for n=1, #tostring(m) do
						    spaceBeforeEnd = spaceBeforeEnd.." "
						end
						v = spaceBeforeEnd..v
					end
				end
				self.body[i][k] = v
		    end
		    i = i + 1
		end
    end
end

function DynamicPage:generateEndBody()
    local i = #self.body + 1
	
	for j = 1, #self.endBody do
	    self.body[i] = {}
		for k, v in pairs(self.endBody[j]) do
		    self.body[i][k] = v
		end
		i = i + 1
	end
end

function DynamicPage:init()
    self:generateBaseBody()
    Page.init(self)
end

function DynamicPage:changeDynamicPart()
    local tempContent = {}
	
	for i, inputBox in ipairs(self.inputBoxes) do
	    tempContent[i]= inputBox.content
	end
	self:generateDynamicBody()
	self:generateEndBody()
	Page.init(self)
	
	for i = 1, #self.inputBoxes do
	    self.inputBoxes[i].content = tempContent[i]
	end
end

function DynamicPage:changeSize()
    self:generateBaseBody()
	self:changeDynamicPart()
end