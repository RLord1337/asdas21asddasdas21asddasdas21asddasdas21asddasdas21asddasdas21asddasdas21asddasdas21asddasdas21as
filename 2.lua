local dfpwm = require("cc.audio.dfpwm")
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()
local files = fs.list("/")
local dfpwmFiles = {}
local queue = {}
local currentSong = nil
local isPlaying = false
local stopPlayback = false
local volume = 1.0 -- default volume

-- Filter DFPWM files
for _, file in ipairs(files) do
    if file:match("%.dfpwm$") then
        table.insert(dfpwmFiles, file)
    end
end

-- GUI Functions
local function drawMenu()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    print("DFPWM Music Player")

    -- Display current song
    if currentSong then
        print("Now Playing: " .. currentSong)
    else
        print("No song playing")
    end

    -- Display queue
    print("\nQueue:")
    for i, song in ipairs(queue) do
        print(i .. ". " .. song)
    end

    -- Display control buttons
    term.setCursorPos(1, 15)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    print("  Play  ")

    term.setCursorPos(10, 15)
    term.setBackgroundColor(colors.red)
    print("  Stop  ")

    term.setCursorPos(20, 15)
    term.setBackgroundColor(colors.green)
    print(" Add to Queue ")

    term.setCursorPos(35, 15)
    term.setBackgroundColor(colors.yellow)
    print("  Remove from Queue  ")

    term.setCursorPos(55, 15)
    term.setBackgroundColor(colors.orange)
    print("  Pause  ")

    -- Display volume control
    term.setCursorPos(1, 20)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    print("Volume: [ " .. string.rep("=", volume * 20) .. " ]")
end

local function stopAudio()
    stopPlayback = true
    for _, speaker in ipairs(speakers) do
        speaker.stop()
    end
end

local function playFile(fileName)
    local file = fs.open(fileName, "rb")
    if not file then
        print("Audio file not found")
        return
    end

    currentSong = fileName
    isPlaying = true
    stopPlayback = false

    while true do
        local chunk = file.read(16 * 1024)
        if not chunk or stopPlayback then
            break
        end

        local buffer = decoder(chunk)
        
        for _, speaker in ipairs(speakers) do
            while not speaker.playAudio(buffer * volume) do
                if stopPlayback then break end
                os.pullEvent("speaker_audio_empty")
            end
            if stopPlayback then break end
        end
    end

    file.close()
    isPlaying = false
    currentSong = nil
    print("Playback finished")
end

-- Main Loop
while true do
    drawMenu()
    local event, param = os.pullEvent()

    if event == "char" then
        local char = param
        if char == 'p' then
            -- Play current selection
            if currentSong then
                playFile(currentSong)
            elseif #queue > 0 then
                local song = table.remove(queue, 1)
                playFile(song)
            else
                print("Queue is empty")
            end
        elseif char == 's' then
            -- Stop playback
            if isPlaying then
                stopAudio()
                print("Playback stopped.")
            else
                print("No audio is playing.")
            end
        elseif char == 'a' then
            -- Add to queue
            term.clearLine()
            term.setCursorPos(1, 18)
            print("Enter song number to add to queue:")
            local num = tonumber(read())
            if num and dfpwmFiles[num] then
                table.insert(queue, dfpwmFiles[num])
                print("Added to queue: " .. dfpwmFiles[num])
            else
                print("Invalid selection.")
            end
            os.sleep(1)
        elseif char == 'r' then
            -- Remove from queue
            term.clearLine()
            term.setCursorPos(1, 18)
            print("Enter queue number to remove:")
            local num = tonumber(read())
            if num and queue[num] then
                print("Removed from queue: " .. queue[num])
                table.remove(queue, num)
            else
                print("Invalid selection.")
            end
            os.sleep(1)
        elseif char == 'c' then
            -- Adjust volume (simulated with text input)
            term.clearLine()
            term.setCursorPos(1, 18)
            print("Enter new volume (0.0 - 1.0):")
            local newVolume = tonumber(read())
            if newVolume and newVolume >= 0 and newVolume <= 1 then
                volume = newVolume
            else
                print("Invalid volume.")
            end
            os.sleep(1)
        end
    end
end
