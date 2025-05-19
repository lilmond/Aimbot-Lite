local ignoreteams = false
local togglekey = "leftshift"
local enablekey = "l"
local maxdistance = 1000
local aimbotenabled = true

local camera = game:GetService("Workspace").CurrentCamera
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")

uis.InputBegan:Connect(function(key, paused)
    local keycode = key.KeyCode
    local keystring = keycode.Name:lower()
    
    if (keystring == togglekey) and (aimbotenabled == true) then
        local nearest_distance = maxdistance
        local target_part = nil

        for i, player in pairs(players:GetPlayers()) do
            if player == players.LocalPlayer then continue end
            if ignoreteams then
                if player.Team == players.LocalPlayer.Team then continue end
            end

            local character = player.Character
            if not character then continue end
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if not humanoid then continue end
            if humanoid.Health <= 0 then continue end
            local wanted_part = character:FindFirstChild("Head")
            if not wanted_part then continue end
            if not (select(2, camera:WorldToViewportPoint(wanted_part.Position))) then continue end

            local distance = (camera.CFrame.Position - wanted_part.Position).Magnitude
            if (distance < nearest_distance) then
                nearest_distance = distance
                target_part = wanted_part
            end
        end

        if target_part then
            while true do
                local held = uis:IsKeyDown(keycode)
                if not held then break end
                if target_part == nil then break end
                camera.CFrame = CFrame.new(camera.CFrame.Position, target_part.Position)
                task.wait()
            end
        end

    elseif (keystring == enablekey) then
        if paused then return end
        if aimbotenabled then
            aimbotenabled = false
        else
            aimbotenabled = true
        end
    end
end)
