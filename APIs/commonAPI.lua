local component = require("component)
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
	}
}

commonAPI = {
	messages=messages,
	basicPorts=basicPorts
}

function commonAPI.reboot()
	os.execute("reboot")
end

-- Gets the used modem if there is multiple
function commonAPI.membershipReport(modem)
	modem.broadcast(basicPorts.arp.toServer, messages.SET_ADDRESS)
end