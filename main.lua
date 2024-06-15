-- Import the required libraries
local dfpwm = require("cc.audio.dfpwm")
local event = require("event")

-- Initialize variables
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()
local isPlaying = false
local playQueue = {}
local audioDirectory = "/audio"
local currentFile = nil
local currentProcess = nil

-- Functions to control playback
local function playFile(filePath)
    local file = fs.open(filePath, "rb")
    if not file then
        print("Audio file not found: " .. filePath)
        return
    end

    isPlaying = true
    currentFile = filePath
    currentProcess = coroutine.create(function()
        while true do
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
        isPlaying = false
        currentFile = nil
        if #playQueue > 0 then
            playFile(table.remove(playQueue, 1))
        end
    end)

    coroutine.resume(currentProcess)
end

local function stopPlayback()
    if currentProcess then
        currentProcess = nil
    end
    for _, speaker in pairs(speakers) do
        speaker.stop()
    end
    isPlaying = false
    currentFile = nil
end

-- Functions for GUI
local function drawGUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("DFPWM Player")

    print("Files:")
    local files = fs.list(audioDirectory)
    for i, file in ipairs(files) do
        print(i .. ". " .. file)
    end

    print("\nCommands:")
    print("[P <number>] Play file")
    print("[S] Stop playback")
    print("[Q] Queue file")
    print("[L] List queue")

    if isPlaying then
        print("\nNow playing: " .. currentFile)
    end

    if #playQueue > 0 then
        print("Queue:")
        for i, file in ipairs(playQueue) do
            print(i .. ". " .. file)
        end
    end
end

local function handleCommand(command)
    local args = {}
    for word in string.gmatch(command, "%S+") do
        table.insert(args, word)
    end

    if args[1] == "P" and args[2] then
        local fileIndex = tonumber(args[2])
        local files = fs.list(audioDirectory)
        if fileIndex and files[fileIndex] then
            playFile(audioDirectory .. "/" .. files[fileIndex])
        else
            print("Invalid file index")
        end
    elseif args[1] == "S" then
        stopPlayback()
    elseif args[1] == "Q" and args[2] then
        local fileIndex = tonumber(args[2])
        local files = fs.list(audioDirectory)
        if fileIndex and files[fileIndex] then
            table.insert(playQueue, audioDirectory .. "/" .. files[fileIndex])
        else
            print("Invalid file index")
        end
    elseif args[1] == "L" then
        print("Queue:")
        for i, file in ipairs(playQueue) do
            print(i .. ". " .. file)
        end
    else
        print("Unknown command")
    end
end

-- Main loop
while true do
    drawGUI()
    local event, param1 = os.pullEvent("key")
    if event == "key" then
        if param1 == keys.enter then
            term.setCursorPos(1, term.getCursorPos() + 1)
            local command = read()
            handleCommand(command)
        end
    end
end
