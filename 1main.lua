local dfpwm = require("cc.audio.dfpwm")

-- Function to find and wrap monitor
local function findMonitor()
    local monitors = peripheral.find("monitor")
    if not monitors then
        print("No monitor found.")
        return nil
    end
    return peripheral.wrap(monitors)
end

-- Initialize peripherals
local monitor = findMonitor()
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()

-- Playlist and player state variables
local playlist = {}
local currentTrack = 1
local isPlaying = false
local volume = 0.5  -- Initial volume (0.0 - 1.0)

-- GUI Constants
local screenWidth, screenHeight = monitor.getSize()
local buttonWidth = 10
local buttonHeight = 3
local buttonColor = colors.blue
local backgroundColor = colors.black
local textColor = colors.white

-- Function to draw GUI
local function drawGUI()
    monitor.setBackgroundColor(backgroundColor)
    monitor.clear()

    -- Draw buttons
    local playPauseText = isPlaying and "Pause" or "Play"
    monitor.setTextColor(textColor)
    monitor.setBackgroundColor(buttonColor)
    monitor.setCursorPos(2, 2)
    monitor.write(playPauseText)
    monitor.setCursorPos(screenWidth - buttonWidth - 1, 2)
    monitor.write("Skip")
    monitor.setCursorPos(2, screenHeight - buttonHeight - 1)
    monitor.write("Add Song")
    monitor.setCursorPos(screenWidth - buttonWidth - 1, screenHeight - buttonHeight - 1)
    monitor.write("Volume")

    -- Draw sliders
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(15, screenHeight - 2)
    monitor.write(string.rep(" ", screenWidth - 16))  -- Progress bar background
    monitor.setBackgroundColor(colors.green)
    local progressBarWidth = math.floor((screenWidth - 16) * (currentTrack / #playlist))
    monitor.setCursorPos(15, screenHeight - 2)
    monitor.write(string.rep(" ", progressBarWidth))  -- Progress bar

    monitor.setCursorPos(screenWidth - 8, screenHeight - 2)
    monitor.setBackgroundColor(colors.gray)
    monitor.write("[        ]")  -- Volume slider background
    monitor.setCursorPos(screenWidth - 7 + math.floor(6 * volume), screenHeight - 2)
    monitor.setBackgroundColor(colors.blue)
    monitor.write(" ")

    -- Draw playlist
    monitor.setBackgroundColor(backgroundColor)
    monitor.setTextColor(textColor)
    monitor.setCursorPos(2, 5)
    monitor.write("Playlist:")

    for i = 1, math.min(#playlist, screenHeight - 7) do
        monitor.setCursorPos(2, 5 + i)
        monitor.write(tostring(i) .. ". " .. playlist[i])
    end
end

-- Function to handle button clicks
local function handleClick(x, y)
    if x >= 2 and x <= 2 + buttonWidth and y == 2 then
        -- Play/Pause button
        if isPlaying then
            for _, speaker in ipairs(speakers) do
                speaker.stop()
            end
        else
            playTrack()
        end
        isPlaying = not isPlaying
    elseif x >= screenWidth - buttonWidth - 1 and x <= screenWidth - 1 and y == 2 then
        -- Skip button
        skipTrack()
    elseif x >= 2 and x <= 2 + buttonWidth and y == screenHeight - buttonHeight - 1 then
        -- Add Song button (placeholder)
        -- Add functionality to add songs to the playlist here
        print("Add Song button clicked.")
    elseif x >= screenWidth - buttonWidth - 1 and x <= screenWidth - 1 and y == screenHeight - buttonHeight - 1 then
        -- Volume button (placeholder)
        -- Add functionality to adjust volume here
        print("Volume button clicked.")
    end
end

-- Function to handle monitor touch events
local function handleTouch()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if event == "monitor_touch" then
            handleClick(x, y)
            drawGUI()
        end
    end
end

-- Function to play the current track
local function playTrack()
    local fileName = playlist[currentTrack]
    if not fileName then
        print("No track to play.")
        return
    end

    local file = fs.open(fileName, "rb")
    if not file then
        print("Audio file not found:", fileName)
        return
    end

    for _, speaker in ipairs(speakers) do
        speaker.setVolume(volume)
    end

    isPlaying = true
    while true do
        local chunk = file.read(16 * 1024)
        if not chunk then
            break
        end

        local buffer = decoder(chunk)

        for _, speaker in ipairs(speakers) do
            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end

    file.close()
    isPlaying = false
end

-- Function to skip to the next track
local function skipTrack()
    currentTrack = currentTrack + 1
    if currentTrack > #playlist then
        currentTrack = 1
    end
    if isPlaying then
        playTrack()
    end
end

-- Main loop
drawGUI()
parallel.waitForAny(handleTouch, function() end)  -- Wait for monitor events or other functions
