this autohotkey script automatically scales your laptop display scaling when an external monitor is connected.

### what it does

- it listens for windows to say when a display is connected or disconnected
- when something changes, it counts how many screens are connected
  - if there is more than one (meaning at least one external display is connected), the laptop goes to 150% (adjustable) so you can see the screen easier
  - if there is only one (i.e., the laptop screen itself), the laptop goes to 125% (adjustable)
- then, the script uses windows display drivers and sets it to the correct percentage

### how to use

1. install autohotkey v2
2. run the script
3. make it run on startup by creating a shortcut and putting it into the startup folder
