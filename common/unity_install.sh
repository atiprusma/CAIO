# Vars
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)
DFP=/system/etc/device_features
DF=$TMPDIR$DFP/$DEVCODE.xml
CUS=$TMPDIR/custom
MICAM=MiuiCamera

# Additional MIUI Camera features
TAMBAL() {
  v=$(cat $DF | grep -nw $1 | cut -d'>' -f2 | cut -d'<' -f1)
  w=$(cat $DF | grep -nw $1 | cut -d':' -f1)
  x=$(($w - 1))
  y=$(($(cat $DF | grep -n '<bool' | tail -n2 | head -n1 | cut -d: -f1) + $x))
  if [ ! "$x" == "-1" ]; then
     if [ ! "$v" == "$2" ]; then
         sed -i "$w s/$v/$2/" $DF 2>/dev/null
         sed -i "$x a\    <!-- Modified by Aradium  -->" $DF 2>/dev/null
     fi
  else
     sed -i "$y a\    <bool name=\"$1\">$2</bool>" $DF 2>/dev/null
     sed -i "$(($y + $x)) a\    <!-- Added by Aradium  -->" $DF 2>/dev/null
  fi
}

# Install stuffs
GORENG() {
  ui_print "  > Pushing $1 files to /system/$2"
  for L in $(find $TMPDIR/$1 -type f -name "*.*"); 
  do
      [ ! -d $TMPDIR/system/$2 ] && mkdir -p $TMPDIR/system/$2 2>/dev/null
      cp_ch $L $TMPDIR/system/$2/$(basename $L) 2>/dev/null
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
  sleep 3
}

# Find and replace installed MIUI Camera
PASANG() {
  ui_print "  > $1 selected"
  ui_print "  > MIUI Camera will using folder name:"
  C=$(find /system/priv-app -type d -name "*MiuiCamera*" | cut -d'/' -f4 | head -n1)
  if [ -n "$C" ]; 
  then
      ui_print "   "$C""
      #mktouch $TMPDIR/system/priv-app/$C/.replace 2>/dev/null
      MICAM="$C"
  else
      ui_print "   "$MICAM""
      ui_print " "
      ui_print "  ! Please manually give permissions for MIUI Camera !"
  fi
  cp_ch $CUS/perms.xml $TMPDIR/system/etc/permissions/privapp-permissions-$(echo $MICAM | tr [:upper:] [:lower:]).xml 2>/dev/null
  cp_ch $CUS/$1.apk $TMPDIR/system/priv-app/$MICAM/$MICAM.apk 2>/dev/null
  sleep 3
}

EISENC() {
  ui_print " "
  ui_print "- Enable EIS? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      ui_print "  > EIS enabled"
      sed -i "s/eis.enable=0/eis.enable=1/g" $TMPDIR/common/system.prop
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
      ui_print "  !! Will cause problem on Oreo, skipping !!"
      sed -i "s/, patch video encoder,/,/g" $TMPDIR/module.prop 2>/dev/null
  fi
}

AOSPLOS() {
  #unzip -oq $CUS/32bit -d $TMPDIR 2>/dev/null
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
  ui_print "- Apply libs? -"
  ui_print "  Vol+ (Up)   = System-wide (App, system and vendor)"
  ui_print "  Vol- (Down) = App only (Recommended)"
  if $VKSEL; then
      #GORENG "32bit" "priv-app/$MICAM/lib/arm"
      GORENG "64bit" "priv-app/$MICAM/lib/arm64"
      GORENG "64bit" "lib64"
      GORENG "64bit" "vendor/lib64"
  else
      #GORENG "32bit" "priv-app/$MICAM/lib/arm"
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
SPAI() {
    ui_print " "
    ui_print "- Enable selfie and portrait AI (Gimmick)? -"
    ui_print "  Vol+ (Up)   = Yes"
    ui_print "  Vol- (Down) = No"
    if $VKSEL; then
      sed -i '3 s/false/true/' $CUS/features.txt
      sed -i '5 s/false/true/' $CUS/features.txt
      sed -i '10 s/false/true/' $CUS/features.txt
    fi
}
ui_print " "
ui_print "- Detecting ROM -"
if [ ! -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ];
then
    ui_print " "
    ui_print "  > $ROM is AOSP/LOS based"
    EISENC
    AOSPLOS
    cp_ch $CUS/model $TMPDIR/system/vendor/etc/camera/model_back.dlc 2>/dev/null
    #cp_ch $CUS/model $TMPDIR/system/vendor/etc/camera/model_front.dlc
    sed -i "2 s/One/One for AOSP\/LOS/" $TMPDIR/module.prop 2>/dev/null
else
    ui_print " "
    ui_print "  > $ROM is MIUI based"
    ui_print "    AOSP/LOS patches will be ignored -"
    EISENC
    prop_process $TMPDIR/custom/miui.prop 2>/dev/null
    sed -i "2 s/One/One for MIUI/" $TMPDIR/module.prop 2>/dev/null
    sed -i "s/install\/replace and patch/patch/g" $TMPDIR/module.prop 2>/dev/null
fi

ui_print " "
ui_print "- Do you want to clean-up app data? -"
ui_print "  Vol+ (Up)   = Yes"
ui_print "  Vol- (Down) = No"
if $VKSEL; then
    BERSIHIN
else
    ui_print "  > Okay, no cleanup"
fi

SPAI

# Check & patch device features
if [ -f $DFP/$DEVCODE.xml ]; then
    rm -rf $DF 2>/dev/null
    cp_ch $DFP/$DEVCODE.xml $DF 2>/dev/null
else
    cp_ch $TMPDIR$DFP/wayne.xml $DF 2>/dev/null
fi
sleep 3

if [ -f $DF ]; then 
    ui_print " "
    ui_print "- Patching MIUI Camera features -" 
    while IFS= read -r I N; 
    do
        TAMBAL $I $N
    done <"$CUS/features.txt"
else
    abort "  ! Failed to patch $DEVCODE.xml !"
fi
sleep 3
ui_print " "
ui_print "   **********************************************"
ui_print "   *           [!!] IF BOOTLOOP [!!]            *"
ui_print "   **********************************************"
ui_print "   *         Please reflash this module         *"
ui_print "   *            FROM RECOVERY/TWRP              *"
ui_print "   **********************************************"
ui_print " "
sleep 5
# Downgrade version code; testing purpose only
sed -i "4 s/$(grep_prop versionCode $TMPDIR/module.prop)/1/" $TMPDIR/module.prop
