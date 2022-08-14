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
