#@
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable
--Callbacks
-- #MACOS package.path =
-- #MACOS  '/opt/homebrew/Cellar/luarocks/3.11.1/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?/init.lua;/opt/homebrew/lib/lua/5.4/?.lua;/opt/homebrew/lib/lua/5.4/?/init.lua;./?.lua;./?/init.lua;/Users/lennartjasper/.luarocks/share/lua/5.4/?.lua;/Users/lennartjasper/.luarocks/share/lua/5.4/?/init.lua'
-- #MACOS local deflate = require("LibDeflate")
-- #MACOS package.path =
-- #MACOS "?.lua;?/init.lua;src/?.lua;src/?/init.lua;../runtime/lua/?.lua;../runtime/lua/sha1/init.lua;./Data/TimelessJewelData/BrutalRestraint.zip"
package.path = package.path .. ";src/?.lua;src/?/init.lua;../runtime-win32/lua/?.lua;../runtime/lua/?.lua" --;../runtime-win32/lua/sha1/init.lua;./Data/TimelessJewelData/BrutalRestraint.zip"
package.cpath = package.cpath .. ";../runtime-win32/lua/?.so;../runtime-win32/lua/?.dll;../runtime-win32/lua/?.dylib;../runtime/?.dll"
local callbackTable = {}
local mainObject

function runCallback(name, ...)
	if callbackTable[name] then
		return callbackTable[name](...)
	elseif mainObject and mainObject[name] then
		return mainObject[name](mainObject, ...)
	end
end

function SetCallback(name, func)
	callbackTable[name] = func
end

function GetCallback(name)
	return callbackTable[name]
end

function SetMainObject(obj)
	mainObject = obj
end

-- Image Handles
local imageHandleClass = {}
imageHandleClass.__index = imageHandleClass
function NewImageHandle()
	return setmetatable({}, imageHandleClass)
end

function imageHandleClass:Load(fileName, ...)
	self.valid = true
end

function imageHandleClass:Unload()
	self.valid = false
end

function imageHandleClass:IsValid()
	return self.valid
end

function imageHandleClass:SetLoadingPriority(pri) end

function imageHandleClass:ImageSize()
	return 1, 1
end

-- Rendering
function RenderInit() end

function GetScreenSize()
	return 1920, 1080
end
function GetScreenScale()
	return 1
end
function SetClearColor(r, g, b, a) end

function SetDrawLayer(layer, subLayer) end

function SetViewport(x, y, width, height) end

function SetDrawColor(r, g, b, a) end

function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end

function DrawImageQuad(imageHandle, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4) end

function DrawString(left, top, align, height, font, text) end

function DrawStringWidth(height, font, text)
	return 1
end

function DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	return 0
end

function StripEscapes(text)
	return text:gsub("%^%d", ""):gsub("%^x%x%x%x%x%x%x", "")
end

function GetAsyncCount()
	return 0
end

-- Search Handles
function NewFileSearch(path) end

-- 	return {
-- 		path = path,
-- 		currentFile = 0,
-- 		GetFileName = function(self) return self.path:gsub("*", self.currentFile) end,
-- 		GetFileModifiedTime = function() return nil end,
-- 		NextFile = function(self)
-- 			if self.currentFile < 4 then
-- 				self.currentFile = self.currentFile + 1
-- 				return self.GetFileName(self)
-- 			end
-- 		end
-- 	}
-- end

-- General Functions
function SetWindowTitle(title) end

function GetCursorPos()
	return 0, 0
end

function SetCursorPos(x, y) end

function ShowCursor(doShow) end

function IsKeyDown(keyName) end

function Copy(text) end

function Paste() end

function Deflate(data)
	-- TODO: Might need this
	return ""
end

function Inflate(data)
	-- TODO: And this
	return ""
end

function GetTime()
	return 0
end

function GetScriptPath()
	return "."
end

function GetRuntimePath()
	return "./runtime"
end

function GetUserPath()
	return ""
end

function MakeDir(path) end

function RemoveDir(path) end

function SetWorkDir(path) end

function GetWorkDir()
	return ""
end

function LaunchSubScript(scriptText, funcList, subList, ...) end

function AbortSubScript(ssID) end

function IsSubScriptRunning(ssID) end

function LoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return func(...)
	else
		error("LoadModule() error loading '" .. fileName .. "': " .. err)
	end
end

function PLoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '" .. fileName .. "': " .. err)
	end
end

function PCall(func, ...)
	local ret = { pcall(func, ...) }
	if ret[1] then
		table.remove(ret, 1)
		return nil, unpack(ret)
	else
		return ret[2]
	end
end

function ConPrintf(fmt, ...)
	-- Optional
	print(string.format(fmt, ...))
end

function ConPrintTable(tbl, noRecurse) end

function ConExecute(cmd) end

function ConClear() end

function SpawnProcess(cmdName, args) end

function OpenURL(url) end

function SetProfiling(isEnabled) end

function Restart() end

function Exit() end

local l_require = require
function require(name)
	-- Hack to stop it looking for lcurl, which we don't really need
	if name == "lcurl.safe" then
		return
	end
	return l_require(name)
end

dofile("Launch.lua")

-- Prevents loading of ModCache
-- Allows running mod parsing related tests without pushing ModCache
-- The CI env var will be true when run from github workflows but should be false for other tools using the headless wrapper
mainObject.continuousIntegrationMode = os.getenv("CI")

runCallback("OnInit")
runCallback("OnFrame") -- Need at least one frame for everything to initialise

if mainObject.promptMsg then
	-- Something went wrong during startup
	print(mainObject.promptMsg)
	io.read("*l")
	return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
local build = mainObject.main.modes["BUILD"]

-- Here's some helpful helper functions to help you get started
function newBuild()
	mainObject.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
	runCallback("OnFrame")
end

function loadBuildFromXML(xmlText, name)
	mainObject.main:SetMode("BUILD", false, name or "", xmlText)
	runCallback("OnFrame")
end

function printTables(table, depth, maxDepth)
	local pre = ""
	for i = 0, depth, 1 do
		pre = pre .. "--"
	end
	for k, v in pairs(table) do
		print(pre, k, " - ", v)
		if type(v) == "table" and depth < maxDepth then
			printTables(v, depth + 1, maxDepth)
		end
	end
end

function printTable(table)
	for k, v in pairs(table) do
		print(k, " - ", v)
	end
end

function reallyActivateAllFlasks(itemsTab)
	itemsTab.activeItemSet["Flask 1"].active = true
	itemsTab.activeItemSet["Flask 2"].active = true
	itemsTab.activeItemSet["Flask 3"].active = true
	itemsTab.activeItemSet["Flask 4"].active = true
	itemsTab.activeItemSet["Flask 5"].active = true
	for _, control in pairs(itemsTab.controls) do
		if control.label == "Flask 1" then
			control.active = true
		end
		if control.label == "Flask 2" then
			control.active = true
		end
		if control.label == "Flask 3" then
			control.active = true
		end
		if control.label == "Flask 4" then
			control.active = true
		end
		if control.label == "Flask 5" then
			control.active = true
		end
	end

	itemsTab:AddUndoState()
	itemsTab.build.buildFlag = true
	runCallback("OnFrame")
end

local function printStatsBad(build)
	local out = build.calcsTab.mainOutput
	print("Act: " .. build.Act)
	print("TotalDPS: " .. out.TotalDPS)
	print("AverageBurstDamage: " .. out.AverageBurstDamage)
	print("AverageDamage: " .. out.AverageDamage)
	print("Str: " .. out.Str)
	print("Dex: " .. out.Dex)
	print("Int: " .. out.Int)
	print("Life: " .. out.Life)
	print("LifeRegen: " .. out.LifeRegen)
	print("Mana: " .. out.Mana)
	print("ManaRegen: " .. out.ManaRegen)
	print("EnergyShield: " .. out.EnergyShield)
	print("Evasion: " .. out.Evasion)
	print("Armour: " .. out.Armour)
	print("SpellSuppressionChance: " .. out.SpellSuppressionChance)
	print("SpellSuppressionChanceOverCap: " .. out.SpellSuppressionChanceOverCap)
	print("BlockChance: " .. out.BlockChance)
	print("SpellBlockChance: " .. out.SpellBlockChance)
	print("AttackDodgeChance: " .. out.AttackDodgeChance)
	print("SpellDodgedChance: " .. out.SpellDodgedChance)
	print("StunAvoidChance: " .. out.StunAvoidChance)


	print("AccuracyHitChance: " .. out.AccuracyHitChance)
	print("CritChance: " .. out.CritChance)
	print("CritMultiplier: " .. out.CritMultiplier)
	print("MainHandSpeed", out.MainHand.Speed)

	print("TotalEHP: " .. out.TotalEHP)

	print("ChaosResist: " .. out.ChaosResist)
	print("ChaosResistOverCap: " .. out.ChaosResistOverCap)
	print("ChaosMaximumHitTaken: " .. out.ChaosMaximumHitTaken)

	print("ColdResist: " .. out.ColdResist)
	print("ColdResistOverCap: " .. out.ColdResistOverCap)
	print("ColdMaximumHitTaken: " .. out.ColdMaximumHitTaken)

	print("FireResist: " .. out.FireResist)
	print("FireResistOverCap: " .. out.FireResistOverCap)
	print("FireMaximumHitTaken: " .. out.FireMaximumHitTaken)

	print("LightningResist: " .. out.LightningResist)
	print("LightningResistOverCap: " .. out.LightningResistOverCap)
	print("LightningMaximumHitTaken: " .. out.LightningMaximumHitTaken)

	print("PhysicalDamageReduction: " .. out.PhysicalDamageReduction)
	print("PhysicalMaximumHitTaken: " .. out.PhysicalMaximumHitTaken)

	print("ChillAvoidChance: " .. out.ChillAvoidChance)
	print("FreezeAvoidChance: " .. out.FreezeAvoidChance)
	print("IgniteAvoidChance: " .. out.IgniteAvoidChance)
	print("ShockAvoidChance: " .. out.ShockAvoidChance)
	print("EnduranceChargesMax: " .. out.EnduranceChargesMax)
	print("FrenzyChargesMax: " .. out.FrenzyChargesMax)
	print("PowerChargesMax: " .. out.PowerChargesMax)

	print("MovementSpeedMod: " .. out.MovementSpeedMod)
end

-- set the output to be a printed to the console
io.output(io.stdout)


local function write(str)
	print(str)
	--io.write("\n")
	io.flush()
end
local function getS(s)
	return s or ""
end
local function getN(n)
	return n or 0
end
local function printStats(build)
	local out = build.calcsTab.mainOutput
	local stats = {
		Act = getS(build.Act),
		TotalDPS = getN(out.TotalDPS),
		AverageBurstDamage = getN(out.AverageBurstDamage),
		AverageDamage = getN(out.AverageDamage),
		Str = getN(out.Str),
		Dex = getN(out.Dex),
		Int = getN(out.Int),
		Life = getN(out.Life),
		LifeRegen = getN(out.LifeRegen),
		Mana = getN(out.Mana),
		ManaRegen = getN(out.ManaRegen),
		EnergyShield = getN(out.EnergyShield),
		Evasion = getN(out.Evasion),
		Armour = getN(out.Armour),
		SpellSuppressionChance = getN(out.SpellSuppressionChance),
		SpellSuppressionChanceOverCap = getN(out.SpellSuppressionChanceOverCap),
		BlockChance = getN(out.BlockChance),
		SpellBlockChance = getN(out.SpellBlockChance),
		AttackDodgeChance = getN(out.AttackDodgeChance),
		SpellDodgeChance = getN(out.SpellDodgeChance),
		StunAvoidChance = getN(out.StunAvoidChance),
		AccuracyHitChance = getN(out.AccuracyHitChance),
		CritChance = getN(out.CritChance),
		CritMultiplier = getN(out.CritMultiplier),
		MainHandSpeed = out.MainHand and out.MainHand.Speed or -math.huge,
		TotalEHP = getN(out.TotalEHP),
		ChaosResist = getN(out.ChaosResist),
		ChaosResistOverCap = getN(out.ChaosResistOverCap),
		ChaosMaximumHitTaken = getN(out.ChaosMaximumHitTaken),
		ColdResist = getN(out.ColdResist),
		ColdResistOverCap = getN(out.ColdResistOverCap),
		ColdMaximumHitTaken = getN(out.ColdMaximumHitTaken),
		FireResist = getN(out.FireResist),
		FireResistOverCap = getN(out.FireResistOverCap),
		FireMaximumHitTaken = getN(out.FireMaximumHitTaken),
		LightningResist = getN(out.LightningResist),
		LightningResistOverCap = getN(out.LightningResistOverCap),
		LightningMaximumHitTaken = getN(out.LightningMaximumHitTaken),
		PhysicalDamageReduction = getN(out.PhysicalDamageReduction),
		PhysicalMaximumHitTaken = getN(out.PhysicalMaximumHitTaken),
		ChillAvoidChance = getN(out.ChillAvoidChance),
		FreezeAvoidChance = getN(out.FreezeAvoidChance),
		IgniteAvoidChance = getN(out.IgniteAvoidChance),
		ShockAvoidChance = getN(out.ShockAvoidChance),
		EnduranceChargesMax = getN(out.EnduranceChargesMax),
		FrenzyChargesMax = getN(out.FrenzyChargesMax),
		PowerChargesMax = getN(out.PowerChargesMax),
		MovementSpeedMod = getN(out.MovementSpeedMod),
		PobCode = common.base64.encode(build:SaveDB("code"))
	}

	-- Manually format the stats table as a JSON-like string
	local jsonStats = "{"
	for key, value in pairs(stats) do
		if type(value) == "number" and value ~= -math.huge and value ~= math.huge then
			jsonStats = jsonStats .. string.format('"%s": %s,', key, value)
		else
			jsonStats = jsonStats .. string.format('"%s": "%s",', key, value)
		end
	end
	-- Remove the trailing comma and close the JSON object
	jsonStats = jsonStats:sub(1, -2) .. "}"

	-- Print the JSON-like string to stdout
	write(jsonStats)
end

local function loadBuildFromJSON(getItemsJSON, getPassiveSkillsJSON)
	mainObject.main:SetMode("BUILD", false, "")
	runCallback("OnFrame")
	local charData = build.importTab:ImportItemsAndSkills(getItemsJSON)
	build.importTab:ImportPassiveTreeAndJewels(getPassiveSkillsJSON, charData)
	--common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+", "-"):gsub("/", "_")
	runCallback("OnFrame")
	write("DONE_CALCULATING")
	printStats(build)
end



local itemJSON
local passiveJSON
local function processBuild()
	write("READY_TO_RECEIVE_DATA")
	itemJSON = io.read()
	passiveJSON = io.read()
	loadBuildFromJSON(itemJSON, passiveJSON)
end

while true do
	processBuild()
end
processBuild()

local open = io.open
local function read_file(path)
	local file = open(path, "rb") -- r read mode and b binary mode
	if not file then return nil end
	local content = file:read "*a" -- *a or *all reads the whole file
	file:close()
	return content
end
--loadBuildFromJSON(arg[2], arg[3])
local items = read_file("items.json")
local passives = read_file("passives.json")
loadBuildFromJSON(items, passives)




-- Assuming build:SaveDB("code") returns the XML data as a string
local xmlData = build:SaveDB("code")

-- Function to write data to an XML file
local function writeToXMLFile(data, filename)
	local file, err = io.open(filename, "w")
	if not file then
		error("Could not open file for writing: " .. err)
	end

	file:write(data)
	file:close()
end

-- Write the XML data to a file
local filename = "output.xml"
writeToXMLFile(xmlData, filename)



--print(build:SaveDB("code"))
--print(common.base64.encode(build:SaveDB("code")):gsub("+", "-"):gsub("/", "_"))
local binary = deflate.binary
local hmac = deflate.hmac
local compress = deflate.compress
local decompress = deflate.decompress
local CompressDeflate = deflate.CompressDeflate
local hmac_binary = deflate.hmac_binary
local sha1 = deflate.sha1
print(build:SaveDB("code"))
print(deflate:DecompressDeflate(deflate:CompressDeflate(build:SaveDB("code"))))

print(common.base64.encode(compressXML(build:SaveDB("code"))):gsub("+", "-"):gsub("/", "_"))
build.importTab.controls.generateCode.onClick()
runCallback("OnFrame")
local code = build.importTab.controls.generateCodeOut.buf
print(code)


-- --loadBuildFromJSON(arg[2], arg[3])
-- loadBuildFromJSON(items, passives)
-- runCallback("OnFrame")
-- local skillsTab = build.skillsTab
-- --skillsTab.
-- local calcsTab = build.calcsTab
local itemsTab = build.itemsTab
-- printStats(calcsTab)
-- itemsTab:AddUndoState()
-- itemsTab.build.buildFlag = true
-- runCallback("OnFrame")
-- printStats(calcsTab)

-- printStats(calcsTab)
-- for _, control in pairs(skillsTab.controls) do
-- 	if control.label == "Main Skill" then
-- 		control.selIndex = 1
-- 		control.selValue = 1
-- 		control:SelSkill()
-- 	end
-- end
local configTab = build.configTab
local treeTab = build.treeTab
local importTab = build.importTab
local version = build.version
local main = build.main
local mainSocketGroup = build.mainSocketGroup
local mainSocketGroupList = build.mainSocketGroupList
local mainSocketGroupLabel = build.mainSocketGroupLabel
--
