-- TODO: two tanks containing similar liquid! --> server side!
-- Include
local serialization = require("serialization")
local buttonAPI = require("buttonAPI")
local commonAPI = require("commonAPI")
local component = require("component")
local sides = require("sides")
local event = require("event")
local term = require("term")
local modem = component.modem

-- DATA
local DNS = "FLUID_TERMINAL"
local fluids = {}
local fluidNames = {}
local fluidKeys = {}
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer,
	commonAPI.ports.fluid.requestFluidData,
	commonAPI.ports.fluid.sendFluidData,
	commonAPI.ports.fluid.getFluid
}

local serverMessage = "TODO: Server message!"
local buttons = {}
local toOrder = 1
local dimension = "B"
local selectedFluidIndex = nil
local minValue = 1
local maxValue = 1

-- Functions
function sizeOf(array)
	local cnt = 0
	for i,v in ipairs(array) do
		cnt = cnt + 1
	end
	return cnt
end

function GUI()
	buttonAPI.clearTable()
	buttonAPI.addButton(" << ", prevFluid, 1, "center")
	
	if buttons.prev and buttons.curr and buttons.nxt then
		local selectedFluidData = fluids[selectedFluidIndex]
		setValues(selectedFluidData)
		
		-- Main buttons
		buttonAPI.addButton(buttons.prev, prevFluid, 2, "left", buttonAPI.colors.grey)
		buttonAPI.addButton(buttons.curr, requestFluid, 2, "center", buttonAPI.colors.red)
		buttonAPI.addButton(buttons.nxt, nextFluid, 2, "right", buttonAPI.colors.grey)
		-- Dimension changer
		buttonAPI.addButtonImplicit("B/mB", changeDimension, 38, 22, 4, 1, buttonAPI.colors.red)
		-- Increase, decrease
		buttonAPI.addButtonImplicit("-",  decrease, 32, 20, 1, 1, buttonAPI.colors.red)
		buttonAPI.addButtonImplicit("+",  increase, 47, 20, 1, 1, buttonAPI.colors.red)
		-- toOrder
		buttonAPI.addButtonImplicit(tostring(toOrder)..dimension,  handEdit, 36, 20, 8, 1, buttonAPI.colors.grey)
		
		-- Switch dimension
		if dimension == "B" then
			buttonAPI.label(1,21, "Available: "..math.floor(selectedFluidData.amount/1000).."B of "..math.floor(selectedFluidData.capacity/1000).."B.")
		elseif dimension == "mB" then
			buttonAPI.label(1,21, "Available: "..selectedFluidData.amount.."mB of "..selectedFluidData.capacity.."mB.")
		end
		
		-- OK btn
		buttonAPI.addButtonImplicit("OK", requestFluid, 38, 24, 4, 1, buttonAPI.colors.green)
	end
	
	buttonAPI.addButton(" >> ",nextFluid, 3, "center")
	
	buttonAPI.heading("Choose the fluid you want to request! Use <- and -> keys to navigate!")
	
	
	buttonAPI.label(1,22, serverMessage)
	buttonAPI.screen()
end

function setValues(selectedFluid)
	if dimension=="B" then
		maxValue = math.floor(selectedFluid.amount/1000)
	else
		maxValue = selectedFluid.amount
	end
end

function handEdit()
	term.setCursor(1, 23)
	io.write(">> ")
	local input = io.read()
	if tonumber(input) then
		if tonumber(input) >= minValue and tonumber(input) <= maxValue then
			toOrder = tonumber(input)
		end
	end
	GUI()
end

function changeDimension()
	if dimension == "B" then
		dimension = "mB"
	else
		dimension = "B"
	end
	GUI()
end

function increase()
	if toOrder+1 <= maxValue then
		toOrder = toOrder + 1
		GUI()
	end
end

function decrease()
	if toOrder > 1 then
		toOrder = toOrder - 1
		GUI()
	end
end

function requestFluid()
		
end

function prevFluid()
	selectedFluidIndex = selectedFluidIndex - 1
	toOrder = 1
	dimension = "B"
	drawButtons()
end

function nextFluid()
	selectedFluidIndex = selectedFluidIndex + 1
	toOrder = 1
	dimension = "B"
	drawButtons()
end

function drawButtons()
	buttons = {}
	--if selectedFluidIndex == nil or selectedFluidIndex < 1 or fluidNames[selectedFluidIndex] == nil then selectedFluidIndex = 1 end
	if selectedFluidIndex == nil or fluids[selectedFluidIndex] == nil then selectedFluidIndex = 1 end
	if selectedFluidIndex < 1 then selectedFluidIndex = sizeOf(fluids) end
	-- Current
	buttons.curr = fluids[selectedFluidIndex].label
	-- Prev
	if fluids[selectedFluidIndex-1] == nil then
		buttons.prev = " "
	else
		buttons.prev = fluids[selectedFluidIndex-1].label
	end
	-- Next
	if fluids[selectedFluidIndex+1] == nil then
		buttons.nxt = " "
	else
		buttons.nxt = fluids[selectedFluidIndex+1].label
	end
	--print(buttons.prev, buttons.curr, buttons.nxt)
	GUI()
end

function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		-- Reply to ARP server
		if onPort == commonAPI.ports.arp.fromServer then
			commonAPI.membershipReport(modem, DNS)
		-- Reply to Fluid terminal
		elseif onPort == commonAPI.ports.fluid.sendFluidData then
			updateFluids(message)
		end 
end

function requestFluidData()
	modem.broadcast(commonAPI.ports.fluid.requestFluidData, "Requesting fluid data...")
end

function updateFluids(rawData)
	fluids = {}
	local tmp = serialization.unserialize(rawData)
	for i, fluid in ipairs(tmp) do
		table.insert(fluids, fluid.data)
	end
	
	table.sort(fluids, function (left, right)
    		return left.label < right.label
	end )
	
	if fluids ~= nil then drawButtons() end
end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
event.timer(5, requestFluidData, math.huge)
commonAPI.initCommandHandler()
buttonAPI.setResolution(80, 25)
GUI()

-- LOOP
while true do
	buttonAPI.getClick()
end