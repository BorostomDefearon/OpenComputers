local URL = "https://rew.githubusercontent.com/Defearon/OpenComputers/master"
local NAME = ""
local DIR = "/home"
local term = require("term")
term.clear()

os.execute("wget -f "..URL.." "..DIR.."/"..NAME..".lua")
term.clear()
print("Running "..DIR.."/"..NAME..".lua...")
os.sleep(2)
term.clear()
os.execute("/home/"..NAME..".lua")