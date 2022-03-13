local BinaryHeap = require("binaryheap")
local event = require("event")

local pathfinding = {}

function pathfinding.findPath(startPos, targetPos, nodeTab)
    local startNode = nodeTab[startPos.x-nodeTab.startX][startPos.z-nodeTab.startZ][1+startPos.y-nodeTab.startY]
	local targetNode = nodeTab[targetPos.x-nodeTab.startX][targetPos.z-nodeTab.startZ][1+targetPos.y-nodeTab.startY]
	local currentNode
	local openSet = BinaryHeap:new()
	local closedSet = {}
	local isFinish = false
	local newMovementCostToNeighbour
	startNode.hCost= 1/0
	startNode.gCost= 0
	openSet:add(startNode)
	
	while (openSet.currentItemCount > 0) do
	    currentNode = openSet:removeFirst()
		closedSet[currentNode] = currentNode
		
		if currentNode ~= targetNode then
			for i, neighbour in ipairs(pathfinding.getNeighbours(currentNode, nodeTab)) do
				if closedSet[neighbour] == nil and neighbour.isObstacle == false then
				    newMovementCostToNeighbour = currentNode.gCost + pathfinding.getDistance(currentNode, neighbour)
					if newMovementCostToNeighbour < neighbour.gCost or (not openSet:contains(neighbour)) then
						neighbour.gCost = newMovementCostToNeighbour
						neighbour.hCost = pathfinding.getDistance(neighbour, targetNode)
						neighbour.parent = currentNode
						if not openSet:contains(neighbour) then
							openSet:add(neighbour)
						else
							openSet:updateItem(neighbour)
						end
					end
				end
			end
		else
			return pathfinding.retracePath(startNode,targetNode)
		end
	end
	return nil
end

function pathfinding.getDistance(nodeA,nodeB)
    local distX = math.abs(nodeA.x - nodeB.x)
	local distY = math.abs(nodeA.y - nodeB.y)
	local distZ = math.abs(nodeA.z - nodeB.z)

    return distX + distY + distZ
end

function pathfinding.retracePath(startNode, endNode)
    local path = {}
	local currentNode = endNode
	local i = 0
	local temp
	while currentNode ~= startNode do
	    i = i + 1
	    path[i] = currentNode
		currentNode = currentNode.parent
	end
	for i= 1, math.floor(#path/2)do
	    temp = path[i]
		path[i]= path[#path-i+1]
		path[#path-i+1] = temp
	end
	return path
end

function pathfinding.getNeighbours(currentNode, nodeTab)
    local neighbours = {}
	local j = 0
	
	for i= -1, 1, 2 do
	    if currentNode.x-nodeTab.startX+i >= 0 and currentNode.x-nodeTab.startX+i < nodeTab.XLength then
	        j = j + 1
			neighbours[j]=nodeTab[currentNode.x-nodeTab.startX+i][currentNode.z-nodeTab.startZ][1+currentNode.y-nodeTab.startY]
		end
	end
	for i=-1,1,2 do
	    if currentNode.y-nodeTab.startY+i >= 0 and currentNode.y-nodeTab.startY+i < nodeTab.YLength then
	        j = j + 1
			neighbours[j]=nodeTab[currentNode.x-nodeTab.startX][currentNode.z-nodeTab.startZ][1+currentNode.y-nodeTab.startY+i]
		end
	end
	for i=-1,1,2 do
		if currentNode.z-nodeTab.startZ+i >= 0 and currentNode.z-nodeTab.startZ+i < nodeTab.ZLength then
	        j = j + 1
			neighbours[j]=nodeTab[currentNode.x-nodeTab.startX][currentNode.z-nodeTab.startZ+i][1+currentNode.y-nodeTab.startY]
		end
	end
	return neighbours
end

return pathfinding