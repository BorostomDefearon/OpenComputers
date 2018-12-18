local component = require("component")
local serialization = require("serialization")
local keyboard=require("keyboard")
local event = require("event")
local term = require("term")

local modem = component.modem
local gpu = component.gpu
local showMessageAmount = 5

local colors = {
	cError=0xFF0000, 
	cNormal= 0xFFFFFF,
	cSuccess=0x00FF00,
	cWarning=0xFFA500
}

local commandButton = "199"

-- Common messageTypes for error handling
local messages = {
	ERROR="ERROR",
	SUCCESS="SUCCESS",
	WARNING="WARNING"
}
-- DNS names
local DNS = {
	FLUID_HANDLER="FLUID_HANDLER",
	FLUID_TERMINAL="FLUID_TERMINAL"
}

-- Well-known ports
local basicPorts = {
	broadcast=1, -- common broadcast port
	arp={
		toServer=2,
		fromServer=3,
		askAddress=4,
		sendAddress=5,
		noAddressError=6
	},
	fluid={
		requestFluidData=100,
		sendFluidData=101,
		getFluid=102,
		message=103
	}
}

commonAPI = {
	messages = messages,
	ports = basicPorts,
	APIs = APIs,
	DNS = DNS
}

--############################
-- Private functions
--############################
function updateAPI()
	  commonAPI.writeError("TEST")
end

function handleCommands(event, address, char, code)
	if tostring(code) == commandButton then
		local w, h = gpu.getResolution()
		term.setCursor(1, h)
		command = io.read()
		if command == "exit" then
			os.execute("reboot")
		elseif command == "update" then
			updateAPI()
		end
	end
end

-- Filtered listening to arp server reply
function ARPReplyFilter(eventType, receiverAddress, senderAddress, port, distance, message)
  if eventType ~= "modem_message" then
    return false
  end
  if port == basicPorts.arp.sendAddress or  port == basicPorts.arp.noAddressError then
  	return true
  end
  return false
end

--############################
-- Public functions
--############################

-- Request specific address from ARP
function commonAPI.requestAddress(ARPaddress, DNS)
	if not ARPaddress then
		 commonAPI.writeError("Unknown ARP address!")
		return nil
	end
	modem.send(ARPaddress, basicPorts.arp.askAddress, DNS)
	local e = {event.pullFiltered(10,ARPReplyFilter)}
	if e[4] == basicPorts.arp.noAddressError then
		 commonAPI.writeError(e[6])
		return nil
	end
	return e[6]
end

-- Writes error message
function commonAPI.writeError(errorMsg)
		local w, h = gpu.getResolution()
		
		term.setCursor(1, h)
		gpu.setForeground(colors.cError)
		print("[ERROR] "..errorMsg)
		gpu.setForeground(colors.cNormal)
end

-- Writes success message
function commonAPI.writeSuccess(successMsg)
		local w, h = gpu.getResolution()
		
		term.setCursor(1, h)
		gpu.setForeground(colors.cSuccess)
		print("[SUCCESS] "..successMsg)
		gpu.setForeground(colors.cNormal)
end

-- Writes warning message
function commonAPI.writeWarning(warningMsg)
		local w, h = gpu.getResolution()
		
		term.setCursor(1, h)
		gpu.setForeground(colors.cWarning)
		print("[WARNING] "..warningMsg)
		gpu.setForeground(colors.cNormal)
end

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