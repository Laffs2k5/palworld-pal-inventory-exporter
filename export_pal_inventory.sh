#!/usr/bin/env bash
set -euo pipefail

# possible inputs from environment variables:
#   PALWORLD_SAVE_FILE:       path to the palworld save file to use as source
#   PALWORLD_SAVE_TOOLS_DIR:  path to directory containing the the palworld-save-tools 'convert.py' script
#   PALWORLD_PALS_DATA_FILE:  path where the json output will be saved

# config
sourceSavFile="${PALWORLD_SAVE_FILE:-/path/to/Level.sav}"
outputPalsDataFile="${PALWORLD_PALS_DATA_FILE:-$(pwd)/pals_data.json}"
saveToolsConvertScript="${PALWORLD_SAVE_TOOLS_DIR:-$(pwd)/palworld-save-tools}/palworld_save_tools/commands/convert.py"
saveFileCustomProperties='.worldSaveData.CharacterSaveParameterMap.Value.RawData'

echo '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'
echo '  Palworld Pal Inventory Exporter'
echo '    Extract pals data from Palworld save file.'
echo '    (powered by palworld-save-tools https://github.com/cheahjs/palworld-save-tools)'
echo ''
echo '  Current configuration:'
echo "    Source save file:           ${sourceSavFile}"
echo "    Output pals data file:      ${outputPalsDataFile}"
echo "    palworld-save-tools script: ${saveToolsConvertScript}"
echo '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'

# check if source file and palworld-save-tools exists
echo -en '\e[34mINFO:\e[0m Checking configuration ...'
if [ ! -f "${sourceSavFile}" ]; then
  echo -e "\n\e[31mERROR:\e[0m Config error: Source file not found at: ${sourceSavFile}"
  exit 1
fi
if [ ! -f "${saveToolsConvertScript}" ]; then
  echo -e "\n\e[31mERROR:\e[0m Config error: palworld-save-tools script not found at: ${saveToolsConvertScript}"
  echo -e "\e[31mERROR:\e[0m               Please make sure the 'convert.py' script from https://github.com/cheahjs/palworld-save-tools is available."
  exit 1
fi
echo -e 'done.'

# check if prerequisite tools are installed
echo -en '\e[34mINFO:\e[0m Checking prerequisites ...'
if ! command -v python -V &>/dev/null; then
  echo -e "\n\e[31mERROR:\e[0m Prerequisite check: Python not found. Please install python."
  exit 1
fi
if ! command -v jq --version &>/dev/null; then
  echo -e "\n\e[31mERROR:\e[0m Prerequisite check: jq not found. Please install jq."
  exit 1
fi
echo -e 'done.'

# check if python version is 3.9 or higher
pythonMajorVersion=$(python -V | cut -d' ' -f2 | cut -d'.' -f1)
pythonMinorVersion=$(python -V | cut -d' ' -f2 | cut -d'.' -f2)
pythonVersion="${pythonMajorVersion}.${pythonMinorVersion}"
if [[ "${pythonMajorVersion}" -lt 3 ]] ||
  { [[ "${pythonMajorVersion}" -eq 3 ]] && [[ "${pythonMinorVersion}" -lt 9 ]]; }; then
  echo -e "\e[31mERROR:\e[0m Prerequisite check: Python version 3.9 or higher required. Found version: ${pythonVersion}"
  exit 1
fi

# temporary files
fullSavTmpFile="$(mktemp -u -p "$(pwd)")"
fullTmpJsonFile="$(mktemp -u -p "$(pwd)").all.json"
palsTmpJsonFile="$(mktemp -u -p "$(pwd)").pals.json"

echo -en '\e[34mINFO:\e[0m Copying palworld save data file ...'
cp "${sourceSavFile}" "${fullSavTmpFile}"
echo 'done.'
echo -e "\e[34mINFO:\e[0m Copy of save data now exists at ${fullSavTmpFile}"

echo -e '\e[34mINFO:\e[0m Converting palworld save data file to json using palworld-save-tools ...'
python "${saveToolsConvertScript}" \
  --convert-nan-to-null \
  --to-json \
  --force \
  --output "${fullTmpJsonFile}" \
  --custom-properties ${saveFileCustomProperties} \
  --minify-json \
  "${fullSavTmpFile}"
echo -e '\e[34mINFO:\e[0m Palworld save data conversion complete.'

# use jq to extract the CharacterSaveParameterMap value to separate file
echo -en '\e[34mINFO:\e[0m Extracting pals data to separate json file ...'
jq -c '.properties.worldSaveData.value.CharacterSaveParameterMap.value' "${fullTmpJsonFile}" >"${palsTmpJsonFile}"
echo -e 'done.'

# shellcheck disable=SC2016
jqScript='map(
  .value.RawData.value.object.SaveParameter.value.CharacterID.value as $CharacterID
  | .value.RawData.value.object.SaveParameter.value.Gender.value.value as $Gender
  | (.value.RawData.value.object.SaveParameter.value.NickName.value // "") as $NickName
  | .value.RawData.value.object.SaveParameter.value.Level.value as $Level
  | .value.RawData.value.object.SaveParameter.value.CraftSpeed.value as $CraftSpeed
  | .value.RawData.value.object.SaveParameter.value.Talent_HP.value as $Talent_HP
  | .value.RawData.value.object.SaveParameter.value.Talent_Melee.value as $Talent_Melee
  | .value.RawData.value.object.SaveParameter.value.Talent_Shot.value as $Talent_Shot
  | .value.RawData.value.object.SaveParameter.value.Talent_Defense.value as $Talent_Defense
  | (.value.RawData.value.object.SaveParameter.value.PassiveSkillList.value.values // []) | sort as $Passives
  | ($Passives[0] // "") as $Passive1
  | ($Passives[1] // "") as $Passive2
  | ($Passives[2] // "") as $Passive3
  | ($Passives[3] // "") as $Passive4
  | $Passives | length as $PassivesCount
  | {
    CharacterID:    $CharacterID,
    NickName:       $NickName,
    Gender :        $Gender,
    Level:          $Level,
    CraftSpeed:     $CraftSpeed,
    IV_HP:          $Talent_HP,
    IV_Melee:       $Talent_Melee,
    IV_Shot:        $Talent_Shot,
    IV_Defense:     $Talent_Defense,
    PassivesCount:  $PassivesCount,
    Passive1:       $Passive1,
    Passive2:       $Passive2,
    Passive3:       $Passive3,
    Passive4:       $Passive4
  })
'

echo -en '\e[34mINFO:\e[0m Looking for pals ...'
palsCount=$(jq -r 'length' "${palsTmpJsonFile}")
if [[ "${palsCount}" -eq 0 ]]; then
  echo -e "\n\e[31mERROR:\e[0m No pals data found in ${palsTmpJsonFile}"
  exit 1
fi
echo -e 'done.'
echo -e "\e[34mINFO:\e[0m Found ${palsCount} pals."

echo -en '\e[34mINFO:\e[0m Parsing relevant data ...'
jq -c "${jqScript}" "${palsTmpJsonFile}" >"${outputPalsDataFile}"
echo -e 'done.'
echo -e "\e[34mINFO:\e[0m Pals data saved to ${outputPalsDataFile}"

echo -en "\e[34mINFO:\e[0m Cleaning up temporary files ..."
rm "${fullSavTmpFile}"
rm "${fullTmpJsonFile}"
rm "${palsTmpJsonFile}"
echo -e 'done.\n'
echo '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'
