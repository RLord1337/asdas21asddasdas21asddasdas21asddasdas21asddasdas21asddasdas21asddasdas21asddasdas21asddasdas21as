local dfpwm = require("cc.audio.dfpwm")

-- Function to list DFPWM files in root directory
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

-- Function to display menu and get user input
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
    
    print("\nType 'remove' to remove a song from queue.")
    print("Type 'play' to play queue.")
    print("Type 'exit' to exit.")
    
    local input = read()
    return input
end

-- Function to play audio from file
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

-- Function to play songs in queue
local function playQueue(queue)
    for _, fileName in ipairs(queue) do
        print("Playing: " .. fileName)
        playAudio(fileName)
        sleep(1)  -- Pause briefly between songs
    end
end

-- Main program
local queue = {}

while true do
    local audioFiles = listAudioFiles()
    local userInput = displayMenu(audioFiles, queue)
    
    if userInput == 'exit' then
        break
    elseif userInput == 'play' then
        if #queue > 0 then
            playQueue(queue)
        else
            print("Queue is empty. Add songs to the queue.")
            sleep(1)  -- Pause briefly
        end
    elseif userInput == 'remove' then
        if #queue > 0 then
            print("Enter the number of the song to remove:")
            local removeIndex = tonumber(read())
            if removeIndex and removeIndex >= 1 and removeIndex <= #queue then
                local removedFile = table.remove(queue, removeIndex)
                print("Removed from queue: " .. removedFile)
            else
                print("Invalid selection.")
                sleep(1)  -- Pause briefly
            end
        else
            print("Queue is empty. No songs to remove.")
            sleep(1)  -- Pause briefly
        end
    elseif tonumber(userInput) and audioFiles[tonumber(userInput)] then
        local selectedFile = audioFiles[tonumber(userInput)]
        print("Added to queue: " .. selectedFile)
        table.insert(queue, selectedFile)
    else
        print("Invalid selection.")
        sleep(1)  -- Pause briefly
    end
end
