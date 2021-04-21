#!/usr/bin/env bash
set -eu

echo "# NSUserKeyEquivalents utility"
select mode in Backup Restore; do

    case $mode in
        Backup)
            # find all Preferences domains that have NSUserKeyEquivalents defined
            domains=(
            -globalDomain
            $(
            defaults find NSUserKeyEquivalents |
            sed '
                /^Found .* keys in domain/!d
                s/.*'\''\([^'\'']*\)'\''.*/\1/
            ' |
            sort
            ))
            # generate shell commands for every menu-keybinding entry
            for domain in "${domains[@]}"; do
                defaults read "$domain" NSUserKeyEquivalents |
                sed '
                    /".*" = ".*";/!d
                    s/.*"\([^"]*\)".*=.*"\([^"]*\)";/"\1" '\''\2'\''/
                    s/^/NSUserKeyEquivalents '\'$domain\'' /
                '
            done |
            # replace what's at the bottom of this script
            sed -e '1,/^########*$/!d' -e '/^########*$/r /dev/stdin' -i~ "$0"
            exit
            ;;

        Restore)
            break
            ;;

        *)
    esac
done

NSUserKeyEquivalents() {
    local domain=$1
    local menu=$2 key=$3
    while read -p "Update $domain's keyboard shortcut for \"$menu\" to $key? [y/N] " -n 1 -s; echo $REPLY; do
        case $REPLY in
            [yY])
                (set -x
                defaults write "$domain" NSUserKeyEquivalents \
                    -dict-add "$menu" "$key"
                )
                break
                ;;
            [nN]) break ;;
        esac
    done
}
################################################################################
NSUserKeyEquivalents 'com.omnigroup.OmniFocus3' "Quit OmniFocus" '@$q'
NSUserKeyEquivalents 'com.omnigroup.OmniFocus3' "Search Here" '@p'
