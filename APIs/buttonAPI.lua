local API = {}
local button={}
 
local component = require("component")
local serialization = require("serialization")
local event = require("event")
local computer = require("computer")
local term = require("term")
local colors = require("colors")
local term = require("term")
local mon = component.gpu
local w, h = mon.getResolution()
local gpu = component.gpu

local buttonHeight = 5

local bColors = {
	green = 0x00AA00,
	red = 0xAA0000,
	black = 0x000000,
	grey = 0x808080 ,
	clickable= 0xAA0000,
	active= 0x00AA00,
	passive= 0xDCDCDC,	
}

local tAlignment = {
	center="center",
	left="left",
	right="right"
}

 function checkxy(x, y)
 	x = tonumber(x)
 	y = tonumber(y)
	if x and y then
	 	for name, data in pairs(button) do
		    	if y >= tonumber(data["y"]) and  y <= tonumber(data["y"]) + tonumber(data["height"]) then
		      	if x >= tonumber(data["x"]) and x <= tonumber(data["x"]) + tonumber(data["width"]) then
		        		data["func"]()
		          	return name
		      	end
		    	end
		end
	end
 	return nil
end

function flash(name)
	local originalColor = button[name]["color"]
  	API.changeColor(name, bColors.black)
  	os.sleep(0.1)
  	API.changeColor(name, originalColor)
  	API.screen()
end

function calculateCoords(strlen, row, alignment)
	local x, y, width, height = 1,1,1,1
	if row == 1 then y = row + 1 else y = ((row-1) * buttonHeight + row + 1) end
  	height = buttonHeight
  
  	if alignment ==tAlignment.left then
  		x = 2
		width = strlen
  	elseif alignment == tAlignment.right then
		x = w - 1 - strlen
		width = strlen
  	elseif alignment == tAlignment.center then
  		x = w/2 - strlen/2
		width = strlen 
  end
  
  return x, y, width, height
end


function API.changeColor(name, color)
  button[name]["color"] = color
  API.screen()
end   

function API.space(h)

end

function API.setButtonHeight(height)
	buttonHeight = height
end

function API.setResolution(width, height)
	w = width
	h = height
	gpu.setResolution(width, height)
end

function API.getClick()
  local _, _, x, y = event.pull(1,touch)
  if x == nil or y == nil then
    local h, w = gpu.getResolution()
    gpu.set(h, w, ".")
    gpu.set(h, w, " ")
  else
  	local name = checkxy(x,y)
    if name ~= nil then flash(name) end
  end
end
 
function API.clear()
  mon.setBackground(bColors.black)
  mon.fill(1, 1, w, h, " ")
end
 
function API.clearTable()
  button = {}
  API.clear()
end
               
function API.addButton(name, func, row, alignment, color)
	if color == nil then color = bColors.clickable end
  	button[name] = {}
	button[name]["name"] = name
  	button[name]["func"] = func

  	local x, y, width, height = calculateCoords(string.len(name), row, alignment)
  
  	button[name]["x"] = x
  	button[name]["y"] = y
  	button[name]["width"] = width
  	button[name]["height"] = height
	button[name]["color"] = color
end

function API.addButtonImplicit(name, func, x, y, width, height, color)
	button[name] = {}
	button[name]["name"] = name
  	button[name]["func"] = func
	button[name]["x"] = x
  	button[name]["y"] = y
  	button[name]["width"] = width
  	button[name]["height"] = height
	button[name]["color"] = color
end

function API.fill(text, color, bData)
  local ytext = (bData["y"] + (bData["y"] + bData["height"])) /2 
  local xtext = (bData["x"] + (bData["x"] + bData["width"])) /2 - string.len(text)/2 + 1
  local oldColor = mon.setBackground(color)
  mon.fill(bData["x"], bData["y"], bData["width"] + 2, bData["height"]," ")
  mon.set(xtext, ytext, text)
  mon.setBackground(oldColor)
end
     
function API.screen()
  for name,data in pairs(button) do
   local currColor = data["color"]
    API.fill(name, currColor, data)
  end
end
     
function API.heading(text)
  w, h = mon.getResolution()
  term.setCursor((w - string.len(text))/2+1, 1)
  term.write(text)
end
     
function API.label(w, h, text)
  term.setCursor(w, h)
  term.write(text)
end

API.colors = bColors
 
return API