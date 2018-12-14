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

local buttons = {}

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
	--[[
	buttonAPI.addButton(" CURR ", test, 2, "center", buttonAPI.colors.passive)
	buttonAPI.addButton(" NEXT ", test, 2, "right", buttonAPI.colors.clickable)
	buttonAPI.addButton(" PREV ", test, 2, "left", buttonAPI.colors.passive)
	--]]
	if buttons.prev and buttons.curr and buttons.nxt then
		--[[
		buttonAPI.addButtonImplicit(buttons.prev, test, 1,1, 10, 10, buttonAPI.colors.passive)
		buttonAPI.addButtonImplicit(buttons.curr, test, 1, 11, 10, 10,  buttonAPI.colors.clickable)
		buttonAPI.addButtonImplicit(buttons.next, test, 1, 22, 10, 10,  buttonAPI.colors.passive)
		print(buttons.prev,buttons.curr,buttons.nxt)
		--]]
		buttonAPI.addButton(buttons.prev, prevFluid, 2, "left", buttonAPI.colors.grey)
		buttonAPI.addButton(buttons.curr, requestFluid, 2, "center", buttonAPI.colors.red)
		buttonAPI.addButton(buttons.nxt, nextFluid, 2, "right", buttonAPI.colors.grey)
	end
	
	buttonAPI.addButton(" >> ",nextFluid, 3, "center")
	buttonAPI.heading("Choose the fluid you want to request! Use <- and -> keys to navigate!")
	buttonAPI.label(1,24,"Version: beta")
	buttonAPI.screen()
end

function requestFluid()
	print(fluidKeys[buttons.curr])	
end

function prevFluid()
	selectedFluid = selectedFluid - 1
	drawButtons()
end

function nextFluid()
	selectedFluid = selectedFluid + 1
	drawButtons()
end


function drawButtons()
	buttons = {}
	--if selectedFluid == nil or selectedFluid < 1 or fluidNames[selectedFluid] == nil then selectedFluid = 1 end
	if selectedFluid == nil or fluidNames[selectedFluid] == nil then selectedFluid = 1 end
	if selectedFluid < 1 then selectedFluid = sizeOf(fluidNames) end
	-- Current
	buttons.curr = fluidNames[selectedFluid][2]
	-- Prev
	if fluidNames[selectedFluid-1] == nil then
		buttons.prev = " "
	else
		buttons.prev = fluidNames[selectedFluid-1][2] 
	end
	-- Next
	if fluidNames[selectedFluid+1] == nil then
		buttons.nxt = " "
	else
		buttons.nxt = fluidNames[selectedFluid+1][2] 
	end
	
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
	fluidNames = {}
	local tmp = serialization.unserialize(rawData)
	for i, fluid in ipairs(tmp) do
		table.insert(fluids, fluid.data)
		table.insert(fluidNames, {fluid.data.name, fluid.data.label})
		fluidKeys[fluid.data.label] = fluid.data.name
	end
	
	table.sort(fluidNames, function (left, right)
    		return left[2] < right[2]
	end )
	print(serialization.serialize(fluidNames))
	if fluidNames ~= nil then drawButtons() end
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