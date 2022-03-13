local task = {}

function task.createFarmlands(SetFarmlandsInputBoxes)
    local farmlands = {}
	local j = 1
	for i=2, #inputBoxes-5, 6 do
	    
		farmlands[j] = Farmland:new({xFarmStart = tonumber(inputBoxes[i].content),
		                             xFarmEnd = tonumber(inputBoxes[i+3].content),
					                 yFarm = tonumber(inputBoxes[i+1].content),
					                 zFarmStart = tonumber(inputBoxes[i+2].content),
					                 zFarmEnd = tonumber(inputBoxes[i+5].content)})
		j = j + 1
    end
	return farmlands
end

return task