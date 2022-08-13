local modName = '[ServerHostHelper]'
local hello = "Starting up!"
local Log = function (message)
	print(modName .. " " .. message)
end



if CLIENT then
	
	if ServerHostHelperCl == nil then
		ServerHostHelperCl = {}
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

	if ServerHostHelperSv == nil then
		ServerHostHelperSv = {}
	else
		return
	end
	
	Log("[Server] "..hello)
	local counter = 0
	local maxBackups = 5
	local savePath = ""
	LuaUserData.RegisterType("Barotrauma.SaveUtil")
	LuaUserData.RegisterType("Barotrauma.CrewManager")
	local CrewManager = LuaUserData.CreateStatic("Barotrauma.CrewManager")
	local SaveUtil = LuaUserData.CreateStatic("Barotrauma.SaveUtil")
	local session = Game.GameSession
	local crewManager = session.CrewManager
	
	local function createBot()
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
	end
	
	
	local function count()
		local ret={}
		ret.nPly = 1
		ret.nBots = 2
		return ret
	end
	
	
	local function createBots()
		local n = 0
		local nBots = 0
		for key, chara in pairs(Client.ClientList) do
			if chara.TeamID == CharacterTeamType.Team1 then
				n = n+1
			end
		end
		for key, chara in pairs(Character.CharacterList) do
			if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
				nBots = nBots+1
			end
		end
		
		if (n >= Game.ServerSettings.MaxPlayers) then return end
		for i=1,(Game.ServerSettings.MaxPlayers - n) do createBot() end
		Log("Added bots")
	end
	
	
	local function removeBot()
		for key, chara in pairs(Character.CharacterList) do
			if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
				chara.Kill(CauseOfDeathType.Unknown)
				return
			end
		end
	end
	
	
	local function removeBots()
		local n = 0
		local nBots = 0
		for key, chara in pairs(Client.ClientList) do
			if chara.TeamID == CharacterTeamType.Team1 then
				n = n+1
			end
		end
		for key, chara in pairs(Character.CharacterList) do
			if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
				nBots = nBots+1
			end
		end
		
		for i=1,(Game.ServerSettings.MaxPlayers - n) do removeBot() end
		Log("Removed bots")
	end
	
	
	Hook.Add("roundEnd", "saveBackup", function()
		print(modName .. " Backing up save...")
		
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
		print(modName .. " Save is backed up!")
	end)
	
	
	Hook.Add("chatMessage", "zxcv", function(message)

		print("message = "..message)
		if message == "c" then
			for key, client in pairs(Client.ClientList) do
				print("g")
			end
		elseif message == "m" then
			createBots()
			Log("Making")
		elseif message == "d" then
			removeBots()
			Log("Removing")
		elseif message == "t" then
			local a=0
			local b=0
			local foo = count(a, b)
			print(foo.nPly.." "..foo.nBots)
			Log("testing")
		end
	end)
	
	
	Hook.Add("client.connected", "removeBotOnConnect", removeBots)
	Hook.Add("client.disconnected", "addBotOnDisconnect", createBots)
	Hook.Add("roundStart", "addBotOnRoundStart", createBots)
	
end