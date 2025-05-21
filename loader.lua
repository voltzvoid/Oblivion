-- GUI STUFF
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local guiName = "SexyGUI"

-- 🧼 Clean up old GUI if it exists
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild(guiName)
if existing then
    existing:Destroy()
end

-- 🌟 Create new GUI
local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.Parent = playerGui

-- Track frames for toggling
local allFrames = {}
local guiVisible = true

-- 👀 Toggle all frames with RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        for _, frame in ipairs(allFrames) do
            frame.Visible = guiVisible
        end
    end
end)

-- 🧱 Configuration
local categories = {
    {Name = "COMBAT", Buttons = {"KILLAURA"}},
    {Name = "PLAYER", Buttons = {}},
    {Name = "MISC",   Buttons = {}},
    {Name = "WORLD",  Buttons = {}},
}

-- 🎨 Colors
local mainColor      = Color3.fromRGB(120,  90, 255)
local buttonColor    = Color3.fromRGB(180, 140, 255)
local buttonColorOn  = Color3.fromRGB( 90,  60, 160)
local titleColor     = Color3.fromRGB( 30,  20,  70)

-- 🪟 Create draggable frame
local function createDraggableFrame(position)
    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(0, 160, 0, 500)
    frame.Position        = position
    frame.BackgroundColor3= mainColor
    frame.BorderSizePixel = 0
    frame.Active          = true
    frame.Draggable       = true
    frame.Visible         = true
    frame.Parent          = gui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness    = 2
    stroke.Color        = Color3.new(0,0,0)
    stroke.Transparency = 0.3

    table.insert(allFrames, frame)
    return frame
end

-- 🏷️ Title
local function createTitle(frame, text)
    local title = Instance.new("TextLabel")
    title.Parent           = frame
    title.Size             = UDim2.new(1, 0, 0, 45)
    title.Position         = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = titleColor
    title.BorderSizePixel  = 0
    title.Font             = Enum.Font.FredokaOne
    title.TextSize         = 24
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = text

    local corner = Instance.new("UICorner", title)
    corner.CornerRadius = UDim.new(0, 12)
end

-- 🔘 Toggle button with callback support
local function createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Parent           = parent
    button.Size             = UDim2.new(0.8,  0, 0, 38)
    button.AnchorPoint      = Vector2.new(0.5, 0)
    button.Position         = UDim2.new(0.5,  0, 0, 0)
    button.BackgroundColor3 = buttonColor
    button.BorderSizePixel  = 0
    button.Font             = Enum.Font.FredokaOne
    button.TextSize         = 20
    button.TextColor3       = Color3.new(1,1,1)
    button.Text             = text
    button.AutoButtonColor  = false

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 10)

    local toggled = false
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        button.BackgroundColor3 = toggled and buttonColorOn or buttonColor
        if callback then
            callback(toggled)
        end
    end)
end

--// KILLAURA CODE INTEGRATION

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Remote Event
local SwordHit = ReplicatedStorage:WaitForChild("rbxts_include")
    .node_modules["@rbxts"].net.out._NetManaged:WaitForChild("SwordHit")

--// Constants
local ATTACK_RADIUS = 10
local COOLDOWN = 0
local localPlayer = Players.LocalPlayer
local lastSwingTime = 0
local currentHRP = nil
local killAuraRunning = false

--// Utilities
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function onCharacterAdded(character)
    currentHRP = character:WaitForChild("HumanoidRootPart")
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

--// Core Logic
local function getEquippedWeapon()
    local inventoryFolder = ReplicatedStorage:FindFirstChild("Inventories")
    if not inventoryFolder then return nil end

    local playerInventory = inventoryFolder:FindFirstChild(localPlayer.Name)
    if not playerInventory then return nil end

    local weapons = {
        "wood_sword", "stone_sword", "iron_sword", "diamond_sword", "emerald_sword",
        "void_sword", "light_sword", "infernal_saber", "rageblade", "ice_sword",
        "double_edge_sword", "twirlblade", "big_wood_sword", "big_wooden_sword",
        "bacon_blade", "pirate_sword", "hotdog_bat", "banana_sword",
        "wood_dao", "stone_dao", "iron_dao", "diamond_dao", "emerald_dao",
        "jade_hammer", "mass_hammer", "frosty_hammer", "noxious_sledgehammer",
        "great_hammer", "paragon_hammer",
        "wood_axe", "stone_axe", "iron_axe", "diamond_axe", "battle_axe", "void_axe",
        "wood_pickaxe", "stone_pickaxe", "iron_pickaxe", "diamond_pickaxe",
        "laser_pickaxe", "miner_pickaxe", "pirate_shovel", "handheld_drill",
        "scythe", "golden_scythe", "nocturne_scythe",
        "deathbloom_dagger",
        "wood_bow", "wood_crossbow", "tactical_crossbow", "golden_bow",
        "feather_bow", "life_bow", "life_crossbow", "demon_empress_bow",
        "vanessa_bow", "demon_express_crossbow",
        "rocket_launcher", "carrot_cannon", "grenade_launcher", "paint_shotgun",
        "boba_blaster", "flamethrower", "tornado_launcher", "snowball_launcher",
        "party_hat_launcher", "party_popper", "firework_rocket_launcher",
        "impulse_gun", "condiment_gun",
        "frying_pan", "toy_hammer", "baguette", "knockback_fish", "bear_claws",
        "baseball_bat", "taser", "stun_grenade", "sticky_firework", "player_vacuum",
        "vacuum", "wizard_staff", "wizard_stick", "raven", "spirit", "spirit_ball",
        "spear", "trumpet", "tnt", "banana_peel", "tesla_trap", "snap_trap",
        "popup_cube", "grapple_hook", "metal_detector", "portal_gun", "bee_net",
        "shears", "charge_shield", "necromancer_staff", "life_headhunter",
        "tactical_headhunter", "ballista", "bananarang"
    }

    for _, name in ipairs(weapons) do
        local found = playerInventory:FindFirstChild(name)
        if found then
            return found
        end
    end
    return nil
end

local function runKillAura()
    killAuraRunning = true
    while killAuraRunning do
        RunService.RenderStepped:Wait()
        if not currentHRP or tick() - lastSwingTime < COOLDOWN then
            continue
        end

        local weapon = getEquippedWeapon()
        if not weapon then continue end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP and getDistance(currentHRP.Position, targetHRP.Position) <= ATTACK_RADIUS then
                    local args = {{
                        chargedAttack = { chargeRatio = 0 },
                        lastSwingServerTimeDelta = 5,
                        entityInstance = player.Character,
                        validate = {
                            selfPosition = { value = currentHRP.Position },
                            targetPosition = { value = targetHRP.Position }
                        },
                        weapon = weapon
                    }}

                    SwordHit:FireServer(unpack(args))
                    lastSwingTime = tick()
                    break
                end
            end
        end
    end
end

-- Control Functions
local function startKillAura()
    if not killAuraRunning then
        task.spawn(runKillAura)
    end
end

local function stopKillAura()
    killAuraRunning = false
end

-- 🛠️ Build the GUI
for i, cat in ipairs(categories) do
    local frame = createDraggableFrame(UDim2.new(0, 30 + (i - 1) * 180, 0, 100))
    createTitle(frame, cat.Name)

    local content = Instance.new("Frame", frame)
    content.Size               = UDim2.new(1, 0, 1, -50)
    content.Position           = UDim2.new(0, 0, 0, 50)
    content.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", content)
    layout.Padding             = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder           = Enum.SortOrder.LayoutOrder

    for _, btnText in ipairs(cat.Buttons) do
        if btnText == "KILLAURA" then
            createButton(content, btnText, function(toggled)
                if toggled then
                    startKillAura()
                else
                    stopKillAura()
                end
            end)
        else
            createButton(content, btnText)
        end
    end
end
