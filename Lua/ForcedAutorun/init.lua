SHH = {}
SHH.name = '[ServerHostHelper]'
SHH.Log = function (message)
  print(SHH.name .. " " .. message)
end
SHH.Path = table.pack(...)[1]
local hello = "Starting up!"


-- config loading

if SHH.config == nil then
  if not File.Exists(SHH.Path .. "/config.json") then

    -- create default config if there is no config file
    SHH.Config = dofile(SHH.Path .. "/Lua/defaultconfig.lua")
    File.Write(SHH.Path .. "/config.json", json.serialize(SHH.Config))

  else

    -- load existing config
    SHH.Config = json.parse(File.Read(SHH.Path .. "/config.json"))

    -- add missing entries
    local defaultConfig = dofile(SHH.Path .. "/Lua/defaultconfig.lua")
    for key, value in pairs(defaultConfig) do
      if SHH.Config[key] == nil then
        SHH.Config[key] = value
      end
    end
  end
end



if CLIENT then

  if SHH.cl == nil then
    SHH.cl = {}
  else
    return
  end

  SHH.Log("[Client] "..hello)
  LuaUserData.RegisterType("Barotrauma.GameMain")
  local GameMain = LuaUserData.CreateStatic("Barotrauma.GameMain")


  -- catch faulty user inputted key configs
  local function tryKey()
    if PlayerInput.KeyHit(Keys[SHH.Config.logKey]) then
      GameMain.Client.ShowLogButton.OnClicked.Invoke()
    end
  end

  Hook.Add("think", "logWindowHotkey",
           function()
             if not Game.IsMultiplayer or GUI.GUI.KeyboardDispatcher.Subscriber ~= nil then return end -- Avoid main menu or executing with chat focused
             if not pcall(tryKey) then -- catch faulty user inputted key configs
               SHH.Log("!!! BAD HOTKEY PROVIDED FOR LOG WINDOW !!!")
             end
  end)

  -- Add a GUI for configuration
  dofile(SHH.Path .. "/Lua/configGui.lua")

elseif SERVER then

  if SHH.sv == nil then
    SHH.sv = {}
  else
    return
  end

  SHH.Log("[Server] "..hello)
  local counter = 0
  local maxBackups = 5
  local savePath = ""
  LuaUserData.RegisterType("Barotrauma.SaveUtil")
  local SaveUtil = LuaUserData.CreateStatic("Barotrauma.SaveUtil")


  -- Gets the least or most occupied job on the crew
  local function getJob(getMax)
    local jobs = {}
    jobs['Captain'] = {c=0,b=false} -- c = count, b = has bots
    jobs['Mechanic'] = {c=0,b=false}
    jobs['Engineer'] = {c=0,b=false}
    jobs['Security Officer'] = {c=0,b=false}
    jobs['Medical Doctor'] = {c=0,b=false}
    jobs['Assistant'] = {c=0,b=false}

    for key, chara in pairs(Character.CharacterList) do
      if chara.TeamID == CharacterTeamType.Team1 and ((chara.IsBot and not chara.IsDead) or (not chara.IsBot)) then
        if chara.IsCaptain then
          jobs['Captain'].c = jobs['Captain'].c + 1
          if chara.IsBot then
            jobs['Captain'].b = true
          end

        elseif chara.IsMechanic then
          jobs['Mechanic'].c = jobs['Mechanic'].c + 1
          if chara.IsBot then
            jobs['Mechanic'].b = true
          end

        elseif chara.IsEngineer then
          jobs['Engineer'].c = jobs['Engineer'].c + 1
          if chara.IsBot then
            jobs['Engineer'].b = true
          end

        elseif chara.IsSecurity then
          jobs['Security Officer'].c = jobs['Security Officer'].c + 1
          if chara.IsBot then
            jobs['Security Officer'].b = true
          end

        elseif chara.IsMedic then
          jobs['Medical Doctor'].c = jobs['Medical Doctor'].c + 1
          if chara.IsBot then
            jobs['Medical Doctor'].b = true
          end

        elseif chara.IsAssistant then
          jobs['Assistant'].c = jobs['Assistant'].c + 1
          if chara.IsBot then
            jobs['Assistant'].b = true
          end
        end
      end
    end


    local job = ""
    local i = nil

    if getMax then -- removing bots
      for k,v in pairs(jobs) do
        if v.b then
          if i == nil then
            job = k
            i = v.c
          elseif v.c > i then
            job = k
            i = v.c
          end
        end
      end

    else -- adding bots
      for k,v in pairs(jobs) do
        if i == nil then
          job = k
          i = v.c
        elseif v.c < i then
          job = k
          i = v.c
        end
      end
    end

    return job
  end


  local function addBot()
    local session = Game.GameSession
    local crewManager = session.CrewManager
    local j = getJob():gsub("%s+", "") -- get least occupied job, no spaces
    local chr = CharacterInfo(CharacterPrefab.HumanSpeciesName,"","", JobPrefab.Get(j))
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
      SHH.Log("WARN: No valid job waypoint found for " .. chr.Job.Name.Value .. " - using random")
      waypoint = WayPoint.GetRandom(SpawnType.Human, nil, Submarine.MainSub)
    end

    if waypoint == nil then
      SHH.Log("ERROR: Could not spawn player - no valid waypoint found")
      return false
    end

    local character = Character.Create(chr, waypoint.WorldPosition, Game.NetLobbyScreen.LevelSeed)
    character.GiveJobItems()
    SHH.Log("Added bot")
  end


  local function removeBot()
    local j = getJob(true) -- get most occupied job
    for key, chara in pairs(Character.CharacterList) do
      if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead and chara.Info.Job.Name.Value == j then
        chara.Kill(CauseOfDeathType.Unknown)
        chara.DespawnNow()
        return
      end
    end
    SHH.Log("Removed bot")
  end


  local function count()
    SHH.Log("Counting...")
    local nPly = 0
    local nBots = 0
    nPly = #Client.ClientList
    for key, chara in pairs(Character.CharacterList) do
      if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
        nBots = nBots+1
      end
    end
    SHH.Log("nPly = "..nPly)
    SHH.Log("nBots = "..nBots)
    return nPly+nBots
  end


  local function handleBots()
    SHH.Log("Handling bots")
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
    SHH.Log("Backing up save...")

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
    SHH.Log("Save is backed up!")
  end


  -- Hooks
  Hook.Add("client.connected", "handleBotsOnConnect", handleBots)
  Hook.Add("client.disconnected", "handleBotsOnDisconnect", handleBots)
  Hook.Add("roundStart", "handleBotsOnRoundStart", handleBots)
  Hook.Add("roundEnd", "saveBackup", backup)


  --Hook.Add("chatMessage", "debugging", function(message)

  --	SHH.Log("message = "..message)
  --	if message == "t" then
  --    SHH.Log("least job: "..getJob())
  --    SHH.Log("most job: "..getJob(true))
  --  elseif message == "a" then
  --    addBot()
  --  elseif message == "r" then
  --    removeBot()
  --	end
  --end)

end
