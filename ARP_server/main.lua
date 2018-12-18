-- IMPORTS
local commonAPI = require("commonAPI")
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local component = require("component")
local modem = component.modem
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer,
	commonAPI.ports.arp.askAddress,
	commonAPI.ports.arp.sendAddress,
	commonAPI.ports.arp.noAddressError
}

-- DATA
local tRoute = {}

-- FUNCTIONS
function drawTable()
	term.clear()
	print("########## Routing Table ##########")
	print("-----------------------------------")
	for dns,address in pairs(tRoute) do
	        print("| "..dns,"|",address.." |")
	end
end

-- sends ARP message to computers
function sendARP()
	tRoute={}
	modem.broadcast(commonAPI.ports.arp.fromServer, commonAPI.messages.GET_ADDRESS)
end

-- Sets routing table
function setRoutingTable(dns, address)
	tRoute[dns] = address
end

-- Sends back requested machine's data
function sendRequestedAddress(to, reqDNS)
	local reqAddress = tRoute[reqDNS]
	if not reqAddress then
		modem.send(to, commonAPI.ports.arp.noAddressError, "ERROR! No address found for "..reqDNS..".")
	else
		modem.send(to, commonAPI.ports.arp.sendAddress, reqAddress)
	end
end

-- Handles incoming modem messages
function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		if onPort == commonAPI.ports.arp.toServer then
			setRoutingTable(message, senderAddress)
			drawTable()
		elseif onPort == commonAPI.ports.arp.askAddress then
			sendRequestedAddress(senderAddress, message)
		end 
end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()
event.timer(30, sendARP, math.huge)

while true do
	drawTable()
	os.sleep(5)
end