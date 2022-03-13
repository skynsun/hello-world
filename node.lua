Node ={
    x,
	y,
	z,
	gCost,
	hCost,
	parent,
	heapIndex,
	isObstacle
}

function Node:fCost()
    return self.gCost + self.hCost
end

function Node:compareTo(nodeToCompare)
    local compare = self:fCost() - nodeToCompare:fCost()
	if compare == 0 then
	    compare = self.hCost - nodeToCompare.hCost
	end
	return - compare
end

function Node:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  return t
end