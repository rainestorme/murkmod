show_plugins() {
    plugins_dir="/mnt/stateful_partition/murkmod/plugins"
    plugin_files=()
    plugin_info=()
    plugin_map=()

    [[ -d "$plugins_dir" ]] || mkdir -p "$plugins_dir"

    while IFS= read -r -d '' file; do
        plugin_files+=("$file")
    done < <(find "$plugins_dir" -type f -name "*.sh" -print0)

    for plugin_script in "${plugin_files[@]}"; do
        mapfile -t meta < <(sed -n '1,200p' "$plugin_script" | sed 's/\r$//')

        PLUGIN_NAME=""
        PLUGIN_FUNCTION=""
        PLUGIN_DESCRIPTION=""
        PLUGIN_AUTHOR=""
        PLUGIN_VERSION=""
        MENU_MARKER=0

        for line in "${meta[@]}"; do
            [[ "$line" =~ ^[[:space:]]*#?[[:space:]]*menu_plugin[[:space:]]*$ ]] && MENU_MARKER=1
            [[ "$line" =~ ^[[:space:]]*PLUGIN_NAME[[:space:]]*=[[:space:]]*(.*)$ ]] && PLUGIN_NAME="${BASH_REMATCH[1]//\"/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_FUNCTION[[:space:]]*=[[:space:]]*(.*)$ ]] && PLUGIN_FUNCTION="${BASH_REMATCH[1]//\"/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_DESCRIPTION[[:space:]]*=[[:space:]]*(.*)$ ]] && PLUGIN_DESCRIPTION="${BASH_REMATCH[1]//\"/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_AUTHOR[[:space:]]*=[[:space:]]*(.*)$ ]] && PLUGIN_AUTHOR="${BASH_REMATCH[1]//\"/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_VERSION[[:space:]]*=[[:space:]]*(.*)$ ]] && PLUGIN_VERSION="${BASH_REMATCH[1]//\"/}"
            [[ -n "$PLUGIN_FUNCTION" && -n "$PLUGIN_NAME" && $MENU_MARKER -eq 1 ]] && break
        done

        [[ $MENU_MARKER -eq 1 || -n "$PLUGIN_FUNCTION" ]] || continue
        [[ -z "$PLUGIN_NAME" ]] && PLUGIN_NAME="$(basename "$plugin_script")"
        [[ -z "$PLUGIN_AUTHOR" ]] && PLUGIN_AUTHOR="<no author>"
        [[ -z "$PLUGIN_VERSION" ]] && PLUGIN_VERSION="<no version>"
        plugin_info+=("$PLUGIN_NAME|$PLUGIN_FUNCTION|$PLUGIN_AUTHOR|$PLUGIN_VERSION")
        plugin_map+=("$plugin_script")
    done

    [[ ${#plugin_info[@]} -eq 0 ]] && { echo "No plugins found."; return 0; }

    printf "#   %-25s %-35s %-20s %-10s\n" "Name" "Function" "Author" "Version"
    printf -- '%.0s-' {1..100}; echo

    for i in "${!plugin_info[@]}"; do
        IFS='|' read -r name func author ver <<< "${plugin_info[$i]}"
        printf "%-3s %-25s %-35s %-20s %-10s\n" "$((i+1))" "$name" "$func" "$author" "$ver"
    done

    read -p "> Select a plugin (or q to quit): " selection
    selection="${selection//$'\r'/}"

    [[ "$selection" = "q" ]] && return 0
    if ! [[ "$selection" =~ ^[1-9][0-9]*$ ]] || (( selection < 1 || selection > ${#plugin_info[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    selected_file="${plugin_map[$((selection-1))]}"
    bash <(cat "$selected_file")
}
