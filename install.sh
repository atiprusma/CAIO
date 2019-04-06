if [ -z $UF ]; then
  UF=$TMPDIR/common/unityfiles
  unzip -oq "$ZIPFILE" 'common/unityfiles/util_functions.sh' -d $TMPDIR >&2
  [ -f "$UF/util_functions.sh" ] || { ui_print "! Unable to extract zip file !"; exit 1; }
  . $UF/util_functions.sh
fi

comp_check
#MINAPI=21
#MAXAPI=25
#DYNLIB=true
#SYSOVER=true
DEBUG=true
#SKIPMOUNT=true

REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

REPLACE="
"
print_modname() {
  center_and_print
  ui_print "    *******************************************"
  ui_print "    *    Special credit to TadiT7 @ github    *"
  ui_print "    *          for numerous ROM dumps         *"
  ui_print "    *******************************************"
  ui_print " "
  unity_main
}

set_permissions() {
 : #oof
}

unity_custom() {
  DEVNAME=$(grep_prop ro.product.model)
  DEVCODE=$(grep_prop ro.build.product)
  # Device check
  if [ "$DEVCODE" == "jasmine" -o "jasmine_sprout" -o "wayne" -o "whyred" ]; then
      [ $DEVCODE == "wayne" ] && DEVNAME="Mi 6X"
      ui_print " "
      ui_print "- Your $DEVNAME ($DEVCODE) is compatible device"
      sed -i "s/Mi 6X/$DEVNAME/g" $TMPDIR/common/system.prop
      sed -i "s/meme/$DEVNAME/g" $TMPDIR/module.prop
  else
      ui_print " "
      ui_print " ! Your $DEVNAME ($DEVCODE) is incompatible !"
      abort 1
  fi
}
