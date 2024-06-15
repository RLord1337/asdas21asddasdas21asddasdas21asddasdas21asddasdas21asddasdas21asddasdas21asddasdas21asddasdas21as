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

local function displayQueue(queue)
    term.clear()
    term.setCursorPos(1, 1)
    print("==== Music Player ====")
    print("Current Queue:")
    for i, file in ipairs(queue) do
        print(i .. ". " .. file)
    end
    print("\nType 'add' to add a song to queue.")
    print("Type 'remove' to remove a song from queue.")
    print("Type 'shuffle' to shuffle queue.")
    print("Type 'play' to play queue.")
    print("Type 'loop' to toggle loop mode.")
    print("Type 'exit' to exit.")
end

local function playAudio(fileName, speakers)
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
        
        for _, speaker in pairs(speakers) do
            while not speaker.playAudio(buffer, 0.1) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
    
    file.close()
    print("Playback finished.")
end

local function playQueue(queue, speakers, loopMode)
    while true do
        for _, fileName in ipairs(queue) do
            print("Playing: " .. fileName)
            playAudio(fileName, speakers)
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
local speakers = {peripheral.find("speaker")}

if #speakers == 0 then
    print("No speakers found")
    return
end

while true do
    displayQueue(queue)
    local userInput = read()
    
    if userInput == 'exit' then
        break
    elseif userInput == 'play' then
        if #queue > 0 then
            playQueue(queue, speakers, loopMode)
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
    elseif userInput == 'add' then
        local audioFiles = listAudioFiles()
        term.clear()
        term.setCursorPos(1, 1)
        print("==== Music Player ====")
        print("Available Songs:")
        for i, file in ipairs(audioFiles) do
            print(i .. ". " .. file)
        end
        print("\nEnter the number of the song to add:")
        
        local selection = tonumber(read())
        
        if selection and audioFiles[selection] then
            local selectedFile = audioFiles[selection]
            print("Added to queue: " .. selectedFile)
            table.insert(queue, selectedFile)
            sleep(1)  -- Pause briefly
        else
            print("Invalid selection.")
            sleep(1)  -- Pause briefly
        end
    elseif userInput == 'remove' then
        print("Enter the number of the song to remove:")
        local selection = tonumber(read())
        
        if selection and queue[selection] then
            local removedFile = table.remove(queue, selection)
            print("Removed from queue: " .. removedFile)
            sleep(1)  -- Pause briefly
        else
            print("Invalid selection.")
            sleep(1)  -- Pause briefly
        end
    else
        print("Invalid selection.")
        sleep(1)  -- Pause briefly
    end
end
