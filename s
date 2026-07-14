-- ESP Avançado - Suporte workspace.Players + game.Players (Full Features)
getgenv().ESP = getgenv().ESP or {}
local ESP = getgenv().ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Cache = {}

ESP.Settings = {
    Enabled = false,
    ShowName = false,
    ShowDistance = false,
    ShowHealth = false,
    ShowBox = false,
    ShowTracer = false,
    ShowSkeleton = false,
    ShowHeadDot = false,
    TeamColor = false,
    MaxDistance = 1500,
    BoxColor = Color3.fromRGB(255, 0, 0),
    TracerColor = Color3.fromRGB(0, 255, 0),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
}

local Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}
}

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

local function GetCharacter(playerName)
    -- Normal Roblox
    local plr = Players:FindFirstChild(playerName)
    if plr and plr.Character then
        return plr.Character
    end
    
    -- Custom Folder (muitos jogos usam isso)
    local folder = workspace:FindFirstChild("Players")
    if folder then
        local model = folder:FindFirstChild(playerName)
        if model then
            return model
        end
    end
    return nil
end

local function CreateESP(playerName)
    if Cache[playerName] then return end
    Cache[playerName] = {
        BoxLines = {},
        Name = CreateDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        Distance = CreateDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.new(1,1,1)}),
        HeadDot = CreateDrawing("Circle", {Radius = 3.5, Filled = true, Color = Color3.new(1,0,0)}),
        HealthOutline = CreateDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0)}),
        HealthBar = CreateDrawing("Line", {Thickness = 1.5}),
        Tracer = CreateDrawing("Line", {Thickness = 2, Color = ESP.Settings.TracerColor}),
        Skeleton = {},
    }
end

local function HideESP(esp)
    for _, obj in pairs(esp or {}) do
        if typeof(obj) == "table" then
            for _, v in ipairs(obj) do if v then v.Visible = false end end
        elseif obj then
            obj.Visible = false
        end
    end
end

local function UpdateESP()
    if not ESP.Settings.Enabled then
        for _, esp in pairs(Cache) do HideESP(esp) end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local playerName = plr.Name

        local char = GetCharacter(playerName)
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if Cache[playerName] then HideESP(Cache[playerName]) end
            continue
        end

        local esp = Cache[playerName] or CreateESP(playerName)
        local root = char.HumanoidRootPart
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChild("Humanoid")
        local distance = (Camera.CFrame.Position - root.Position).Magnitude

        if distance > ESP.Settings.MaxDistance then
            HideESP(esp) continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then HideESP(esp) continue end

        local teamColor = ESP.Settings.TeamColor and (plr.Team and plr.Team.TeamColor.Color or ESP.Settings.BoxColor) or ESP.Settings.BoxColor

        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0,2.6,0)).Y) / 2
        local boxSize = Vector2.new(size * 1.9, size * 2.15)
        local boxPos = Vector2.new(rootPos.X - boxSize.X/2, rootPos.Y - boxSize.Y/2)

        -- Bounding Box
        if ESP.Settings.ShowBox then
            if #esp.BoxLines == 0 then
                for i = 1, 8 do esp.BoxLines[i] = CreateDrawing("Line", {Thickness = 1.5}) end
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
            esp.Name.Text = playerName
            esp.Name.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y - 18)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        -- Distance
        if ESP.Settings.ShowDistance then
            esp.Distance.Text = string.format("%.0f", distance) .. "m"
            esp.Distance.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 5)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
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

        -- Head Dot
        if ESP.Settings.ShowHeadDot and head then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            esp.HeadDot.Visible = true
        else
            esp.HeadDot.Visible = false
        end

        -- Tracer
        if ESP.Settings.ShowTracer then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.Tracer.Color = ESP.Settings.TracerColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end

        -- Skeleton
        if ESP.Settings.ShowSkeleton then
            for i, bonePair in ipairs(Bones) do
                local part1 = char:FindFirstChild(bonePair[1])
                local part2 = char:FindFirstChild(bonePair[2])
                if part1 and part2 then
                    if not esp.Skeleton[i] then
                        esp.Skeleton[i] = CreateDrawing("Line", {Thickness = 1.5, Color = ESP.Settings.SkeletonColor})
                    end
                    local pos1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2 = Camera:WorldToViewportPoint(part2.Position)
                    esp.Skeleton[i].From = Vector2.new(pos1.X, pos1.Y)
                    esp.Skeleton[i].To = Vector2.new(pos2.X, pos2.Y)
                    esp.Skeleton[i].Visible = true
                end
            end
        else
            for _, line in ipairs(esp.Skeleton) do if line then line.Visible = false end end
        end
    end
end

-- Inicialização
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr.Name) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr.Name) end
end)

RunService.RenderStepped:Connect(UpdateESP)

print("✅ ESP Completo carregado! (Suporte a workspace.Players)")
