-- Include
local serialization = require("serialization")
local commonAPI = require("commonAPI")
local component = require("component")
local sides = require("sides")
local event = require("event")
local term = require("term")
local modem = component.modem
-- Constants
local fluidSides = {sides.top, sides.left, sides.right}
local outputSide = sides.bottom

-- DATA
local DNS = "FLUID_HANDLER"
local transposers = {}
local fluids = {}
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer,
	commonAPI.ports.fluid.requestFluidData,
	commonAPI.ports.fluid.sendFluidData,
	commonAPI.ports.fluid.getFluid
}

-- Functions
function setTransposers()
	transposers={}
	for address in component.list("transposer") do
		local proxy = component.proxy(address)
		table.insert(transposers, proxy)
	end
end

function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		-- Reply to ARP server
		if onPort == commonAPI.ports.arp.fromServer then
			commonAPI.membershipReport(modem, DNS)
		-- Reply to Fluid terminal
		elseif onPort == commonAPI.ports.fluid.requestFluidData then
			sendFluidData(senderAddress)
		end 
end

function sendFluidData(address)
	print("Sending fluidData to "..address..".")
	local fluidData =  serialization.serialize(fluids)
	modem.send(address, commonAPI.ports.fluid.sendFluidData, fluidData)
end

function updateFluids()
	fluids={}
	for i,transposer in ipairs(transposers) do
		for j,side in ipairs(fluidSides) do
			local fluid = transposer.getFluidInTank(side)[1]
			if  fluid ~= nil then
				table.insert(fluids, {data=fluid, transposer=i, side=side})
			end
		end
	end
end

function test()
	for i,fluid in ipairs(fluids) do
		print(fluid.data.label.." : "..sides[fluid.side].." side of transposer number"..fluid.transposer..".")
	end
end
-- INIT
--print(transposers[1].transferFluid(sides.top, sides.bottom))
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()

-- LOOP
while true do
	term.clear()
	setTransposers()
	updateFluids()
	test()
	os.sleep(5)
end