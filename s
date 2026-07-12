--// ESP Avançado Completo 2026 - Tudo Incluso (Sem tecla Insert)
getgenv().ESP = getgenv().ESP or {}

local ESP = getgenv().ESP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Cache = {}

-- Configurações
ESP.Settings = {
    Enabled = true,
    ShowBox = true,
    BoxType = "Corner", -- "Corner" ou "2D"
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowSkeleton = true,
    ShowTracer = true,
    ShowHeadDot = true,
    TeamColor = true,
    WallCheck = false,
    MaxDistance = 800,

    BoxColor = Color3.fromRGB(255, 255, 255),
    SkeletonColor = Color3.fromRGB(0, 255, 200),
    TracerColor = Color3.fromRGB(255, 80, 80),
    HeadDotColor = Color3.fromRGB(255, 50, 50),
    TracerPosition = "Bottom",
}

local Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},  {"LeftUpperArm", "LeftLowerArm"},  {"LeftLowerArm", "LeftHand"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"LowerTorso", "LeftUpperLeg"},  {"LeftUpperLeg", "LeftLowerLeg"},  {"LeftLowerLeg", "LeftFoot"}
}

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
    if Cache[player] then return end
    local esp = {
        Box = CreateDrawing("Square", {Filled = false, Thickness = 1.5}),
        BoxOutline = CreateDrawing("Square", {Filled = false, Thickness = 3.5, Color = Color3.new(0,0,0)}),
        Name = CreateDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        Distance = CreateDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        HeadDot = CreateDrawing("Circle", {Radius = 3.5, Filled = true}),
        HealthOutline = CreateDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0)}),
        HealthBar = CreateDrawing("Line", {Thickness = 1.5}),
        Tracer = CreateDrawing("Line", {Thickness = 2}),
        Skeleton = {},
        BoxLines = {},
    }
    Cache[player] = esp
end

local function RemoveESP(player)
    local esp = Cache[player]
    if not esp then return end
    for _, v in pairs(esp) do
        if typeof(v) == "table" then
            for _, line in ipairs(v) do if line then line:Remove() end end
        elseif v then v:Remove() end
    end
    Cache[player] = nil
end

local function UpdateESP()
    if not ESP.Settings.Enabled then return end

    for player, esp in pairs(Cache) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            for _, obj in pairs(esp) do if typeof(obj) == "Instance" then obj.Visible = false end end
            continue
        end

        local root = char.HumanoidRootPart
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChild("Humanoid")
        if not head or not humanoid then continue end

        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        if distance > ESP.Settings.MaxDistance then
            for _, obj in pairs(esp) do if typeof(obj) == "Instance" then obj.Visible = false end end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for _, obj in pairs(esp) do if typeof(obj) == "Instance" then obj.Visible = false end end
            continue
        end

        local teamColor = GetTeamColor(player)
        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0,2.6,0)).Y) / 2
        local boxSize = Vector2.new(size * 1.9, size * 2.15)
        local boxPos = Vector2.new(rootPos.X - boxSize.X/2, rootPos.Y - boxSize.Y/2)

        -- Box
        if ESP.Settings.ShowBox then
            if ESP.Settings.BoxType == "Corner" then
                if #esp.BoxLines == 0 then
                    for i = 1, 8 do esp.BoxLines[i] = CreateDrawing("Line", {Thickness = 1.5}) end
                end
                local w, h = boxSize.X, boxSize.Y
                local p = boxPos
                local pts = {
                    {Vector2.new(p.X, p.Y), Vector2.new(p.X + w*0.25, p.Y)},
                    {Vector2.new(p.X, p.Y), Vector2.new(p.X, p.Y + h*0.25)},
                    {Vector2.new(p.X + w, p.Y), Vector2.new(p.X + w - w*0.25, p.Y)},
                    {Vector2.new(p.X + w, p.Y), Vector2.new(p.X + w, p.Y + h*0.25)},
                    {Vector2.new(p.X, p.Y + h), Vector2.new(p.X + w*0.25, p.Y + h)},
                    {Vector2.new(p.X, p.Y + h), Vector2.new(p.X, p.Y + h - h*0.25)},
                    {Vector2.new(p.X + w, p.Y + h), Vector2.new(p.X + w - w*0.25, p.Y + h)},
                    {Vector2.new(p.X + w, p.Y + h), Vector2.new(p.X + w, p.Y + h - h*0.25)},
                }
                for i, pos in ipairs(pts) do
                    esp.BoxLines[i].From = pos[1]
                    esp.BoxLines[i].To = pos[2]
                    esp.BoxLines[i].Color = teamColor
                    esp.BoxLines[i].Visible = true
                end
            else
                esp.Box.Size = boxSize
                esp.Box.Position = boxPos
                esp.Box.Color = teamColor
                esp.Box.Visible = true
                esp.BoxOutline.Size = boxSize
                esp.BoxOutline.Position = boxPos
                esp.BoxOutline.Visible = true
            end
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end

        -- Name
        if ESP.Settings.ShowName then
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y - 18)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        -- Health Bar
        if ESP.Settings.ShowHealth and humanoid then
            local healthPerc = humanoid.Health / humanoid.MaxHealth
            esp.HealthOutline.From = Vector2.new(boxPos.X - 8, boxPos.Y)
            esp.HealthOutline.To = Vector2.new(boxPos.X - 8, boxPos.Y + boxSize.Y)
            esp.HealthOutline.Visible = true

            esp.HealthBar.From = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y)
            esp.HealthBar.To = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y - (boxSize.Y * healthPerc))
            esp.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPerc), 255 * healthPerc, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
        end

        -- Distance
        if ESP.Settings.ShowDistance then
            esp.Distance.Text = string.format("%.0f studs", distance)
            esp.Distance.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 5)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end

        -- Head Dot
        if ESP.Settings.ShowHeadDot and head then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            esp.HeadDot.Color = ESP.Settings.HeadDotColor
            esp.HeadDot.Visible = true
        else
            esp.HeadDot.Visible = false
        end

        -- Tracer
        if ESP.Settings.ShowTracer then
            local y = ESP.Settings.TracerPosition == "Top" and 0 or
                      ESP.Settings.TracerPosition == "Middle" and Camera.ViewportSize.Y/2 or
                      Camera.ViewportSize.Y
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, y)
            esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.Tracer.Color = teamColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end

        -- Skeleton
        if ESP.Settings.ShowSkeleton then
            if #esp.Skeleton == 0 then
                for _, bone in ipairs(Bones) do
                    table.insert(esp.Skeleton, CreateDrawing("Line", {Thickness = 1.2, Color = ESP.Settings.SkeletonColor}))
                end
            end
            for i, bonePair in ipairs(Bones) do
                local p1 = char:FindFirstChild(bonePair[1])
                local p2 = char:FindFirstChild(bonePair[2])
                local line = esp.Skeleton[i]
                if p1 and p2 then
                    local v1 = Camera:WorldToViewportPoint(p1.Position)
                    local v2 = Camera:WorldToViewportPoint(p2.Position)
                    line.From = Vector2.new(v1.X, v1.Y)
                    line.To = Vector2.new(v2.X, v2.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
        end
    end
end

-- Inicialização
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr) end
end)

Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(UpdateESP)

print("✅ ESP Avançado Completo carregado com sucesso!")
