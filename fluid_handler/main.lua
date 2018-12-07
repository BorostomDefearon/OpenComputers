-- Include
local ser = require("serialization")
local component = require("component")
local modem = component.modem

-- DATA
local transposers = {}

-- Functions
function setTransposers()
	for address in component.list("transposer") do
		local proxy = component.proxy(address)
		table.insert(transposers, proxy)
	end
end

-- TEST
print(transposers[1].transferFluid(sides.top, sides.bottom))