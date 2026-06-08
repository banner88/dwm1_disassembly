from pyboy import PyBoy
from pathlib import Path

pyboy = PyBoy("data/DWM-hacked.gbc", window="null")  # headless
for _ in range(600):  # ~10 seconds at 60fps
    pyboy.tick()
pyboy.screen.image.save("title_screen.png")
pyboy.stop()
print("Saved title_screen.png")
