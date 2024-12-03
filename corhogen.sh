#!/usr/bin/env bash

#region SERVICES

run_wait_for_addon() {

    # Handle parameters
    local addonid="${1:-}"

    # Invoke command
    while true; do
        local address='localhost:8080'
        local headers='content-type:application/json'
        local payload='[{"jsonrpc":"2.0","method":"Addons.GetAddonDetails","params":{"addonid": "'"$addonid"'", "properties":["name","path","dependencies","broken","enabled","installed"]},"id":1}]'
        local details="$(curl "http://$address/jsonrpc" -H "$headers" -d "$payload")"
        factor1="$(echo "$details" | jq -r '.[0].result.addon.broken' || true)"
        factor2="$(echo "$details" | jq -r '.[0].result.addon.installed' || true)"
        factor3="$(echo "$details" | jq -r '.[0].result.addon.enabled' || true)"
        [[ "$factor1" == "false" && "$factor2" == "true" && "$factor3" == "true" ]] && return 0
        sleep 1
    done
    return 1

}

set_addon() {

    # Handle parameters
    local addonid="${1}"
    local enabled="${2}"

    # Invoke command
    local address="localhost:8080"
    local headers="content-type:application/json"
    local payload='{"jsonrpc":"2.0","method":"Addons.SetAddonEnabled","params":{"addonid":"'"$addonid"'","enabled":'"$enabled"'},"id":1}'
    curl -s -H "$headers" -d "$payload" "http://$address/jsonrpc"

}

set_favourite() {

    # Handle parameters
    local heading="${1}"
    local variant="${2}"
    local deposit="${3}"
    local picture="${4}"

    # Assert presence
    # run_update_entware
    # /opt/bin/opkg install jq
    # local address='localhost:8080'
    # local headers='content-type:application/json'
    # local payload='{"jsonrpc": "2.0","method": "Favourites.GetFavourites","params": {},"id": 1}'
    # local details="$(curl "http://$address/jsonrpc" -H "$headers" -d "$payload")"
    # [[ "$details" == *"$heading"* ]] && return 0

    # Invoke command
    local address="localhost:8080"
    local headers="content-type:application/json"
    local payload='{"jsonrpc":"2.0","method":"Favourites.AddFavourite","params":{"title":"'"$heading"'","type":"window","window":"'"$variant"'","windowparameter":"'"$deposit"'","thumbnail":"'"$picture"'"},"id":1}'
    echo $payload
    curl -H "$headers" -d "$payload" "http://$address/jsonrpc" && sleep 2

}

set_webserver() {

    # Handle parameters
    local enabled="${1:-false}"
    local secured="${2:-true}"
    local webuser="${3:-kodi}"
    local webpass="${4:-}"

    # Launch kodi
    systemctl stop kodi && sleep 4

    # Change settings
    local configs="$HOME/.kodi/userdata/guisettings.xml"
    set_xml_setting "$configs" '//*[@id="services.webserver"]' "$enabled"
    set_xml_setting "$configs" '//*[@id="services.webserverauthentication"]' "$secured"
    set_xml_setting "$configs" '//*[@id="services.webserverusername"]' "$webuser"
    set_xml_setting "$configs" '//*[@id="services.webserverpassword"]' "$webpass"

    # Finish kodi
    systemctl start kodi && sleep 4

}

set_xml_setting() {

    # Handle parameters
    local xmlfile="${1}"
    local pattern="${2}"
    local payload="${3}"
    local default="${4:-true}"

    # Change xml
    xmlstarlet ed -L -u "$pattern" -v "$payload" "$xmlfile"
    [[ "$default" == "true" ]] && xmlstarlet ed -L -u "$pattern/@default" -v 'false' "$xmlfile"

}

#endregion

#region GENERALS

run_update_coreelec() {

    # TODO: Change autoupdate setting
    # TODO: Remove show dialog after update setting

}

run_update_estuary() {

    # Change settings
    systemctl stop kodi && sleep 4
    local configs="$HOME/.kodi/userdata/addon_data/skin.estuary/settings.xml"
    set_xml_setting "$configs" '//*[@id="homemenunofavbutton"]' 'false'
    set_xml_setting "$configs" '//*[@id="homemenunogamesbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunomoviebutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunomusicbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunomusicvideobutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunopicturesbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunoprogramsbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunoradiobutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunotvbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunotvshowbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunovideosbutton"]' 'true'
    set_xml_setting "$configs" '//*[@id="homemenunoweatherbutton"]' 'true'
    systemctl start kodi && sleep 4

    # Remove favourites
    rm "$HOME/.kodi/userdata/favourites.xml"
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4

    # Update favourites
    set_favourite "MOVIES\n " "10025" "videodb://movies/titles/" "DefaultMovies.png"
    set_favourite "SERIES\n " "10025" "special://profile/playlists/video/Series.xsp" "DefaultTVShows.png"
    set_favourite "ANIMES\n " "10025" "special://profile/playlists/video/Animes.xsp" "DefaultAddonLookAndFeel.png"
    set_favourite "YOUTUBE\n " "10025" "plugin://plugin.video.youtube/" ""
    set_favourite "FENLIGHT\n " "10025" "plugin://plugin.video.fenlight/" ""
    set_favourite "LESALKODIQUES\n " "10025" "plugin://plugin.video.vstream/?function=load&sFav=load&site=pastebin&siteUrl=http%3a%2f%2fvenom&title=PasteBin" ""
    set_favourite "OTAKU\n " "10025" "plugin://plugin.video.otaku/" ""
    set_favourite "UMBRELLA\n " "10025" "plugin://plugin.video.umbrella/" ""
    # set_favourite "CUMINATION\n " "10025" "plugin://plugin.video.cumination/" ""

}

run_update_kodi() {

    # Enable webserver
    set_webserver "true" "false"

    # Finish kodi
    systemctl stop kodi && sleep 4

    # Change settings
    # TODO: Remove gui sounds
    local configs="$HOME/.kodi/userdata/guisettings.xml"
    set_xml_setting "$configs" '//*[@id="addons.unknownsources"]' 'true'
    set_xml_setting "$configs" '//*[@id="addons.updatemode"]' '1'
    set_xml_setting "$configs" '//*[@id="audiooutput.channels"]' '10'
    set_xml_setting "$configs" '//*[@id="audiooutput.dtshdpassthrough"]' 'true'
    set_xml_setting "$configs" '//*[@id="audiooutput.dtspassthrough"]' 'true'
    set_xml_setting "$configs" '//*[@id="audiooutput.eac3passthrough"]' 'true'
    set_xml_setting "$configs" '//*[@id="audiooutput.passthrough"]' 'true'
    set_xml_setting "$configs" '//*[@id="audiooutput.truehdpassthrough"]' 'true'
    set_xml_setting "$configs" '//*[@id="filelists.showparentdiritems"]' 'false'
    set_xml_setting "$configs" '//*[@id="videolibrary.backgroundupdate"]' 'true'
    set_xml_setting "$configs" '//*[@id="locale.audiolanguage"]' 'mediadefault'
    set_xml_setting "$configs" '//*[@id="locale.country"]' 'Belgique'
    set_xml_setting "$configs" '//*[@id="locale.timezone"]' 'Europe/Brussels'
    set_xml_setting "$configs" '//*[@id="locale.subtitlelanguage"]' 'original'
    set_xml_setting "$configs" '//*[@id="subtitles.bordersize"]' '25'
    set_xml_setting "$configs" '//*[@id="subtitles.colorpick"]' 'FFFFFFFF'
    set_xml_setting "$configs" '//*[@id="videoplayer.adjustrefreshrate"]' '2'
    set_xml_setting "$configs" '/settings/viewstates/videonavtitles/sortattributes' '0'
    set_xml_setting "$configs" '/settings/viewstates/videonavtitles/sortmethod' '40'
    set_xml_setting "$configs" '/settings/viewstates/videonavtitles/sortorder' '2'
    set_xml_setting "$configs" '/settings/viewstates/videonavtitles/viewmode' '131572' # wall
    set_xml_setting "$configs" '/settings/viewstates/videonavtvshows/sortattributes' '0'
    set_xml_setting "$configs" '/settings/viewstates/videonavtvshows/sortmethod' '40'
    set_xml_setting "$configs" '/settings/viewstates/videonavtvshows/sortorder' '2'
    set_xml_setting "$configs" '/settings/viewstates/videonavtvshows/viewmode' '131572' # wall

    # Change keyboard
    local configs="$HOME/.kodi/userdata/keymaps/keyboard.xml"
    mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
    echo '<keymap>' | tee -a "$configs"
    echo '    <fullscreenvideo>' | tee -a "$configs"
    echo '        <keyboard>' | tee -a "$configs"
    echo '            <backspace>Stop</backspace>' | tee -a "$configs"
    echo '            <key id="216">Stop</key>' | tee -a "$configs"
    echo '        </keyboard>' | tee -a "$configs"
    echo '    </fullscreenvideo>' | tee -a "$configs"
    echo '</keymap>' | tee -a "$configs"

    # Launch kodi
    systemctl start kodi && sleep 8

}

#endregion

#region UPDATERS

run_update_cocoscrapers() {

    # Update repository
    local address="https://github.com/CocoJoe2411/repository.cocoscrapers/raw/refs/heads/main/zips/repository.cocoscrapers/repository.cocoscrapers-1.0.0.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.cocoscrapers"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="script.module.cocoscrapers"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

}

run_update_cumination() {

    # Update repository
    local address="https://dobbelina.github.io/repository.dobbelina-1.0.4.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.dobbelina"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="plugin.video.cumination"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    # kodi-send -a "RunAddon($addonid)" && sleep 4
    # systemctl stop kodi && sleep 4
    # local configs="$HOME/.kodi/userdata/addon_data/plugin.video.cumination/settings.xml"
    # systemctl start kodi && sleep 4

}

run_update_entware() {

    # Update package
    echo n | /usr/sbin/installentware
    /opt/bin/opkg update
    /opt/bin/opkg upgrade

}

run_update_fenlight() {

    # Update plugin
    local address="https://tikipeter.github.io/packages/plugin.video.fenlight-2.0.04.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="plugin.video.fenlight"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    systemctl stop kodi && sleep 4
    local configs="$HOME/.kodi/userdata/addon_data/plugin.video.fenlight/databases/settings.db"
    # INFO: sqlite3 "$configs" "select * from settings"
    sqlite3 "$configs" "update settings set setting_value = 'script.module.cocoscrapers' where setting_id = 'external_scraper.module'"
    sqlite3 "$configs" "update settings set setting_value = 'CocoScrapers Module' where setting_id = 'external_scraper.name'"
    sqlite3 "$configs" "update settings set setting_value = true where setting_id = 'provider.external'"
    systemctl start kodi && sleep 4

}

run_update_lesalkodiques() {

    # Update repository
    local address="https://kodi-vstream.github.io/repo/repository.vstream-0.0.6.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.vstream"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="plugin.video.vstream"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    systemctl stop kodi && sleep 4
    local configs="$HOME/.kodi/userdata/addon_data/plugin.video.vstream/settings.xml"
    set_xml_setting "$configs" '//*[@id="pastebin_url"]' "https://paste.lesalkodiques.com/raw/"
    set_xml_setting "$configs" '//*[@id="srt-view"]' "true"
    local members=(
        "pastebin_label_1 Films"
        "pastebin_id_1 1eda79b1"
        "pastebin_label_2 Séries"
        "pastebin_id_2 6730992c"
        "pastebin_label_3 Documentaires"
        "pastebin_id_3 00c0fdec"
        "pastebin_label_4 Concerts"
        "pastebin_id_4 017cea8a"
        "pastebin_label_5 Cartoons"
        "pastebin_id_5 fff5fe57"
        "pastebin_label_6 Animés"
        "pastebin_id_6 e227f398"
        # "pastebin_label_7 Québec"
        # "pastebin_id_7 5da625b7"
    )
    for element in "${members[@]}"; do
        k="${element%% *}"
        v="${element#* }"
        c=$(xmlstarlet sel -t -v "//setting[@id='$k']" "$configs" 2>/dev/null) &&
            [ "$c" != "$v" ] &&
            xmlstarlet ed -L -u "//setting[@id='$k']" -v "$v" "$configs" ||
            xmlstarlet ed -L -s "/settings" -t elem -n "setting" -v "$v" -i "//settings/setting[last()]" -t attr -n "id" -v "$k" "$configs" ||
            true
    done
    systemctl start kodi && sleep 4

}

run_update_otaku() {

    # Update repository
    local address="https://github.com/Goldenfreddy0703/repository.otaku/raw/refs/heads/master/repository.otaku-1.0.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.otaku"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="plugin.video.otaku"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    # systemctl stop kodi && sleep 4
    # local configs="$HOME/.kodi/userdata/addon_data/plugin.video.otaku/settings.xml"
    # systemctl start kodi && sleep 4

}

run_update_sources() {

    # Create directories
    local deposit="$(find "/var/media" -maxdepth 1 -type d | sort -r | head -1)"
    [[ -n "$deposit" ]] && mkdir -p "$deposit/Animes"
    [[ -n "$deposit" ]] && mkdir -p "$deposit/Movies"
    [[ -n "$deposit" ]] && mkdir -p "$deposit/Series"

    # Create playlists
    systemctl stop kodi && sleep 4
    local configs="$HOME/.kodi/userdata/playlists/video/Animes.xsp"
    mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>' | tee -a "$configs"
    echo '<smartplaylist type="tvshows">' | tee -a "$configs"
    echo '    <name>Animes</name>' | tee -a "$configs"
    echo '    <match>all</match>' | tee -a "$configs"
    echo '    <rule field="path" operator="contains">' | tee -a "$configs"
    echo '        <value>animes</value>' | tee -a "$configs"
    echo '    </rule>' | tee -a "$configs"
    echo '    <order direction="ascending">sorttitle</order>' | tee -a "$configs"
    echo '</smartplaylist>' | tee -a "$configs"
    local configs="$HOME/.kodi/userdata/playlists/video/Series.xsp"
    mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>' | tee -a "$configs"
    echo '<smartplaylist type="tvshows">' | tee -a "$configs"
    echo '    <name>Series</name>' | tee -a "$configs"
    echo '    <match>all</match>' | tee -a "$configs"
    echo '    <rule field="path" operator="contains">' | tee -a "$configs"
    echo '        <value>series</value>' | tee -a "$configs"
    echo '    </rule>' | tee -a "$configs"
    echo '    <order direction="ascending">sorttitle</order>' | tee -a "$configs"
    echo '</smartplaylist>' | tee -a "$configs"
    systemctl start kodi && sleep 4

    # TODO: Add sources with sqlite
    # systemctl stop kodi && sleep 4
    # local configs="$HOME/.kodi/userdata/sources.xml"
    # mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
    # echo '<sources>' | tee -a "$configs"
    # echo '    <programs>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '    </programs>' | tee -a "$configs"
    # echo '    <video>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '        <source>' | tee -a "$configs"
    # echo '            <name>Animes</name>' | tee -a "$configs"
    # echo "            <path pathversion=\"1\">$deposit/Animes/</path>" | tee -a "$configs"
    # echo '            <allowsharing>true</allowsharing>' | tee -a "$configs"
    # echo '        </source>' | tee -a "$configs"
    # echo '        <source>' | tee -a "$configs"
    # echo '            <name>Movies</name>' | tee -a "$configs"
    # echo "            <path pathversion=\"1\">$deposit/Movies/</path>" | tee -a "$configs"
    # echo '            <allowsharing>true</allowsharing>' | tee -a "$configs"
    # echo '        </source>' | tee -a "$configs"
    # echo '        <source>' | tee -a "$configs"
    # echo '            <name>Series</name>' | tee -a "$configs"
    # echo "            <path pathversion=\"1\">$deposit/Series/</path>" | tee -a "$configs"
    # echo '            <allowsharing>true</allowsharing>' | tee -a "$configs"
    # echo '        </source>' | tee -a "$configs"
    # echo '    </video>' | tee -a "$configs"
    # echo '    <music>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '    </music>' | tee -a "$configs"
    # echo '    <pictures>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '    </pictures>' | tee -a "$configs"
    # echo '    <files>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '            <name>Extras</name>' | tee -a "$configs"
    # echo "            <path pathversion=\"1\">$deposit/Extras/</path>" | tee -a "$configs"
    # echo '            <allowsharing>true</allowsharing>' | tee -a "$configs"
    # echo '        </source>' | tee -a "$configs"
    # echo '    </files>' | tee -a "$configs"
    # echo '    <games>' | tee -a "$configs"
    # echo '        <default pathversion="1"></default>' | tee -a "$configs"
    # echo '    </games>' | tee -a "$configs"
    # echo '</sources>' | tee -a "$configs"
    # systemctl start kodi && sleep 4

}

run_update_transmission() {

    # Create directories
    local deposit="$(find "/var/media" -maxdepth 1 -type d | sort -r | head -1)"
    [[ -n "$deposit" ]] && mkdir -p "$deposit/Extras"
    [[ -n "$deposit" ]] && mkdir -p "$deposit/Extras/Incomplete"

    # Update dependencies
    run_update_entware
    /opt/bin/opkg install jq moreutils
    /opt/bin/opkg install transmission-web transmission-daemon

    # Change settings
    /opt/etc/init.d/S88transmission stop
    local configs="$HOME/.opt/etc/transmission/settings.json"
    local deposit="$(find /var/media -maxdepth 1 -type d | sort -r | head -1)"
    [[ -n "$deposit" ]] && /opt/bin/jq ".\"download-dir\" = \"$deposit/Extras\"" "$configs" | /opt/bin/sponge "$configs"
    [[ -n "$deposit" ]] && /opt/bin/jq ".\"incomplete-dir\" = \"$deposit/Extras/Incomplete\"" "$configs" | /opt/bin/sponge "$configs"
    /opt/bin/jq '."incomplete-dir-enabled" = true' "$configs" | /opt/bin/sponge "$configs"
    /opt/bin/jq ".\"ratio-limit\" = 0.0" "$configs" | /opt/bin/sponge "$configs"
    /opt/bin/jq '."ratio-limit-enabled" = true' "$configs" | /opt/bin/sponge "$configs"
    /opt/etc/init.d/S88transmission start

}

run_update_umbrella() {

    # Update repository
    local address="https://umbrellaplug.github.io/repository.umbrella-2.2.6.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.umbrella"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    rm -fr "${deposit:?}/$addonid"
    mv "$deposit/repository.umbrellaplug.github.io" "$deposit/$addonid" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" "true" && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="plugin.video.umbrella"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    systemctl stop kodi && sleep 4
    local configs="$HOME/.kodi/userdata/addon_data/plugin.video.umbrella/settings.xml"
    set_xml_setting "$configs" '//*[@id="provider.external.enabled"]' "true"
    set_xml_setting "$configs" '//*[@id="external_provider.module"]' "script.module.cocoscrapers"
    set_xml_setting "$configs" '//*[@id="external_provider.name"]' "cocoscrapers"
    systemctl start kodi && sleep 4

}

run_update_youtube() {

    # Update dependencies
    run_update_entware
    /opt/bin/opkg install jq moreutils

    # Update repository
    local address="https://ftp.fau.de/osmc/osmc/download/dev/anxdpanic/repositories/repository.yt.unofficial-2.0.7.zip"
    local deposit="$HOME/.kodi/addons"
    local addonid="repository.yt.unofficial"
    kodi-send -a "Extract($address, $deposit)" && sleep 4
    systemctl stop kodi && sleep 4 && systemctl start kodi && sleep 4
    set_addon "$addonid" true && sleep 4
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Update plugin
    local addonid="plugin.video.youtube"
    kodi-send -a "InstallAddon($addonid)" && sleep 4
    kodi-send -a "SendClick(11)"
    run_wait_for_addon "$addonid"

    # Change settings
    # systemctl stop kodi && sleep 4
    # local apikeys="$HOME/.kodi/userdata/addon_data/plugin.video.youtube/api_keys.json"
    # local configs="$HOME/.kodi/userdata/addon_data/plugin.video.youtube/settings.xml"
    # set_xml_setting "$configs" '//*[@id="kodion.setup_wizard"]' "false"
    # systemctl stop kodi && sleep 4

}

#endregion

main() {

    run_update_coreelec
    run_update_kodi
    run_update_sources
    run_update_transmission
    run_update_cocoscrapers
    # run_update_cumination
    run_update_lesalkodiques
    run_update_fenlight
    run_update_otaku
    run_update_umbrella
    run_update_youtube
    run_update_estuary

}

main "$@"
