local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker found")
end

local decoder = dfpwm.make_decoder()
local file, err = io.open("VillagerNLoud.dfpwm", "rb")

if not file then
    error("Failed to open file: " .. err)
end

for chunk in file:lines(16 * 1024) do
    local buffer = decoder(chunk)

    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end

file:close()
