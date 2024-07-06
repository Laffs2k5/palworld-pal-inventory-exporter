# Palworld Pal Inventory Exporter

Small bash script for exporting pal inventory from a Palworld save file as JSON.

## Description

This Bash script is designed to export pal inventory data from a Palworld save file. It utilizes the `palworld-save-tools` for converting the save file into a JSON format, which is then processed to extract and save the inventory data.

The output data can for example be used as input in spreadsheets for tracking breeding progress, pal stats, or other analysis.

### Example Output

```json
[
  {
    "CharacterID": "CowPal",
    "NickName": "Milkyway 2.0",
    "Gender": "EPalGenderType::Female",
    "Level": 38,
    "CraftSpeed": 70,
    "IV_HP": 84,
    "IV_Melee": 54,
    "IV_Shot": 54,
    "IV_Defense": 93,
    "PassivesCount": 3,
    "Passive1": "Nocturnal",
    "Passive2": "PAL_FullStomach_Down_2",
    "Passive3": "PAL_sadist",
    "Passive4": ""
  },
  {
    "CharacterID": "Boar",
    "NickName": "",
    "Gender": "EPalGenderType::Male",
    "Level": 29,
    "CraftSpeed": 70,
    "IV_HP": 61,
    "IV_Melee": 19,
    "IV_Shot": 41,
    "IV_Defense": 77,
    "PassivesCount": 1,
    "Passive1": "TrainerWorkSpeed_UP_1",
    "Passive2": "",
    "Passive3": "",
    "Passive4": ""
  }
]
```

## Prerequisites

- Bash
- Python 3.9 or higher
- `jq` JSON processor - <https://jqlang.github.io/jq/>

Additionally, the `convert.py` script from [palworld-save-tools](https://github.com/cheahjs/palworld-save-tools) is required to be accessible within a specified directory.

## Configuration

The script uses environment variables for configuration:

- `PALWORLD_SAVE_FILE`: Path to the Palworld save file to use as the source.
- `PALWORLD_SAVE_TOOLS_DIR`: Path to the directory containing the `palworld-save-tools` `convert.py` script.
- `PALWORLD_PALS_DATA_FILE`: Path where the JSON output will be saved.

If these variables are not set, the script uses default paths as specified in the script comments.

## Usage

1. Ensure all prerequisites are installed and accessible.
2. Set the required environment variables, if not using the default paths.
3. Run the script

### Example usage with palworld-save-tools as git submodule

For this to work we use the `PYTHONPATH` environment variable to make python aware of the `palworld-save-tools` package. Ie. run from source not from a release distribution.

```bash
# init submodule
# (this clones the palworld-save-tools repository into a subdirectory of this repository)
git submodule init
git submodule update

# invoke the script
PYTHONPATH="$(pwd)/palworld-save-tools" \
  PALWORLD_SAVE_FILE='/path/to/Level.sav' \
  ./export_pal_inventory.sh
```

### Example usage with all environment variables set

This requires you to have a copy of a release distribution of `palworld-save-tools` extracted locally, see the [palworld-save-tools - releases](https://github.com/cheahjs/palworld-save-tools/releases) page.

```bash
# invoke the script
PALWORLD_SAVE_FILE='/path/to/Level.sav' \
  PALWORLD_SAVE_TOOLS_DIR='/path/to/palworld-save-tools' \
  PALWORLD_PALS_DATA_FILE='/path/to/output/pal_inventory.json' \
  ./export_pal_inventory.sh
```

The script will perform checks for the prerequisites, the source save file, and the palworld-save-tools script. If all checks pass, it will proceed to export the pal inventory data to the specified JSON file.

License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
