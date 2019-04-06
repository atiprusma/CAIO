# Things that ONLY run during an upgrade - you probably won't need this
# A use for this would be to back up app data before it's wiped if your module includes an app
# NOTE: the normal upgrade process is just an uninstall followed by an install
if $BOOTMODE;
then
    ui_print "- Magisk Manager upgrade detected, go ahead"
    return 1
else
    abort  "! Please upgrade from Magisk Manager !"
fi