-- Taken from https://github.com/Mannatwo/Neurotrauma/blob/5a4b8c47de50a78996ccc483f99fd3db1769f951/Neurotrauma/Lua/Scripts/Client/configgui.lua#L1

-- I'm sorry for the eyes of anyone looking at the GUI code.

local MultiLineTextBox = dofile(SHH.Path .. "/Lua/MultiLineTextBox.lua")

Game.AddCommand("shh", "Opens Server Host Helper's config",
                function ()
                  SHH.ToggleGUI()
end)

local function CommaStringToTable(str)
    local tbl = {}

    for word in string.gmatch(str, '([^,]+)') do
        table.insert(tbl, word)
    end

    return tbl
end
local function ClearElements(guicomponent, removeItself)
    local toRemove = {}

    for value in guicomponent.GetAllChildren() do
        table.insert(toRemove, value)
    end

    for index, value in pairs(toRemove) do
        value.RemoveChild(value)
    end

    if guicomponent.Parent and removeItself then
        guicomponent.Parent.RemoveChild(guicomponent)
    end
end
local function GetAmountOfPrefab(prefabs)
    local amount = 0
    for key, value in prefabs do
        amount = amount + 1
    end

    return amount
end


Hook.Add("stop", "SHH.CleanupGUI", function ()
    if selectedGUIText then
        selectedGUIText.Parent.RemoveChild(selectedGUIText)
    end

    if SHH.GUIFrame then
        ClearElements(SHH.GUIFrame, true)
    end
end)

SHH.ShowGUI = function ()
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.3, 0.6), GUI.Screen.Selected.Frame.RectTransform, GUI.Anchor.Center))

    SHH.GUIFrame = frame

    frame.CanBeFocused = true

    local config = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.BottomCenter))

    local closebtn = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.3), frame.RectTransform, GUI.Anchor.TopRight), "X", GUI.Alignment.Center, "GUIButtonSmall")
    closebtn.OnClicked = function ()
        SHH.ToggleGUI()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Server Host Helper Config", nil, nil, GUI.Alignment.Center)

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Note: Only the host can edit the servers config. Enter \"reloadlua\" in console to apply changes. For dedicated servers you need to edit the file config.json, this GUI wont work. See steam workshop description on how to configure.", nil, nil, GUI.Alignment.Center, true)

    local savebtn = GUI.Button(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Save Config", GUI.Alignment.Center, "GUIButtonSmall")
    savebtn.OnClicked = function ()
        File.Write(SHH.Path .. "/config.json", json.serialize(SHH.Config))
    end



    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Hotkey for Server Log Popup (proper capitals and press Enter)",
                  nil, nil, GUI.Alignment.Center, true)
    local logKey = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform))
    logKey.Text = SHH.Config.logKey
    logKey.OnEnterPressed = function ()
      SHH.Log("changed!")
      SHH.Config.logKey = logKey.Text
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Organ damage gain multiplier", nil, nil, GUI.Alignment.Center, true)
    local organDamageGain = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    organDamageGain.valueStep = 0.1
    organDamageGain.MinValueFloat = 0
    organDamageGain.MaxValueFloat = 100
    organDamageGain.FloatValue = 0
    organDamageGain.OnValueChanged = function ()
      SHH.Log("hi")
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Fibrillation speed multiplier", nil, nil, GUI.Alignment.Center, true)
    local fibrillationSpeed = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    fibrillationSpeed.valueStep = 0.1
    fibrillationSpeed.MinValueFloat = 0
    fibrillationSpeed.MaxValueFloat = 100
    fibrillationSpeed.FloatValue = SHH.Config.fibrillationSpeed
    fibrillationSpeed.OnValueChanged = function ()
        SHH.Config.fibrillationSpeed = fibrillationSpeed.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Infection rate multiplier", nil, nil, GUI.Alignment.Center, true)
    local infectionRate = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    infectionRate.valueStep = 0.1
    infectionRate.MinValueFloat = 0
    infectionRate.MaxValueFloat = 100
    infectionRate.FloatValue = SHH.Config.infectionRate
    infectionRate.OnValueChanged = function ()
        SHH.Config.infectionRate = infectionRate.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Fracture chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local fractureChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    fractureChance.valueStep = 0.1
    fractureChance.MinValueFloat = 0
    fractureChance.MaxValueFloat = 100
    fractureChance.FloatValue = SHH.Config.fractureChance
    fractureChance.OnValueChanged = function ()
        SHH.Config.fractureChance = fractureChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Dislocation chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local dislocationChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    dislocationChance.valueStep = 0.1
    dislocationChance.MinValueFloat = 0
    dislocationChance.MaxValueFloat = 100
    dislocationChance.FloatValue = SHH.Config.dislocationChance
    dislocationChance.OnValueChanged = function ()
        SHH.Config.dislocationChance = dislocationChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Traumatic amputation chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local traumaticAmputationChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    traumaticAmputationChance.valueStep = 0.1
    traumaticAmputationChance.MinValueFloat = 0
    traumaticAmputationChance.MaxValueFloat = 100
    traumaticAmputationChance.FloatValue = SHH.Config.traumaticAmputationChance
    traumaticAmputationChance.OnValueChanged = function ()
        SHH.Config.traumaticAmputationChance = traumaticAmputationChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Pneumothorax chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local pneumothoraxChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    pneumothoraxChance.valueStep = 0.1
    pneumothoraxChance.MinValueFloat = 0
    pneumothoraxChance.MaxValueFloat = 100
    pneumothoraxChance.FloatValue = SHH.Config.pneumothoraxChance
    pneumothoraxChance.OnValueChanged = function ()
        SHH.Config.pneumothoraxChance = pneumothoraxChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Tamponade chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local tamponadeChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    tamponadeChance.valueStep = 0.1
    tamponadeChance.MinValueFloat = 0
    tamponadeChance.MaxValueFloat = 100
    tamponadeChance.FloatValue = SHH.Config.tamponadeChance
    tamponadeChance.OnValueChanged = function ()
        SHH.Config.tamponadeChance = tamponadeChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Heart attack chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local heartattackChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    heartattackChance.valueStep = 0.1
    heartattackChance.MinValueFloat = 0
    heartattackChance.MaxValueFloat = 100
    heartattackChance.FloatValue = SHH.Config.heartattackChance
    heartattackChance.OnValueChanged = function ()
        SHH.Config.heartattackChance = heartattackChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Stroke chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local strokeChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    strokeChance.valueStep = 0.1
    strokeChance.MinValueFloat = 0
    strokeChance.MaxValueFloat = 100
    strokeChance.FloatValue = SHH.Config.strokeChance
    strokeChance.OnValueChanged = function ()
        SHH.Config.strokeChance = strokeChance.FloatValue
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "CPR Rib break chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local CPRFractureChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    CPRFractureChance.valueStep = 0.1
    CPRFractureChance.MinValueFloat = 0
    CPRFractureChance.MaxValueFloat = 100
    CPRFractureChance.FloatValue = SHH.Config.CPRFractureChance
    CPRFractureChance.OnValueChanged = function ()
        SHH.Config.CPRFractureChance = CPRFractureChance.FloatValue
    end

    local disableBotAlgorithms = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Disable bot treatment algorithms (they're laggy)")
    disableBotAlgorithms.Selected = SHH.Config.disableBotAlgorithms
    disableBotAlgorithms.OnSelected = function ()
        SHH.Config.disableBotAlgorithms = disableBotAlgorithms.State == 3
    end

    local organRejection = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Organ rejection")
    organRejection.Selected = SHH.Config.organRejection
    organRejection.OnSelected = function ()
        SHH.Config.organRejection = organRejection.State == 3
    end

    -- Surgery Plus specific options
    if NTSP~=nil then

        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Neurotrauma surgery plus", nil, nil, GUI.Alignment.Center, true)

        local NTSPenableSurgicalInfection = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Surgical infection")
        NTSPenableSurgicalInfection.Selected = SHH.Config.NTSPenableSurgicalInfection
        NTSPenableSurgicalInfection.OnSelected = function ()
            SHH.Config.NTSPenableSurgicalInfection = NTSPenableSurgicalInfection.State == 3
        end

        local NTSPenableSurgerySkill = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Surgery skill")
        NTSPenableSurgerySkill.Selected = SHH.Config.NTSPenableSurgerySkill
        NTSPenableSurgerySkill.OnSelected = function ()
            SHH.Config.NTSPenableSurgerySkill = NTSPenableSurgerySkill.State == 3
        end

    end

--[[

-- Multilines

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Client High Priority Items", nil, nil, GUI.Alignment.Center, true)

    local clientHighPriorityItems = MultiLineTextBox(config.Content.RectTransform, "", 0.2)

    clientHighPriorityItems.Text = table.concat(NT.Config.clientItemHighPriority, ",")

    clientHighPriorityItems.OnTextChangedDelegate = function (textBox)
        NT.Config.clientItemHighPriority = CommaStringToTable(textBox.Text)
    end

-- Tickboxes

    local hideInGameWires = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Hide In Game Wires")

    hideInGameWires.Selected = NT.Config.hideInGameWires

    hideInGameWires.OnSelected = function ()
        NT.Config.hideInGameWires = hideInGameWires.State == 3
    end

    ]]
end


SHH.HideGUI = function()
    if SHH.GUIFrame then
        ClearElements(SHH.GUIFrame, true)
    end
end

SHH.GUIOpen = false
SHH.ToggleGUI = function ()
    SHH.GUIOpen = not SHH.GUIOpen

    if SHH.GUIOpen then
        SHH.ShowGUI()
    else
        SHH.HideGUI()
    end
end
