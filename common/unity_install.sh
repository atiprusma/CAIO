# Vars
MICAM="MiuiCamera"
CUS=$TMPDIR/custom
DFO=$ORIGDIR/system/etc/device_features/$DEVCODE.xml
DFM=$TMPDIR/system/etc/device_features/$DEVCODE.xml
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)

# Additional MIUI Camera features
TAMBAL() {
  V=$(cat $DFM | grep -nw $1 | cut -d'>' -f2 | cut -d'<' -f1)
  W=$(cat $DFM | grep -nw $1 | cut -d':' -f1)
  X=$(($W - 1))
  Y=$(($(cat $DFM | grep -n '<bool' | tail -n2 | head -n1 | cut -d: -f1) + $X))
  if [ ! "$X" == "-1" ]; then
    if [ ! "$V" == "$2" ]; then
      sed -i "$W s/$V/$2/" $DFM 2>/dev/null;
      sed -i "$X a\    <!-- Modified by $MODID -->" $DFM 2>/dev/null
    else
      continue
    fi  
  else
    sed -i "$Y a\    <bool name=\"$1\">$2</bool>" $DFM 2>/dev/null
    sed -i "$(($Y + $X)) a\    <!-- Added by $MODID -->" $DFM 2>/dev/null
  fi
}

# Install stuffs
GORENG() {
  ui_print "  > Pushing $1 files to /system/$2"
  for L in $(find $TMPDIR/$1 -type f -name "*.*"); 
  do
      [ ! -d $TMPDIR/system/$2 ] && mkdir -p $TMPDIR/system/$2 2>/dev/null
      cp -f $L $TMPDIR/system/$2/$(basename $L) 2>/dev/null
  done
  sleep 3
}

# Cleanups
BERSIHIN() {
  ui_print "  > Cleaning up old app data"
  for b in $(find /data -name "*MiuiCamera*" -o -name "*com.android.camera*"); 
  do
      [ "$(echo $b | cut -d'/' -f-4)" == "/data/media/0" ] && continue
      if [ -d "$b" ]; then
          rm -rf $b 2>/dev/null 2>/dev/null
      else
          rm -f $b 2>/dev/null 2>/dev/null
      fi
  done
}

# Find and replace installed MIUI Camera
PASANG() {
  ui_print "  > $1 selected"
  BERSIHIN
  SYSCAM=$(find $ORIGDIR/system/priv-app -type d -name "*MiuiCamera*")
  if [ -d "$SYSCAM" ]; then
      MICAM=$(echo $SYSCAM | cut -d'/' -f7 | head -n1)
      mktouch $TMPDIR/system/priv-app/$MICAM/.replace 2>/dev/null
  else
      MICAM="$1"Camera
      [ ! "$1" == "Part7" ] && { ui_print " "; ui_print "  Notes: $1 need manual permissions granting"; }
      cp_ch -i $CUS/perms.xml $TMPDIR/system/etc/permissions/privapp-permissions-com.android.camera.xml 2>/dev/null
      cp_ch -i $CUS/perms.xml $TMPDIR/system/vendor/etc/permissions/privapp-permissions-com.android.camera.xml 2>/dev/null
  fi
  mkdir -p $TMPDIR/system/priv-app/$MICAM 2/dev/null
  cp -f $CUS/$1.apk $TMPDIR/system/priv-app/$MICAM/$MICAM.apk 2>/dev/null
  sleep 3
}

EISENC() {
  ui_print " "
  ui_print "- Enable EIS? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      ui_print "  > EIS enabled"
      sed -i "s/eis.enable=0/eis.enable=1/g" $TMPDIR/custom/aosplos.prop
      sed -i "s/eis.enable=0/eis.enable=1/g" $TMPDIR/custom/miui.prop
      sed -i "s/disable EIS/enable EIS/g" $TMPDIR/module.prop
  else
      ui_print "  > EIS disabled"
  fi

  if [ $API -ge 28 ];
  then
      ui_print " "
      ui_print "- Patch video encoder? -"
      ui_print "  Vol+ (Up)   = Yes"
      ui_print "  Vol- (Down) = No"
      if $VKSEL; then
          unzip -oq $CUS/Encoder -d $TMPDIR 2>/dev/null
          GORENG "Encoder" "lib"
          GORENG "Encoder" "vendor/lib"
      else
          sed -i "s/, patch video encoder,/,/g" $TMPDIR/module.prop 2>/dev/null
      fi
  else
      ui_print "  !! Will cause problem on below SDK 28, skipping !!"
      sed -i "s/, patch video encoder,/,/g" $TMPDIR/module.prop 2>/dev/null
  fi
}

AOSPLOS() {
  unzip -oq $CUS/64bit -d $TMPDIR 2>/dev/null
  
  ui_print " "
  ui_print "- Which MIUI Camera you want to install? -"
  ui_print "  Vol+ (Up)   = Part7 by Hadinata (CAIO 8)"
  ui_print "  Vol- (Down) = Stock Mi A2 or Stock Mi A1"
  if $VKSEL; then
    PASANG "Part7"
    sed -i "s/MIUI Camera/MIUI Camera from Part7/g" $TMPDIR/module.prop 2>/dev/null
  else
    ui_print " "
    ui_print "  Vol+ (Up)   = Stock Mi A2 (CAIO X-ID)"
    ui_print "  Vol- (Down) = Stock Mi A1"
    if $VKSEL; then
      PASANG "MiA2"
      sed -i "s/MIUI Camera/MIUI Camera from Mi A2/g" $TMPDIR/module.prop 2>/dev/null
    else
      PASANG "MiA1"
      sed -i "s/MIUI Camera/MIUI Camera from Mi A1/g" $TMPDIR/module.prop 2>/dev/null
    fi
  fi

  ui_print " "
  ui_print "- Apply seemless 4K60 for Google Camera? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if [ "$DEVCODE" == "wayne" -o "whyred" ]; then
    if $VKSEL; then
      unzip -oq $CUS/GCam -d $TMPDIR 2>/dev/null
      GORENG "GCam" "vendor/lib"
    else
      sed -i "s/, seemless 4K60FPS on GCam,/,/g" $TMPDIR/module.prop 2>/dev/null
    fi
  fi

  ui_print " "
  ui_print "- Apply mute camera sounds ? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      unzip -oq $CUS/Mutes -d $TMPDIR 2>/dev/null
      GORENG "Mutes" "media/audio/ui"
      GORENG "Mutes" "product/media/audio/ui"
  else
      sed -i "s/, mute camera sounds,/,/g" $TMPDIR/module.prop 2>/dev/null
  fi

  ui_print " "
  ui_print "- Apply MIUI Camera libs? -"
  ui_print "  Vol+ (Up)   = System-wide (App, system and vendor)"
  ui_print "  Vol- (Down) = App only (Recommended)"
  if $VKSEL; then
      GORENG "64bit" "priv-app/$MICAM/lib/arm64"
      GORENG "64bit" "lib64"
      GORENG "64bit" "vendor/lib64"
  else
      GORENG "64bit" "priv-app/$MICAM/lib/arm64"
  fi

  ui_print " "
  ui_print "- Apply FP Shutter ? -"
  ui_print "  Vol+ (Up)   = Yes (May cause FP ghost-touch)"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      unzip -oq $CUS/FPShutter -d $TMPDIR 2>/dev/null
      GORENG "FPShutter" "vendor/usr/keylayout"
  else
      sed -i "s/, enable FP shutter,/,/g" $TMPDIR/module.prop 2>/dev/null
  fi
}

DF_PATCH() {
  ui_print " "
  ui_print "- Enable Gimmick-AI (selfie and portrait)? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = Ignore, i know its useless"
  if $VKSEL; then
      ui_print "  > Enabled"
      sed -i '3 s/false/true/' $CUS/features.txt
      sed -i '5 s/false/true/' $CUS/features.txt
      sed -i '10 s/false/true/' $CUS/features.txt
  else
      ui_print "  > Ignored"
  fi
  
  if [ -f $DFO ]; then
  ui_print " "
  ui_print "- $DEVCODE.xml available from your $ROM -"
  ui_print "  Vol+ (Up)   = Use $ROM provided"
  ui_print "  Vol- (Down) = Use $MODID provided"
    if $VKSEL; then
      ui_print "  > Using system provided $DEVCODE.xml"
      cp -rf $DFO $DFM 2>/dev/null
    else
      ui_print "  > Using $MODID provided $DEVCODE.xml"
      cp -rf $CUS/$DEVCODE.xml $DFM 2>/dev/null
    fi
  else
      ui_print "- $ROM have no $DEVCODE.xml, using $MODID provided -"
      cp -rf $CUS/$DEVCODE.xml $DFM 2>/dev/null
  fi
  
  if [ -f $DFM ]; then 
      ui_print " "
      ui_print "- Patching $DEVCODE features -" 
      while IFS= read -r I N; 
      do
        TAMBAL $I $N
      done <"$CUS/features.txt"
  else
      abort "  ! Failed to extract files !"
  fi
}

ui_print " "
ui_print "- Detecting ROM -"
if [ ! -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ];
then
    ui_print " "
    ui_print "  > $ROM is AOSP/LOS based"
    cp -f $CUS/model $TMPDIR/system/vendor/etc/camera/model_back.dlc 2>/dev/null
    sed -i "2 s/One/One for AOSP\/LOS/" $TMPDIR/module.prop 2>/dev/null
    EISENC
    AOSPLOS
    DF_PATCH
    prop_process $TMPDIR/custom/aosplos.prop
else
    ui_print " "
    ui_print "  > $ROM is MIUI based"
    ui_print "    AOSP/LOS patches will be ignored -"
    EISENC
    DF_PATCH
    sed -i "2 s/One/One for MIUI/" $TMPDIR/module.prop 2>/dev/null
    sed -i "s/install\/replace and patch/patch/g" $TMPDIR/module.prop 2>/dev/null
    sed -i "s/, mute camera sounds, enable FP shutter,/,/g" $TMPDIR/module.prop 2/dev/null
    prop_process $TMPDIR/custom/miui.prop
fi

ui_print " "
ui_print "   **********************************************"
ui_print "   *           [!!] IF BOOTLOOP [!!]            *"
ui_print "   **********************************************"
ui_print "   *         Please reflash this module         *"
ui_print "   *            FROM RECOVERY/TWRP              *"
ui_print "   **********************************************"
ui_print " "
sleep 5
