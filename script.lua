-- 1. รันสคริปต์หลัก
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/miirandahub/loader/refs/heads/main/stealaeggs"))()
    end)
end)

local LOGO_ID = "rbxassetid://115592023833919"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local searchingLowServer = false
local sidePanelCreated = false
local lowServerFrame = nil
local startBtn = nil

-- -------------------------------------------------------------
-- 2. ระบบ Reconnect & Error Handling
-- -------------------------------------------------------------
local function hopToLowServer()
    local placeId = game.PlaceId
    local servers = {}
    local req = request or http_request or (syn and syn.request) or game.HttpGet
    
    pcall(function()
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        local res = (type(req) == "function" and req(game, url)) or game:HttpGet(url)
        if res then
            local data = HttpService:JSONDecode(res)
            if data and data.data then
                for _, s in ipairs(data.data) do
                    if s.playing and s.playing >= 1 and s.playing <= 5 and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end
            end
        end
    end)
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
    else
        TeleportService:Teleport(placeId, LocalPlayer)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player)
    if player == LocalPlayer then
        task.wait(1)
        hopToLowServer()
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    hopToLowServer()
end)

-- -------------------------------------------------------------
-- 3. ระบบค้นหาเซิร์ฟเวอร์คนน้อย (Low Server Hopper)
-- -------------------------------------------------------------
local function startLowServerHop()
    if searchingLowServer then return end
    searchingLowServer = true

    if startBtn then
        startBtn.Text = "STOP"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end

    task.spawn(function()
        while searchingLowServer do
            pcall(function()
                local cursor = ""
                local found = false

                while searchingLowServer and not found do
                    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                    if cursor ~= "" then
                        url = url .. "&cursor=" .. cursor
                    end

                    local req = game:HttpGet(url)
                    local data = HttpService:JSONDecode(req)

                    if data and data.data then
                        for _, server in ipairs(data.data) do
                            if not searchingLowServer then break end
                            if server.id ~= game.JobId and server.playing and server.playing > 0 and server.playing < (server.maxPlayers or 12) then
                                found = true
                                searchingLowServer = false
                                if startBtn then
                                    startBtn.Text = "JOINING..."
                                    startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                                end
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                                break
                            end
                        end

                        if data.nextPageCursor and not found then
                            cursor = data.nextPageCursor
                        else
                            break
                        end
                    else
                        break
                    end
                    task.wait(1)
                end
            end)

            if searchingLowServer then
                task.wait(2)
            end
        end
    end)
end

local function stopLowServerHop()
    searchingLowServer = false
    if startBtn then
        startBtn.Text = "START"
        startBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 255)
    end
end

-- -------------------------------------------------------------
-- 4. ระบบ Side Panel สำหรับ Low Server
-- -------------------------------------------------------------
local function createSidePanel(mainFrame)
    if sidePanelCreated or not mainFrame then return end
    sidePanelCreated = true

    local toggleRedBtn = Instance.new("TextButton")
    toggleRedBtn.Name = "NovaLowServerToggle"
    toggleRedBtn.Size = UDim2.new(0, 32, 0, 32)
    toggleRedBtn.Position = UDim2.new(1, -36, 0, 8)
    toggleRedBtn.BackgroundColor3 = Color3.fromRGB(230, 45, 60)
    toggleRedBtn.Text = "="
    toggleRedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleRedBtn.TextSize = 22
    toggleRedBtn.Font = Enum.Font.FredokaOne
    toggleRedBtn.BorderSizePixel = 0
    toggleRedBtn.ZIndex = 100
    toggleRedBtn.Parent = mainFrame

    local redCorner = Instance.new("UICorner")
    redCorner.CornerRadius = UDim.new(0, 8)
    redCorner.Parent = toggleRedBtn

    lowServerFrame = Instance.new("Frame")
    lowServerFrame.Name = "NovaLowServerWindow"
    lowServerFrame.Size = UDim2.new(0, 180, 0, 150)
    lowServerFrame.Position = UDim2.new(1, 10, 0, 0)
    lowServerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    lowServerFrame.BorderSizePixel = 0
    lowServerFrame.Visible = false
    lowServerFrame.ZIndex = 90
    lowServerFrame.Parent = mainFrame

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = lowServerFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(180, 70, 255)
    frameStroke.Thickness = 1.5
    frameStroke.Parent = lowServerFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "NovaLowServerTitle"
    titleLabel.Size = UDim2.new(1, -20, 0, 35)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Low Server"
    titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = lowServerFrame

    startBtn = Instance.new("TextButton")
    startBtn.Name = "StartHopButton"
    startBtn.Size = UDim2.new(1, -30, 0, 42)
    startBtn.Position = UDim2.new(0, 15, 0, 75)
    startBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 255)
    startBtn.Text = "START"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.TextSize = 18
    startBtn.Font = Enum.Font.FredokaOne
    startBtn.BorderSizePixel = 0
    startBtn.Parent = lowServerFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = startBtn

    toggleRedBtn.MouseButton1Click:Connect(function()
        lowServerFrame.Visible = not lowServerFrame.Visible
    end)

    startBtn.MouseButton1Click:Connect(function()
        if searchingLowServer then
            stopLowServerHop()
        else
            startLowServerHop()
        end
    end)
end

-- -------------------------------------------------------------
-- 5. ระบบ Rebrand แบบประหยัดทรัพยากรเครื่อง (Optimized Process)
-- -------------------------------------------------------------
local function processObject(obj)
    if not obj then return end
    if obj.Name == "NovaLowServerTitle" or obj.Name == "StartHopButton" or obj.Name == "NovaLowServerToggle" then return end

    -- 1. เปลี่ยน Text
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local txt = tostring(obj.Text)
        local upperTxt = txt:upper()
        
        if upperTxt:find("MIRANDA") then
            if obj:FindFirstAncestorOfClass("ScreenGui") or obj:FindFirstAncestorOfClass("CoreGui") then
                obj.RichText = true
                obj.Text = '<font color="rgb(180, 70, 255)">NOVA</font> <font color="rgb(255, 255, 255)">HUB</font>'
                
                local mainFrame = obj:FindFirstAncestorOfClass("Frame")
                if mainFrame and not sidePanelCreated then
                    createSidePanel(mainFrame)
                end
            else
                obj.Text = txt:gsub("MIRANDA", "NOVA"):gsub("Miranda", "NOVA")
            end
        elseif txt:find("discord.gg") and not txt:find("WJ9zAP45F") then
            obj.Text = "discord.gg/WJ9zAP45F"
        end
    end

    -- 2. เปลี่ยน Image/Logo
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        local imgStr = tostring(obj.Image)
        local isMirandaImg = imgStr:find("18431013444") or imgStr:find("18431013") or imgStr:find("1843101")
        
        local isScriptButton = false
        if obj.Parent and (obj.Parent.Name:lower():find("miranda") or obj.Parent.Name:lower():find("hub") or obj.Parent:IsA("ScreenGui")) then
            if obj.Size.X.Offset <= 80 and obj.Size.Y.Offset <= 80 then
                isScriptButton = true
            end
        end

        if isMirandaImg or isScriptButton then
            if obj.Image ~= LOGO_ID then
                obj.Image = LOGO_ID
            end
        end
    end
end

-- ระบบตรวจจับวัตถุแบบ Event-Based (ไม่กิน FPS)
local targetContainers = {
    (gethui and gethui()),
    CoreGui,
    Workspace,
    LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
}

for _, container in pairs(targetContainers) do
    if container then
        -- ตรวจสอบวัตถุใหม่ทันทีที่ถูกเพิ่มเข้ามา
        container.DescendantAdded:Connect(function(descendant)
            task.wait(0.05)
            pcall(processObject, descendant)
        end)
    end
end

-- สแกนซ้ำระยะยาวห่างขึ้นเป็นทุก 2.5 วินาที เพื่อป้องกันการตกหล่น
task.spawn(function()
    while true do
        pcall(function()
            for _, root in pairs(targetContainers) do
                if root then
                    for _, descendant in pairs(root:GetDescendants()) do
                        processObject(descendant)
                    end
                end
            end
        end)
        task.wait(2.5)
    end
end)
