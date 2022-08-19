SHH = {}
SHH.name = '[ServerHostHelper]'
SHH.Log = function (message)
  print(SHH.name .. " " .. message)
end
SHH.Path = table.pack(...)[1]
SHH.Debug = false
local hello = "Starting up!"


-- Functions
SHH.handleBots = function() end


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
  local saveCount = 0
  local savePath = ""
  LuaUserData.RegisterType("Barotrauma.SaveUtil")
  local saveUtil = LuaUserData.CreateStatic("Barotrauma.SaveUtil")
  local session = Game.GameSession


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
        if k == "Captain" and jobs["Captain"].c >= 1 then
          -- skip it, only need 1 captain
        elseif i == nil then
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
    if (session == nil or session.CrewManager == nil) then return end
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
    if SHH.Debug then
      SHH.Log("Added bot")
    end
  end


  local function removeBot()
    local j = getJob(true) -- get most occupied job
    for key, chara in pairs(Character.CharacterList) do
      if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead and chara.Info.Job.Name.Value == j then
        chara.Kill(CauseOfDeathType.Unknown)
        chara.DespawnNow()
        if SHH.Debug then
          SHH.Log("Removed bot")
        end
        return
      end
    end
  end


  local function count()
    if SHH.Debug then
      SHH.Log("Counting...")
    end
    local nPly = 0
    local nBots = 0
    nPly = #Client.ClientList
    for key, chara in pairs(Character.CharacterList) do
      if chara.TeamID == CharacterTeamType.Team1 and chara.IsBot and not chara.IsDead then
        nBots = nBots+1
      end
    end
    if SHH.Debug then
      SHH.Log("nPly = "..nPly)
      SHH.Log("nBots = "..nBots)
    end
    return nPly+nBots
  end


  SHH.handleBots = function (removeBots) -- need this to deal with count() being wrong on disconnects
    if not SHH.Config.bots then return end
    if SHH.Debug then
      SHH.Log("Handling bots")
    end
    local n = count()
    if removeBots then
      n = n - 1
    end
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
    if not Game.IsMultiplayer or not SHH.Config.backup then return end
    if SHH.Debug then
      SHH.Log("Backing up save...")
    end

    local tmp = Game.GameSession.SavePath
    if savePath ~= tmp then
      savePath = tmp
      saveCount = 0
    end

    local basePath = string.match(savePath, "^.*\\")
    local baseName = string.match(savePath, "\\([^\\]*)$")
    baseName = string.match(baseName, "(.*)[.]")

    local saveName = baseName .. '-' .. saveCount
    local saveFilename = saveName .. '.save'

    -- CharacterData xml is tightly coupled into the save functions which is dependent on the Session.SavePath
    session.SavePath = basePath .. saveFilename
    saveUtil.SaveGame(session.SavePath)
    session.SavePath = tmp -- Reset it back to avoid -0-0-0... from counter adding on

    saveCount = (saveCount + 1) % SHH.Config.backupCount
    if SHH.Debug then
      SHH.Log("Save is backed up!")
    end
  end


  -- Hooks
  Hook.Add("client.connected", "handleBotsOnConnect", SHH.handleBots)
  Hook.Add("client.disconnected", "handleBotsOnDisconnect", function() SHH.handleBots(true) end) -- need this to deal with count() being wrong on disconnects
  Hook.Add("roundStart", "handleBotsOnRoundStart", SHH.handleBots)
  Hook.Add("roundEnd", "saveBackup", backup)


  if SHH.Debug then
    Hook.Add("chatMessage", "debugging", function(message)
               SHH.Log("message = "..message)
               if message == "t" then
                 SHH.Log("least job: "..getJob())
                 SHH.Log("most job: "..getJob(true))
               elseif message == "a" then
                 addBot()
               elseif message == "r" then
                 removeBot()
               elseif message == "h" then
                 SHH.handleBots()
               elseif message == "s" then
                 backup()
               end
    end)
  end

end
