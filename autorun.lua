local URL = "https://rew.githubusercontent.com/Defearon/OpenComputers/master"
local NAME = "main"
local DIR = "/home"
local term = require("term")
local commonAPI = "https://raw.githubusercontent.com/Defearon/OpenComputers/master/APIs/commonAPI.lua"
os.sleep(1)
term.clear()

os.execute("wget -f "..URL.." "..DIR.."/"..NAME..".lua")
term.clear()
os.execute("wget -f "..commonAPI.." /lib/commonAPI.lua")
term.clear()
os.execute(DIR.."/"..NAME..".lua")