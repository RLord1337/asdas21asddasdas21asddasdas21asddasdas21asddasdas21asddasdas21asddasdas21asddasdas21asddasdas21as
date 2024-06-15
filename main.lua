local modem = peripheral.find("modem")
local speakers = {peripheral.find("speaker")}

if modem then
    print("Modem found")
else
    print("No modem found")
end

if #speakers > 0 then
    for i, speaker in pairs(speakers) do
        print("Playing note on speaker " .. i)
        speaker.playNote("pling")
    end
else
    print("No speakers found")
end
