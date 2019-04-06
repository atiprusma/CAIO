# Downgrade version code; only testing purpose
#sed -i "4 s/13/10/" $TMPDIR/module.prop

# Vars
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)
DFP=/system/etc/device_features
DF=$TMPDIR$DFP/$DEVCODE.xml
CUS=$TMPDIR/custom
MICAM=MiuiCamera

# Additional MIUI Camera Features
TAMBAL() {
  v=$(cat $DF | grep -nw $1 | cut -d'>' -f2 | cut -d'<' -f1)
  w=$(cat $DF | grep -nw $1 | cut -d':' -f1)
  x=$(($w - 1))
  y=$(($(cat $DF | grep -n '<bool' | tail -n2 | head -n1 | cut -d: -f1) + $x))
  if [ ! "$x" == "-1" ]; then
     if [ ! "$v" == "$2" ]; then
         sed -i "$w s/$v/$2/" $DF
         #ui_print "~ $1 changed \"$v\" => \"$2\""
         sed -i "$x a\    <!-- Modified by Aradium  -->" $DF
         
     #else
         #ui_print "! $1 ALREADY \"$2\""
     fi
  else
     sed -i "$y a\    <bool name=\"$1\">$2</bool>" $DF
     sed -i "$(($y + $x)) a\    <!-- Added by Aradium  -->" $DF
     #ui_print "+ $1 => \"$2\" added"
  fi
}

# Install libs
GORENG() {
  ui_print "- Pushing $1 files to /system/$2"
  for L in $(find $TMPDIR/$1 -type f -name "*.*"); 
  do
      cp_ch $L $TMPDIR/system/$2/$(basename $L)
  done
}

# Cleanups
BERSIHIN() {
  ui_print " "
  ui_print "- Removing old remain files"
  for b in $(find /data -name "*MiuiCamera*" -o -name "*com.android.camera*"); 
  do
      [ "$(echo $b | cut -d'/' -f-4)" == "/data/media/0" ] && continue
      if [ -d "$b" ]; then
          rm -rf $b 2>/dev/null
      else
          rm -f $b 2>/dev/null
      fi
  done
}

# Find and replace installed MIUI Camera
PASANG() {
  ui_print " "
  ui_print "- Finding installed Miui Camera"
  for c in $(find /system/priv-app -type d -name "*MiuiCamera*"); 
  do
      if [ -d $c ]; 
      then
          MICAM=$(echo $c | cut -d'/' -f4)
          ui_print " "
          ui_print "  ! $MICAM installed on system, replacing"
          mkdir -p $TMPDIR$c
          mktouch $TMPDIR$c/.replace
      else
          ui_print " "
          ui_print "- No MiuiCamera found, install as is"
      fi
  done
  [ "$MICAM" ] && cp_ch $TMPDIR/APK/$1.apk $TMPDIR/system/priv-app/$MICAM/$MICAM.apk
  #cp_ch $CUS/priv-app-permissions-miuicamera.xml $TMPDIR/system/etc/permissions/priv-app-permissions-$MICAM.xml
  #cp_ch $CUS/miuicamera-permissions.xml $TMPDIR/system/etc/default-permissions/$MICAM-permissions.xml
  BERSIHIN
}

EISENC() {  
  ui_print " "
  ui_print "- Enable EIS?"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
    sed -i "s/eis.enable=0/eis.enable=1/g" $TMPDIR/common/system.prop
    sed -i "s/disable EIS/enable EIS/g" $TMPDIR/module.prop
  fi
  
  if [ $API -ge 28 ];
  then
      ui_print " "
      ui_print "- Patch video encoder?"
      ui_print "  Vol+ (Up)   = Yes"
      ui_print "  Vol- (Down) = No"
      if $VKSEL; then
          unzip -oq $CUS/Encoder -d $TMPDIR
          GORENG "Encoder" "lib"
          GORENG "Encoder" "vendor/lib"
      else
          sed -i "s/, patch video encoder,/,/g" $TMPDIR/module.prop
      fi
  else
      ui_print " ! Will cause problem on Oreo, skipping"
      sed -i "s/, patch video encoder,/,/g" $TMPDIR/module.prop
  fi
}

AOSPLOS() {
  unzip -oq $CUS/APK -d $TMPDIR
  unzip -oq $CUS/32bit -d $TMPDIR
  unzip -oq $CUS/64bit -d $TMPDIR
  
  ui_print " "
  ui_print "- Which MIUI Camera you want to install?"
  ui_print "  Vol+ (Up)   = Part7 by Hadinata (CAIO 8)"
  ui_print "  Vol- (Down) = Stock Mi A2 or Stock Mi A1"
  if $VKSEL; then
      PASANG "Part7"
      sed -i "s/MIUI Camera/Part7 MIUI Camera/g" $TMPDIR/module.prop
  else
      ui_print " "
      ui_print "  Vol+ (Up)   = Stock Mi A2 (CAIO X-ID)"
      ui_print "  Vol- (Down) = Stock Mi A1"
      if $VKSEL; then
          PASANG "MiA2"
          sed -i "s/MIUI Camera/Stock Mi A2 MIUI Camera/g" $TMPDIR/module.prop
      else
          PASANG "MiA1"
          sed -i "s/MIUI Camera/Stock Mi A1 MIUI Camera/g" $TMPDIR/module.prop
      fi
  fi
    
  ui_print " "
  ui_print "- Apply system-wide libs?"
  ui_print "  Vol+ (Up)   = Yes (App, system and vendor)"
  ui_print "  Vol- (Down) = No  (App only - Recommended)"
  if $VKSEL; then
      GORENG "32bit" "priv-app/$MICAM/lib/arm"
      GORENG "64bit" "priv-app/$MICAM/lib/arm64"
      GORENG "64bit" "lib64"
      GORENG "64bit" "vendor/lib64"
  else
      GORENG "32bit" "priv-app/$MICAM/lib/arm"
      GORENG "64bit" "priv-app/$MICAM/lib/arm64"
  fi
  
  ui_print " "
  ui_print "- Apply seemless 4K60 libs for Google Camera?"
  ui_print "  Vol+ (Up)   = Yes (wayne & whyred only)"
  ui_print "  Vol- (Down) = No  (Other device)"
  if $VKSEL; then
      unzip -oq $CUS/GCam -d $TMPDIR
      GORENG "GCam" "vendor/lib"
  else
      sed -i "s/, seemless 4K60FPS on GCam,/,/g" $TMPDIR/module.prop
  fi
  
  ui_print " "
  ui_print "- Apply mute camera sounds ?"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      unzip -oq $CUS/Mutes -d $TMPDIR
      GORENG "Mutes" "media/audio/ui"
      GORENG "Mutes" "product/media/audio/ui"
  else
      sed -i "s/, mute camera sounds,/,/g" $TMPDIR/module.prop
  fi
  
  ui_print " "
  ui_print "- Enable FP Shutter ?"
  ui_print "  Vol+ (Up)   = Yes (May cause ghost touch from FP)"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
      unzip -oq $CUS/FPShutter -d $TMPDIR
      GORENG "FPShutter" "vendor/usr/keylayout"
  else
      sed -i "s/, enable FP shutter,/,/g" $TMPDIR/module.prop
  fi
}

# Detect ROM and Installation
if $BOOTMODE; then
    ui_print " "
    ui_print "- Magisk Manager install detected, go ahead"
    ui_print " "
    ui_print "- Detecting ROM..."
    if [ ! -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ]; 
    then
        ui_print " "
        ui_print "- $ROM is AOSP/LOS based"
        EISENC
        AOSPLOS
        cp_ch $CUS/model $TMPDIR/system/vendor/etc/camera/model_back.dlc
        #cp_ch $CUS/model $TMPDIR/system/vendor/etc/camera/model_front.dlc
        sed -i "2 s/One/One for AOSP\/LOS/" $TMPDIR/module.prop
    else
        ui_print " "
        ui_print " - $ROM is MIUI based"
        ui_print " - Skipping some AOSP/LOS patches"
        EISENC
        prop_process $TMPDIR/custom/memeui.prop
        sed -i "2 s/One/One for MemeUI/" $TMPDIR/module.prop
        sed -i "s/. Systemlessly install\/replace and patch MIUI Camera features,/./g" $TMPDIR/module.prop
    fi   
    if [ $DFP/$DEVCODE.xml ]; then
        rm -rf $DF
        cp -rf $DFP/$DEVCODE.xml $DF
    else
        cp -rf $TMPDIR$DFP/wayne.xml $DF
    fi
    ui_print " "
    ui_print "+ Patching $DEVCODE.xml..." 
    while IFS= read -r I N; 
    do
        TAMBAL $I $N
    done <"$CUS/features.txt"
else
    abort  "  ! Please install from Magisk Manager !"
fi

# Check device features
[ ! -f $DF ] && abort "! Failed to patch $DEVCODE.xml !"
 
ui_print " "
ui_print "   ****************  [NOTES]  *******************"
ui_print "   **            !! IF BOOTLOOP !!             **"
ui_print "   **       Please reflash this module         **"
ui_print "   **           from RECOVERY/TWRP             **"
ui_print "   **********************************************"
ui_print " "
