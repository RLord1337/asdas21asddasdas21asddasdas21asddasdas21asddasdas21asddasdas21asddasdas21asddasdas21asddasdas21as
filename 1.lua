local dfpwm = require("cc.audio.dfpwm")
local speakers = {peripheral.find("speaker")}
local decoder = dfpwm.make_decoder()

if #speakers == 0 then
    print("No speakers found")
    return
end

local file = fs.open("club.dfpwm", "rb")
if not file then
    print("Audio file not found")
    return
end

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
print("Playback finished")
