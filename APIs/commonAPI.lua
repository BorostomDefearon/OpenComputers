local component = require("component")
local serialization = require("serialization")
local event = require("event")
-- Common messages
local messages = {
	REBOOT="reboot",
	GET_ADDRESS="get_address",
	SET_ADDRESS="set_address"
}
-- Well-known ports
local basicPorts = {
	broadcast=1, -- common broadcast port
	arp={
		toServer=2,
		fromServer=3
	},
	fluid={
		requestFluidData=100,
		sendFluidData=101,
		getFluid=102
	}
}

local APIs = {
	
}

commonAPI = {
	messages = messages,
	ports = basicPorts,
	APIs = APIs
}

--############################
-- Private functions
--############################
function handleCommands(keyboardAddress, char, code, playerName)
	event.ignore("key_down", handleCommands)
	io.write("")
	io.write(">> ")
	command = io.read()
	if command == "exit" then
		os.execute("reboot")
	end
	event.listen("key_down", handleCommands)
end
--############################
-- Public functions
--############################

-- Reboot computer
function commonAPI.reboot()
	os.execute("reboot")
end

-- Handle basic commands
function commonAPI.initCommandHandler()
	event.listen("key_down", handleCommands)
end

-- Open modem on machine's used port-list
function commonAPI.initModem(modem, port_list)
	for i, port in ipairs(port_list) do
		modem.open(port)
	end
end

-- Reports network membership on given modem and DNS
function commonAPI.membershipReport(modem, DNS)
	modem.broadcast(basicPorts.arp.toServer, DNS)
end


return commonAPI