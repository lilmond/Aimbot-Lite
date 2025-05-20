--[[


 ██▓███   ▒█████   ██▓   ▓██   ██▓ ███▄ ▄███▓ ▒█████   ██▀███   ██▓███   ██░ ██  ██▓ ▄████▄  
▓██░  ██▒▒██▒  ██▒▓██▒    ▒██  ██▒▓██▒▀█▀ ██▒▒██▒  ██▒▓██ ▒ ██▒▓██░  ██▒▓██░ ██▒▓██▒▒██▀ ▀█  
▓██░ ██▓▒▒██░  ██▒▒██░     ▒██ ██░▓██    ▓██░▒██░  ██▒▓██ ░▄█ ▒▓██░ ██▓▒▒██▀▀██░▒██▒▒▓█    ▄ 
▒██▄█▓▒ ▒▒██   ██░▒██░     ░ ▐██▓░▒██    ▒██ ▒██   ██░▒██▀▀█▄  ▒██▄█▓▒ ▒░▓█ ░██ ░██░▒▓▓▄ ▄██▒
▒██▒ ░  ░░ ████▓▒░░██████▒ ░ ██▒▓░▒██▒   ░██▒░ ████▓▒░░██▓ ▒██▒▒██▒ ░  ░░▓█▒░██▓░██░▒ ▓███▀ ░
▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▓  ░  ██▒▒▒ ░ ▒░   ░  ░░ ▒░▒░▒░ ░ ▒▓ ░▒▓░▒▓▒░ ░  ░ ▒ ░░▒░▒░▓  ░ ░▒ ▒  ░
░▒ ░       ░ ▒ ▒░ ░ ░ ▒  ░▓██ ░▒░ ░  ░      ░  ░ ▒ ▒░   ░▒ ░ ▒░░▒ ░      ▒ ░▒░ ░ ▒ ░  ░  ▒   
░░       ░ ░ ░ ▒    ░ ░   ▒ ▒ ░░  ░      ░   ░ ░ ░ ▒    ░░   ░ ░░        ░  ░░ ░ ▒ ░░        
             ░ ░      ░  ░░ ░            ░       ░ ░     ░               ░  ░  ░ ░  ░ ░      
                          ░ ░                                                       ░        

]]--

-- Aimbot Lite V2
-- Made by https://github.com/lilmond
-- Source: https://github.com/lilmond/Aimbot-Lite

-- MAIN SETTINGS:
getgenv().AIMBOT_FORCE_STOP = false -- Set this to true to forcefully stop the script.
getgenv().AIMBOT_ACTIVATE_KEY = "leftshift"
getgenv().AIMBOT_TOGGLE_KEY = "l" -- Button that when pressed, enables or disables aimbot.
getgenv().AIMBOT_KEEP_AIMLOCK = false -- Keep aim locking at a target until activate key is pressed again.

-- WHITELISTS:
-- Set AIMBOT_TARGET_WHITE to true to target only whitelisted players.
-- This is by default set to false which will prevent whitelisted players from being targetted.
-- Note: Write the AIMBOT_WHITELISTS properly as any mistake will cause the entire script not to work.
getgenv().AIMBOT_TARGET_WHITE = false
getgenv().AIMBOT_WHITELISTS = {

}

-- TARGET SETTINGS:
getgenv().AIMBOT_TARGET_PART = "Head"
getgenv().AIMBOT_VERIFY_ONSCREEN = true -- Target players only within your screen, doesn't matter if walls are blocking them, unless you enable AIMBOT_VERIFY_WALLS.
getgenv().AIMBOT_VERIFY_WALLS = false -- Verify if target is being blocked by a wall or any other parts. NOTE: This is buggy as hell due to the way Roblox raycasting works, I don't wanna use Whitelist RaycastFilterType since it would require me using workspace:GetDescendats() which would ruin the efficiency of the script.
getgenv().AIMBOT_EXCLUDE_TEAM = false -- Prevents players within your team from being targetted.
getgenv().AIMBOT_MAX_DISTANCE = 1000
getgenv().AIMBOT_IGNORE_DEAD = true -- Ignore players with 0 health.

-- Predicts the future position of player based on their character's velocity.
-- Please note that this may not be accurate.
-- Set AIMBOT_PREDICT_MULT accordingly, especially when you're laggy.
getgenv().AIMBOT_PREDICT_POSITION = false
getgenv().AIMBOT_PREDICT_MULT = 0.1

-- Target Types:
-- 1 = Nearest player
-- 2 = Furthest player
-- 3 = Lowest HP player
-- 4 = Highest HP player
getgenv().AIMBOT_TARGET_TYPE = 1

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local AIMBOT_ENABLED = true
local ACTIVATE_KEY_HELD = false

local function isWhitelisted(playerName)
    for i, v in pairs(getgenv().AIMBOT_WHITELISTS) do
        if string.lower(v) == string.lower(playerName) then
            return true
        end
    end

    return false
end

local function isTargetBlockedByWall(targetPart, targetCharacter)
    local origin = Camera.CFrame.Position + Camera.CFrame.LookVector * 0.5 -- slightly in front of camera
    local direction = (targetPart.Position - origin)

    local blacklist = {}

    -- Exclude all other player characters
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(blacklist, player.Character)
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = blacklist
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)

    if result then
        if result.Instance:IsDescendantOf(targetCharacter) then
            return false -- hit target itself, not blocked
        end
        return true -- blocked by something else
    end

    return false -- nothing hit, no wall
end

local function findTargetCharacter()
    local targetCharacter = nil
    local lastNumber = nil

    local targetType = getgenv().AIMBOT_TARGET_TYPE
    local maxDistance = getgenv().AIMBOT_MAX_DISTANCE
    local targetPartName = getgenv().AIMBOT_TARGET_PART
    local targetWhite = getgenv().AIMBOT_TARGET_WHITE
    local ignoreDead = getgenv().AIMBOT_IGNORE_DEAD
    local verifyOnScreen = getgenv().AIMBOT_VERIFY_ONSCREEN
    local verifyWalls = getgenv().AIMBOT_VERIFY_WALLS

    for i, player in pairs(Players:GetPlayers()) do
        if player == Player then continue end

        if getgenv().AIMBOT_EXCLUDE_TEAM then
            if player.Team == Player.Team then continue end
        end

        local playerWhitelisted = isWhitelisted(player.Name)
        if targetWhite then
            if (not playerWhitelisted) then continue end
        else
            if playerWhitelisted then continue end
        end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then continue end

        if (ignoreDead and humanoid.Health <= 0) then continue end
        
        local targetPart = character:FindFirstChild(targetPartName)
        if not targetPart then continue end

        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude

        if distance >= maxDistance then continue end

        if verifyOnScreen then
            if not (select(2, Camera:WorldToViewportPoint(targetPart.Position))) then continue end
        end
        
        if verifyWalls then
            if isTargetBlockedByWall(targetPart, character) then continue end
        end

        if targetType == 1 then
            if (lastNumber == nil or distance <= lastNumber) then
                targetCharacter = character
                lastNumber = distance
            end
        elseif targetType == 2 then
            if (lastNumber == nil or distance >= lastNumber) then
                targetCharacter = character
                lastNumber = distance
            end
        elseif targetType == 3 then
            if (lastNumber == nil or humanoid.Health <= lastNumber) then
                targetCharacter = character
                lastNumber = humanoid.Health
            end
        elseif targetType == 4 then
            if (lastNumber == nil or humanoid.Health >= lastNumber) then
                targetCharacter = character
                lastNumber = humanoid.Health
            end
        end
    end

    return targetCharacter
end

local function activateAimbot()
    local targetCharacter = findTargetCharacter()
    if (not targetCharacter) then return end

    local targetPart = targetCharacter:FindFirstChild(getgenv().AIMBOT_TARGET_PART)

    getgenv().CURRENT_LOCK_CON = RunService.RenderStepped:Connect(function()
        if ((not ACTIVATE_KEY_HELD) or (getgenv().AIMBOT_FORCE_STOP) or (not AIMBOT_ENABLED)) then
            getgenv().CURRENT_LOCK_CON:Disconnect()
            return
        end

        local targetPosition = nil

        if getgenv().AIMBOT_PREDICT_POSITION then
            local partVelocity = targetPart.Velocity
            targetPosition = CFrame.new(Camera.CFrame.Position, targetPart.Position + (partVelocity * getgenv().AIMBOT_PREDICT_MULT))
        else
            targetPosition = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end

        Camera.CFrame = targetPosition
    end)
end

local function startKeyListener()
    if getgenv().AIMBOT_RUNNING then return end
    getgenv().AIMBOT_RUNNING = true

    if getgenv().AIMBOT_KEY_LISTENER1 then
        getgenv().AIMBOT_KEY_LISTENER1:Disconnect()
    end

    if getgenv().AIMBOT_KEY_LISTENER2 then
        getgenv().AIMBOT_KEY_LISTENER2:Disconnect()
    end

    getgenv().AIMBOT_KEY_LISTENER1 = UserInputService.InputBegan:Connect(function(key, gameProcessed)
        if getgenv().AIMBOT_FORCE_STOP then
            getgenv().AIMBOT_KEY_LISTENER1:Disconnect()
            return
        end

        local keyString = string.lower(key.KeyCode.Name)

        if (keyString == string.lower(getgenv().AIMBOT_TOGGLE_KEY) and (not gameProcessed)) then
            if AIMBOT_ENABLED then
                AIMBOT_ENABLED = false
            else
                AIMBOT_ENABLED = true
            end
            print(`Toggled Aimbot to: {AIMBOT_ENABLED}`)
        elseif (keyString == string.lower(getgenv().AIMBOT_ACTIVATE_KEY) and AIMBOT_ENABLED) then
            if getgenv().AIMBOT_KEEP_AIMLOCK then
                if getgenv().CURRENT_LOCK_CON then
                    getgenv().CURRENT_LOCK_CON:Disconnect()
                    getgenv().CURRENT_LOCK_CON = nil
                    return
                end
            end

            ACTIVATE_KEY_HELD = true
            activateAimbot()
        end
    end)

    getgenv().AIMBOT_KEY_LISTENER2 = UserInputService.InputEnded:Connect(function(key, gameProcessed)
        if getgenv().AIMBOT_FORCE_STOP then
            getgenv().AIMBOT_KEY_LISTENER2:Disconnect()
            return
        end

        local keyString = string.lower(key.KeyCode.Name)

        if (keyString == string.lower(getgenv().AIMBOT_ACTIVATE_KEY) and (not getgenv().AIMBOT_KEEP_AIMLOCK)) then
            ACTIVATE_KEY_HELD = false
        end
    end)
end

if (not getgenv().AIMBOT_FORCE_STOP) then
    startKeyListener()
else
    getgenv().AIMBOT_RUNNING = false
end
