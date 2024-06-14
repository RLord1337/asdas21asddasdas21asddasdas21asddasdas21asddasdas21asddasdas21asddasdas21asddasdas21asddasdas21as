local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker found")
end

local decoder = dfpwm.make_decoder()
local file = fs.open("VillagerNLoud.dfpwm", "rb")

if not file then
    error("Failed to open file")
end

while true do
    local chunk = file.read(16 * 1024)
    if not chunk then break end

    local buffer = decoder(chunk)

    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end

file.close()
