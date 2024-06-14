local speaker = peripheral.find("speaker")
local file = fs.open("VillagerNLoud.dfpwm, "rb")

while true do
  local bytes = file.read(16384)
  if not bytes then return end
  speaker.playAudio(bytes)

  -- Alternatively, make playAudio block until its buffer is empty, meaning
  -- we can drop this line.
  repeat local _, name = os.pullEvent("need_audio") until name == peripheral.getName(speaker)
end
