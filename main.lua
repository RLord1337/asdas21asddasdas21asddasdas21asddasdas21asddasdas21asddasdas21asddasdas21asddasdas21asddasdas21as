local dfpwm = require("cc.audio.dfpwm")
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()
local files = fs.list("/")
local dfpwmFiles = {}
local isPlaying = false
local stopPlayback = false

-- Filter DFPWM files
for _, file in ipairs(files) do
    if file:match("%.dfpwm$") then
        table.insert(dfpwmFiles, file)
    end
end

-- GUI Functions
local function drawMenu()
    term.clear()
    term.setCursorPos(1, 1)
    print("DFPWM Player")
    print("Select a file to play:")
    for i, file in ipairs(dfpwmFiles) do
        print(i .. ". " .. file)
    end
    print("\nPress 's' to stop playback.")
    print("\nEnter the number of the file to play:")
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

    isPlaying = true
    stopPlayback = false

    while true do
        -- Check for user input or timer event every 0.1 seconds
        local timerId = os.startTimer(0.1)
        local event, param = os.pullEvent()
        os.cancelTimer(timerId)

        if event == "char" then
            local char = param
            if char == 's' then
                if isPlaying then
                    stopAudio()
                    print("Playback stopped.")
                else
                    print("No audio is playing.")
                end
                break
            else
                local selection = tonumber(char)
                if selection and dfpwmFiles[selection] then
                    local selectedFile = dfpwmFiles[selection]
                    print("Playing " .. selectedFile)
                    playFile(selectedFile)
                else
                    print("Invalid selection.")
                end
            end
        elseif event == "timer" and param == timerId then
            -- Continue playback
            local chunk = file.read(16 * 1024)
            if not chunk or stopPlayback then
                break
            end

            local buffer = decoder(chunk)
            
            for _, speaker in ipairs(speakers) do
                while not speaker.playAudio(buffer) do
                    if stopPlayback then break end
                    os.pullEvent("speaker_audio_empty")
                end
                if stopPlayback then break end
            end
        end
    end

    file.close()
    isPlaying = false
    print("Playback finished")
end

-- Main Loop
while true do
    drawMenu()
    local event, param = os.pullEvent()

    if event == "char" then
        local char = param
        if char == 's' then
            if isPlaying then
                stopAudio()
                print("Playback stopped.")
            else
                print("No audio is playing.")
            end
        else
            local selection = tonumber(char)
            if selection and dfpwmFiles[selection] then
                local selectedFile = dfpwmFiles[selection]
                print("Playing " .. selectedFile)
                playFile(selectedFile)
            else
                print("Invalid selection.")
            end
        end
    end
end
