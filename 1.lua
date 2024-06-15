local dfpwm = require("cc.audio.dfpwm")

local function listAudioFiles()
    local files = fs.list("/")
    local audioFiles = {}
    
    for _, file in ipairs(files) do
        if file:match("%.dfpwm$") then
            table.insert(audioFiles, file)
        end
    end
    
    return audioFiles
end

local function displayMenu(audioFiles, queue)
    term.clear()
    term.setCursorPos(1, 1)
    print("==== Music Player ====")
    print("Current Queue:")
    for i, file in ipairs(queue) do
        print(i .. ". " .. file)
    end
    print("\nSelect a song to add to queue:")
    
    for i, file in ipairs(audioFiles) do
        print(i .. ". " .. file)
    end
    
    print("\nType 'shuffle' to shuffle queue.")
    print("Type 'play' to play queue.")
    print("Type 'loop' to toggle loop mode.")
    print("Type 'exit' to exit.")
    
    local input = read()
    return input
end

local function playAudio(fileName)
    local speakers = peripheral.find("speaker")
    local decoder = dfpwm.make_decoder()
    local file = fs.open(fileName, "rb")
    
    if not file then
        print("File not found.")
        return
    end
    
    while true do
        local chunk = file.read(16 * 1024)
        if not chunk then
            break
        end
        
        local buffer = decoder(chunk)
        
        if speakers then
            while not speakers.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
    
    file.close()
    print("Playback finished.")
end

local function playQueue(queue, loopMode)
    while true do
        for _, fileName in ipairs(queue) do
            print("Playing: " .. fileName)
            playAudio(fileName)
            sleep(1)  -- Pause briefly between songs
            
            if not loopMode and _ == #queue then
                return  -- Exit function if not in loop mode and reached end of queue
            end
        end
    end
end

local function shuffleQueue(queue)
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end
end

-- Main program
local queue = {}
local loopMode = false

while true do
    local audioFiles = listAudioFiles()
    local userInput = displayMenu(audioFiles, queue)
    
    if userInput == 'exit' then
        break
    elseif userInput == 'play' then
        if #queue > 0 then
            playQueue(queue, loopMode)
        else
            print("Queue is empty. Add songs to the queue.")
            sleep(1)  -- Pause briefly
        end
    elseif userInput == 'shuffle' then
        shuffleQueue(queue)
        print("Queue shuffled.")
        sleep(1)  -- Pause briefly
    elseif userInput == 'loop' then
        loopMode = not loopMode
        print("Loop mode " .. (loopMode and "enabled" or "disabled") .. ".")
        sleep(1)  -- Pause briefly
    elseif tonumber(userInput) and audioFiles[tonumber(userInput)] then
        local selectedFile = audioFiles[tonumber(userInput)]
        print("Added to queue: " .. selectedFile)
        table.insert(queue, selectedFile)
    else
        print("Invalid selection.")
        sleep(1)  -- Pause briefly
    end
end
