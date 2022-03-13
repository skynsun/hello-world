---------------------------------
--          Requires           --
---------------------------------

local event = require("event")
local term = require("term")
local menu = require("menu")
local display = require("display")
require("page")
require("dynamicpage")


---------------------------------
--         Variables           --
---------------------------------

local running = true

local character = {endOfText = 3}
local mainMenu = Page:new({
  title = "Auto Crops",
  body = {{text="Start Crop The Program:" , isDesc=true},
          {text="Run"                     , isSelectable=true, isSubMenu=true},
		  {text="Configuration:"          , isDesc=true},
		  {text="Set Items Coordinates"   , isSelectable=true, isSubMenu=true},
		  {text="Set Farmland Coordinates", isSelectable=true, isSubMenu=true},
		  {text="Scan Environement"       , isSelectable=true, isSubMenu=true},
		  {text="Return To Shell:"        , isDesc=true},
		  {text="Exit"                    , isSelectable=true, isReturn=true}}
})

local RunMenu = Page:new({
    title = "Run",
	body = {{text="Search New Species",           isSelectable=true, isStarting=true},
	        {text=""          , isDesc=true},
	        {text="Number Of Seeds",   isSelectable=true, hasNumberBox = true},
			{text=""          , isDesc=true},
	        {text="Grow with High Stats Seed",    isSelectable=true, isStarting=true},
			{text="Grow without High Stats Seed", isSelectable=true, isStarting=true},
			{text="Return To Main Menu And Save", isSelectable=true, isReturn = true}}
})

local SetItems = Page:new({
    title = "Set Items Coordinates",
    body = {{text="Cropstick",           isSelectable=true, hasCoordbox = true, hasFacing = true},
		    {text="Charger",             isSelectable=true, hasCoordbox = true, hasFacing = true},
			{text="Trash Can",           isSelectable=true, hasCoordbox = true, hasFacing = true},
			{text="High Stats Seeds",    isSelectable=true, hasCoordbox = true, hasFacing = true},
		    {text="Seeds To Grow",       isSelectable=true, hasCoordbox = true, hasFacing = true},
		    {text="Looted Seeds",        isSelectable=true, hasCoordbox = true, hasFacing = true},
			{text="Bank Seeds",          isSelectable=true, hasCoordbox = true, hasFacing = true},
		    {text="Return To Main Menu And Save", isSelectable=true, isReturn = true}}
})

local SetFarmlands = DynamicPage:new({
    title = "Set Farmland Coordinates",
    baseBody = {{text="Set Farmland Number", isSelectable=true, hasNumberBox = true}},
    repeatedBody = {{text="%s. Start", isSelectable=true, hasCoordbox = true},
                    {text="End"   , isSelectable=true, hasCoordbox = true}},
           -- Dynamic body
    endBody = {{text="Return To Main Menu And Save", isSelectable=true, isReturn = true}}		   
})

local SetMap = Page:new({
    title = "Scan Environement",
	body = {{text="Scan length of X axis",   isSelectable=true, hasNumberBox = true},
	        {text="Scan length of Z axis", isSelectable=true, hasNumberBox = true},
			{text="Launch Scan", isSelectable=true, isScan = true},
			{text="Return To Main Menu And Save", isSelectable=true, isReturn = true}}
})

---------------------------------
--          Fonctions          --
---------------------------------

function inputProcess(_,_,chara,keyPress,_)
    local selection
    -- Close Program --
    if chara == character.endOfText then 
        running = false
		if display.isBlinking() then
		    display.stopBlinkingCursor()
		end
    else 
        running = menu:input(chara, keyPress)
    end
end

---------------------------------
--            Main             --
---------------------------------

menu:init(mainMenu,RunMenu, SetItems,SetFarmlands,SetMap)

while(running) do
	inputProcess(event.pull("key_down"))
end

term.clear()