local CONFIG = {
    KeyListURL = "https://raw.githubusercontent.com/emanuelnuel313-dotcom/scripts/main/keys.txt",
    ScriptURL  = "https://raw.githubusercontent.com/emanuelnuel313-dotcom/scripts/main/script.lua",
    GetKeyURL  = "https://linkvertise.com/YOURLINK",
    SaveFile   = "qlnt_key.txt",
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local function fetchKeys()
    local ok, res = pcall(function() return game:HttpGet(CONFIG.KeyListURL) end)
    if not ok or not res then
        warn("[KeySystem] Could not fetch key list. Check your URL.")
        return {}
    end
    local set = {}
    for line in res:gmatch("[^\r\n]+") do
        line = line:gsub("%s", "")
        if #line > 0 then set[line] = true end
    end
    return set
end

local validKeys = fetchKeys()

local function savedKey()
    if not readfile then return nil end
    local ok, res = pcall(readfile, CONFIG.SaveFile)
    if ok and res and #res > 0 then return res:gsub("%s", "") end
end

local function runScript()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(CONFIG.ScriptURL))()
    end)
    if not ok then warn("[KeySystem] Script error: " .. tostring(err)) end
end

-- if a saved key is still valid, skip the GUI
local s = savedKey()
if s and validKeys[s] then
    runScript()
    return
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "QLNT_Key"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(0.5, -160, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 200, 120)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundTransparency = 1
title.Text = "QLNT | KEY SYSTEM"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 38)
box.Position = UDim2.new(0, 20, 0, 52)
box.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderText = "Paste your key here..."
box.Text = ""
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.BorderSizePixel = 0
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local getBtn = Instance.new("TextButton")
getBtn.Size = UDim2.new(0.45, -25, 0, 36)
getBtn.Position = UDim2.new(0, 20, 0, 102)
getBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
getBtn.Text = "Get Key"
getBtn.TextColor3 = Color3.new(1, 1, 1)
getBtn.Font = Enum.Font.GothamSemibold
getBtn.TextSize = 14
getBtn.BorderSizePixel = 0
getBtn.Parent = frame
Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0, 6)

local subBtn = Instance.new("TextButton")
subBtn.Size = UDim2.new(0.45, -25, 0, 36)
subBtn.Position = UDim2.new(0.5, 5, 0, 102)
subBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
subBtn.Text = "Submit"
subBtn.TextColor3 = Color3.new(1, 1, 1)
subBtn.Font = Enum.Font.GothamBold
subBtn.TextSize = 14
subBtn.BorderSizePixel = 0
subBtn.Parent = frame
Instance.new("UICorner", subBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -40, 0, 24)
status.Position = UDim2.new(0, 20, 0, 144)
status.BackgroundTransparency = 1
status.Text = "Enter a key to continue"
status.TextColor3 = Color3.fromRGB(160, 160, 170)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

getBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(CONFIG.GetKeyURL) end
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(CONFIG.GetKeyURL) end)
    status.Text = "Link opened + copied"
    status.TextColor3 = Color3.fromRGB(200, 200, 120)
end)

subBtn.MouseButton1Click:Connect(function()
    local key = box.Text:gsub("%s", "")
    if #key == 0 then
        status.Text = "Enter a key first"
        status.TextColor3 = Color3.fromRGB(220, 120, 120)
        return
    end
    validKeys = fetchKeys()
    if validKeys[key] then
        if writefile then pcall(writefile, CONFIG.SaveFile, key) end
        status.Text = "Valid! Loading..."
        status.TextColor3 = Color3.fromRGB(120, 220, 120)
        task.wait(0.4)
        gui:Destroy()
        runScript()
    else
        status.Text = "Invalid key"
        status.TextColor3 = Color3.fromRGB(220, 120, 120)
    end
end)
