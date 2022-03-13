local Crop = require("crop")
local Farmland = {xFarmStart,
	              xFarmEnd,
	              yFarm,
	              zFarmStart,
	              zFarmEnd,
	              crops
}

function Farmland:getSideLength()
    local x , z
	x = math.abs(self.xFarmEnd - self.xFarmStart) + 1
	z = math.abs(self.zFarmEnd - self.zFarmStart) + 1
	
	if x <= z then
	    return x
	else 
	    return z
	end
end

function Farmland:getX(relativX)
    return math.abs(relativX - self.xFarmStart) + 1
end

function Farmland:getZ(relativZ)
    return math.abs(relativZ - self.zFarmStart) + 1
end

function Farmland:new(t)
    local xStep = 1
	local zStep = 1
	
	if t.xFarmStart > t.xFarmEnd then
	    xStep = -1
	end
	if t.zFarmStart > t.zFarmEnd then
	    zStep = -1
	end
	t.crops = {}
    for k = 1, math.abs(t.xFarmEnd - t.xFarmStart) + 1 do
		t.crops [k]= {}
		for l = 1 , math.abs(t.zFarmEnd - t.zFarmStart) + 1 do
			t.crops[k][l]= Crop:new({x=t.xFarmStart+(k-1)*xStep, y=t.yFarm, z=t.zFarmStart+(l-1)*zStep})
		end
	end

    setmetatable(t, self)
    self.__index = self
    return t
end

return Farmland