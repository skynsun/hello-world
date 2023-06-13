local component = require("component")
local serial = require("serialization")
local display = require("display")
local node = require("node")
local filesystem = require("filesystem")
local computer = require("computer")
local event = require("event")
local geo = component.geolyzer
local nav = component.navigation

local map = {
	fileName = "map.data",
	yLength = 5
}

function map:generateMap(xWide, zWide, farmLandInputBoxes)
    local temp
	local data
	local file
	local x, y ,z = nav.getPosition()
	local xLength = math.ceil(tonumber(xWide)/2) * 2
	local zLength = math.ceil(tonumber(zWide)/2) * 2
	local xFarmStart, xFarmEnd, zFarmStart, zFarmEnd, yFarm, tempFarm
	local currRelativePosX, currRelativePosZ
	local xScanStart, zScanStart
	
	display.scanLoading()
	data = {}
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	xScanStart = x - (xLength/2)
	zScanStart = z - (zLength/2)
	for i = 0, xLength do
        data[i] = {}
		currRelativePosX = i-(xLength/2)
        for j = 0, zLength do
		    currRelativePosZ = j-(zLength/2)
            temp = geo.scan(currRelativePosX, currRelativePosZ,0,1,1, self.yLength)
	        data[i][j]={}
	        for k = 1, self.yLength do
				if temp[k] ~= 0 then
				    -- Obstacle détecté
					data[i][j][k] = true
				else
				    -- espace vide
				    data[i][j][k] = false
				end
				
				if currRelativePosX == 0 and currRelativePosZ == 0 and k == 1 then
				    data[i][j][k] = false
				end
				
				for l=2, #farmLandInputBoxes-5, 6 do
					xFarmStart = tonumber(farmLandInputBoxes[l].content)
					xFarmEnd = tonumber(farmLandInputBoxes[l+3].content)
					yFarm = tonumber(farmLandInputBoxes[l+1].content)
					zFarmStart = tonumber(farmLandInputBoxes[l+2].content)
					zFarmEnd = tonumber(farmLandInputBoxes[l+5].content)
					
					if xFarmStart > xFarmEnd then
					    tempFarm = xFarmStart
						xFarmStart = xFarmEnd
					    xFarmEnd = tempFarm
					end
					if zFarmStart > zFarmEnd then
                        tempFarm = zFarmStart
						zFarmStart = zFarmEnd
					    zFarmEnd = tempFarm
					end
					
					if (k-1 + y) == yFarm and (xScanStart + i) >= xFarmStart and (xScanStart + i) <= xFarmEnd and (zScanStart + j) >= zFarmStart and (zScanStart + j) <= zFarmEnd then
					    data[i][j][k] = true
					end
				end
	        end
        end
		display.updateScanLoading((i/xLength)*100)
    end
    file = io.open(self.fileName, "w")
	
	file:write(serial.serialize(xScanStart).."\n")
	file:write(serial.serialize(y).."\n")
	file:write(serial.serialize(zScanStart).."\n")
	file:write(serial.serialize(xLength).."\n")
	file:write(serial.serialize(self.yLength).."\n")
	file:write(serial.serialize(zLength).."\n")
	
	for i = 0, xLength do
        for j = 0, zLength do
	        file:write(serial.serialize(data[i][j]).."\n")
		end
	end
    file:close()
end

function map:createNodeTab()
    local nodeTab = {}
	local file
	local readTemp
	
    if filesystem.exists("/home/"..self.fileName) then
        file = io.open(self.fileName, "r")
	    nodeTab.startX = serial.unserialize(file:read("*l"))
		nodeTab.startY = serial.unserialize(file:read("*l"))
		nodeTab.startZ = serial.unserialize(file:read("*l"))
		nodeTab.XLength = serial.unserialize(file:read("*l"))
		nodeTab.YLength = serial.unserialize(file:read("*l"))
		nodeTab.ZLength = serial.unserialize(file:read("*l"))
		
		for i=0, nodeTab.XLength do
		    nodeTab[i] = {}
			for j=0, nodeTab.ZLength do
			    nodeTab[i][j] = {}
			    readTemp = serial.unserialize(file:read("*l"))
				for k=1, nodeTab.YLength do
					nodeTab[i][j][k] = Node:new({x = i+nodeTab.startX,y = k-1+nodeTab.startY,z =j+nodeTab.startZ,isObstacle=readTemp[k]})
				end
			end
		end
		
		file:close()
		return nodeTab
	else
	    return nil
	end
end

function map:initNodeTab(nodeTab)
    for i=0, nodeTab.XLength do
		for j=0, nodeTab.ZLength do  
			for k=1, nodeTab.YLength do
					nodeTab[i][j][k].gCost = 1/0
					nodeTab[i][j][k].heapIndex = nil
			end
		end
	end
end

return map