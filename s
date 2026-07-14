-- ESP Avançado - Suporte Total a Menu (Toggle em tempo real)
getgenv().ESP = getgenv().ESP or {}
local ESP = getgenv().ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Cache = {}
local Connections = {}

ESP.Settings = {
    Enabled = true,
    ShowBox = true,
    BoxType = "Corner",
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowSkeleton = true,
    ShowTracer = true,
    ShowHeadDot = true,
    TeamColor = true,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 0, 255),
}

-- Funções básicas
local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

local function GetTeamColor(player)
    if ESP.Settings.TeamColor and player.Team then
        return player.Team.TeamColor.Color
    end
    return ESP.Settings.BoxColor
end

local function CreateESP(player)
    if player == LocalPlayer or Cache[player] then return end
    
    Cache[player] = {
        BoxLines = {},
        Name = CreateDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        Distance = CreateDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        HeadDot = CreateDrawing("Circle", {Radius = 3.5, Filled = true, Color = Color3.new(1,0,0)}),
        HealthOutline = CreateDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0)}),
        HealthBar = CreateDrawing("Line", {Thickness = 1.5}),
        Tracer = CreateDrawing("Line", {Thickness = 2}),
        Skeleton = {},
    }
end

local function HideESP(esp)
    if not esp then return end
    for _, obj in pairs(esp) do
        if typeof(obj) == "table" then
            for _, v in ipairs(obj) do if v then v.Visible = false end end
        elseif obj and typeof(obj) == "Instance" then
            obj.Visible = false
        end
    end
end

local function RemoveESP(player)
    local esp = Cache[player]
    if esp then
        HideESP(esp)
        Cache[player] = nil
    end
end

local function UpdateESP()
    if not ESP.Settings.Enabled then
        for _, esp in pairs(Cache) do
            HideESP(esp)
        end
        return
    end

    for player, esp in pairs(Cache) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            HideESP(esp)
            continue
        end

        local root = char.HumanoidRootPart
        local humanoid = char:FindFirstChild("Humanoid")
        local distance = (Camera.CFrame.Position - root.Position).Magnitude

        if distance > ESP.Settings.MaxDistance then
            HideESP(esp)
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            HideESP(esp)
            continue
        end

        local teamColor = GetTeamColor(player)
        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0,2.6,0)).Y) / 2
        local boxSize = Vector2.new(size * 1.9, size * 2.15)
        local boxPos = Vector2.new(rootPos.X - boxSize.X/2, rootPos.Y - boxSize.Y/2)

        -- Box
        if ESP.Settings.ShowBox and ESP.Settings.BoxType == "Corner" then
            if #esp.BoxLines == 0 then
                for i = 1, 8 do 
                    esp.BoxLines[i] = CreateDrawing("Line", {Thickness = 1.5}) 
                end
            end
            local w, h = boxSize.X, boxSize.Y
            local p = boxPos
            local pts = {
                {Vector2.new(p.X, p.Y), Vector2.new(p.X + w*0.25, p.Y)},
                {Vector2.new(p.X, p.Y), Vector2.new(p.X, p.Y + h*0.25)},
                {Vector2.new(p.X+w, p.Y), Vector2.new(p.X+w - w*0.25, p.Y)},
                {Vector2.new(p.X+w, p.Y), Vector2.new(p.X+w, p.Y + h*0.25)},
                {Vector2.new(p.X, p.Y+h), Vector2.new(p.X + w*0.25, p.Y+h)},
                {Vector2.new(p.X, p.Y+h), Vector2.new(p.X, p.Y+h - h*0.25)},
                {Vector2.new(p.X+w, p.Y+h), Vector2.new(p.X+w - w*0.25, p.Y+h)},
                {Vector2.new(p.X+w, p.Y+h), Vector2.new(p.X+w, p.Y+h - h*0.25)},
            }
            for i, pos in ipairs(pts) do
                esp.BoxLines[i].From = pos[1]
                esp.BoxLines[i].To = pos[2]
                esp.BoxLines[i].Color = teamColor
                esp.BoxLines[i].Visible = true
            end
        else
            for _, line in ipairs(esp.BoxLines) do if line then line.Visible = false end end
        end

        -- Name
        if ESP.Settings.ShowName then
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y - 18)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        -- Health
        if ESP.Settings.ShowHealth and humanoid then
            local perc = humanoid.Health / humanoid.MaxHealth
            esp.HealthOutline.From = Vector2.new(boxPos.X - 8, boxPos.Y)
            esp.HealthOutline.To = Vector2.new(boxPos.X - 8, boxPos.Y + boxSize.Y)
            esp.HealthOutline.Visible = true
            
            esp.HealthBar.From = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y)
            esp.HealthBar.To = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y - boxSize.Y * perc)
            esp.HealthBar.Color = Color3.fromRGB(255 * (1-perc), 255 * perc, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
        end

        -- Distance
        if ESP.Settings.ShowDistance then
            esp.Distance.Text = string.format("%.0f", distance) .. "m"
            esp.Distance.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 5)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end
    end
end

-- Inicialização
for _, plr in ipairs(Players:GetPlayers()) do
    CreateESP(plr)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(UpdateESP)

print("✅ ESP com suporte total a Menu carregado!")
