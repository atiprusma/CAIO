# This version downgrade is for testing purpose only
sed -ri "s/versionCode=(.*)/versionCode=140/" $TMPDIR/module.prop 2>/dev/null

# Variables
CUS=$TMPDIR/custom
DFO=$ORIGDIR/system/etc/device_features/$DEVCODE.xml
DFM=$UNITY/system/etc/device_features/$DEVCODE.xml
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)
SYSCAM=$(find $ORIGDIR/system/priv-app -type d -name "*MiuiCamera*" | head -n1)

# Description edit
DEDIT() {
  sed -ri "s/description=(.*)/description=\1 $1/" $TMPDIR/module.prop 2>/dev/null
}

# Additional MIUI Camera features
TAMBAL() {
  V=$(cat $DFM | grep -nw $1 | cut -d'>' -f2 | cut -d'<' -f1 | head -n1)
  W=$(cat $DFM | grep -nw $1 | cut -d':' -f1 | head -n1)
  X=$(($W - 1))
  Y=$(($(cat $DFM | grep -n '<bool' | tail -n2 | head -n1 | cut -d: -f1) + $X))
  if [ ! "$X" == "-1" ]; then
    if [ ! "$V" == "$2" ]; then
      sed -i "$W s/$V/$2/" $DFM 2>/dev/null;
      sed -i "$X a\    <!-- Modified by $MODID -->" $DFM 2>/dev/null
    else
      return 1
    fi  
  else
    sed -i "$Y a\    <bool name=\"$1\">$2</bool>" $DFM 2>/dev/null
    sed -i "$(($Y + $X)) a\    <!-- Added by $MODID -->" $DFM 2>/dev/null
  fi
}

# Install stuffs
GORENG() {
  for L in $(find $TMPDIR/$1 -type f -name "*.*");
  do
    # [ ! -d $UNITY/system/$2 ] && mkdir -p $UNITY/system/$2 2>/dev/null
    cp_ch $L $UNITY/system/$2/$(basename $L) 2>/dev/null
  done
}


# Clean-up app data
BERSIHIN() {

  ui_print " "
  ui_print "- Cleaning up old data -"
  for b in $(find /data -name "*MiuiCamera*" -o -name "*com.android.camera*"); 
  do
      [ "$(echo $b | cut -d'/' -f-4)" == "/data/media/0" ] && continue
      [ "$(echo $b | cut -d'/' -f-4)" == "/data/adb/modules" ] && continue
      [ "$(echo $b | cut -d'/' -f-4)" == "/data/adb/modules_update" ] && continue
      if [ -d "$b" ]; then
          rm -rf $b 2>/dev/null
      else
          rm -f $b 2>/dev/null
      fi
  done
}

# Basic patches
BASIC() {
  ui_print " "
  ui_print "  Decompressing base files..."
  unzip -oq $CUS/Base.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/Encoder.zip -d $TMPDIR 2>/dev/null
  DEDIT "Applied:"
  
  ui_print " "
  ui_print "- Enable EIS? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
    EIS=true
    ui_print "  > EIS enabled"
  else
    EIS=false
    ui_print "  > EIS disabled"
  fi

  if [ $API -ge 28 ]; then
    ui_print " "
    ui_print "- Patch video encoder? -"
    ui_print "  Vol+ (Up)   = Yes"
    ui_print "  Vol- (Down) = No"
    if $VKSEL; then
      ui_print "  > Encoder patched"
      ENC=true
    else
      ENC=false
      ui_print "  > Encoder not patched"
    fi
  else
    ui_print "  ! Encoder patch is not applicable on SDK $API, skipping !"
  fi
  
  ui_print " "
  ui_print "- Enable Gimmick AI (selfie, square and portrait)? -"
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
  ui_print "- $ROM have $DEVCODE.xml -"
  ui_print "  Vol+ (Up)   = Use $ROM provided"
  ui_print "  Vol- (Down) = Use $MODID provided"
    if $VKSEL; then
      ui_print "  > Using $DEVCODE.xml from $ROM"
      cp_ch $DFO $DFM 2>/dev/null
    else
      ui_print "  > Using $DEVCODE.xml from $MODID "
      cp_ch $CUS/$DEVCODE.xml $DFM 2>/dev/null
    fi
  else
    ui_print " "
    ui_print "- $ROM have no MIUI features, using $MODID provided -"
    cp_ch $CUS/$DEVCODE.xml $DFM 2>/dev/null
  fi
}

# Additional AOSP/LOS patches
AOSPLOS() {
  ui_print " "
  ui_print "  Decompressing AOSP/LOS files..."
  unzip -oq $CUS/lib.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/lib64.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/GCam.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/Mutes.zip -d $TMPDIR 2>/dev/null
  sleep 3
  
  ui_print " "
  ui_print "- Which MIUI Camera you want to install? -"
  ui_print "  Vol+ (Up)   = AI Part7 MIUI Camera"
  ui_print "  Vol- (Down) = Mi A2 or Mi A1 Stock MIUI Camera"
  if $VKSEL; then
    APK="Part7"
  else
    ui_print " "
    ui_print "  Vol+ (Up)   = Mi A2 Stock Camera "
    ui_print "  Vol- (Down) = Mi A1 Stock Camera"
    if $VKSEL; then
      APK="MiA2"
    else
      APK="MiA1"
    fi
  fi
  ui_print "  > $APK MIUI Camera selected"
  
  if [ $DEVCODE == "tulip" ] || [ $DEVCODE == "wayne" ] || [ $DEVCODE == "whyred" ]; then
    ui_print " "
    ui_print "- Apply seemless GCam 4K60 recording ? -"
    ui_print "  Vol+ (Up)   = Yes"
    ui_print "  Vol- (Down) = No"
    if $VKSEL; then
      ui_print "  > Applied GCam 4K60 patch"
      FOURK=true
    else
      ui_print "  > GCam 4K60 not applied"
      FOURK=false
    fi
  else
    ui_print "  ! GCam 4K60 CANNOT be applied to your $DEVNAME ($DEVCODE) !"
    FOURK=false
  fi

  ui_print " "
  ui_print "- Apply mute MIUI Camera sounds ? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No"
  if $VKSEL; then
     ui_print "  > Mute camera sounds applied"
     ui_print "  ! Uncheck \"Camera Sounds\" from MIUI Camera settings"
     MUTE=true
  else
     ui_print "  > Mute camera sounds not applied"
     MUTE=false
  fi

  ui_print " "
  ui_print "- Apply system-wide lib? -"
  ui_print "  Vol+ (Up)   = Yes"
  ui_print "  Vol- (Down) = No (Recommended)"
  if $VKSEL; then
      ui_print "  > Applied to system-wide"
      SWLIB=true
  else
      ui_print "  > Applied to app only"
      SWLIB=false
  fi
 
  if [ -n "$SYSCAM" ]; then
    if $BOOTMODE; then
      INSNAME=$(echo $SYSCAM | cut -d'/' -f7)
    else
      INSNAME=$(echo $SYSCAM | cut -d'/' -f4)
    fi
    ui_print " "
    ui_print "- $INSNAME installed, replacing -"
    mktouch $UNITY/system/priv-app/$INSNAME/.replace 2>/dev/null
    DEDIT "replace MIUI Camera with $APK, "
  else
    ui_print " "
    ui_print "- No MIUI Camera installed -"
    if [ ! "$APK" == "Part7" ]; then
      ui_print " "
      ui_print "  [Note]: Manually grant permission for MIUI Camera "
      sleep 3
    fi
    INSNAME=MiuiCamera
    DEDIT "install MIUI Camera from $APK, "
    cp_ch $CUS/perms.xml $UNITY/system/etc/permissions/privapp-permissions-miuicamera.xml 2>/dev/null
  fi
  
  ui_print " "
  ui_print "- Processing AOSP/LOS patches -"
  BERSIHIN
  cp_ch $CUS/$APK.apk $UNITY/system/priv-app/$INSNAME/$INSNAME.apk 2>/dev/null
  GORENG "lib" "priv-app/$INSNAME/lib/arm"
  GORENG "lib64" "priv-app/$INSNAME/lib/arm64"
  
  if [ ! "$APK" == "Part7" ]; then
    unzip -oq $CUS/oat.zip -d $TMPDIR 2>/dev/null
    cp_ch -r $TMPDIR/oat $UNITY/system/priv-app/$INSNAME/oat 2>/dev/null
  fi
  
  cp_ch $CUS/model.dlc $UNITY/system/vendor/etc/camera/model_back.dlc 2>/dev/null
  
  if $SWLIB; then
    GORENG "lib64" "lib64"
    GORENG "lib64" "vendor/lib64"
    sleep 3
  fi
  
  if $MUTE; then
    DEDIT "mute camera sounds, "
    GORENG "Mutes" "media/audio/ui"
    GORENG "Mutes" "product/media/audio/ui"
  fi
  
  if $FOURK; then
    DEDIT "seemless GCam 4K60 recording, "
    GORENG "GCam" "vendor/lib"
  fi
}

ui_print " "
ui_print "- Detecting ROM -"
if $MAGISK; then
  if [ -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ]; then
    ui_print " "
    ui_print "- $ROM is MIUI based -"
    ui_print "- AOSP/LOS patches will be ignored -"
    sed -ri "s/name=(.*)/name=\1 for MIUI/" $TMPDIR/module.prop 2>/dev/null
    prop_process $CUS/miui.prop
    BASIC
    DEDIT "seemless GCam 4K60 recording, "
  else
    ui_print " "
    ui_print "- $ROM is AOSP/LOS based -"
    sed -ri "s/name=(.*)/name=\1 for AOSP\/LOS/" $TMPDIR/module.prop 2>/dev/null
    prop_process $CUS/aosplos.prop
    BASIC
    AOSPLOS
  fi
  
  if $EIS; then
    DEDIT "EIS enabled, "
    sed -i "s/eis.enable=0/eis.enable=1/g" $CUS/aosplos.prop
    sed -i "s/eis.enable=0/eis.enable=1/g" $CUS/miui.prop
  else
    DEDIT "EIS disabled, "
  fi
  
  if $ENC; then
    DEDIT "video encoder patch, "
    GORENG "Encoder" "lib"
    GORENG "Encoder" "vendor/lib"
  fi
  
  if [ -f $DFM ]; then
    ui_print " "
    ui_print "- Patching $DEVCODE.xml -"
    DEDIT "and patch $DEVCODE.xml"
    while IFS= read -r I N; do
      TAMBAL $I $N
    done <"$CUS/features.txt"
  else
    abort "  ! Failed to extract files !"
  fi
else
  abort "  ! $MODID only for Magisk !"
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
