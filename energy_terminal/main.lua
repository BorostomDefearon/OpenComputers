-- IMPORTS
local commonAPI = require("commonAPI")
local buttonAPI = require("buttonAPI")
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
	commonAPI.ports.arp.noAddressError,
	commonAPI.ports.energy.requestEnergyData,
	commonAPI.ports.energy.sendEnergyData,
	commonAPI.ports.energy.stopStartEnergy,
	commonAPI.ports.energy.message
}

-- CONSTANTS
local refreshFreq = 3
local delta = 0
local ARPaddress

-- DATA
local DNS = commonAPI.DNS.ENERGY_TERMINAL
local energyCells = {}
local max_energy = "No data..."
local curr_energy = "No data..."
local status = "No data..."
local delta = 0


-- FUNCTIONS

-- Draws GUI
function GUI()
  term.clear()
	buttonAPI.clearTable()
	if status == "DISABLED" then
    buttonAPI.addButtonImplicit("Enable ", enableEnergy, 36, 10, 7, 3, buttonAPI.colors.green)
	elseif status == "ENABLED" then
    buttonAPI.addButtonImplicit("Disable", disableEnergy, 36, 10, 7, 3, buttonAPI.colors.red)
	end
	buttonAPI.screen()
end

-- Prints the screen
function redraw()
  GUI()
  term.setCursor(1,1)
	print("########## Energy stored ##########")
	print("-----------------------------------")
	print (curr_energy, "/",max_energy.." RF")
	print("")
	print("Delta: ", delta.." RF/s [Approx. "..tostring(delta / 20).."RF/t]")
	print("Status: ", status)
end

-- Request energy data from energy server
function requestEnergyData()
	local energyHandlerAddress =  commonAPI.requestAddress(ARPaddress, commonAPI.DNS.ENERGY_HANDLER)
	if energyHandlerAddress then 
		modem.send(energyHandlerAddress, commonAPI.ports.energy.requestEnergyData, "test")
	end
end

-- Handles energy data
function handleEnergyData(message)	
	local tMessage = serialization.unserialize(message)
	max_energy = tMessage.MaxEnergy
	curr_energy = tMessage.CurrEnergy
	status = tMessage.Status
	delta = tMessage.Delta
end

-- Disable energy providing
function disableEnergy()
  local energyHandlerAddress =  commonAPI.requestAddress(ARPaddress, commonAPI.DNS.ENERGY_HANDLER)
	if energyHandlerAddress then 
		modem.send(energyHandlerAddress, commonAPI.ports.energy.stopStartEnergy, "STOP")
	end
end

-- Enable energy providing
function enableEnergy()
	local energyHandlerAddress =  commonAPI.requestAddress(ARPaddress, commonAPI.DNS.ENERGY_HANDLER)
	if energyHandlerAddress then 
		modem.send(energyHandlerAddress, commonAPI.ports.energy.stopStartEnergy, "START")
	end
end

-- Handles message from handler
function handleMessage(message)
  local tMessage = serialization.unserialize(message)
  if tMessage.messageType == commonAPI.messages.SUCCESS then 
    commonAPI.writeSuccess(tMessage.text)
  elseif tMessage.messageType == commonAPI.messages.ERROR then 
    commonAPI.writeError(tMessage.text)
  end
end

-- Handles modem message
function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		-- Reply to ARP server
		if onPort == commonAPI.ports.arp.fromServer then
			commonAPI.membershipReport(modem, DNS)
			ARPaddress = senderAddress
		-- Got energy data from handler
		elseif onPort == commonAPI.ports.energy.sendEnergyData then
			handleEnergyData(message)	
    -- Got reply from handler
    elseif onPort == commonAPI.ports.energy.message then
      handleMessage(message)
		end
		
end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()
event.timer(refreshFreq, requestEnergyData, math.huge)
buttonAPI.setResolution(80, 25)

while true do
  buttonAPI.getClick()
	commonAPI.redrawScreen(redraw)
	--os.sleep(refreshFreq)
end