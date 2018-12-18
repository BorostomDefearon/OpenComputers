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
local fluidToKeep = 1000 --mB

-- Addresses
local addresses = {
	ARPaddress = nil
}

-- DATA
local DNS = commonAPI.DNS.FLUID_HANDLER
local transposers = {}
local fluids = {}
local ports = {
	commonAPI.ports.arp.toServer,
	commonAPI.ports.arp.fromServer,
	commonAPI.ports.fluid.requestFluidData,
	commonAPI.ports.fluid.sendFluidData,
	commonAPI.ports.fluid.getFluid,
	commonAPI.ports.fluid.message
}

-- Initializes the transposers
function setTransposers()
	transposers={}
	for address in component.list("transposer") do
		local proxy = component.proxy(address)
		table.insert(transposers, proxy)
	end
end

function transpose(transposer, side, reqQuantity)
	return transposer.transferFluid(side, outputSide, reqQuantity)
end

function message(address, msgType, msgText)
	modem.send(address, commonAPI.ports.fluid.message, serialization.serialize({messageType=msgType, text=msgText}))
	print(msg)
end


-- Serves the request
function serveFluids(array, address)
	local reqFluid = array.name
	local reqQuantity = array.quantity
	local fluid = fluids[reqFluid]
	-- If fluid available
	if fluid ~= nil then
		local transposer = transposers[fluid.transposer]
		local side = fluid.side
		local fluidData = fluid.data
		local multiple = fluid.multiple
		-- If amount available
		if (fluidData.amount - fluidToKeep) > reqQuantity then
		
			-- [EMPTY BUFFER]
			if transposer.getTankLevel(outputSide) == 0 then
				-- [SINGLE STORED]
				if not multiple then 
					if transpose(transposer, side, reqQuantity) then message(address, commonAPI.messages.SUCCESS, "Succeed!")
					else message(address, commonAPI.messages.ERROR, "Something went wrong... Please check me!") end
				-- [MULTIPLE STORED]
				else
					if transpose(transposer, side, reqQuantity) then message(address, commonAPI.messages.WARNING, "Succeed, but fluid stored in multiple tanks!")
					else message(address, commonAPI.messages.ERROR, "Could not satisfy request! Fluid stored in multiple tanks. Please check it!") end
				end
			-- [SAME FLUID IN BUFFER]	
			elseif transposer.getFluidInTank(outputSide) [1].name == fluidData.name then
				-- [SINGLE STORED]
				if not multiple then 
					if transpose(transposer, side, reqQuantity) then message(address, commonAPI.messages.WARNING, "Succeed, but previous request's quantity was not consumed yet!")
					else message(address, commonAPI.messages.ERROR, "Something went wrong... Previous request's quantity was not consumed yet! Maybe buffer is full!") end
				-- [MULTIPLE STORED]
				else
					if transpose(transposer, side, reqQuantity) then message(address, commonAPI.messages.WARNING, "Succeed, but fluid stored in multiple tanks! Buffer also contained previous request's quantity!")
					else message(address, commonAPI.messages.ERROR, "Could not satisfy request! Fluid stored in multiple tanks. Buffer contained previous request's quantity!") end
				end
			--  [ERROR BUFFER]
			else message(address, commonAPI.messages.ERROR, "The buffer already contains something else!") end
		-- If there is not enough fluid
		else message(address, commonAPI.messages.ERROR, "Not enough fluid!") end
	-- If there is no such fluid
	else message(address, commonAPI.messages.ERROR, "No such fluid!") end
	
	updateFluids()
end

-- Handles modem message
function handleModemMessage(eventType, myAddress, senderAddress, onPort, fromDistance, message)
		-- Reply to ARP server
		if onPort == commonAPI.ports.arp.fromServer then
			commonAPI.membershipReport(modem, DNS)
			ARPaddress = senderAddress
		-- Reply to Fluid terminal
		elseif onPort == commonAPI.ports.fluid.requestFluidData then
			sendFluidData(senderAddress)
		elseif onPort == commonAPI.ports.fluid.getFluid then
			serveFluids(serialization.unserialize(message),senderAddress)
		end 
end

-- Sends fluid data to fluid terminal
function sendFluidData(address)
	local fluidData =  {}
	for name, row in pairs(fluids) do
		table.insert(fluidData, row.data)
	end
	modem.send(address, commonAPI.ports.fluid.sendFluidData, serialization.serialize(fluidData))
end

-- Updates fluid array
function updateFluids()
	fluids={}
	for i,transposer in ipairs(transposers) do
		for j,side in ipairs(fluidSides) do
			local fluid = transposer.getFluidInTank(side)[1]
			if  fluid.label ~= nil then 
				--[ORIGINAL CODE] table.insert(fluids, {data=fluid, transposer=i, side=side})
				if fluids[fluid.name] == nil then
					fluids[fluid.name] = {data=fluid, transposer=i, side=side, multiple=false}
				else
					-- Sums the amounts and capacities
					local fluidInTank = fluids[fluid.name]
					local tData = {
						amount=fluidInTank.data.amount + fluid.amount,
						capacity=fluidInTank.data.capacity + fluid.capacity,
						hasTag=fluid.hasTag,
						label=fluid.label,
						name=fluid.name
					}
					-- Sets the transposer and side for the tank that has larger amount in it
					local newTransposer, newSide = nil
					if fluidInTank.data.amount > fluid.amount then
						newTransposer = fluidInTank.transposer
						newSide = fluidInTank.side
					else
						newTransposer = i
						newSide = side
					end
					fluids[fluid.name] = {data=tData, transposer=newTransposer, side=newSide, multiple=true}
				end
			end
		end
	end
end

-- INIT
--print(transposers[1].transferFluid(sides.top, sides.bottom))
commonAPI.initModem(modem, ports)
event.listen("modem_message", handleModemMessage)
commonAPI.initCommandHandler()



function test()
	for key, row in pairs(fluids) do
		print("FLUID: "..row.data.label, "TRANSPOSER: "..row.transposer, "SIDE: "..row.side, "AMOUNT:"..row.data.amount)
	end
end


-- LOOP
while true do
	term.clear()
	setTransposers()
	updateFluids()
	os.sleep(30)
end