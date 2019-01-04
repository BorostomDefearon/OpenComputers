-- IMPORTS
local commonAPI = require("commonAPI")
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local component = require("component")
local modem = component.modem
local gpu = component.gpu

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
local energy_cell =  "tile_thermalexpansion_cell_resonant_name"  
local max_energy = 0
local curr_energy = 0
local delta = 0
local refreshFreq = 1

-- DATA
local DNS = commonAPI.DNS.ENERGY_HANDLER
local energyCells = {}
local status = "ENABLED"
-- FUNCTIONS

-- Initializes the thermal_expansion_cell-s
function setEnergyCells()
	energyCells = {}
	for address in component.list(energy_cell) do
		local proxy = component.proxy(address)
		table.insert(energyCells, proxy)
	end
end

-- Updates energy data
function updateEnergyData()
	setEnergyCells()
	max_energy = 0
	local prev_energy_level = curr_energy
	curr_energy = 0
	
	for i,cell in ipairs(energyCells) do
		max_energy = max_energy + cell.getMaxEnergyStored()
		curr_energy = curr_energy + cell.getEnergyStored()
	end
	delta = curr_energy - prev_energy_level
end

-- Disable energy providing
function disableEnergy()
	for i,cell in ipairs(energyCells) do
		cell.setControlSetting("HIGH")
	end
	status = "DISABLED"
  return true
end

-- Enable energy providing
function enableEnergy()
	for i,cell in ipairs(energyCells) do
		cell.setControlSetting("DISABLED")
	end
	status = "ENABLED"
  return true
end

-- Handles energy start or stop event
function handleStartStopRequest(message, senderAddress)
	local success = false
  local msgType = commonAPI.messages.ERROR
  local msgText = "Operation failed!"
  
	if message == "STOP" then
		success = disableEnergy()
	elseif message == "START" then
		success = enableEnergy()
	else return end
  
  if success then msgType = commonAPI.messages.SUCCESS msgText = "Operation succeed!" end
  modem.send(senderAddress, commonAPI.ports.energy.message, serialization.serialize({messageType=msgType, text=msgText}))
end

-- Sends back energy data
function sendEnergyData(senderAddress)
	modem.send(senderAddress, commonAPI.ports.energy.sendEnergyData, serialization.serialize({MaxEnergy=max_energy, CurrEnergy=curr_energy, Delta=delta, Status=status}))
end

-- Prints the screen, for testing issues
function redraw()
	term.clear()
	print("########## Energy stored ##########")
	print("-----------------------------------")
	print (curr_energy, "/",max_energy.." RF")
	print("")
	print("Delta: ", delta.." RF/s [Approx. "..tostring(delta / 20).."RF/t]")
	print("Status: ", status)
end

-- Handles modem message
function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		-- Reply to ARP server
		if onPort == commonAPI.ports.arp.fromServer then
			commonAPI.membershipReport(modem, DNS)
			ARPaddress = senderAddress
		-- Energy data request from terminal
		elseif onPort == commonAPI.ports.energy.requestEnergyData then
			sendEnergyData(senderAddress)
		-- Start or stop the energy
		elseif onPort == commonAPI.ports.energy.stopStartEnergy then
			handleStartStopRequest(message, senderAddress)
		end
end

-- INIT
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()
event.timer(refreshFreq, updateEnergyData, math.huge)
gpu.setResolution(80, 25)

while true do
	commonAPI.redrawScreen(redraw)
	os.sleep(1)
end