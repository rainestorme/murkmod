#!/bin/bash
# menu_plugin
PLUGIN_NAME="Wallpaper Manager"
PLUGIN_FUNCTION="Manage wallpaper"
PLUGIN_DESCRIPTION="Allows you to manage policy-set wallpapers through Pollen automagically"
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

# Prompt the user to choose a file from /home/chronos/user/Downloads/
echo "Choose a jpg or png from your Downloads folder"
PS3="Enter the number of the file you want to choose: "
options=($(ls -1 /home/chronos/user/Downloads | grep -E '\.(jpg|png)$'))
select opt in "${options[@]}"
do
    if [[ -n "$opt" ]]; then
        image_path="/home/chronos/user/Downloads/$opt"
        break
    fi
done

# Fetch the SHA256 hash of the image file
hash=$(sha256sum "$image_path" | cut -d ' ' -f 1)

# Construct the new JSON object with the updated values
new_json="{\"hash\": \"$hash\", \"url\": \"file://$image_path\"}"

# Update the "WallpaperImage" key in the JSON file with the new values
json_file="/etc/opt/chrome/policies/managed/policy.json"
if grep -q "\"WallpaperImage\":" "$json_file"; then
    # "WallpaperImage" key already exists in the JSON file, update its value
    sed -i "s/\(\"WallpaperImage\":{\).*\(:{.*\)\(}\)/\1$new_json\3/" "$json_file"
else
    # "WallpaperImage" key does not exist in the JSON file, add it to the end
    sed -i "s/\(}\)$/,\n    \"WallpaperImage\": $new_json\n\1/" "$json_file"
fi

echo "Set wallpaper successfully."
