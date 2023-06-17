local component = require("component")
local robot = require("robot")
local sides = require("sides")
local inv = component.inventory_controller
local beam = component.tractor_beam

local event = require("event")

itemTypes = {cropStick = 1,
             guide = 2,
			 highStatGuide = 3,
		     junk = 4,
			 seed = 5,
			 spade = 6
}

local Inventory = {emptySlot,
                   cursor = 1,
				   itemsBySlot,
				   categorizedItems,
				   equippedSlot,
				   otherThanSpadeEquipped,
				   guideName
}

function Inventory:init()
	local item, itemType
	self.categorizedItems = {}
	self.itemsBySlot = {}
	self.emptySlot = {}
	
	robot.select(1)
	
	for k, v in pairs(itemTypes) do
	    self.categorizedItems[v] = {}
	end
	
	for slot = 1, robot.inventorySize() do
		self:addEmptySlot(slot)
		item = inv.getStackInInternalSlot(slot)
		if item ~= nil then
			self:addItem(item, self:determineItemType(item), slot)
		end
	end
	
	self:checkEquippedItem()
	self:sort()
end

function Inventory:determineItemType(item)
    local itemType
	
	if string.find(item.name, "IC2:blockCrop") ~= nil then
		itemType = itemTypes.cropStick
	elseif string.find(item.name, "IC2:itemCropSeed") ~= nil then
		itemType = itemTypes.seed
	elseif string.find(item.name, "berriespp:itemSpade") ~= nil then
		itemType = itemTypes.spade
	else
		itemType = itemTypes.junk
	end
	
	return itemType
end

function Inventory:checkEquippedItem()
    local itemType, slot, item
	if #self.emptySlot > 0 then
	    robot.select(self.emptySlot[1])
	    inv.equip()
	    self.equippedSlot = inv.getStackInInternalSlot(self.emptySlot[1])
	    if self.equippedSlot ~= nil then
		    itemType = self:determineItemType(self.equippedSlot)
		    if itemType == itemTypes.spade then
		        self.equippedSlot.slot = 0
	            inv.equip()
		    else
		        self:addItem(self.equippedSlot, itemType, self.emptySlot[1])
			    if #self.categorizedItems[itemTypes.spade] > 0 then
			        robot.select(self.categorizedItems[itemTypes.spade][1].slot)
				    inv.equip()
				    self.equippedSlot = self.categorizedItems[itemTypes.spade][1]
				    self:removeFirstItemByCategory(itemTypes.spade)
					self.equippedSlot.slot = 0
			    end
		    end
		else
		    if #self.categorizedItems[itemTypes.spade] > 0 then
			    robot.select(self.categorizedItems[itemTypes.spade][1].slot)
				inv.equip()
				self.equippedSlot = self.categorizedItems[itemTypes.spade][1]
				self:removeFirstItemByCategory(itemTypes.spade)
				self.equippedSlot.slot = 0
			end
		end
		self.otherThanSpadeEquipped = false
	else
	    if #self.categorizedItems[itemTypes.spade] > 0 then
		    slot = self.categorizedItems[itemTypes.spade][1].slot
			robot.select(slot)
			inv.equip()
			self.equippedSlot = self.categorizedItems[itemTypes.spade][1]
			self:removeFirstItemByCategory(itemTypes.spade)
			self.equippedSlot.slot = 0
			item = inv.getStackInInternalSlot(slot)
			if item ~= nil then
			    self:addItem(item, self:determineItemType(item), slot)
			end
			self.otherThanSpadeEquipped = false
		else
		    robot.select(1)
			inv.equip()
			self.equippedSlot = inv.getStackInInternalSlot(slot)
			self.equippedSlot.slot = 0
			if self.equippedSlot ~= nil then
			    if self:determineItemType(self.equippedSlot) == itemTypes.spade then
				    self.otherThanSpadeEquipped = false
				else
				    self.otherThanSpadeEquipped = true
				end
			else
			    self.otherThanSpadeEquipped = false
			end
			inv.equip()
		end
	end
	robot.select(1)
end

function Inventory:removeBySlot(slot)
    local itemCategory, itemNumber
	itemCategory, itemNumber = self:findCategorizedItem(slot)
	self:addEmptySlot(slot)
	self.itemsBySlot[slot] = nil
	table.remove(self.categorizedItems[itemCategory], itemNumber)
	self:updateCursor(slot)
end

function Inventory:findCategorizedItem(slot)
    local itemCategory = 1
	local isFound = false
	local itemNumber
	while itemCategory <= #self.categorizedItems and not isFound do
	    itemNumber = 1
		while itemNumber <= #self.categorizedItems[itemCategory] do
		    if self.categorizedItems[itemCategory][itemNumber].slot == slot then
			    isFound = true
			else
			    itemNumber = itemNumber + 1
			end
	    end
		if not isFound then
		    itemCategory = itemCategory + 1
		end
	end
	return itemCategory, itemNumber
end

function Inventory:removeFirstItemByCategory(itemType)
	local slot = self.categorizedItems[itemType][1].slot
	self:addEmptySlot(slot)
	self.itemsBySlot[slot] = nil
	table.remove(self.categorizedItems[itemType], 1)
	self:updateCursor(slot)
end

function Inventory:updateCursor(slot)
    local i
	if self.cursor == slot + 1 then
	    i = slot
		while self.itemsBySlot[i] == nil and i > 0 do
		    i = i - 1
		end
		self.cursor = i + 1
	end
end

function Inventory:addItem(item, itemType, slot)
	self.itemsBySlot[slot] = item
	self.categorizedItems[itemType][#self.categorizedItems[itemType]+1] = item
	self.categorizedItems[itemType][#self.categorizedItems[itemType]].slot = slot
	self:removeEmptySlot(slot)
	
	if self.cursor < slot then
	    self.cursor = slot + 1
	end
end

function Inventory:removeEmptySlot(slot)
    local i = 1
	while self.emptySlot[i] ~= slot do 
		    i = i + 1
	end
	table.remove(self.emptySlot, i)
end

function Inventory:addEmptySlot(slot)
    i = 1
	if #self.emptySlot > 0 then
	    while i <= #self.emptySlot and self.emptySlot[i] < slot do 
		    i = i + 1
	    end
	end
	table.insert(self.emptySlot, i, slot)
end

function Inventory:swap(slotA, slotB)
    local i, tempItem
	if self.itemsBySlot[slotA] == nil and self.itemsBySlot[slotB] == nil then
	elseif self.itemsBySlot[slotA] == nil then
	    self:removeEmptySlot(slotA)
		self:addEmptySlot(slotB)
		self.itemsBySlot[slotB].slot = slotA
	elseif self.itemsBySlot[slotB] == nil then
        self:removeEmptySlot(slotB)
		self:addEmptySlot(slotA)
		self.itemsBySlot[slotA].slot = slotB
	else
	    self.itemsBySlot[slotA].slot = slotB
	    self.itemsBySlot[slotB].slot = slotA
	end
	
	tempItem = self.itemsBySlot[slotA]
	self.itemsBySlot[slotA] = self.itemsBySlot[slotB]
	self.itemsBySlot[slotB] = tempItem
	
	
	robot.select(slotA)
	robot.transferTo(slotB)
	robot.select(1)
end

function Inventory:sort()
    local nextItemSlot = robot.inventorySize()
	while self.itemsBySlot[nextItemSlot] == nil and nextItemSlot > 1 do
		nextItemSlot = nextItemSlot - 1
	end
	while self.cursor > self:getNumberOfItemsStack() + 1 do
		self:swap(nextItemSlot, self.emptySlot[1])
		while self.itemsBySlot[nextItemSlot] == nil do
		    nextItemSlot = nextItemSlot - 1
	    end
		self.cursor = nextItemSlot
	end
end

function Inventory:drop(itemType, NumberOfStackToKeep)
    local success = true
	
	if NumberOfStackToKeep == nil then
	    NumberOfStackToKeep = 0
	end
	
	while #self.categorizedItems[itemType] > NumberOfStackToKeep and success do
	    robot.select(self.categorizedItems[itemType][1 + NumberOfStackToKeep].slot)
	    success = robot.drop()
		if success then
		    self:addEmptySlot(self.categorizedItems[itemType][1 + NumberOfStackToKeep].slot)
			self.itemsBySlot[self.categorizedItems[itemType][1 + NumberOfStackToKeep].slot] = nil
		    table.remove(self.categorizedItems[itemType],1 + NumberOfStackToKeep)
		end
	end
	robot.select(1)
	if success then
	    success = self:dropEquippedSlot(itemType)
	end
	return success
end

function Inventory:throwJunk()
	return self:drop(itemTypes.junk)
end

function Inventory:stachLooted()
    return self:drop(itemTypes.seed)
end

function Inventory:stachExcessCropStick()
    return self:drop(itemTypes.cropStick, 1)
end

function Inventory:stachGuide()
    return self:drop(itemTypes.guide)
end

function Inventory:stachHighStatGuide()
    return self:drop(itemTypes.highStatGuide)
end

function Inventory:dropEquippedSlot(itemType)
    local success = true
    if self.otherThanSpadeEquipped then
	    if self:determineItemType(self.equippedSlot) == itemType then
		    inv.equip()
		    success = robot.drop()
			if success then
		        self.equippedSlot = nil
		        inv.equip()
			    self.otherThanSpadeEquipped = false
		    end
		end
	end
	return success
end

function Inventory:pickUpCropStick()
    local success = true
	local item
	if self:getCropStickNumber() < 64 then
	    if #self.categorizedItems[itemTypes.cropStick] == 0 and #self.emptySlot > 0 then
	        robot.select(self.emptySlot[1])
	        success = robot.suck()
		    self:addItem(inv.getStackInInternalSlot(self.emptySlot[1]), itemTypes.cropStick, self.emptySlot[1])
	    elseif #self.categorizedItems[itemTypes.cropStick] > 0 then
	        robot.select(self.categorizedItems[itemTypes.cropStick][1].slot)
		    success = robot.suck(64 - robot.count())
			self:updateStack(self.categorizedItems[itemTypes.cropStick][1].slot)
	    else
		    success = false
	    end
	end
	
	return success
end

function Inventory:pickUpMixedGuideSeedToGrow()
    local number = math.floor((self:getSpaceLeft() + self:getGuideStack() + self:getHighStatGuideStack())/2) - self:getGuideStack()
	return self:pickUpGuide(number, itemTypes.guide)
end

function Inventory:pickUpMixedGuideHighStatSeeds()
    local number = math.floor((self:getSpaceLeft() + self:getGuideStack() + self:getHighStatGuideStack())/2) - self:getHighStatGuideStack()
    return self:pickUpGuide(number, itemTypes.highStatGuide)
end

function Inventory:pickUpNotMixedGuide()
	return self:pickUpGuide(robot.inventorySize() - self:getNumberOfItemsStack(), itemTypes.guide)
end

function Inventory:pickUpGuide(maxGuideToPickUp, guideType)
    local isChestEmpty = false
	local item, itemNumber, name
	local i = 1

	while i <= inv.getInventorySize(sides.front) and self.guideName == nil and guideType == itemTypes.guide	do
	    item = inv.getStackInSlot(sides.front,i)
		if item ~= nil then
		    name = self:getSeedsName(item)
			if self:determineItemType(item) == itemTypes.seed then
			    self.guideName = name
			end
		end
		i = i + 1
	end
	i = 1
	itemNumber = 0
	while itemNumber < maxGuideToPickUp and i <= inv.getInventorySize(sides.front) do
	    i = 1
		item = nil
		while item == nil and i <= inv.getInventorySize(sides.front) do
		    item = inv.getStackInSlot(sides.front,i)
			if item ~= nil then
			    name = self:getSeedsName(item)
				if self:determineItemType(item) == itemTypes.seed and (name == self.guideName or guideType == itemTypes.highStatGuide) then
				    itemNumber = itemNumber + 1
					robot.select(self.emptySlot[1])
					inv.suckFromSlot(sides.front, i)
					self:addItem(item, guideType, self.emptySlot[1])
				else
				    item = nil
				end
			end
			i = i + 1
		end
	end
	robot.select(1)
	if i > inv.getInventorySize(sides.front) then
	    isChestEmpty = true
	end
	
	if guideType == itemTypes.guide then
	    return isChestEmpty, self.guideName
	else
	    return isChestEmpty
	end
end

function Inventory:getSeedsInBanks()
    local seedsInBanks = {}
	local item, name
	
	for i = 1, inv.getInventorySize(sides.front) do
		item = inv.getStackInSlot(sides.front,i)
		
		if item ~= nil then
			name = self:getSeedsName(item)
			if self:determineItemType(item) == itemTypes.seed and seedsInBanks[name] == nil then
                seedsInBanks[name] = name
			end
		end
	end
	
	return seedsInBanks
end

function Inventory:getSeedsName(item)
    local name
	
	if item.crop ~= nil then
		name = item.crop.name
	else
	    if item.label == "Sugar Beet Seeds" then
		    name = "Sugar Beet"
		end
	end
	
	return name
end

function Inventory:putDoubleStick()
    robot.select(self.categorizedItems[itemTypes.cropStick][1].slot)
	inv.equip()
	robot.useDown()
	robot.useDown()
	inv.equip()
	robot.select(1)
	self:updateStack(self.categorizedItems[itemTypes.cropStick][1].slot)

end

function Inventory:harvestWeed()
    robot.useDown()
	robot.select(self.categorizedItems[itemTypes.cropStick][1].slot)
	inv.equip()
	robot.useDown()
	inv.equip()
	robot.select(1)
	self:updateInventory()
end

function Inventory:harvestJunkCrop()
    return self:harvestCrop(itemTypes.junk)
end

function Inventory:harvestGuideCrop()
    return self:harvestCrop(itemTypes.guide)
end

function Inventory:harvestHighStatGuideCrop()
    return self:harvestCrop(itemTypes.highStatGuide)
end

function Inventory:harvestSeedCrop()
    return self:harvestCrop(itemTypes.seed)
end

function Inventory:harvestCrop(itemType)
    local success, numberOfSeeds

	success = robot.swingDown()
	if success then
	    numberOfSeeds = self:updateInventory(itemType)
	end
	
	return success, numberOfSeeds
end

function Inventory:getCropstickStack()
    return #self.categorizedItems[itemTypes.cropStick]
end

function Inventory:getCropStickNumber()
    if self.categorizedItems[itemTypes.cropStick][1] ~= nil then
	    return self.categorizedItems[itemTypes.cropStick][1].size
	else
	    return 0
	end
end

function Inventory:suckOverHighStatGuideCrop()
    return self:suckFromGround(itemTypes.highStatGuide)
end

function Inventory:suckOverSeedCrop()
    return self:suckFromGround(itemTypes.seed)
end

function Inventory:suckOverGuideCrop()
    return self:suckFromGround(itemTypes.guide)
end

function Inventory:suckOverJunkCrop()
    return self:suckFromGround(itemTypes.junk)
end

function Inventory:suckFromGround(itemType)
    while beam.suck() do
	end
	return self:updateInventory(itemType)
end

function Inventory:updateInventory(itemType)
    local itemTypeTemp, item, previousSize, numberOfSeeds
	local isFinish = false
	
	numberOfSeeds = 0
	
	-- Update Existing item
	for i=1 , robot.inventorySize() do
	    if self.itemsBySlot[i] ~= nil then
		    itemTypeTemp = self:determineItemType(self.itemsBySlot[i])
			if itemTypeTemp == itemTypes.junk or itemTypeTemp == itemTypes.cropStick or itemTypeTemp == itemTypes.seed then
				previousSize = self.itemsBySlot[i].size
				self:updateStack(i)
				if itemType == itemTypes.seed and itemTypeTemp == itemTypes.seed then
				   numberOfSeeds = numberOfSeeds + self.itemsBySlot[i].size - previousSize
				end
			end
		end
	end
	
	-- Add new item stack
	while not isFinish and #self.emptySlot > 0 do
	    item = inv.getStackInInternalSlot(self.emptySlot[1])
		if item ~= nil then
		    itemTypeTemp = self:determineItemType(item)
			if itemTypeTemp == itemTypes.seed then
			    itemTypeTemp = itemType
				--numberOfSeeds = numberOfSeeds + 1
				--- TEST CODE ---
				if itemType == itemTypes.seed then
				   numberOfSeeds = numberOfSeeds + item.size
				   print("add="..item.size)
				end
				--- TEST CODE ---
			end
			self:addItem(item, itemTypeTemp, self.emptySlot[1])
		else
		    isFinish = true
		end
	end
	return numberOfSeeds
end

function Inventory:updateStack(slot)
    local item
	item = inv.getStackInInternalSlot(slot)
	if item ~= nil then
	    for k, v in pairs(item) do
		    self.itemsBySlot[slot][k] = v
	    end
	else
	    self:removeBySlot(slot)
	end
end

function Inventory:plantHighStatGuide()
    return self:plant(itemTypes.highStatGuide)
end

function Inventory:plantGuide()
    return self:plant(itemTypes.guide)
end

function Inventory:plant(itemType)
    local success = true
	local guide
	
	robot.select(self.categorizedItems[itemTypes.cropStick][1].slot)
	inv.equip()
	success = robot.useDown()
	inv.equip()
	if success then
	    self:updateStack(self.categorizedItems[itemTypes.cropStick][1].slot)
	    guide = self.categorizedItems[itemType][1]
		robot.select(self.categorizedItems[itemType][1].slot)
		inv.equip()
		robot.useDown()
		---- Current code --
		--self:removeFirstItemByCategory(itemType)
		--inv.equip()
		--------------------
		--- TEST CODE ---
		inv.equip()
		if inv.getStackInInternalSlot(self.categorizedItems[itemType][1].slot) ~= nil then
		   self:updateStack(self.categorizedItems[itemType][1].slot)
		else
		   self:removeFirstItemByCategory(itemType)
		end
		-----------------
	end
	robot.select(1)
	
	if success then
	    return guide
	else
	    return nil
	end
end

function Inventory:getGuideStack()
    return #self.categorizedItems[itemTypes.guide]
end

function Inventory:getHighStatGuideStack()
    return #self.categorizedItems[itemTypes.highStatGuide]
end

function Inventory:getLootedStack()
    return #self.categorizedItems[itemTypes.seed]
end

function Inventory:getJunkStack()
    return #self.categorizedItems[itemTypes.junk]
end

function Inventory:getNumberOfItemsStack()
    local num = 0
	
	for k, categorizedItem in pairs(self.categorizedItems) do
	    num = num + #categorizedItem
	end
	
    return num
end

function Inventory:getFirstGuide()
    return self.categorizedItems[itemTypes.guide][1]
end

function Inventory:turnGuideIntoJunk()
    while #self.categorizedItems[itemTypes.guide] > 0 do
	    self.categorizedItems[itemTypes.junk][#self.categorizedItems[itemTypes.junk]+1] = self.categorizedItems[itemTypes.guide][1]
		table.remove(self.categorizedItems[itemTypes.guide], 1)
	end
end

function Inventory:getSpaceLeft()
    return robot.inventorySize() - self:getNumberOfItemsStack()
end

function Inventory:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  t.items={}
  return t
end

return Inventory