-- IMPORTS
local commonAPI = require("commonAPI")
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local component = require("component")
local modem = component.modem
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer
}

-- DATA
local tRoute = {}

-- FUNCTIONS
function drawTable()
	print("########## Routing Table ##########")
	print("----------------------------------------------------")
	for i,row in ipairs(tRoute) do
	        print("| "..row.dns,"|",row.address.." |")
	end
end

-- sends ARP message to computers
function sendARP()
	tRoute={}
	modem.broadcast(commonAPI.ports.arp.fromServer, commonAPI.messages.GET_ADDRESS)
end

function setRoutingTable(dns, address)
	for i,row in ipairs(tRoute) do
		if row.dns == dns or row.address == address then
			return
		end
	end
	table.insert(tRoute, {dns=dns, address=address})
end

function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		if onPort == commonAPI.ports.arp.toServer then
			setRoutingTable(message, senderAddress)
		end 
end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()
event.timer(30, sendARP, math.huge)

while true do
	term.clear()
	drawTable()
	os.sleep(5)
end