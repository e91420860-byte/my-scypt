
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))

local ui = uiLoader({
    rounding = false, -- Whether certain features get rounded
    theme = 'cherry', -- The theme. Available themes are: cherry, orange, lemon, lime, raspberry, blueberry, grape, watermelon
    smoothDragging = true -- Smooth dragging
})

ui.autoDisableToggles = true -- All toggles will automatically be disabled when the ui is destroyed (window is closed)

local sigma = game:service'VirtualUser'

game:service'Players'.LocalPlayer.Idled:connect(function()
	sigma:CaptureController()
	sigma:ClickButton2(Vector2.new())
end)

local chatbotenabled = false
local autolobbyenabled = false
local cupsenabled = false
local tictactoeenabled = false
local priceisrightenabled = false
local enabled = false

local localPlayer = game:GetService("Players").LocalPlayer
local currentCamera = game:GetService("Workspace").CurrentCamera
local mouse = localPlayer:GetMouse()
local MPS = game:GetService("MarketplaceService")
local http = game:GetService("HttpService")


local function deepClone(original)
    local clone = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            clone[key] = deepClone(value)
        else
            clone[key] = value
        end
    end
    return clone
end

function SendMessageEMBED(url, embed)
    if not url or url == "" then return end
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                }
            }
        }
    }
    local body = http:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

--auto lobby
local lobby = false -- lobby has been made?
local price = 0
local gameType = ""
local ingame = false
local maxwait = 20 -- seconds
local createdat = 0 -- created at: tick()
local games = {
    "SwordFight",
    "PriceIsRight",
    "TicTacToe",
    "Cups",
    --"BlockDrop"
}
local gamepasses = getgenv().gamepassIDs
if #gamepasses == 0 then
    error("u forgot ur gamepasses")
  return
end

local function closePopUp()
    local buttons = game:GetService("Players").LocalPlayer.PlayerGui.BattleResults["Middle Middle"]:GetChildren()
    for _,v in buttons do
        local bg = v:FindFirstChild("Background")
        if bg then
            if v.Visible then
                local close = bg:FindFirstChild("Close")
                local close2 = bg:FindFirstChild("Close2")
                if close then
                    firesignal(close.MouseButton1Click)
                elseif close2 then
                    firesignal(close2.MouseButton1Click)
                end
            end
        end
    end
end

local function createLobby()
    local tickets = {}
    for _,v in pairs(localPlayer.DataSave.Common.FillOnStart.Tickets:GetChildren()) do
        if v.Name ~= "0" then
            tickets[v.Name] = v.Value
        end
    end
    local tmpgames = deepClone(games)
    if enabled == false then
        table.remove(tmpgames, table.find(tmpgames, "SwordFight"))
    end
    if cupsenabled == false then
        table.remove(tmpgames, table.find(tmpgames, "Cups"))
    end
    if tictactoeenabled == false then
        table.remove(tmpgames, table.find(tmpgames, "TicTacToe"))
    end
    if priceisrightenabled == false then
        table.remove(tmpgames, table.find(tmpgames, "PriceIsRight"))
    end

    if #tmpgames <= 0 then
        ui.notify({
            title = 'Auto Lobby',
            message = 'You have no games enabled! Please enable 1 or more games and try again!',
            duration = 3
        })
        return
    end
    gameType = tmpgames[math.random(1, #tmpgames)]
    local possibleprices = {}
    for i,v in pairs(tickets) do
        if v > 0 then
            table.insert(possibleprices, tonumber(i))
        end
    end
    if #possibleprices == 0 then
        ui.notify({
            title = 'Error',
            message = 'You have no tickets! Please purchase tickets and try again!',
            duration = 3
        })
        return
    end
    price = possibleprices[math.random(1, #possibleprices)]
    local gamepasslist = gamepasses[tostring(price)]
    local gamepass = gamepasslist[math.random(1, #gamepasslist)]

    local args = {
        gameType,
        price,
        {
            assetType = "GamePass",
            assetId = gamepass
        },
        true
    }
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteCalls"):WaitForChild("GameSpecific"):WaitForChild("Tickets"):WaitForChild("CreateRoom"):InvokeServer(unpack(args))

    ui.notify({
        title = 'Auto Lobby',
        message = gameType..' Lobby created for '..tostring(price)..' Robux!',
        duration = 3
    })

    lobby = true
    ingame = false
    createdat = tick()

    local embed = {
        ["title"] = "Lobby Created | "..tostring(price).. " Robux",
        ["color"] = 7419530,
        ["fields"] = {
            {
                ["name"] = "Game Type",
                ["value"] = gameType
            }
        },
        ["footer"] = {
            ["text"] = "Account: "..tostring(localPlayer.Name)
        }
    }
    SendMessageEMBED(url, embed)
end

local function destroyLobby()
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteCalls"):WaitForChild("GameSpecific"):WaitForChild("Tickets"):WaitForChild("DestroyRoom"):InvokeServer()
    lobby = false
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote
local ResultMessages = ReplicatedStorage.RemoteCalls.GameSpecific.Battle.ResultMessages -- RemoteEvent

ResultMessages.OnClientEvent:Connect(function(...)
    local args = {...}
    local data = args[2]
    local plr1 = data.collectorInfo
    local plr2 = data.owerInfo
    local amountBet = data.price

    local outcome, fought, color

    if plr2.userId == localPlayer.UserId then
        outcome = "Loss | "..tostring(amountBet).. " Robux Ticket"
        fought = plr1.displayName.."(@"..plr1.userName..") | "..tostring(plr1.userId)
        color = 15548997

        if amountBet > 0 then
            tickets[tostring(amountBet)] = tickets[tostring(amountBet)] - 1
        end
    else
        outcome = "Win | "..tostring(amountBet/10*6).. " Robux ("..tostring(amountBet).." B/T)"
        fought = plr2.displayName.."(@"..plr2.userName..") | "..tostring(plr2.userId)
        color = 5763719
    end

    local embed = {
        ["title"] = outcome,
        ["color"] = color,
        ["fields"] = {
            {
                ["name"] = "Opponent",
                ["value"] = fought
            }
        },
        ["footer"] = {
            ["text"] = "Account: "..tostring(localPlayer.Name)
        }
    }
    SendMessageEMBED(url, embed)

    ingame = false
    task.wait(5)
    closePopUp()
    if autolobbyenabled then
        createLobby()
    end
end)

local Players = game:GetService("Players")
local ChangeSceneAndPlay = Players.LocalPlayer.PlayerScripts.General.MusicPlayer.ChangeSceneAndPlay

ChangeSceneAndPlay.Event:Connect(function(sceneName)
    if sceneName == "Battle" then
        local embed = {
            ["title"] = "Game Started | "..gameType,
            ["color"] = 10181046,
            ["footer"] = {
                ["text"] = "Account: "..tostring(localPlayer.Name)
            }
        }
        SendMessageEMBED(url, embed)

        lobby = false
        ingame = true
    end
end)

-- lightweight loop for maxwait
task.spawn(function()
    while task.wait(2) do
        if not autolobbyenabled then continue end
        if ingame then continue end

        -- don't create a new lobby if you're already matched
        local quitBtn = localPlayer.PlayerGui.WaitingForOpponent["Bottom Middle"].WaitingForOpponent.Background.Quit_Off
        if quitBtn.Visible then continue end

        -- remake if lobby expired
        if lobby and tick() - createdat >= maxwait then
            destroyLobby()
            createLobby()
        end
    end
end)
--auto lobby

-- auto cups
local numberTable = {1,2,3,4,5}
local diamondCups = {}

local shouldreset = false
local resetprogress = 0

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote
local CupsShowDiamondSpot = ReplicatedStorage.RemoteCalls.GameSpecific.Battle.CupsShowDiamondSpot -- RemoteEvent
local CupsMove = ReplicatedStorage.RemoteCalls.GameSpecific.Battle.CupsMove -- RemoteEvent

CupsShowDiamondSpot.OnClientEvent:Connect(function(...)
    local args = {...}
    if #args ~= 5 then return end -- if #args == 5 then its revealing it at the start or at the end

    if shouldreset then
        resetprogress = resetprogress + 1
        if resetprogress == 5 then
            numberTable = {1,2,3,4,5}
            diamondCups = {}
            resetprogress = 0
            shouldreset = false
            return
        end
    end

    local cup = args[2]
    local diamond = args[3]

    if diamond then
        table.insert(diamondCups, cup)
    end
end)

CupsMove.OnClientEvent:Connect(function(...)
    local args = {...}

    for _,datatable in pairs(args[2]) do
        local A = table.find(numberTable, datatable[1])
        local B = table.find(numberTable, datatable[2])
        tmp = numberTable[A]
        numberTable[A] = numberTable[B]
        numberTable[B] = tmp
    end
end)

game.Players.LocalPlayer.PlayerGui.Cups.ChildAdded:Connect(function(item)
    if not cupsenabled then return end
    if not (item.Name == "Bottom Middle Play Template" or item.Name == "Bottom Middle Play") then
        return
    end
    task.wait(2)
    local position1 = table.find(numberTable, diamondCups[1])
    local position2 = table.find(numberTable, diamondCups[2])
    local chosenpos = nil
    if game.Players.LocalPlayer.PlayerGui.Cups["Bottom Middle Play"].Buttons:FindFirstChild(position1) then
        chosenpos = position1
    else
        chosenpos = position2
    end
    firesignal(game.Players.LocalPlayer.PlayerGui.Cups["Bottom Middle Play"].Buttons[tostring(chosenpos)].MouseButton1Click)
end)

-- auto cups

-- chat bot
local function sendChat(msg)
    local TextChatService = game:GetService("TextChatService")
    local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if channel and channel.ClassName == "TextChannel" then
        channel:SendAsync(msg)
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local event = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if event and event:FindFirstChild("SayMessageRequest") then
        event.SayMessageRequest:FireServer(msg, "All")
        return
    end

    warn("No supported chat system found")
end

local function splitCamelCase(str)
    local spaced = str:gsub("(%l)(%u)", "%1 %2")
    return spaced
end

local function formatMessage(msg)
    local lgtype = splitCamelCase(gameType)

    msg = string.gsub(msg, "{game}", string.lower(lgtype))
    msg = string.gsub(msg, "{gameCAPS}", string.upper(lgtype))
    msg = string.gsub(msg, "{price}", tostring(price))
    return msg
end

delay = 3


task.spawn(function()
    local lastsend = tick()
    while task.wait(1) do
        print(delay)
        if not ((tick() - lastsend) >= delay) then
            continue
        end

        if chatbotenabled == false or autolobbyenabled == false then
            continue
        end

        if (not ingame) and lobby and autobegmessages and #autobegmessages > 0 then
            local msg = autobegmessages[math.random(1, #autobegmessages)]
            msg = formatMessage(msg)

            sendChat(msg)
            lastsend = tick()
        end
    end
end)
-- chat bot

-- tic tac toe bot with fixed minimax + move coords

local mainboard = { -- board[y][x]
    {" ", " ", " "},
    {" ", " ", " "},
    {" ", " ", " "}
}

local function outputboard(board)
    local text = board[1][1] .. "|" .. board[1][2] .. "|" .. board[1][3] ..
        "\n-+-+-\n" .. board[2][1] .. "|" .. board[2][2] .. "|" .. board[2][3] ..
        "\n-+-+-\n" .. board[3][1] .. "|" .. board[3][2] .. "|" .. board[3][3]
    return text .. "\n~~~~~\n"
end

-- winner detection
local function won(board)
    for y = 1, 3 do
        if board[y][1] ~= " " and board[y][1] == board[y][2] and board[y][2] == board[y][3] then
            return board[y][1]
        end
    end
    for x = 1, 3 do
        if board[1][x] ~= " " and board[1][x] == board[2][x] and board[2][x] == board[3][x] then
            return board[1][x]
        end
    end
    if board[1][1] ~= " " and board[1][1] == board[2][2] and board[2][2] == board[3][3] then
        return board[1][1]
    end
    if board[1][3] ~= " " and board[1][3] == board[2][2] and board[2][2] == board[3][1] then
        return board[1][3]
    end
    return false
end

local function isfull(board)
    for y = 1, 3 do
        for x = 1, 3 do
            if board[y][x] == " " then
                return false
            end
        end
    end
    return true
end

-- expand: generate moves with coordinates
local function expand(board, player)
    local moves = {}
    for y = 1, 3 do
        for x = 1, 3 do
            if board[y][x] == " " then
                local boardcopy = deepClone(board)
                boardcopy[y][x] = player
                table.insert(moves, { board = boardcopy, y = y, x = x })
            end
        end
    end
    return moves
end

-- depth-aware utility
local function terminal_score(board, depth)
    local w = won(board)
    if w == "x" then
        return 1 - depth * 0.01
    elseif w == "o" then
        return -1 + depth * 0.01
    else
        return 0
    end
end

-- minimax with alpha-beta pruning
local function minimax(board, player, depth, alpha, beta)
    local w = won(board)
    if w or isfull(board) then
        return terminal_score(board, depth)
    end

    if player == "x" then
        local best = -math.huge
        local children = expand(board, "x")
        for _, child in ipairs(children) do
            local score = minimax(child.board, "o", depth + 1, alpha, beta)
            if score > best then best = score end
            if best > alpha then alpha = best end
            if beta <= alpha then break end
        end
        return best
    else
        local best = math.huge
        local children = expand(board, "o")
        for _, child in ipairs(children) do
            local score = minimax(child.board, "x", depth + 1, alpha, beta)
            if score < best then best = score end
            if best < beta then beta = best end
            if beta <= alpha then break end
        end
        return best
    end
end

-- choose best move directly
local function bestMove(board, player)
    local children = expand(board, player)

    local bestScore = (player == "x") and -math.huge or math.huge
    local bestY, bestX = nil, nil

    for _, child in ipairs(children) do
        local score = minimax(child.board, (player == "x") and "o" or "x", 0, -math.huge, math.huge)
        if player == "x" then
            if score > bestScore then
                bestScore = score
                bestY, bestX = child.y, child.x
            end
        else
            if score < bestScore then
                bestScore = score
                bestY, bestX = child.y, child.x
            end
        end
    end

    return bestY, bestX, bestScore
end

-- UI helpers
local x = "🇽"
local o = "⭕"

local function updateboard()
    local board = game.Players.LocalPlayer.PlayerGui.TicTacToe["Bottom Middle"].Buttons
    for i=1,3 do
        if board["Drop_"..tostring(i)].TextLabel.Text == x then
            mainboard[1][i] = "x"
        elseif board["Drop_"..tostring(i)].TextLabel.Text == o then
            mainboard[1][i] = "o"
        else
            mainboard[1][i] = " "
        end
    end

    for i=4,6 do
        if board["Drop_"..tostring(i)].TextLabel.Text == x then
            mainboard[2][i-3] = "x"
        elseif board["Drop_"..tostring(i)].TextLabel.Text == o then
            mainboard[2][i-3] = "o"
        else
            mainboard[2][i-3] = " "
        end
    end

    for i=7,9 do
        if board["Drop_"..tostring(i)].TextLabel.Text == x then
            mainboard[3][i-6] = "x"
        elseif board["Drop_"..tostring(i)].TextLabel.Text == o then
            mainboard[3][i-6] = "o"
        else
            mainboard[3][i-6] = " "
        end
    end
end

game.Players.LocalPlayer.PlayerGui.TicTacToe.ChildAdded:Connect(function(item)
    if not tictactoeenabled then return end
    task.wait(1)

    if (item.Name ~= "Bottom Middle Template") and (item.Name ~= "Bottom Middle") then return end

    -- snapshot
    updateboard()

    -- decide my mark
    local whatami = "x"
    if game.Players.LocalPlayer.PlayerGui.TicTacToe["Top Middle"].RoundInfo.TeamColorRed.Visible == true then
        whatami = "o"
    end

    local y, x, _ = bestMove(mainboard, whatami)
    if not y or not x then return end

    local idx = (y - 1) * 3 + x
    local buttons = game.Players.LocalPlayer.PlayerGui.TicTacToe["Bottom Middle"].Buttons
    local tile = buttons["Drop_" .. tostring(idx)]
    if tile and tile.MouseButton1Click then
        firesignal(tile.MouseButton1Click)
    end
end)


--price is right

local function getarena()
    local arena = localPlayer.DataSave.DontSave.MostRecentArena.Value
    return arena
end

local function findclosestdata(asset)
    local a = request({
        Url = "https://economy.roproxy.com/v1/assets/"..asset.."/resale-data",
        Method = "GET",
        Headers = {["Content-Type"] = "application/json"},
    })

    local http = game:GetService("HttpService")


    local success, data = pcall(function()
        return http:JSONDecode(a.Body)
    end)

    if not success then
        return nil
    end


    if not data.priceDataPoints or #data.priceDataPoints == 0 then
        return nil
    end

    local arena = getarena()
    local important = arena.ArenaTemplate.Important
    local lastupdated = important.LastUpdated
    local SGUI = lastupdated.SurfaceGui
    local TLBL = SGUI.TextLabel
    local txt = TLBL.Text

    local lastupdatedText = txt
    local lastupdated = string.split(string.split(string.split(lastupdatedText, ": ")[2], ")")[1], "/")
    lastupdated = {lastupdated[3], lastupdated[1], lastupdated[2]}

    local lastupdatedStamp = os.time({
        year = lastupdated[1],
        month = lastupdated[2],
        day = lastupdated[3]
    })

    local closest = nil
    local closestval = nil
    local smallestDiff = math.huge

    for _, v in pairs(data.priceDataPoints) do
        local dateStr = v.date:split("T")[1] -- "YYYY-MM-DD"
        local y, m, d = table.unpack(dateStr:split("-"))
        y, m, d = tonumber(y), tonumber(m), tonumber(d)

        local timestamp = os.time({year = y, month = m, day = d})
        local diff = math.abs(lastupdatedStamp - timestamp)

        if diff < smallestDiff then
            smallestDiff = diff
            closest = {y, m, d}
            closestval = v.value
        end
    end

    return closestval
end


local function higherorlower()
    local arena = getarena()
    local assetid = string.split(string.split(arena.ArenaTemplate.Important.ItemImage.SurfaceGui.ImageLabel.Image, "id=")[2], "&w")[1]
    local val = findclosestdata(assetid)
    local guessprice = arena.ArenaTemplate.Important.GuessPrice.SurfaceGui.TextLabel.Text
    guessprice = string.split(guessprice, "$")[2]
    guessprice = string.gsub(guessprice, ",", "")
    guessprice = tonumber(guessprice)
    local higher = val > guessprice
    if higher == true then
        firesignal(localPlayer.PlayerGui.PriceIsRight["Bottom Middle"].Buttons.Higher.MouseButton1Click)
    else
        firesignal(localPlayer.PlayerGui.PriceIsRight["Bottom Middle"].Buttons.Lower.MouseButton1Click)
    end
end

local watcher = localPlayer.PlayerGui.PriceIsRight.ChildAdded:Connect(function()
    if priceisrightenabled then
        higherorlower()
    end
end)
-- price is right

-- sword fight bot
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local maxdist = 9
local otherdist = 75
local speed = 1

-- === Auto-swing + touch hits ===
game:GetService("RunService").RenderStepped:Connect(function()
    if enabled == true then
        local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            tool:Activate()

            local p = Players:GetPlayers()
            for i = 2, #p do
                local v = p[i].Character
                if v
                    and v:FindFirstChild("Humanoid")
                    and v.Humanoid.Health > 0
                    and v:FindFirstChild("HumanoidRootPart")
                    and localPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position) <= maxdist
                then
                    for _, part in next, v:GetChildren() do
                        if part:IsA("BasePart") then
                            firetouchinterest(tool.Handle, part, 0)
                            firetouchinterest(tool.Handle, part, 1)
                        end
                    end
                end
            end
        end
    end
end)

-- === Targeting ===
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = otherdist

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= localPlayer then
            local char = v.Character
            if char
                and char:FindFirstChild("Humanoid")
                and char.Humanoid.Health > 0
                and char:FindFirstChild("HumanoidRootPart")
                and char:FindFirstChild("Head")
                and not char:FindFirstChildOfClass("ForceField")
            then
                local myhrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                local vhrp  = char:FindFirstChild("HumanoidRootPart")
                if myhrp and vhrp then
                    local magnitude = (vhrp.Position - myhrp.Position).Magnitude
                    if magnitude < shortestDistance then
                        closestPlayer = v
                        shortestDistance = magnitude
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- === Local humanoid setup ===
local stateType = Enum.HumanoidStateType

local function getLocalHumanoid()
    local char = localPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

do
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:SetStateEnabled(stateType.FallingDown, false)
    humanoid:SetStateEnabled(stateType.Ragdoll, false)
end

-- === Orbiting + Jump mirroring ===
local strafeAngle = 0
local strafeDirection = 1 -- 1 = clockwise, -1 = counter-clockwise
local strafeSpeed = 2     -- radians per second (orbit speed)

-- NEW: bind to target's StateChanged so we jump the moment they do
local boundTarget
local boundConn
local lastJumpAt = 0

local function unbindTarget()
    if boundConn then
        boundConn:Disconnect()
        boundConn = nil
    end
    boundTarget = nil
end

local function bindTarget(targetPlayer)
    unbindTarget()
    boundTarget = targetPlayer
    if not targetPlayer then return end

    local targetHum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetHum then return end

    boundConn = targetHum.StateChanged:Connect(function(_, newState)
        if newState ~= stateType.Jumping and newState ~= stateType.Freefall then return end

        local myChar = localPlayer.Character
        local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local theirHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not (myHum and myHRP and theirHRP) then return end

        -- distance gate
        local dist = (myHRP.Position - theirHRP.Position).Magnitude
        if dist > (maxdist + 2) then return end

        -- small cooldown so we don't spam if states flap
        local t = tick()
        if t - lastJumpAt < 0.15 then return end
        lastJumpAt = t

        -- If grounded, normal jump flag; otherwise force the state as a backup
        if myHum.FloorMaterial ~= Enum.Material.Air then
            myHum.Jump = true
        else
            myHum:ChangeState(stateType.Jumping)
        end
    end)
end

task.spawn(function()
    local lastTime = tick()
    while true do
        RunService.Heartbeat:Wait()
        local dt = tick() - lastTime
        lastTime = tick()

        local lc = localPlayer.Character
        local closest = enabled and getClosestPlayer() or nil

        -- (Re)bind jump mirroring to the current closest target
        if closest ~= boundTarget then
            bindTarget(closest)
        end
        if not enabled and boundTarget then
            unbindTarget()
        end

        if lc and lc.PrimaryPart and closest and enabled then
            local TargetHRP = closest.Character and closest.Character:FindFirstChild("HumanoidRootPart")
            local HRP = lc:FindFirstChild("HumanoidRootPart")
            local hum = getLocalHumanoid()
            if not (TargetHRP and HRP and hum) then
                continue
            end

            hum.AutoRotate = false

            -- Flat look direction (ignore Y)
            local flatDirection = Vector3.new(
                TargetHRP.Position.X - HRP.Position.X,
                0,
                TargetHRP.Position.Z - HRP.Position.Z
            ).Unit

            -- Apply sword angle offset (25° yaw)
            local angleOffset = CFrame.Angles(0, math.rad(25), 0)

            -- Smooth rotation toward enemy
            HRP.CFrame = HRP.CFrame:Lerp(
                CFrame.new(HRP.Position, HRP.Position + flatDirection) * angleOffset,
                speed
            )

            -- Orbit at desired range
            local desiredDistance = maxdist - 1
            strafeAngle = strafeAngle + (strafeDirection * strafeSpeed * dt)
            local orbitX = math.cos(strafeAngle) * desiredDistance
            local orbitZ = math.sin(strafeAngle) * desiredDistance
            local targetPos = TargetHRP.Position + Vector3.new(orbitX, 0, orbitZ)
            hum:MoveTo(targetPos)

            -- Occasionally flip strafe direction (less predictable)
            if math.random(1, 400) == 1 then
                strafeDirection = -strafeDirection
            end
        elseif lc then
            local hum = getLocalHumanoid()
            if hum then hum.AutoRotate = true end
        end
    end
end)
-- sword fight bot


local window = ui.newWindow({
    text = 'ttokenn.xyz | Double Down', -- Title of window
    resize = true, -- Ability to resize
    size = Vector2.new(550, 376), -- Window size, accepts UDim2s and Vector2s
    position = nil -- Custom position, defaults to roughly the bottom right corner
})

local menu = window:addMenu({
    text = 'Main' -- Title of menu
})
do
    -- Menus have sections which house all the controls
    local section = menu:addSection({
        text = 'Auto Play', -- Title of section
        side = 'auto', -- Side of the menu that the section is placed on. Defaults to 'auto', but can be 'left' or 'right'
        showMinButton = true, -- Ability to minimize this section. Defaults to true
    })

    do
        local AutoSwordFight = section:addToggle({
            text = 'Sword Fight',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoSwordFight:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Sword Fight',
                message = 'Auto Sword Fight was set to:   ' .. tostring(newState),
                duration = 3
            })
            enabled = newState
        end)


        local AutoPriceIsRight = section:addToggle({
            text = 'Price Is Right',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoPriceIsRight:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Price Is Right',
                message = 'Auto Price Is Right was set to:   ' .. tostring(newState),
                duration = 3
            })
            priceisrightenabled = newState
        end)

        AutoPriceIsRight:setTooltip("May be inaccurate due to Roblox limtations!")


        local AutoTTT = section:addToggle({
            text = 'Tic Tac Toe',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoTTT:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Tic Tac Toe',
                message = 'Auto Tic Tac Toe was set to:   ' .. tostring(newState),
                duration = 3
            })
            tictactoeenabled = newState
        end)


        local AutoCups = section:addToggle({
            text = 'Cups',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoCups:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Cups',
                message = 'Auto Cups was set to:   ' .. tostring(newState),
                duration = 3
            })
            cupsenabled = newState
        end)
    end

    local section = menu:addSection({
        text = 'Auto Lobby',
        side = 'right',
        showMinButton = true
    })
    do
        local AutoLobby = section:addToggle({
            text = 'Auto Create Lobby',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoLobby:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Lobby',
                message = 'Auto Lobby was toggled to ' .. tostring(newState),
                duration = 3
            })
            autolobbyenabled = newState
            if autolobbyenabled and (not ingame) and (not lobby) then
                createLobby()
            elseif autolobyenabled == false then
                lobby = false
                destroyLobby()
            end
        end)

        section:addSlider({
            text = 'Lobby Recreate Delay',
            min = 20,
            max = 600,
            step = 1,
        }, function(newValue)
            maxwait = newValue
        end)
    end
    local section = menu:addSection({
        text = 'Auto Chat',
        side = 'right',
        showMinButton = true
    })
    do
        local AutoChat = section:addToggle({
            text = 'Auto Chat Bot',
            state = false -- Starting state of the toggle - doesn't automatically call the callback
        })

        AutoChat:bindToEvent('onToggle', function(newState) -- Call a function when toggled
            ui.notify({
                title = 'Auto Chat Bot',
                message = 'Auto Chat Bot was toggled to ' .. tostring(newState),
                duration = 3
            })
            chatbotenabled = newState
        end)
        AutoChat:setTooltip("Only works with Auto Lobby enabled!")

        section:addSlider({
            text = 'Chat Delay',
            min = 3,
            max = 150,
            step = 1,
            val = 30
        }, function(newValue)
            delay = newValue
        end)
    end
end
