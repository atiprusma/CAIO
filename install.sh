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
  # Device check vars
  DEVNAME=$(grep_prop ro.product.model)
  DEVCODE=$(grep_prop ro.build.product)
  DEVLIST="
  daisy_sprout
  jasmine_sprout
  tulip
  wayne
  whyred
  "
  # Begin checking devices
  if $MAGISK; then
     [ "$DEVCODE" ==  "wayne" ] && DEVNAME="Mi 6X"
     LANJUT=false
     for HP in ${DEVLIST}; do
       [ "$DEVCODE" == "$HP" ] && LANJUT=true
     done
     if $LANJUT; then
       ui_print "- Your $DEVNAME ($DEVCODE) is supported"
       sed -i "s/UnF/$DEVNAME/g" $TMPDIR/module.prop
     else
       abort "  ! Your $DEVNAME ($DEVCODE) is not supported"
     fi
  else
     abort " ! $MODID only for magisk for system file safety !"
  fi
}
