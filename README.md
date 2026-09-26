# Cat Companion

A cozy pixel cat that lives on your Windows desktop. No goals, no stats: it just hangs around.

- Sits, loafs, naps, and moves around the bottom of your screen by hopping into its box
- Click it to pet it, or stroke it by moving the mouse back and forth over it (don't overdo it)
- Drag it wherever you like
- Place beds, bowls, toys, a cat tower and plants on your desktop, and the cat uses them
- Falls asleep when you're away from the PC and hides while a fullscreen app is running
- Stays out of the taskbar, with a tray icon instead
- 12 skins, 4 sizes, multi-monitor support, optional start with Windows

Right-click the cat (or the tray icon) for the menu.

## Art

The sprites are not included. They are paid assets by [ToffeeCraft](https://toffeecraft.itch.io/):

- [Cat Pack](https://toffeecraft.itch.io/cat-pack)
- Cat Room pack

Buy them, then unzip them so the folders look like this:

```
assets/catpack/Sprites/...
assets/catpack/CatItems/...
assets/catpack/CatPackDifferentSkins/...
assets/catroom/...
```

## Running

1. Install [Godot 4.7](https://godotengine.org/download)
2. Open `project.godot` in Godot and press F5
   (turn off "Embed Game on Next Play" in the Game tab, or the window can't move)

Or run it without the editor:

```
godot --path path/to/catcompanion
```

Window awareness (taskbar, away detection, fullscreen) uses a small PowerShell helper, so it only works on Windows.
