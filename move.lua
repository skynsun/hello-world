local sides = require("sides")
local robot_api = require("robot")
local map = require("map")
local pathfinding = require("pathfinding")

local move = {}

function move:y(currPosition, vY)
    local moved = 0
	local success = true
	local reason
	local step
	
	if vY > 0 then
	    step = 1
	    while moved < vY and success do
	        success, reason = robot_api.up()
		    if success then
			    moved = moved + 1
				currPosition.y = currPosition.y + 1
			else
			    print(reason)
			end
	    end
	elseif vY < 0 then
	    step = -1
	    while moved < math.abs(vY) and success do
	        success, reason = robot_api.down()
		    if success then
			    moved = moved + 1
				currPosition.y = currPosition.y - 1
			end
	    end
	end
	
	if moved == math.abs(vY) then
	    return
	else
		return step * moved, reason
	end
end

function move:turn(currPosition, side)
    if     currPosition.f == sides.north then
	    if side == sides.north then
		elseif side == sides.south then
		    robot_api.turnAround()
		elseif side == sides.west then
		    robot_api.turnLeft()
		else
		    robot_api.turnRight()
		end
	elseif currPosition.f == sides.south then
	    if side == sides.north then
		    robot_api.turnAround()
		elseif side == sides.south then
		elseif side == sides.west then
		    robot_api.turnRight()
		else
		    robot_api.turnLeft()
		end
	elseif currPosition.f == sides.west then
	    if side == sides.north then
		    robot_api.turnRight()
		elseif side == sides.south then
		    robot_api.turnLeft()
		elseif side == sides.west then
		else
		    robot_api.turnAround()
		end
	else
	    if side == sides.north then
		    robot_api.turnLeft()
		elseif side == sides.south then
		    robot_api.turnRight()
		elseif side == sides.west then
		    robot_api.turnAround()
		else
		end
	end
	currPosition.f = side
end

function move:x(currPosition, v)
	local moved = 0
	local success = true
	local reason
	local step
	
	if math.abs(v) > 0 then
	    if v > 0 then
		    self:turn(currPosition, sides.east)
			step = 1
	    elseif v < 0 then
		    self:turn(currPosition, sides.west)
			step = -1
	    end
		while moved < math.abs(v) and success do
		    success, reason = robot_api.forward()
			if success then
			    moved = moved + 1
				currPosition.x = currPosition.x + step
			--else
			--    print(reason)
			end
		end
	end
	if moved == math.abs(v) then
	    return
	else
		return step * moved, reason
	end
end

function move:z(currPosition, v)
    local moved = 0
	local success = true
	local reason
	local step
	
	if math.abs(v) > 0 then
	    if v > 0 then
		    self:turn(currPosition, sides.south)
			step = 1
	    elseif v < 0 then
		    self:turn(currPosition, sides.north)
			step = -1
	    end
		while moved < math.abs(v) and success do
		    success, reason = robot_api.forward()
			if success then
			    moved = moved + 1
				currPosition.z = currPosition.z + step
			--else
			--    print(reason)
			end
		end
	end
	if moved == math.abs(v) then
	    return
	else
		return step * moved, reason
	end
end

function move:to(currPosition,x,y,z)
	local vX = x - currPosition.x
	local vY = y - currPosition.y
    local vZ = z - currPosition.z
	local remainingStep
	local reason
	
	repeat
	    remainingStep = nil
		reason = nil
		remainingStep, reason = self:x(currPosition, vX)
		if remainingStep ~= nil then
		    vX = vX - remainingStep
		end
	until reason == entity
	
	repeat
	    remainingStep = nil
		reason = nil
		remainingStep, reason = self:z(currPosition, vZ)
		if remainingStep ~= nil then
		    vZ = vZ - remainingStep
		end
	until reason == entity
	
	repeat
	    remainingStep = nil
		reason = nil
		remainingStep, reason = self:y(currPosition, vY)
		if remainingStep ~= nil then
		    vY = vY - remainingStep
		end
	until reason == entity
	
end

function move:followPath(nodeTab, currPosition, finalPosition, finalSide)
    map:initNodeTab(nodeTab)
    for i, path in ipairs(pathfinding.findPath(currPosition, finalPosition, nodeTab)) do
	    move:to(currPosition,path.x,path.y,path.z)
	end
	if finalSide ~= nil then
	    move:turn(currPosition, finalSide)
	end
end

return move