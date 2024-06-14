-- Open the modem to communicate with other computers
rednet.open("top")

-- Target computer ID (replace with the ID of Computer B)
local receiverID = 227

-- Initialize variables for queue and current file being sent
local queue = {}
local currentFile = nil
local isSending = false

-- Button handling functions
local buttons = {}

local function drawButton(x, y, w, h, label, bgColor, textColor, callback)
    term.setBackgroundColor(bgColor)
    term.setTextColor(textColor)
    for i = 0, h - 1 do
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", w))
    end
    term.setCursorPos(x + math.floor((w - #label) / 2), y + math.floor(h / 2))
    term.write(label)
    table.insert(buttons, {x = x, y = y, w = w, h = h, callback = callback})
end

local function handleClick(x, y)
    for _, button in ipairs(buttons) do
        if x >= button.x and x < button.x + button.w and y >= button.y and y < button.y + button.h then
            button.callback()
            return true
        end
    end
    return false
end

-- Function to send a file over Rednet
local function sendFile(filename, receiverID)
    -- Open the file in binary mode
    local file = io.open(filename, "rb")
    if not file then
        print("Error: File not found or unable to open:", filename)
        return false
    end

    -- Read the file in chunks and send each chunk
    local chunkSize = 16 * 1024  -- 16 KB chunks
    local chunk
    repeat
        chunk = file:read(chunkSize)
        if chunk then
            rednet.send(receiverID, chunk)  -- Send chunk over Rednet
        end
    until not chunk

    file:close()
    return true
end

-- Function to add a file to the queue
local function addToQueue(filename)
    table.insert(queue, filename)
    print("Added to queue:", filename)
end

-- Function to list all .dfpwm files in the current directory
local function listDFPWMFiles()
    local files = fs.list(shell.dir())
    local dfpwmFiles = {}
    for _, file in ipairs(files) do
        if fs.isDir(file) then
            -- Skip directories
        elseif file:match("%.dfpwm$") then
            table.insert(dfpwmFiles, file)
        end
    end
    return dfpwmFiles
end

-- Function to handle sending files from the queue
local function sendFromQueue()
    if #queue > 0 and not isSending then
        isSending = true
        local filename = queue[1]  -- Get the first file in the queue
        currentFile = filename
        print("Sending file:", filename)
        if sendFile(filename, receiverID) then
            print("File sent successfully to Computer B")
        else
            print("Failed to send file to Computer B")
        end
        isSending = false
    elseif isSending then
        print("Already sending a file:", currentFile)
    else
        print("Queue is empty.")
    end
end

-- Function to shuffle the queue
local function shuffleQueue()
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end
    print("Queue shuffled.")
end

-- Function to stop sending files and send stop command to Computer B
local function stopSending()
    isSending = false
    currentFile = nil
    print("Sending stopped.")

    -- Send stop command to Computer B
    rednet.send(receiverID, "stop")
    print("Stop command sent to Computer B.")
end

-- Function to clear the queue
local function clearQueue()
    queue = {}
    print("Queue cleared.")
end

-- Function to draw the GUI
local function drawGUI()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    print("=== Sender Program ===\n")

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

    -- Display available .dfpwm files
    local dfpwmFiles = listDFPWMFiles()
    print("\nAvailable .dfpwm Files:")
    for i, file in ipairs(dfpwmFiles) do
        print(i .. ". " .. file)
    end

    -- Draw buttons
    buttons = {}
    drawButton(1, 10, 15, 3, "Add to Queue", colors.green, colors.black, function()
        term.setCursorPos(1, 13)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        print("Enter file number to add:")
        local num = tonumber(read())
        if num and dfpwmFiles[num] then
            addToQueue(dfpwmFiles[num])
        else
            print("Invalid file number.")
        end
    end)
    drawButton(17, 10, 15, 3, "Shuffle Queue", colors.blue, colors.black, shuffleQueue)
    drawButton(1, 14, 15, 3, "Stop Sending", colors.red, colors.black, stopSending)
    drawButton(17, 14, 15, 3, "Send Queue", colors.yellow, colors.black, sendFromQueue)
    drawButton(1, 18, 15, 3, "Clear Queue", colors.orange, colors.black, clearQueue)
end

-- Main loop to run the GUI
while true do
    drawGUI()

    -- Wait for user interaction
    local event, side, x, y = os.pullEvent("mouse_click")
    if event == "mouse_click" then
        handleClick(x, y)
    end
end