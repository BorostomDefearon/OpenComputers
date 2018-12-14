local API = {}
local button={}
 
local component = require("component")
local event = require("event")
local computer = require("computer")
local term = require("term")
local colors = require("colors")
local term = require("term")
local mon = component.gpu
local w, h = mon.getResolution()
local Green = 0x00AA00
local Red = 0xAA0000
local Black = 0x000000
local Grey = 0xDCDCDC 	
local gpu = component.gpu

local alignmentData = {
	absoluteCenter={x=w/2, y=h/2},
	center={x=w/2, y=1},
	left={x=1, y=1},
	right={x=w-10, y=1},
}

local alignment = {
	absoluteCenter="absoluteCenter",
	center="center",
	left="left",
	right="right"
}

local screenColorMatrix = {}
local screenTextMatrix = {} 
local rowControl = {}
 
buttonStatus = nil
 

function setRowData(row, height, width)
	if rowControl[row] ~= nil then
		rowControl[row] = {height = height, currentPos = width + 1}
	else
		local pos = rowControl[row].currentPos
		if rowControl[row].height < height then
			rowControl[row].height = height
		end
		rowControl[row].currentPos = pos + width + 1
	end
end 
 
 function checkxy(x, y)
  for name, data in pairs(button) do
    if y>=data["ymin"] and  y <= data["ymax"] then
      if x>=data["xmin"] and x<= data["xmax"] then
        data["func"]()
          return true
      end
    end
  end
  return false
end

function calculateCoords(height, width, row, alignment)
	local xmin, xmax, ymin, ymax = 1,1,1,1

  	ymin = row
  	ymax = ((row+height) /2)
  
  	if alignment == "left" then
  		xmin = 1
		xmax = width
		ymin = row
  		ymax = ((row+height) /2)
  	elseif justify == "right" then
  		-- TODO
  	elseif alignment == "center" then
  		xmin =alignmentData.center.x - width/2
		xmax = alignmentData.center.x + width/2 
  	elseif alignment == "absoluteCenter" then
  		xmin = alignmentData.center.x - width/2
		xmax = alignmentData.center.x + width/2 
		ymin = alignmentData.absoluteCenter.y - height/2 + row
		ymax = alignmentData.absoluteCenter.y + height/2 + row
  end
  
  return xmin, xmax, ymin, ymax
end

function API.space(h)

end

function API.getClick()
  local _, _, x, y = event.pull(1,touch)
  if x == nil or y == nil then
    local h, w = gpu.getResolution()
    gpu.set(h, w, ".")
    gpu.set(h, w, " ")
  else
    checkxy(x,y)
  end
end
 
function API.clear()
  mon.setBackground(Black)
  mon.fill(1, 1, w, h, " ")
end
 
function API.clearTable()
  button = {}
  API.clear()
end
               
function API.addButton(name, func, height, width, row, alignment)
	if height < 1 then height = 1 end
	if width < string.len(name) then width = name end
	setRowData(row, height, width)
	
  	button[name] = {}
  	button[name]["func"] = func
  	button[name]["active"] = false

  	local xmin,xmax,ymin,ymax = calculateCoords(height, width, row, alignment)
  
  	button[name]["xmin"] = xmin
  	button[name]["ymin"] = ymin
  	button[name]["xmax"] = xmax
  	button[name]["ymax"] = ymax
end
 
function API.fill(text, color, bData)
  local yspot = math.floor((bData["ymin"] + bData["ymax"]) /2)
  local xspot = math.floor((bData["xmax"] + bData["xmin"] - string.len(text)) /2)+1
  local oldColor = mon.setBackground(color)
  mon.fill(bData["xmin"], bData["ymin"], (bData["xmax"]-bData["xmin"]+1), (bData["ymax"]-bData["ymin"]+1), " ")
  mon.set(xspot, yspot, text)
  mon.setBackground(oldColor)
end
     
function API.screen()
  local currColor
  for name,data in pairs(button) do
    local on = data["active"]
    if on == true then currColor = Green else currColor = Red end
    API.fill(name, currColor, data)
  end
end
 
 
return API
 
 
 
 
 
--eof