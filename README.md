# Update Checker (Pac-Man Widget)

Pac-Man themed system update checker for **Noctalia** on pacman-based Linux distributions.

Displays update availability directly in the bar using an animated Pac-Man indicator, with configurable idle behavior and refresh timing.

---

## Features

- Animated Pac-Man update indicator
- Idle animation when system is up to date
- Optional themed idle icon color
- Optional idle pellet display
- Native Noctalia settings panel
- Configurable refresh timing
- Configurable animation timing
- Right-click context menu actions
- Tooltip status reporting
- Panel view of pending updates
- Automatic refresh after pacman transactions
- Uses safe `checkupdates` backend (no root required)

---

## Requirements

- Noctalia **>= 3.6.0**
- pacman-based distribution (Arch / CachyOS / EndeavourOS / etc.)
- `pacman-contrib` installed

Install dependency if needed:

```bash
sudo pacman -S pacman-contrib
```

---

## Installation

Clone or copy the plugin into:

```bash
~/.config/noctalia/plugins/update-checker
```

Example:

```bash
git clone https://github.com/OhNoIBrokeIt/noctalia-update-checker ~/.config/noctalia/plugins/update-checker
```

Restart Noctalia:

```bash
killall qs
qs -c noctalia-shell
```

Then add **Update Checker** from the bar widget picker.

---

## Settings

The plugin currently supports:

- Check interval
- Initial animation duration
- Idle chomp interval
- Use themed idle icon color
- Show idle pellet

Settings are available via:

Right-click widget → Plugin settings

---

## Behavior

When updates are available:

- Pac-Man animates
- Update count is displayed
- Hover restarts animation
- Clicking opens update panel

When the system is up to date:

- Pac-Man enters idle animation mode
- Optional pellet indicator shown
- Optional themed icon coloring applied

Right-click opens:

- Check now
- Open updates panel
- Plugin settings

The widget refreshes automatically after pacman transactions.

---

## Backend Design

This plugin uses:

`checkupdates`

from:

`pacman-contrib`

Advantages:

- Does not require root
- Does not lock pacman database
- Safe for periodic polling
- Recommended Arch update-checking method

---

## File Structure

```
update-checker/
├── manifest.json
├── Main.qml
├── BarWidget.qml
├── Panel.qml
├── Settings.qml
├── settings.json
├── en.json
├── updates-check.sh
└── README.md
```

---

## Troubleshooting

### No updates detected

Verify dependency:

```bash
checkupdates
```

If command fails:

```bash
sudo pacman -S pacman-contrib
```

### Widget not visible

Restart Noctalia:

```bash
killall qs
qs -c noctalia-shell
```

Then re-add widget from bar settings.

### Script not executable

Fix:

```bash
chmod +x updates-check.sh
```

---

## Screenshots

Placeolder for screenshot

Example path:

`docs/screenshot.png`

---

## License

MIT

---

## Author

Created by **ohnoibrokeit**

Contributions welcome.
