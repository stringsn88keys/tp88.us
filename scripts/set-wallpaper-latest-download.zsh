set_wallpaper_latest_download() {
    local img
    img=$(
        find ~/Downloads -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.heic" \
               -o -iname "*.bmp"  -o -iname "*.tiff" \) \
            -print0 \
        | xargs -0 ls -t 2>/dev/null \
        | head -1
    )

    if [[ -z "$img" ]]; then
        echo "set_wallpaper_latest_download: no image found in ~/Downloads" >&2
        return 1
    fi

    osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"${img}\""
    echo "Wallpaper set to: $img"
}

# Run directly when executed as a script; define only when sourced
[[ -n "$ZSH_SCRIPT" ]] && set_wallpaper_latest_download
