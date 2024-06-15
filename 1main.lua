local dfpwm = require("cc.audio.dfpwm")
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()
local running = false
local currentPlayback

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
    print("Enter the number of the file to play, or 'stop' to stop playback:")
end

local function handleUserInput()
    while true do
        drawGUI()
        local input = read()
        if input == "stop" then
            running = false
            if currentPlayback then
                currentPlayback.terminate()
            end
        else
            local fileIndex = tonumber(input)
            if fileIndex and fileIndex > 0 and fileIndex <= #listFiles() then
                local filename = listFiles()[fileIndex]
                if currentPlayback then
                    currentPlayback.terminate()
                end
                currentPlayback = parallel.waitForAny(function() playFile(filename) end)
            end
        end
    end
end

parallel.waitForAny(handleUserInput)
