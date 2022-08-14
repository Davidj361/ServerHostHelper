local SHH = {}
local modName = '[ServerHostHelper]'
local hello = "Starting up!"
local Log = function (message)
	print(modName .. " " .. message)
end

-- local function mod.ToggleGUI()
-- 	mod.GUIOpen = not mod.GUIOpen
--
--     if mod.GUIOpen then
--         mod.ShowGUI()
--     else
--         mod.HideGUI()
--     end
-- end


if CLIENT then

	if mod.cl == nil then
		mod.cl = {}
	else
		return
	end

	Log("[Client] "..hello)
	LuaUserData.RegisterType("Barotrauma.GameMain")
	local GameMain = LuaUserData.CreateStatic("Barotrauma.GameMain")

	Hook.Add("think", "logWindowHotkey", function()
		if GUI.GUI.KeyboardDispatcher.Subscriber ~= nil then return end -- Avoid executing with chat focused
		if PlayerInput.KeyHit(Keys.Z) then
			GameMain.Client.ShowLogButton.OnClicked.Invoke()
		end
	end)


elseif SERVER then

	if mod.sv == nil then
		mod.sv = {}
	else
		return
	end

	Log("[Server] "..hello)
	local counter = 0
	local maxBackups = 5
	local savePath = ""
	LuaUserData.RegisterType("Barotrauma.SaveUtil")
	local SaveUtil = LuaUserData.CreateStatic("Barotrauma.SaveUtil")


	local function addBot()
		local session = Game.GameSession
		local crewManager = session.CrewManager
		local chr = CharacterInfo("human")
		chr.TeamID = CharacterTeamType.Team1
		crewManager.AddCharacterInfo(chr)

		-- Taken from https://github.com/MassCraxx/MidRoundSpawn/blob/main/Lua/Autorun/midroundspawn.lua
		local spawnWayPoints = WayPoint.SelectCrewSpawnPoints({chr}, Submarine.MainSub)
		local randomIndex = Random.Range(1, #spawnWayPoints)
		local waypoint = spawnWayPoints[randomIndex]

		-- find waypoint the hard way
		if waypoint == nil then
			for i,wp in pairs(WayPoint.WayPointList) do
				if
					wp.AssignedJob ~= nil and
					wp.SpawnType == SpawnType.Human and
					wp.Submarine == Submarine.MainSub and
					wp.CurrentHull ~= nil
				then
					if chr.Job.Prefab == wp.AssignedJob then
						waypoint = wp
						break
					end
				end
			end
		end

		-- none found, go random
		if waypoint == nil then
			MidRoundSpawn.Log("WARN: No valid job waypoint found for " .. chr.Job.Name.Value .. " - using random")
			waypoint = WayPoint.GetRandom(SpawnType.Human, nil, Submarine.MainSub)
		end

		if waypoint == nil then
			MidRoundSpawn.Log("ERROR: Could not spawn player - no valid waypoint found")
			return false
		end

		local character = Character.Create(chr, waypoint.WorldPosition, Game.NetLobbyScreen.LevelSeed)
		character.GiveJobItems()
		Log("Added bot")
	end


	local function removeBot()
		for key, chara in pairs(Character.CharacterList) do
			if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
				chara.Kill(CauseOfDeathType.Unknown)
				return
			end
		end
		Log("Removed bot")
	end


	local function count()
		Log("Counting...")
		local nPly = 0
		local nBots = 0
		-- for key, chara in pairs(Client.ClientList) do
		-- 	nPly = nPly+1
		-- end
		nPly = #Client.ClientList
		for key, chara in pairs(Character.CharacterList) do
			if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
				nBots = nBots+1
			end
		end
		Log("nPly = "..nPly)
		Log("nBots = "..nBots)
		return nPly+nBots
	end


	local function handleBots()
		Log("Handling bots")
		local n = count()
		local m = Game.ServerSettings.MaxPlayers
		for i=1,(math.abs(n-m)) do
			if n > m then
				removeBot()
			elseif n < m then
				addBot()
			end
		end
	end


	local function backup()
		Log("Backing up save...")

		local tmp = Game.GameSession.SavePath
		if savePath ~= tmp then
			savePath = tmp
			counter = 0
		end

		local basePath = string.match(savePath, "^.*\\")
		local baseName = string.match(savePath, "\\([^\\]*)$")
		baseName = string.match(baseName, "(.*)[.]")

		local saveFilename = baseName .. '-' .. counter .. '.save'
		local xmlFilename = baseName .. '-' .. counter .. '_CharacterData.xml'

		--Game.SaveGame(basePath .. saveFilename) -- Doesn't always work
		SaveUtil.SaveGame(basePath .. saveFilename)
		Game.GameSession.Save(basePath .. xmlFilename)

		counter = (counter + 1) % maxBackups
		Log("Save is backed up!")
	end


	-- Hooks
	Hook.Add("client.connected", "handleBotsOnConnect", handleBots)
	Hook.Add("client.disconnected", "handleBotsOnDisconnect", handleBots)
	Hook.Add("roundStart", "handleBotsOnRoundStart", handleBots)
	Hook.Add("roundEnd", "saveBackup", backup)


	-- Commands
	Game.AddCommand("shh", "Opens Server Host Helper's config", function ()
		NT.ToggleGUI()
	end)


	--Hook.Add("chatMessage", "debugging", function(message)
	--
	--	print("message = "..message)
	--	if message == "c" then
	--		for key, client in pairs(Client.ClientList) do
	--			print("g")
	--		end
	--	elseif message == "h" then
	--		handleBots()
	--		Log("Handling")
	--	elseif message == "a" then
	--		addBot()
	--		Log("Handling")
	--	elseif message == "r" then
	--		removeBot()
	--		Log("Handling")
	--	elseif message == "t" then
	--		for i=1,1 do print("i = "..i) end
	--	end
	--end)

end
