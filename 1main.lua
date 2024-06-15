local dfpwm = require("cc.audio.dfpwm")
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()
local running = false
local currentPlayback
local queue = {}

if #speakers == 0 then
    print("No speakers found")
    return
end

local function listFiles()
    local files = fs.list("")
    local dfpwmFiles = {}
    for _, file in ipairs(files) do
        if file:sub(-6) == ".dfpwm" then
            table.insert(dfpwmFiles, file)
        end
    end
    return dfpwmFiles
end

local function playFile(filename)
    local file = fs.open(filename, "rb")
    if not file then
        print("Audio file not found")
        return
    end

    running = true
    while running do
        local chunk = file.read(16 * 1024)
        if not chunk then
            break
        end

        local buffer = decoder(chunk)
        
        for _, speaker in pairs(speakers) do
            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end

    file.close()
    running = false
end

local function stopPlayback()
    running = false
    if currentPlayback then
        currentPlayback.terminate()
    end
end

local function drawGUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("DFPWM Player")
    print("------------")
    print("Files:")
    local files = listFiles()
    for i, file in ipairs(files) do
        print(i .. ". " .. file)
    end
    print("------------")
    print("Queue:")
    for i, file in ipairs(queue) do
        print(i .. ". " .. file)
    end
    print("------------")
    print("[Play] [Stop] [Add to Queue] [Clear Queue]")
end

local function handleUserInput()
    while true do
        drawGUI()
        local event, button, x, y = os.pullEvent("mouse_click")
        if y == 18 then
            if x >= 1 and x <= 5 then
                if #queue > 0 then
                    local filename = table.remove(queue, 1)
                    if currentPlayback then
                        currentPlayback.terminate()
                    end
                    currentPlayback = parallel.waitForAny(function() playFile(filename) end)
                end
            elseif x >= 7 and x <= 11 then
                stopPlayback()
            elseif x >= 13 and x <= 23 then
                print("Enter file number to add to queue:")
                local input = read()
                local fileIndex = tonumber(input)
                if fileIndex and fileIndex > 0 and fileIndex <= #listFiles() then
                    table.insert(queue, listFiles()[fileIndex])
                end
            elseif x >= 25 and x <= 35 then
                queue = {}
            end
        end
    end
end

parallel.waitForAny(handleUserInput)
