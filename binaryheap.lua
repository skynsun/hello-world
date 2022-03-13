local BinaryHeap = {
    items,
	currentItemCount = 0
}

function BinaryHeap:add(item)
    item.heapIndex = self.currentItemCount
	self.items[self.currentItemCount] = item
	self:sortUp(item)
	self.currentItemCount = self.currentItemCount + 1
end

function BinaryHeap:removeFirst()
    local firstItem = self.items[0]
	self.currentItemCount = self.currentItemCount - 1
	self.items[0] = self.items[self.currentItemCount]
	self.items[0].heapIndex = 0
	self:sortDown(self.items[0])
	return firstItem
end

function BinaryHeap:updateItem(item)
    self:sortUp(item)
end

function BinaryHeap:contains(item)
	return self.items[item.heapIndex] == item
end

function BinaryHeap:sortDown(item)
    local childIndexLeft
	local childIndexRight
	local swapIndex
	
	while true do
	    childIndexLeft = item.heapIndex * 2 + 1
	    childIndexRight = item.heapIndex * 2 + 2
	    swapIndex = 0
		if childIndexLeft < self.currentItemCount then
		    swapIndex = childIndexLeft
			if childIndexRight < self.currentItemCount then
			    if self.items[childIndexLeft]:compareTo(self.items[childIndexRight]) < 0 then
				    swapIndex = childIndexRight
				end
			end
			if item:compareTo(self.items[swapIndex]) < 0 then
			    self:swap(item, self.items[swapIndex])
			else
			    return
			end
		else
		    return
		end
	end
end

function BinaryHeap:sortUp(item)
	local parentIndex = math.floor(math.abs((item.heapIndex-1)/2))
	local parentItem
	local isFinish = false

	while not isFinish do
	    parentItem = self.items[parentIndex]
		if item:compareTo(parentItem) > 0 then
		    self:swap(item, parentItem)
		else
		    isFinish = true
		end
	    parentIndex = math.floor(math.abs((item.heapIndex - 1)/2))
	end
end

function BinaryHeap:swap(itemA, itemB)
   local tempIndex
	self.items[itemA.heapIndex] = itemB
	self.items[itemB.heapIndex] = itemA
	tempIndex = itemA.heapIndex
	itemA.heapIndex = itemB.heapIndex
	itemB.heapIndex = tempIndex
end

function BinaryHeap:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  t.items={}
  return t
end

return BinaryHeap