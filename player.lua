-- Open the modem to communicate with other computers
rednet.open("top")
 
-- Function to receive a file over Rednet
local function receiveFile(filename)
    local file = io.open(filename, "wb")
    if not file then
        print("Error: Unable to create file:", filename)
        return false
    end
 
    while true do
        -- Wait for the next chunk of data
        local senderID, message, distance = rednet.receive()
 
        -- Write the received chunk to the file
        file:write(message)
 
        -- If the message length is less than chunk size, it means it's the last chunk
        if #message < 16 * 1024 then
            break
        end
    end
 
    file:close()
    return true
end
 
-- Initialize variables for queue and current file being played
local queue = {}
local currentFile = nil
local isPlaying = false
 
-- Function to play the received audio file
local function playFile(filename)
    local dfpwm = require("cc.audio.dfpwm")
    local speaker = peripheral.wrap("right")  -- Adjusted to find speaker on the right side
 
    if not speaker then
        print("Error: Speaker peripheral not found on the right side")
        return
    end
 
    local decoder = dfpwm.make_decoder()
    local file = io.open(filename, "rb")
    if not file then
        print("Error: Unable to open file for playing:", filename)
        return
    end
 
    for chunk in io.lines(filename, 16 * 1024) do
        local buffer = decoder(chunk)
 
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
 
    file:close()
    print("File played successfully")
 
    -- Delete the file to avoid storage issues
    fs.delete(filename)
    print("File deleted to save storage")
end
 
-- Function to handle receiving files
local function handleReceive()
    while true do
        local senderID, message, protocol = rednet.receive()
 
        if message == "stop" then
            isPlaying = false
            currentFile = nil
            print("Playback stopped.")
        else
            local filename = "received.dfpwm"
            if receiveFile(filename) then
                table.insert(queue, filename)
                print("File received successfully")
            else
                print("Failed to receive file")
            end
        end
 
        if not isPlaying and #queue > 0 then
            isPlaying = true
            currentFile = table.remove(queue, 1)
            playFile(currentFile)
            isPlaying = false
            currentFile = nil
        end
    end
end
 
-- Function to draw the GUI
local function drawGUI()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    print("=== Receiver Program ===\n")
 
    -- Display current queue
    term.setTextColor(colors.yellow)
    term.write("Queue:\n")
    term.setTextColor(colors.white)
    if #queue == 0 then
        print("Queue is empty.")
    else
        for i, filename in ipairs(queue) do
            print(i .. ". " .. filename)
        end
    end
 
    -- Display current playing file
    if currentFile then
        term.setTextColor(colors.green)
        print("\nNow Playing:")
        term.setTextColor(colors.white)
        print(currentFile)
    end
 
    -- Draw buttons
    term.setCursorPos(1, 18)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.write(" Stop Playback ")
 
    -- Wait for user interaction
    local event, side, x, y = os.pullEvent("mouse_click")
    if event == "mouse_click" and x >= 1 and x <= 15 and y == 18 then
        -- Stop playback button clicked
        rednet.send(senderID, "stop")
        isPlaying = false
        currentFile = nil
        print("Playback stopped.")
    end
end
 
-- Main loop to run the GUI and handle receiving files
while true do
    parallel.waitForAny(handleReceive, drawGUI)
end