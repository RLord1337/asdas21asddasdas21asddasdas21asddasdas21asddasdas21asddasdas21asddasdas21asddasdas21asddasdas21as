local dfpwm = require("cc.audio.dfpwm")
local fs = require("fs")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

if not speaker then
    print("No speaker found")
    return
end

local function list_files()
    local files = fs.list("")
    local dfpwm_files = {}
    for _, file in ipairs(files) do
        if file:match("%.dfpwm$") then
            table.insert(dfpwm_files, file)
        end
    end
    return dfpwm_files
end

local function draw_gui(files, selected, is_playing)
    term.clear()
    term.setCursorPos(1, 1)
    print("DFPWM Player")
    print("Select a file to play:")
    for i, file in ipairs(files) do
        if i == selected then
            print("> " .. file)
        else
            print("  " .. file)
        end
    end
    if is_playing then
        print("\nPlaying: " .. files[selected])
        print("[Stop]")
    else
        print("\n[Play]")
    end
    print("[Exit]")
end

local function play_file(file)
    local file_handle = fs.open(file, "rb")
    if not file_handle then
        print("Failed to open file: " .. file)
        return
    end

    while true do
        local chunk = file_handle.read(16 * 1024)
        if not chunk then
            break
        end

        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end

    file_handle.close()
end

local function gui_thread()
    local files = list_files()
    if #files == 0 then
        print("No DFPWM files found")
        return
    end

    local selected = 1
    local is_playing = false
    local play_thread = nil

    draw_gui(files, selected, is_playing)

    while true do
        local event, key = os.pullEvent("key")
        if key == keys.up then
            selected = (selected - 2) % #files + 1
        elseif key == keys.down then
            selected = selected % #files + 1
        elseif key == keys.enter then
            if is_playing then
                if play_thread then
                    play_thread = nil
                end
                is_playing = false
            else
                play_thread = parallel.waitForAny(function() play_file(files[selected]) end)
                is_playing = true
            end
        elseif key == keys.e then
            return
        end
        draw_gui(files, selected, is_playing)
    end
end

local function stop_audio()
    -- This function will set the play_thread to nil to stop playback
    -- Needs a mechanism to actually stop the playback thread
end

parallel.waitForAll(gui_thread)
