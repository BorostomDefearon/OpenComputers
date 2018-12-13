-- Include
local serialization = require("serialization")
local commonAPI = require("commonAPI")
local component = require("component")
local sides = require("sides")
local event = require("event")
local term = require("term")
local modem = component.modem

-- DATA
local DNS = "FLUID_TERMINAL"
local fluids = {}
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer,
	commonAPI.ports.fluid.requestFluidData,
	commonAPI.ports.fluid.sendFluidData,
	commonAPI.ports.fluid.getFluid
}

-- Functions
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
	print("Requesting fluid data...")
	modem.broadcast(commonAPI.ports.fluid.requestFluidData, "Requesting fluid data...")
end

function updateFluids(rawData)
	print(rawData)
	fluids = serialization.unserialize(rawData)
end

function test()

end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()

-- LOOP
while true do
	requestFluidData()
	os.sleep(5)
end