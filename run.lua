-----------------------------------------
--            Native Import            --
-----------------------------------------
local component = require("component")
local term = require("term")
local c = require("computer")
local sides = require("sides")
local nav = component.navigation
-----------------------------------------
--            Project Import           --
-----------------------------------------
local Farmland = require("farmland")
local move = require("move")
--local pathfinding = require("pathfinding")
local map = require("map")
local Inventory = require ("inventory")
local BinaryHeap = require("binaryheap")

-----------------------------------------
--            Test library             --
-----------------------------------------
local robot = require("robot")
local inv = component.inventory_controller
local event = require("event")
local geo = component.geolyzer

-----------------------------------------


local mode = {searchNewSpecies = 1, 
              growWithHighStatsSeed = 3, 
			  growWithoutHighStatsSeed = 4
}

local over = {seed = 1,
              guide = 2,
			  junk = 3,
			  highStatGuide = 4}
		  
local guideMinStat = {resistance = 4,
                     gain = 30,
					 growth = 20

}

local guideMaxStat = {resistance = 0,
                     gain = 31,
					 growth = 21
}
local lootMaxStat = {resistance = 0,
                     gain = 31,
					 growth = 23
}

local lootMinStat= {resistance = 4,
                     gain = 30,
					 growth = 22
}

local lootNumber

local run = {currPosition = {},
             farmlands,
			 robotInventory,
			 nodeTab,
			 plantedGuideToReplace,
			 guideNotPlanted,
			 cropsToCheck,
			 currGrowingSeedName,
			 seedsInBank,
			 posItems = {cropstick = {},
			             charger = {},
                         trashCan = {},
			             highStatsSeeds = {},
			             seedsToGrow = {},
						 lootedSeeds = {},
						 bankSeeds = {}}
}


function run:init(SetFarmlandsInputBoxes, setItemsInputBoxes)
    local i, j, k, l
	
	-- initilize position
	self.currPosition.x, self.currPosition.y, self.currPosition.z = nav.getPosition()
	self.currPosition.f = nav.getFacing()
	self.currPosition.x = math.floor(self.currPosition.x)
	self.currPosition.y = math.floor(self.currPosition.y)
	self.currPosition.z = math.floor(self.currPosition.z)
	-- read the map file --
	self.nodeTab = map:createNodeTab()
	
	--initialize farmlands--
	j = 1
	self.farmlands = {}
	for i=2, #SetFarmlandsInputBoxes-5, 6 do
		self.farmlands[j] = Farmland:new({xFarmStart = tonumber(SetFarmlandsInputBoxes[i].content),
		                                  xFarmEnd = tonumber(SetFarmlandsInputBoxes[i+3].content),
					                      yFarm = tonumber(SetFarmlandsInputBoxes[i+1].content),
					                      zFarmStart = tonumber(SetFarmlandsInputBoxes[i+2].content),
					                      zFarmEnd = tonumber(SetFarmlandsInputBoxes[i+5].content)})
	
		j = j + 1
    end
	-- initialize inventory --
	self.robotInventory = Inventory:new()
	self.robotInventory:init()
	-- initialize cropsToCheck
	cropsToCheckPresence = {}
	self.cropsToCheck = {}
	self.cropsToCheck.index = {}
	for i, farmland in pairs(self.farmlands) do
	    self.cropsToCheck.index[i] = 1
	end

	-- initialize guide heap --
	self.plantedGuideToReplace = BinaryHeap:new()
	self.guideNotPlanted = {}
	l = 1
	for i, farmland in pairs(self.farmlands) do
		k = math.ceil(farmland:getSideLength()/2)
		for j = k, 1, -1 do
		    if k == farmland:getSideLength()/2 then
			    self.guideNotPlanted[l] = farmland.crops[j][j]
				l = l + 1
				self.guideNotPlanted[l] = farmland.crops[farmland:getSideLength()-j+1][farmland:getSideLength()-j+1]
				l = l + 1
			else
			    if j == k then
				    self.guideNotPlanted[l] = farmland.crops[j][j]
				    l = l + 1
				else
				    self.guideNotPlanted[l] = farmland.crops[farmland:getSideLength()-j + 1][farmland:getSideLength()-j + 1]
				    l = l + 1
					self.guideNotPlanted[l] = farmland.crops[j][j]
				    l = l + 1
				end
			end
		end
	end
	-- read items positions --
	for k, v in pairs(self.posItems) do
	
	    if k == "cropstick" then
		    i = 1
		elseif k == "charger" then
		    i = 5
        elseif k == "trashCan" then
		    i = 9
		elseif k == "highStatsSeeds" then
		    i = 13
		elseif k == "seedsToGrow" then
		    i = 17
		elseif k == "lootedSeeds" then
		    i = 21
		elseif k == "bankSeeds" then
		    i = 25
		end
		
        self.posItems[k].x = tonumber(setItemsInputBoxes[i].content)
		self.posItems[k].y = tonumber(setItemsInputBoxes[i+1].content)
		self.posItems[k].z = tonumber(setItemsInputBoxes[i+2].content)
		
		if     setItemsInputBoxes[i+3].content == "N" then
		    self.posItems[k].f = sides.north
		elseif setItemsInputBoxes[i+3].content == "S" then
		    self.posItems[k].f = sides.south
		elseif setItemsInputBoxes[i+3].content == "W" then
		    self.posItems[k].f = sides.west
		elseif setItemsInputBoxes[i+3].content == "E" then
		    self.posItems[k].f = sides.east
		end
	end
end

function run:findFarmland(pos)
    local i = 1
	local isFound = false
	local xStart, xEnd, zStart, zEnd
	while not isFound and i < #self.farmlands do
	    if self.farmlands[i].xFarmStart > self.farmlands[i].xFarmEnd then
		    xStart = self.farmlands[i].xFarmEnd
			xEnd = self.farmlands[i].xFarmStart
		else
		    xStart = self.farmlands[i].xFarmStart
			xEnd = self.farmlands[i].xFarmEnd
		end
		if self.farmlands[i].zFarmStart > self.farmlands[i].zFarmEnd then
		    zStart = self.farmlands[i].zFarmEnd
			zEnd = self.farmlands[i].zFarmStart
		else
		    zStart = self.farmlands[i].zFarmStart
			zEnd = self.farmlands[i].zFarmEnd
		end
		
		if pos.x >= xStart and pos.x <= xEnd and pos.z >= zStart and pos.z <= zEnd then
		    isFound = true
		else
		   i = i + 1
		end
	end
	return i
end

function run:checkEnergy()
	if math.ceil(c.energy()/c.maxEnergy()*100) < 15 then
	    move:followPath(self.nodeTab,self.currPosition, self.posItems.charger, self.posItems.charger.f)
		while math.ceil(c.energy()/c.maxEnergy()*100) < 95 do
		    os.sleep(5)
		end
	end
end

function run:cropPosScore(farmlandNumber, crop)
    local score
	local xFarm = self.farmlands[farmlandNumber]:getX(crop.x)
	local zFarm = self.farmlands[farmlandNumber]:getZ(crop.z)
	
	
	if xFarm >= zFarm  then
	    score = math.pow(xFarm, 2)
	else
	    score = math.pow(zFarm, 2)
	end
	
	return score + zFarm - xFarm
end

function run:inCropsToCheck(farmlandNumber, crop)
    local i = self.cropsToCheck.index[farmlandNumber]
	local isFound = false
	
	if farmlandNumber == #self.farmlands then
	    stopIndex = #self.cropsToCheck + 1
	else
	    stopIndex = self.cropsToCheck.index[farmlandNumber + 1]
	end
	
	while not isFound and i < stopIndex do
	    if crop == self.cropsToCheck[i] then
		    isFound = true
		end
		i = i + 1
	end
	
	return isFound
end

function run:removeCropsToCheck(farmlandNumber, crop)
    local i = self.cropsToCheck.index[farmlandNumber]
	local isFound = false
	
	if farmlandNumber == #self.farmlands then
	    stopIndex = #self.cropsToCheck + 1
	else
	    stopIndex = self.cropsToCheck.index[farmlandNumber + 1]
	end
	
	while not isFound do
	    if crop.x == self.cropsToCheck[i].x and crop.z == self.cropsToCheck[i].z then
		    isFound = true
		else
		    i = i + 1
		end
	end
	table.remove(self.cropsToCheck, i)
	if farmlandNumber < #self.farmlands then
	    for i =	farmlandNumber + 1, #self.farmlands do
		    self.cropsToCheck.index[i] = self.cropsToCheck.index[i] - 1
		end
	end
end

function run:addCropsToCheck(farmlandNumber, crop)
    local i = self.cropsToCheck.index[farmlandNumber]
	local isFound = false
	local stopIndex
	local cropPosScore
	
	if farmlandNumber == #self.farmlands then
	    stopIndex = #self.cropsToCheck + 1
	else
	    stopIndex = self.cropsToCheck.index[farmlandNumber + 1]
	end
	
	cropPosScore = self:cropPosScore(farmlandNumber, crop)
	
	while i < stopIndex and not isFound do
	    if cropPosScore < self:cropPosScore(farmlandNumber, self.cropsToCheck[i]) then
		    isFound = true
		else
		    i = i + 1
		end
	end
	
	table.insert(self.cropsToCheck, i, crop)
	
	if farmlandNumber < #self.farmlands then
	    for i =	farmlandNumber + 1, #self.farmlands do
		    self.cropsToCheck.index[i] = self.cropsToCheck.index[i] + 1
		end
	end
end

function run:gatherGuideWithHighStatsSeed()
    local currGuide
	local success = true
	local finalPosition = {}
	local isHighStatSeedChestEmpty = false
	local isSeedsToGrowChestEmpty = false
	
	while not isHighStatSeedChestEmpty and not isSeedsToGrowChestEmpty and #self.guideNotPlanted > 0 and success do
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
	    isSeedsToGrowChestEmpty, self.currGrowingSeedName = self.robotInventory:pickUpMixedGuideSeedToGrow()
	
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.highStatsSeeds, self.posItems.highStatsSeeds.f)
	    isHighStatSeedChestEmpty = self.robotInventory:pickUpMixedGuideHighStatSeeds()
		
		while #self.guideNotPlanted > 0 and ((self.farmlands[self:findFarmland(self.guideNotPlanted[1])]:getX(self.guideNotPlanted[1].x)% 2 == 0 and self.robotInventory:getGuideStack() > 0) or (self.farmlands[self:findFarmland(self.guideNotPlanted[1])]:getX(self.guideNotPlanted[1].x)% 2 == 1 and self.robotInventory:getHighStatGuideStack() > 0)) do
		    success = self:checkCropStick(1)
		    if success then
			    currGuide = self.guideNotPlanted[1]
			    finalPosition.x = currGuide.x
			    finalPosition.y = currGuide.y + 1
			    finalPosition.z = currGuide.z
			    move:followPath(self.nodeTab,self.currPosition, finalPosition)
				if self.farmlands[self:findFarmland(finalPosition)]:getX(finalPosition.x)% 2 == 0 then
				    guidePlanted = self.robotInventory:plantGuide()
				else
				    guidePlanted = self.robotInventory:plantHighStatGuide()
				end
				table.remove(self.guideNotPlanted, 1)
				if guidePlanted ~= nil then
					currGuide.resistance = guidePlanted.crop.resistance
					currGuide.growth  = guidePlanted.crop.growth
					currGuide.gain  = guidePlanted.crop.gain
					if self.farmlands[self:findFarmland(finalPosition)]:getX(finalPosition.x)% 2 == 1 then
					    currGuide.malus = 200
					end
					currGuide.gotWood = true
					self:addCropsToCheck(self:findFarmland(self.currPosition), currGuide)
					if (not (currGuide.resistance == guideMaxStat.resistance and currGuide.growth >= guideMaxStat.growth and currGuide.gain >= guideMaxStat.gain)) or currGuide.malus ~= 0 then
					    self.plantedGuideToReplace:add(currGuide)
					end
					guidePlanted = nil
				end
			end
		end
	end
	
	if #self.guideNotPlanted == 0 then
	    if self.robotInventory:getGuideStack() > 0 then
	        move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
		    self.robotInventory:stachGuide()
		end
		if self.robotInventory:getHighStatGuideStack() > 0 then
		    move:followPath(self.nodeTab, self.currPosition, self.posItems.highStatsSeeds, self.posItems.highStatsSeeds.f)
			self.robotInventory:stachHighStatGuide()
		end
	end
end

function run:gatherGuideWithoutHighStatsSeed()
    local isChestEmpty = false
	local success = true
	local finalPosition = {}
	local guidePlanted
	
	while not isChestEmpty and #self.guideNotPlanted > 0 and success do
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
	    isChestEmpty, self.currGrowingSeedName = self.robotInventory:pickUpNotMixedGuide()

	    while #self.guideNotPlanted > 0 and self.robotInventory:getGuideStack() > 0 and success do
		    success = self:checkCropStick(1)
			
			if success then
			    currGuide = self.guideNotPlanted[1]
			    finalPosition.x = currGuide.x
			    finalPosition.y = currGuide.y + 1
			    finalPosition.z = currGuide.z
			    move:followPath(self.nodeTab,self.currPosition, finalPosition)
				guidePlanted = self.robotInventory:plantGuide()
				table.remove(self.guideNotPlanted, 1)
				if guidePlanted ~= nil then
					currGuide.resistance = guidePlanted.crop.resistance
					currGuide.growth  = guidePlanted.crop.growth
					currGuide.gain  = guidePlanted.crop.gain
					currGuide.gotWood = true
					self:addCropsToCheck(self:findFarmland(self.currPosition), currGuide)
					if not (currGuide.resistance == guideMaxStat.resistance and currGuide.growth >= guideMaxStat.growth and currGuide.gain >= guideMaxStat.gain) then
					    self.plantedGuideToReplace:add(currGuide)
					end
					guidePlanted = nil
				end
			end
		end
	end

	if #self.guideNotPlanted == 0 and self.robotInventory:getGuideStack() > 0 then
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
		self.robotInventory:stachGuide()
	end
	
	return success
end

function run:gatherGuideSearchNewSpecies()
    local isChestEmpty = false
	local success = true
	local finalPosition = {}
	local guidePlanted
	
	move:followPath(self.nodeTab, self.currPosition, self.posItems.bankSeeds, self.posItems.bankSeeds.f)
	self.seedsInBank = self.robotInventory:getSeedsInBanks()
	
	while not isChestEmpty and #self.guideNotPlanted > 0 and success do
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
	    isChestEmpty, self.currGrowingSeedName = self.robotInventory:pickUpNotMixedGuide()
	
	    while #self.guideNotPlanted > 0 and self.robotInventory:getGuideStack() > 0 and success do
		    success = self:checkCropStick(1)
			
			if success then
			    currGuide = self.guideNotPlanted[1]
			    finalPosition.x = currGuide.x
			    finalPosition.y = currGuide.y + 1
			    finalPosition.z = currGuide.z
			    move:followPath(self.nodeTab,self.currPosition, finalPosition)
				guidePlanted = self.robotInventory:plantGuide()
				table.remove(self.guideNotPlanted, 1)
				if guidePlanted ~= nil then
					currGuide.resistance = guidePlanted.crop.resistance
					currGuide.growth  = guidePlanted.crop.growth
					currGuide.gain  = guidePlanted.crop.gain
					currGuide.gotWood = true
					self:addCropsToCheck(self:findFarmland(self.currPosition), currGuide)
					guidePlanted = nil
				end
			end
		end
	end

	if #self.guideNotPlanted == 0 and self.robotInventory:getGuideStack() > 0 then
	    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
		self.robotInventory:stachGuide()
	end
	
	return success
end

function run:setupCrossCrop(farmlandNumber, crop)
    local relativX = self.farmlands[farmlandNumber]:getX(crop.x)
	local relativZ = self.farmlands[farmlandNumber]:getZ(crop.z)
	local finalPos = {}
	local shifting = 0
	
	if relativX > 1 and relativZ > 1 then
	    if self.farmlands[farmlandNumber].crops[relativX-1][relativZ-1].mature == true then
		    if self.farmlands[farmlandNumber].crops[relativX-1][relativZ].gotWood == false then
			    finalPos.x = self.farmlands[farmlandNumber].crops[relativX-1][relativZ].x
			    finalPos.y = self.farmlands[farmlandNumber].crops[relativX-1][relativZ].y + 1
			    finalPos.z = self.farmlands[farmlandNumber].crops[relativX-1][relativZ].z
				move:followPath(self.nodeTab, self.currPosition, finalPos)
				self.robotInventory:putDoubleStick()
				self.farmlands[farmlandNumber].crops[relativX-1][relativZ].gotWood = true
				self:addCropsToCheck(farmlandNumber, self.farmlands[farmlandNumber].crops[relativX-1][relativZ])
			end
			if self.farmlands[farmlandNumber].crops[relativX][relativZ-1].gotWood == false then
			    finalPos.x = self.farmlands[farmlandNumber].crops[relativX][relativZ-1].x
			    finalPos.y = self.farmlands[farmlandNumber].crops[relativX][relativZ-1].y + 1
			    finalPos.z = self.farmlands[farmlandNumber].crops[relativX][relativZ-1].z
				move:followPath(self.nodeTab, self.currPosition, finalPos)
				self.robotInventory:putDoubleStick()
				self.farmlands[farmlandNumber].crops[relativX][relativZ-1].gotWood = true
				self:addCropsToCheck(farmlandNumber, self.farmlands[farmlandNumber].crops[relativX][relativZ-1])
				shifting = 1
			end
		end
	end
	if relativX < self.farmlands[farmlandNumber]:getSideLength() and relativZ < self.farmlands[farmlandNumber]:getSideLength() then
	    if self.farmlands[farmlandNumber].crops[relativX+1][relativZ+1].mature == true then
		    if self.farmlands[farmlandNumber].crops[relativX+1][relativZ].gotWood == false then
			    finalPos.x = self.farmlands[farmlandNumber].crops[relativX+1][relativZ].x
			    finalPos.y = self.farmlands[farmlandNumber].crops[relativX+1][relativZ].y + 1
			    finalPos.z = self.farmlands[farmlandNumber].crops[relativX+1][relativZ].z
				move:followPath(self.nodeTab, self.currPosition, finalPos)
				self.robotInventory:putDoubleStick()
				self.farmlands[farmlandNumber].crops[relativX+1][relativZ].gotWood = true
				self:addCropsToCheck(farmlandNumber, self.farmlands[farmlandNumber].crops[relativX+1][relativZ])
			end
			if self.farmlands[farmlandNumber].crops[relativX][relativZ+1].gotWood == false then
			    finalPos.x = self.farmlands[farmlandNumber].crops[relativX][relativZ+1].x
			    finalPos.y = self.farmlands[farmlandNumber].crops[relativX][relativZ+1].y + 1
			    finalPos.z = self.farmlands[farmlandNumber].crops[relativX][relativZ+1].z
				move:followPath(self.nodeTab, self.currPosition, finalPos)
				self.robotInventory:putDoubleStick()
				self.farmlands[farmlandNumber].crops[relativX][relativZ+1].gotWood = true
				self:addCropsToCheck(farmlandNumber, self.farmlands[farmlandNumber].crops[relativX][relativZ+1])
			end
		end
	end
	
	return shifting
end

function run:growWithoutHighStatsSeed()
    local lootedSeeds = 0
	local success = true
	local isLootChestFull = false
	local i, finalPos,currFarmland, analyze, pickup, isRemoved, shifting, currCrop, guidePlanted, guideRemplaced, numberOfSeeds
	finalPos = {}
	
	isRemoved = false
	guideRemplaced = false
	
	while lootedSeeds < lootNumber and not isLootChestFull and success do
	    i = 1
		while i <= #self.cropsToCheck and success do
		    self:checkEnergy()
			
			if self.robotInventory:getSpaceLeft() < 1 then
			    success = self:checkInventory()
			end
			if success then
			    success = self:checkCropStick(12)
			end
			
			if success then
			    finalPos.x = self.cropsToCheck[i].x
			    finalPos.y = self.cropsToCheck[i].y + 1
			    finalPos.z = self.cropsToCheck[i].z
			    move:followPath(self.nodeTab, self.currPosition, finalPos)
			    currFarmland = self:findFarmland(self.currPosition)
			    analyze = geo.analyze(sides.bottom)
			    if self.farmlands[currFarmland]:getX(self.currPosition.x) == self.farmlands[currFarmland]:getZ(self.currPosition.z) then
			        -- Guide crop
				    if analyze["crop:size"] == analyze["crop:maxSize"] then
				        self.cropsToCheck[i].mature = true
						shifting = self:setupCrossCrop(currFarmland, self.cropsToCheck[i])
					    self:removeCropsToCheck(currFarmland, self.cropsToCheck[i+shifting])
						isRemoved = true
				    end
			    else
			        if analyze["crop:name"] == "weed" then
					    self.robotInventory:harvestWeed()
					elseif analyze["crop:name"] == self.currGrowingSeedName then
					    if analyze["crop:size"] < analyze["crop:maxSize"] then
						    if (not (analyze["crop:growth"] >= lootMinStat.growth and analyze["crop:growth"] <= lootMaxStat.growth and analyze["crop:resistance"] <= lootMinStat.resistance and analyze["crop:gain"] >= lootMinStat.gain)) and (#self.guideNotPlanted == 0 or analyze["crop:growth"] > guideMaxStat.growth)then
							    if analyze["crop:growth"] > guideMaxStat.growth then
								    self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								elseif self.plantedGuideToReplace.items[0] == nil then
								    self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								elseif self.plantedGuideToReplace.items[0]:compareToAnalyze(analyze) <= 0 then
								    self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								end
							end
						else
						    pickup = false
						    if (self.plantedGuideToReplace.items[0] ~= nil or #self.guideNotPlanted > 0) and analyze["crop:growth"] <= guideMaxStat.growth then
							    if #self.guideNotPlanted > 0 then
								    self.robotInventory:harvestGuideCrop()
								    pickup = true
								    success = self:checkItemOnTheGround(over.guide)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								    while self.robotInventory:getGuideStack() > 0 and success do
								        if #self.guideNotPlanted > 0 then
										    currCrop = self.guideNotPlanted[1]
											table.remove(self.guideNotPlanted, 1)
											finalPos.x = currCrop.x
			                                finalPos.y = currCrop.y + 1
			                                finalPos.z = currCrop.z
											move:followPath(self.nodeTab, self.currPosition, finalPos)
											guidePlanted = self.robotInventory:plantGuide()
				                            if guidePlanted ~= nil then
												guideRemplaced = true
				                                currCrop.resistance = guidePlanted.crop.resistance
				                                currCrop.growth  = guidePlanted.crop.growth
				                                currCrop.gain  = guidePlanted.crop.gain
					                            currCrop.gotWood = true
					                            if not self:inCropsToCheck(self:findFarmland(self.currPosition), currCrop) then
													self:addCropsToCheck(self:findFarmland(self.currPosition), currCrop)
											    end
					                            if not (currCrop.resistance == guideMaxStat.resistance and currCrop.growth >= guideMaxStat.growth and currCrop.gain >= guideMaxStat.gain) then
					                                self.plantedGuideToReplace:add(currCrop)
					                            end
					                            guidePlanted = nil
											end

									    end
									    if not guideRemplaced then
									        self.robotInventory:turnGuideIntoJunk()
									    end
									    guideRemplaced = false
									end
								elseif self.plantedGuideToReplace.items[0]:compareToAnalyze(analyze) > 0 then
							        self.robotInventory:harvestGuideCrop()
								    pickup = true
								    success = self:checkItemOnTheGround(over.guide)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								    while self.robotInventory:getGuideStack() > 0 and success do
								        if self.plantedGuideToReplace.items[0] ~= nil then
									        if self.plantedGuideToReplace.items[0]:compareToItem(self.robotInventory:getFirstGuide()) > 0 then
										        currCrop = self.plantedGuideToReplace:removeFirst()
											    finalPos.x = currCrop.x
			                                    finalPos.y = currCrop.y + 1
			                                    finalPos.z = currCrop.z
											    move:followPath(self.nodeTab, self.currPosition, finalPos)
												self.robotInventory:harvestJunkCrop()
											    success = self:checkItemOnTheGround(over.junk)
											    if success then
											        guidePlanted = self.robotInventory:plantGuide()
				                                    if guidePlanted ~= nil then
												        guideRemplaced = true
				                                        currCrop.resistance = guidePlanted.crop.resistance
				                                        currCrop.growth  = guidePlanted.crop.growth
				                                        currCrop.gain  = guidePlanted.crop.gain
					                                    currCrop.gotWood = true
					                                    if not self:inCropsToCheck(self:findFarmland(self.currPosition), currCrop) then
													        self:addCropsToCheck(self:findFarmland(self.currPosition), currCrop)
													    end
					                                    if not (currCrop.resistance == guideMaxStat.resistance and currCrop.growth >= guideMaxStat.growth and currCrop.gain >= guideMaxStat.gain) then
					                                        self.plantedGuideToReplace:add(currCrop)
					                                    end
					                                    guidePlanted = nil
				                                    end
											    end
										    end
									    end
									    if not guideRemplaced then
									        self.robotInventory:turnGuideIntoJunk()
									    end
									    guideRemplaced = false
									end
								end
							end
						    if not pickup then
						        if analyze["crop:growth"] >= lootMinStat.growth and analyze["crop:growth"] <= lootMaxStat.growth and analyze["crop:resistance"] <= lootMinStat.resistance and analyze["crop:gain"] >= lootMinStat.gain then
							        success, numberOfSeeds = self.robotInventory:harvestSeedCrop()
								    if success then
								        lootedSeeds = lootedSeeds + numberOfSeeds
								        success, numberOfSeeds = self:checkItemOnTheGround(over.seed)
								        lootedSeeds = lootedSeeds + numberOfSeeds
								        if success then
								            self.robotInventory:putDoubleStick()
											move:followPath(self.nodeTab, self.currPosition, finalPos)
									    end
								    end
							    elseif analyze["crop:growth"] >= guideMinStat.growth and analyze["crop:growth"] <= guideMaxStat.growth and analyze["crop:resistance"] <= guideMinStat.resistance and analyze["crop:gain"] >= guideMinStat.gain then
								    self.robotInventory:harvestGuideCrop()
								    pickup = true
								    success = self:checkItemOnTheGround(over.guide)
								    if success then
								        self.robotInventory:putDoubleStick()
										if self.robotInventory:getGuideStack() > 0 then
										    move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
											success = self.robotInventory:stachGuide()
										end
								    end
								else
							        self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								end
							end
						end
					elseif analyze["crop:name"] ~= nil and analyze["crop:name"] ~= self.currGrowingSeedName then
						self.robotInventory:harvestJunkCrop()
						success = self:checkItemOnTheGround(over.junk)
						if success then
						    self.robotInventory:putDoubleStick()
						end
					end
			    end
			    if isRemoved then
				    isRemoved = false
				else
			        i = i + 1
				end
			end
		end
	end
end

function run:growWithHighStatsSeed()
    local lootedSeeds = 0
	local success = true
	local isLootChestFull = false
	local i, finalPos,currFarmland, analyze, pickup, isRemoved, shifting, currCrop, guidePlanted, guideRemplaced, numberOfSeeds
	finalPos = {}
	
	isRemoved = false
	guideRemplaced = false
	
	while lootedSeeds < lootNumber and not isLootChestFull and success do
	    i = 1
		while i <= #self.cropsToCheck and success do
		    self:checkEnergy()
			
			if self.robotInventory:getSpaceLeft() < 1 then
			    success = self:checkInventory()
			end
			if success then
			    success = self:checkCropStick(12)
			end
			
			if success then
			    finalPos.x = self.cropsToCheck[i].x
			    finalPos.y = self.cropsToCheck[i].y + 1
			    finalPos.z = self.cropsToCheck[i].z
			    move:followPath(self.nodeTab, self.currPosition, finalPos)
			    currFarmland = self:findFarmland(self.currPosition)
			    analyze = geo.analyze(sides.bottom)
			    if self.farmlands[currFarmland]:getX(self.currPosition.x) == self.farmlands[currFarmland]:getZ(self.currPosition.z) then
			        -- Guide crop
				    if analyze["crop:size"] == analyze["crop:maxSize"] then
				        self.cropsToCheck[i].mature = true
						shifting = self:setupCrossCrop(currFarmland, self.cropsToCheck[i])
					    self:removeCropsToCheck(currFarmland, self.cropsToCheck[i+shifting])
						isRemoved = true
				    end
			    else
			        if analyze["crop:name"] == "weed" then
					    self.robotInventory:harvestWeed()
					elseif analyze["crop:name"] == self.currGrowingSeedName then
					    if analyze["crop:size"] < analyze["crop:maxSize"] then
						    if (not (analyze["crop:growth"] >= lootMinStat.growth and analyze["crop:growth"] <= lootMaxStat.growth and analyze["crop:resistance"] <= lootMinStat.resistance and analyze["crop:gain"] >= lootMinStat.gain)) and (#self.guideNotPlanted == 0 or (not(analyze["crop:resistance"] <= guideMinStat.resistance and analyze["crop:growth"] >= guideMinStat.growth and analyze["crop:gain"] >= guideMinStat.gain))) then
							    if self.plantedGuideToReplace.items[0] == nil then
								    self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								elseif self.plantedGuideToReplace.items[0]:compareToAnalyze(analyze) <= 0 then
								    self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								end
							end
						else
						    pickup = false
						    if (self.plantedGuideToReplace.items[0] ~= nil or (#self.guideNotPlanted > 0 and analyze["crop:resistance"] <= guideMinStat.resistance and analyze["crop:growth"] >= guideMinStat.growth and analyze["crop:gain"] >= guideMinStat.gain)) and analyze["crop:growth"] <= guideMaxStat.growth then
							    if #self.guideNotPlanted > 0 and analyze["crop:resistance"] <= guideMinStat.resistance and analyze["crop:growth"] >= guideMinStat.growth and analyze["crop:gain"] >= guideMinStat.gain then
								    self.robotInventory:harvestGuideCrop()
								    pickup = true
								    success = self:checkItemOnTheGround(over.guide)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								    while self.robotInventory:getGuideStack() > 0 and success do
								        if #self.guideNotPlanted > 0 then
										    currCrop = self.guideNotPlanted[1]
											table.remove(self.guideNotPlanted, 1)
											finalPos.x = currCrop.x
			                                finalPos.y = currCrop.y + 1
			                                finalPos.z = currCrop.z
											move:followPath(self.nodeTab, self.currPosition, finalPos)
											guidePlanted = self.robotInventory:plantGuide()
				                            if guidePlanted ~= nil then
												guideRemplaced = true
				                                currCrop.resistance = guidePlanted.crop.resistance
				                                currCrop.growth  = guidePlanted.crop.growth
				                                currCrop.gain  = guidePlanted.crop.gain
					                            currCrop.gotWood = true
					                            if not self:inCropsToCheck(self:findFarmland(self.currPosition), currCrop) then
													self:addCropsToCheck(self:findFarmland(self.currPosition), currCrop)
											    end
					                            if not (currCrop.resistance == guideMaxStat.resistance and currCrop.growth >= guideMaxStat.growth and currCrop.gain >= guideMaxStat.gain) then
					                                self.plantedGuideToReplace:add(currCrop)
					                            end
					                            guidePlanted = nil
											end

									    end
									    if not guideRemplaced then
									        self.robotInventory:turnGuideIntoJunk()
									    end
									    guideRemplaced = false
									end
								elseif self.plantedGuideToReplace.items[0]:compareToAnalyze(analyze) > 0 then
							        self.robotInventory:harvestGuideCrop()
								    pickup = true
								    success = self:checkItemOnTheGround(over.guide)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								    while self.robotInventory:getGuideStack() > 0 and success do
								        if self.plantedGuideToReplace.items[0] ~= nil then
									        if self.plantedGuideToReplace.items[0]:compareToItem(self.robotInventory:getFirstGuide()) > 0 then
										        currCrop = self.plantedGuideToReplace:removeFirst()
											    finalPos.x = currCrop.x
			                                    finalPos.y = currCrop.y + 1
			                                    finalPos.z = currCrop.z
											    move:followPath(self.nodeTab, self.currPosition, finalPos)
												if currCrop.malus ~= 0 then
												    self.robotInventory:harvestHighStatGuideCrop()
											        success = self:checkItemOnTheGround(over.highStatGuide)
												else
												    self.robotInventory:harvestJunkCrop()
											        success = self:checkItemOnTheGround(over.junk)
												end
											    if success then
											        guidePlanted = self.robotInventory:plantGuide()
				                                    if guidePlanted ~= nil then
												        guideRemplaced = true
				                                        currCrop.resistance = guidePlanted.crop.resistance
				                                        currCrop.growth  = guidePlanted.crop.growth
				                                        currCrop.gain  = guidePlanted.crop.gain
														if currCrop.malus ~= 0 then
														    currCrop.malus = 0
														end
					                                    currCrop.gotWood = true
					                                    if not self:inCropsToCheck(self:findFarmland(self.currPosition), currCrop) then
													        self:addCropsToCheck(self:findFarmland(self.currPosition), currCrop)
													    end
					                                    if not (currCrop.resistance == guideMaxStat.resistance and currCrop.growth >= guideMaxStat.growth and currCrop.gain >= guideMaxStat.gain) then
					                                        self.plantedGuideToReplace:add(currCrop)
					                                    end
					                                    guidePlanted = nil
				                                    end
											    end
										    end
									    end
									    if not guideRemplaced then
									        self.robotInventory:turnGuideIntoJunk()
									    end
									    guideRemplaced = false
									end
								end
							end
						    if not pickup then
						        if analyze["crop:growth"] >= lootMinStat.growth and analyze["crop:growth"] <= lootMaxStat.growth and analyze["crop:resistance"] <= lootMinStat.resistance and analyze["crop:gain"] >= lootMinStat.gain then
							        success, numberOfSeeds = self.robotInventory:harvestSeedCrop()
								    if success then
								        lootedSeeds = lootedSeeds + numberOfSeeds
								        success, numberOfSeeds = self:checkItemOnTheGround(over.seed)
								        lootedSeeds = lootedSeeds + numberOfSeeds
								        if success then
								            self.robotInventory:putDoubleStick()
									    end
								    end
							    else
							        self.robotInventory:harvestJunkCrop()
								    success = self:checkItemOnTheGround(over.junk)
								    if success then
								        self.robotInventory:putDoubleStick()
								    end
								end
							end
						end
					elseif analyze["crop:name"] ~= nil and analyze["crop:name"] ~= self.currGrowingSeedName then
						self.robotInventory:harvestJunkCrop()
						success = self:checkItemOnTheGround(over.junk)
						if success then
						    self.robotInventory:putDoubleStick()
						end
					end
			    end
			    if isRemoved then
				    isRemoved = false
				else
			        i = i + 1
				end
			end
		end
	end
end

function run:searchNewSpecies()
	local success = true
	local isLootChestFull = false
	local i, finalPos,currFarmland, analyze, pickup, isRemoved, shifting, currCrop, guidePlanted, guideRemplaced, numberOfSeeds, lootedSeeds
	finalPos = {}
	
	isRemoved = false
	guideRemplaced = false
	
	while not isLootChestFull and success do
	    i = 1
		while i <= #self.cropsToCheck and success do
		    self:checkEnergy()
			
			if self.robotInventory:getSpaceLeft() < 1 then
			    success = self:checkInventory()
			end
			if success then
			    success = self:checkCropStick(12)
			end
			
			if success then
			    finalPos.x = self.cropsToCheck[i].x
			    finalPos.y = self.cropsToCheck[i].y + 1
			    finalPos.z = self.cropsToCheck[i].z
			    move:followPath(self.nodeTab, self.currPosition, finalPos)
			    currFarmland = self:findFarmland(self.currPosition)
			    analyze = geo.analyze(sides.bottom)
			    if self.farmlands[currFarmland]:getX(self.currPosition.x) == self.farmlands[currFarmland]:getZ(self.currPosition.z) then
			        -- Guide crop
				    if analyze["crop:size"] == analyze["crop:maxSize"] then
				        self.cropsToCheck[i].mature = true
						shifting = self:setupCrossCrop(currFarmland, self.cropsToCheck[i])
					    self:removeCropsToCheck(currFarmland, self.cropsToCheck[i+shifting])
						isRemoved = true
				    end
			    else
			        if analyze["crop:name"] == "weed" then
					    self.robotInventory:harvestWeed()
					elseif self.seedsInBank[analyze["crop:name"]] == nil and analyze["crop:name"] ~= nil then
					    if analyze["crop:size"] == analyze["crop:maxSize"] then
							lootedSeeds = 0
							success, numberOfSeeds = self.robotInventory:harvestSeedCrop()
							if success then
								lootedSeeds = lootedSeeds + numberOfSeeds
								success, numberOfSeeds = self:checkItemOnTheGround(over.seed)
								lootedSeeds = lootedSeeds + numberOfSeeds
								if success then
								    if lootedSeeds > 0 then
									    self.seedsInBank[analyze["crop:name"]] = analyze["crop:name"]
									end
								    self.robotInventory:putDoubleStick()
							    end
							end
						end
					elseif analyze["crop:name"] ~= nil then
						self.robotInventory:harvestJunkCrop()
						success = self:checkItemOnTheGround(over.junk)
						if success then
						    self.robotInventory:putDoubleStick()
						end
					end
			    end
			    if isRemoved then
				    isRemoved = false
				else
			        i = i + 1
				end
			end
		end
	end
end

function run:checkItemOnTheGround(above)
    local success = true
	local lastPos = {}
	local numberOfSeeds = 0
	lastPos.x = self.currPosition.x
	lastPos.y = self.currPosition.y
	lastPos.z = self.currPosition.z
	if self.robotInventory:getSpaceLeft() == 0 then
	    success = self:checkInventory()
		if success then
		    move:followPath(self.nodeTab, self.currPosition, lastPos)
			if above == over.junk then
			    self.robotInventory:suckOverJunkCrop()
			elseif above == over.seed then
			    numberOfSeeds = self.robotInventory:suckOverSeedCrop()
			elseif above == over.guide then
			    self.robotInventory:suckOverGuideCrop()
			elseif above == over.highStatGuide then
			    self.robotInventory:suckOverHighStatGuideCrop()
			end
		end
	end
	
	return success, numberOfSeeds
end

function run:checkInventory()
    local success = true
	if self.robotInventory:getHighStatGuideStack() > 0 and success then
	    move:followPath(self.nodeTab,self.currPosition, self.posItems.highStatsSeeds, self.posItems.highStatsSeeds.f)
		success = self.robotInventory:stachHighStatGuide()
	end
	if self.robotInventory:getLootedStack() > 0 and success then
		move:followPath(self.nodeTab,self.currPosition, self.posItems.lootedSeeds, self.posItems.lootedSeeds.f)
		success = self.robotInventory:stachLooted()
	end
	if self.robotInventory:getJunkStack() > 0 and success then
	    move:followPath(self.nodeTab,self.currPosition, self.posItems.trashCan, self.posItems.trashCan.f)
		self.robotInventory:throwJunk()
	end
	if self.robotInventory:getCropstickStack() > 1 and success then
	    move:followPath(self.nodeTab,self.currPosition, self.posItems.cropstick, self.posItems.cropstick.f)
		success = self.robotInventory:stachExcessCropStick()
	end
	
	return success
end

function run:checkCropStick(cropStickMin)
    local success = true
	if self.robotInventory:getCropStickNumber() < cropStickMin then
		move:followPath(self.nodeTab,self.currPosition, self.posItems.cropstick, self.posItems.cropstick.f)
		success = self.robotInventory:pickUpCropStick()
	end
	return success
end

function run:tidyUpFarmland()
    local isCropstickLeft = true
	local success = true
	local finalPos = {}
	local sideLength, currCrops, x, z, i, analyze
	
	while isCropstickLeft and success do
	    isCropstickLeft = false
	    i = 1
		while i <= #self.farmlands and success do
			sideLength = self.farmlands[i]:getSideLength()
			x = 1
			while x <= sideLength and success do
			    z = 1
				while z <= sideLength and success do
				    self:checkEnergy()
			        if self.robotInventory:getSpaceLeft() < 1 then
			            success = self:checkInventory()
			        end
					if success then
				        currCrops = self.farmlands[i].crops[x][z]
					    if currCrops.gotWood then
					        isCropstickLeft = true
						    finalPos.x = currCrops.x
						    finalPos.y = currCrops.y + 1
						    finalPos.z = currCrops.z
						    move:followPath(self.nodeTab,self.currPosition, finalPos)
							analyze = geo.analyze(sides.bottom)
							if analyze["crop:name"] == "weed" then
							    self.robotInventory:harvestJunkCrop()
						        success = self:checkItemOnTheGround(over.junk)
								currCrops.gotWood = false
							elseif analyze["crop:name"] ~= self.currGrowingSeedName and x ~= z then
						        self.robotInventory:harvestJunkCrop()
						        success = self:checkItemOnTheGround(over.junk)
								currCrops.gotWood = false
							elseif analyze["crop:size"] == analyze["crop:maxSize"] then
					            if analyze["crop:name"] ~= self.currGrowingSeedName and x == z then
							        self.robotInventory:harvestHighStatGuideCrop()
								    success = self:checkItemOnTheGround(over.highStatGuide)
							    elseif analyze["crop:name"] == self.currGrowingSeedName and x == z then
								    self.robotInventory:harvestGuideCrop()
								    success = self:checkItemOnTheGround(over.guide)
								    if success and self.robotInventory:getGuideStack() > 0 then
										move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
										success = self.robotInventory:stachGuide()
								    end
								elseif analyze["crop:growth"] >= lootMinStat.growth and analyze["crop:growth"] <= lootMaxStat.growth and analyze["crop:resistance"] <= lootMinStat.resistance and analyze["crop:gain"] >= lootMinStat.gain then
								    success = self.robotInventory:harvestSeedCrop()
								    if success then
								        success = self:checkItemOnTheGround(over.seed)
									end
								elseif analyze["crop:growth"] >= guideMinStat.growth and analyze["crop:growth"] <= guideMaxStat.growth and analyze["crop:resistance"] <= guideMinStat.resistance and analyze["crop:gain"] >= guideMinStat.gain then
								    self.robotInventory:harvestGuideCrop()
								    success = self:checkItemOnTheGround(over.guide)
								    if success and self.robotInventory:getGuideStack() > 0 then
										move:followPath(self.nodeTab, self.currPosition, self.posItems.seedsToGrow, self.posItems.seedsToGrow.f)
									    success = self.robotInventory:stachGuide()
								    end
								else
								    self.robotInventory:harvestJunkCrop()
						            success = self:checkItemOnTheGround(over.junk)
								end
								currCrops.gotWood = false
							end
						end
					end
				    z = z + 1
				end
			    x = x + 1
			end
	        i = i + 1
		end
	end
end

function run:main(SetFarmlandsInputBoxes, setItemsInputBoxes, selectedRun, numberOfSeeds)
    term.clear()
	lootNumber = tonumber(numberOfSeeds)
	self:init(SetFarmlandsInputBoxes, setItemsInputBoxes)
	local currCrop
	if self.currPosition.x == nil then
	    print(self.currPosition.y)
		event.pull("key_down")
	else
		
		self:checkEnergy()
		if self:checkInventory() then
		    if self:checkCropStick(64) then
		        if selectedRun == mode.searchNewSpecies then
				    self:gatherGuideSearchNewSpecies()
					self:searchNewSpecies()
		        elseif selectedRun == mode.growWithHighStatsSeed then
				    self:gatherGuideWithHighStatsSeed()
					self:growWithHighStatsSeed()
		        elseif selectedRun == mode.growWithoutHighStatsSeed then
		            self:gatherGuideWithoutHighStatsSeed()
					self:growWithoutHighStatsSeed()
				end
				self:checkInventory()
				self:tidyUpFarmland()
				self:checkInventory()
				move:followPath(self.nodeTab,self.currPosition, self.posItems.charger, self.posItems.charger.f)
		    end
		end
		--move:followPath(self.nodeTab,self.currPosition, self.posItems.charger, self.posItems.charger.f)
	end
end

return run