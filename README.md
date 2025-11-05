# Lyft - Floating Bar for Turtle WoW Items

A lightweight addon for Turtle WoW that provides a floating action bar with quick access to useful items like teleportation devices, runes, and other frequently used items.

## Features

- **Floating Draggable Bar**: Move the bar anywhere on your screen
- **Smart Item Detection**: Automatically detects items in your inventory and equipment
- **Charge Display**: Shows remaining charges for items like runes and teleport devices
- **Cooldown Support**: Displays item cooldowns with spinning clock animation
- **One-Click Usage**: Click to use items directly from the bar
- **Auto-Equip**: For items that need to be equipped (like Guild Tabard), automatically equips them first
- **Tooltip Information**: Hover over icons for detailed item information

## Supported Items

- **Portable Wormhole Generator: Orgrimmar** - Teleport to Orgrimmar
- **Verdant Rune** - Teleport to Emerald Sanctum
- **Time-Worn Rune** - Teleport to Caverns of Time
- **Guild Tabard** - Teleport to Guild House (requires equipping)
- **Dimensional Ripper - Everlook** - Teleport to Everlook (requires equipping)
- **Hearthstone** - Return to your home location

## Installation

1. Download the latest release
2. Extract the `Lyft` folder to your `World of Warcraft/Interface/AddOns/` directory
3. Restart WoW or reload your UI (`/reload`)

## Usage

### Basic Commands
- `/lyft` or `/lift` - Show/hide the bar
- `/lyftreset` or `/liftreset` - Reset bar position to default
- `/lyftdebug verdant` - Debug scan for Verdant Rune

### Bar Interaction
- **Drag**: Click and drag the bar title to move it
- **Click**: Click any icon to use the corresponding item
- **Auto-Equip**: For equipped items, the addon will automatically equip them if needed

### Icon States
- **Green "USE"**: Item is equipped and ready to use
- **Yellow "EQP"**: Item is in bags and needs to be equipped first
- **Number**: Item count or charges remaining
- **Greyed Out**: Item not available in inventory
- **Spinning Clock**: Item is on cooldown

## Configuration

The addon automatically saves its position. No additional configuration is needed.

## Troubleshooting

- If items don't appear, make sure they're in your bags or bank
- Use `/lyftdebug verdant` to verify item detection
- Reset position with `/lyftreset` if the bar gets lost off-screen

## Compatibility

- Designed for **Turtle WoW** (Vanilla 1.12 client)
- Lua 5.0 compliant
- Works with other addons

## Credits

Based on the ConsumesManagerBar design concept.

## Support

For issues or suggestions, please report them on the addon's release page.
