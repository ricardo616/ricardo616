--// ESP Moderno - Otimizado e Visualmente Melhorado
--// Feito para ser mais fluido, bonito e fácil de ler

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Cache = {}
local Connections = {}

local Bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},  {"LeftUpperArm", "LeftLowerArm"},  {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},  {"LeftUpperLeg", "LeftLowerLeg"},  {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

--// Configurações (fáceis de editar)
local ESP = {
    Enabled = true,

    -- Box
    ShowBox = true,
    BoxType = "Corner", -- "2D" ou "Corner"
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    BoxThickness = 1.5,

    -- Name
    ShowName = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 13,

    -- Health
    ShowHealth = true,
    HealthBarOutline = true,

    -- Distance
    ShowDistance = true,

    -- Skeleton
    ShowSkeleton = true,
    SkeletonColor = Color3.fromRGB(0, 255, 200),
    SkeletonThickness = 1.2,

    -- Tracer
    ShowTracer = true,
    TracerColor = Color3.fromRGB(255, 100, 100),
    TracerThickness = 2,
    TracerPosition = "Bottom", -- "Top", "Middle", "Bottom"

    -- Outros
    TeamCheck = false,
    WallCheck = false,
    MaxDistance = 500,
}

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function CreateESP(player)
    if Cache[player] then return end

    local esp = {
        Box = CreateDrawing("Square", {Filled = false, Thickness = ESP.BoxThickness, Color = ESP.BoxColor}),
        BoxOutline = CreateDrawing("Square", {Filled = false, Thickness = ESP.BoxThickness + 2, Color = ESP.BoxOutlineColor}),
        
        Name = CreateDrawing("Text", {Size = ESP.NameSize, Center = true, Outline = true, Color = ESP.NameColor}),
        Distance = CreateDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(220, 220, 220)}),
        
        HealthOutline = CreateDrawing("Line", {Thickness = 3, Color = Color3.fromRGB(0,0,0)}),
        HealthBar = CreateDrawing("Line", {Thickness = 1.5}),
        
        Tracer = CreateDrawing("Line", {Thickness = ESP.TracerThickness, Color = ESP.TracerColor, Transparency = 0.8}),
        
        Skeleton = {},
        BoxLines = {},
    }

    Cache[player] = esp
end

local function RemoveESP(player)
    local esp = Cache[player]
    if not esp then return end

    for _, obj in pairs(esp) do
        if typeof(obj) == "table" then
            for _, line in ipairs(obj) do
                if line and typeof(line) == "Instance" then line:Remove() end
            end
        elseif obj and typeof(obj) == "Instance" then
            obj:Remove()
        end
    end
    Cache[player] = nil
end

local function IsVisible(character)
    if not ESP.WallCheck then return true end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local ray = Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})

    return not hit or hit:IsDescendantOf(character)
end

local function UpdateESP()
    for player, esp in pairs(Cache) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
            for _, obj in pairs(esp) do
                if typeof(obj) == "Instance" then obj.Visible = false end
            end
            continue
        end

        local humanoid = char:FindFirstChild("Humanoid")
        local root = char.HumanoidRootPart
        local head = char.Head

        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        if distance > ESP.MaxDistance or (ESP.TeamCheck and player.Team == LocalPlayer.Team) then
            for _, obj in pairs(esp) do
                if typeof(obj) == "Instance" then obj.Visible = false end
            end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for _, obj in pairs(esp) do
                if typeof(obj) == "Instance" then obj.Visible = false end
            end
            continue
        end

        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y -
                     Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.6, 0)).Y) / 2

        local boxSize = Vector2.new(math.floor(size * 1.9), math.floor(size * 2.1))
        local boxPos = Vector2.new(math.floor(rootPos.X - boxSize.X / 2), math.floor(rootPos.Y - boxSize.Y / 2))

        --// Name
        if ESP.ShowName then
            esp.Name.Visible = true
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y - 18)
        else
            esp.Name.Visible = false
        end

        --// Box
        if ESP.ShowBox then
            if ESP.BoxType == "2D" then
                esp.Box.Size = boxSize
                esp.Box.Position = boxPos
                esp.Box.Visible = true

                esp.BoxOutline.Size = boxSize
                esp.BoxOutline.Position = boxPos
                esp.BoxOutline.Visible = true
            else -- Corner
                local w, h = boxSize.X, boxSize.Y
                local t = 1

                local positions = {
                    -- Top Left
                    {Vector2.new(boxPos.X, boxPos.Y), Vector2.new(boxPos.X + w/4, boxPos.Y)},
                    {Vector2.new(boxPos.X, boxPos.Y), Vector2.new(boxPos.X, boxPos.Y + h/4)},
                    -- Top Right
                    {Vector2.new(boxPos.X + w, boxPos.Y), Vector2.new(boxPos.X + w - w/4, boxPos.Y)},
                    {Vector2.new(boxPos.X + w, boxPos.Y), Vector2.new(boxPos.X + w, boxPos.Y + h/4)},
                    -- Bottom Left
                    {Vector2.new(boxPos.X, boxPos.Y + h), Vector2.new(boxPos.X + w/4, boxPos.Y + h)},
                    {Vector2.new(boxPos.X, boxPos.Y + h), Vector2.new(boxPos.X, boxPos.Y + h - h/4)},
                    -- Bottom Right
                    {Vector2.new(boxPos.X + w, boxPos.Y + h), Vector2.new(boxPos.X + w - w/4, boxPos.Y + h)},
                    {Vector2.new(boxPos.X + w, boxPos.Y + h), Vector2.new(boxPos.X + w, boxPos.Y + h - h/4)},
                }

                if #esp.BoxLines == 0 then
                    for i = 1, 8 do
                        esp.BoxLines[i] = CreateDrawing("Line", {Thickness = ESP.BoxThickness, Color = ESP.BoxColor})
                    end
                end

                for i, pos in ipairs(positions) do
                    local line = esp.BoxLines[i]
                    line.From = pos[1]
                    line.To = pos[2]
                    line.Visible = true
                end
            end
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end

        --// Health Bar
        if ESP.ShowHealth and humanoid then
            local healthPerc = humanoid.Health / humanoid.MaxHealth
            local barHeight = boxSize.Y * healthPerc

            esp.HealthOutline.From = Vector2.new(boxPos.X - 8, boxPos.Y)
            esp.HealthOutline.To = Vector2.new(boxPos.X - 8, boxPos.Y + boxSize.Y)
            esp.HealthOutline.Visible = true

            esp.HealthBar.From = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y)
            esp.HealthBar.To = Vector2.new(boxPos.X - 7, boxPos.Y + boxSize.Y - barHeight)
            esp.HealthBar.Color = Color3.fromRGB(255 - (255 * healthPerc), 255 * healthPerc, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
        end

        --// Distance
        if ESP.ShowDistance then
            esp.Distance.Text = string.format("%.0f studs", distance)
            esp.Distance.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 4)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end

        --// Skeleton
        if ESP.ShowSkeleton then
            if #esp.Skeleton == 0 then
                for _, bonePair in ipairs(Bones) do
                    table.insert(esp.Skeleton, CreateDrawing("Line", {
                        Thickness = ESP.SkeletonThickness,
                        Color = ESP.SkeletonColor,
                        Transparency = 0.85
                    }))
                end
            end

            for i, bonePair in ipairs(Bones) do
                local line = esp.Skeleton[i]
                local p1 = char:FindFirstChild(bonePair[1])
                local p2 = char:FindFirstChild(bonePair[2])

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

        --// Tracer
        if ESP.ShowTracer then
            local y = ESP.TracerPosition == "Top" and 0 or
                     ESP.TracerPosition == "Middle" and Camera.ViewportSize.Y/2 or
                     Camera.ViewportSize.Y

            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, y)
            esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
    end
end

--// Inicialização
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr) end
end)

Players.PlayerRemoving:Connect(RemoveESP)

Connections.Render = RunService.RenderStepped:Connect(UpdateESP)

--// Retorna as configurações para menu externo
return ESP
