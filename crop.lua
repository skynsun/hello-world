local Crop = {cropName= "",
              resistance = 32,
			  growth = -1,
			  gain = -1,
			  malus = 0,
			  mature = false,
			  gotWood = false,
			  x,
			  y,
			  z,
			  heapIndex}

function Crop:stats()
    return self.growth * 100 + self.gain * 90 - self.resistance * 20 - self.malus
end

function Crop:compareTo(cropToCompare)
    local compare = self:stats() - cropToCompare:stats()
	if compare == 0 then
	    compare = self.growth - cropToCompare.growth
	end
	return - compare
end

function Crop:compareToAnalyze(analyzeToCompare)
    local compare = self:stats() - (analyzeToCompare["crop:growth"]*100 + analyzeToCompare["crop:gain"]*90 - analyzeToCompare["crop:resistance"]*20)
	if compare == 0 then
	    compare = self.growth - analyzeToCompare["crop:growth"]
	end
	return - compare
end

function Crop:compareToItem(itemToCompare)
    local compare = self:stats() - (itemToCompare.crop.growth*100 + itemToCompare.crop.gain*90 - itemToCompare.crop.resistance*20)
	if compare == 0 then
	    compare = self.growth - itemToCompare.crop.growth
	end
	return - compare
end

function Crop:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  t.items={}
  return t
end

return Crop