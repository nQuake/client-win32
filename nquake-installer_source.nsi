;nQuake NSIS Online Installer Script
;By Empezar 2007-05-31; Last modified 2013-10-17

!define VERSION "2.7"
!define SHORTVERSION "27"

Name "nQuake"
OutFile "nquake${SHORTVERSION}_installer.exe"
InstallDir "C:\nQuake"

!define INSTALLER_URL "http://nquake.com" # Note: no trailing slash!
!define DISTFILES_PATH "$LOCALAPPDATA\nQuake\" # Note: no trailing slash!

# Editing anything below this line is not recommended
;---------------------------------------------------

InstallDirRegKey HKCU "Software\nQuake" "Install_Dir"

;----------------------------------------------------
;Header Files

!include "MUI.nsh"
!include "Win\COM.nsh"
!include "FileAssociation.nsh"
!include "FileFunc.nsh"
!insertmacro GetSize
!insertmacro GetTime
!include "LogicLib.nsh"
!include "Time.nsh"
!include "Locate.nsh"
!include "VersionCompare.nsh"
!include "VersionConvert.nsh"
!include "WinMessages.nsh"
!include "MultiUser.nsh"
!include "nquake-macros.nsh"

;----------------------------------------------------
;Variables

Var ADDON_CLANARENA
Var ADDON_FORTRESS
Var ADDON_TEXTURES
Var ASSOCIATE_FILES
Var CONFIG_NAME
Var CONFIG_INVERT
Var CONFIG_FORWARD
Var CONFIG_BACK
Var CONFIG_MOVELEFT
Var CONFIG_MOVERIGHT
Var CONFIG_JUMP
Var CONFIGCFG
Var DISTFILES_DELETE
Var DISTFILES_PATH
Var DISTFILES_REDOWNLOAD
Var DISTFILES_UPDATE
Var DISTFILES_URL
Var DISTFILES
Var DISTLOG
Var DISTLOGTMP
Var ERRLOG
Var ERRLOGTMP
Var ERRORS
Var INSTALLED
Var INSTLOG
Var INSTLOGTMP
Var INSTSIZE
Var NQUAKE_INI
Var OFFLINE
Var REMOVE_ALL_FILES
Var REMOVE_MODIFIED_FILES
Var RETRIES
Var SIZE
Var STARTMENU_FOLDER

;----------------------------------------------------
;Interface Settings

!define MUI_ICON "nquake.ico"
!define MUI_UNICON "nquake.ico"

!define MUI_WELCOMEFINISHPAGE_BITMAP "nquake-welcomefinish.bmp"

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "nquake-header.bmp"

!define MULTIUSER_EXECUTIONLEVEL Highest

;----------------------------------------------------
;Installer Pages

!define MUI_PAGE_CUSTOMFUNCTION_PRE "WelcomeShow"
!define MUI_WELCOMEPAGE_TITLE "nQuake Installation Wizard"
!insertmacro MUI_PAGE_WELCOME

LicenseForceSelection checkbox "I agree to these terms and conditions"
!insertmacro MUI_PAGE_LICENSE "license.txt"

Page custom DOWNLOAD

Page custom CONFIG

Page custom ADDONS

Page custom ASSOCIATION

DirText "Setup will install nQuake in the following folder. To install in a different folder, click Browse and select another folder. Click Next to continue.$\r$\n$\r$\nIt is NOT ADVISABLE to install in the Program Files folder." "Destination Folder" "Browse" "Select the folder to install nQuake in:"
!define MUI_PAGE_CUSTOMFUNCTION_SHOW DirectoryPageShow
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_STARTMENU "Application" $STARTMENU_FOLDER

ShowInstDetails "nevershow"
!insertmacro MUI_PAGE_INSTFILES

Page custom ERRORS

!define MUI_PAGE_CUSTOMFUNCTION_SHOW "FinishShow"
!define MUI_FINISHPAGE_LINK "Click here to visit the QuakeWorld portal"
!define MUI_FINISHPAGE_LINK_LOCATION "http://www.quakeworld.nu/"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR/readme.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Open readme"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

;----------------------------------------------------
;Uninstaller Pages

UninstPage custom un.UNINSTALL

!insertmacro MUI_UNPAGE_INSTFILES

;----------------------------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

;----------------------------------------------------
;NSIS Manipulation

LangString ^Branding ${LANG_ENGLISH} "nQuake Installer v${VERSION}"
LangString ^SetupCaption ${LANG_ENGLISH} "nQuake Installer"
LangString ^SpaceRequired ${LANG_ENGLISH} "Download size: "

;----------------------------------------------------
;Reserve Files

ReserveFile "config.ini"
ReserveFile "download.ini"
ReserveFile "addons.ini"
ReserveFile "association.ini"
ReserveFile "errors.ini"
ReserveFile "uninstall.ini"

!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;----------------------------------------------------
;Installer Sections

Section "" # Prepare installation

  SetOutPath $INSTDIR

  # Set progress bar
  RealProgress::SetProgress /NOUNLOAD 0

  # Read information from custom pages
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_PATH "download.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_UPDATE "download.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_REDOWNLOAD "download.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_DELETE "download.ini" "Field 6" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_NAME "config.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_INVERT "config.ini" "Field 6" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_FORWARD "config.ini" "Field 9" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_BACK "config.ini" "Field 11" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_MOVELEFT "config.ini" "Field 13" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_MOVERIGHT "config.ini" "Field 15" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_JUMP "config.ini" "Field 17" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_FORTRESS "addons.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_CLANARENA "addons.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_TEXTURES "addons.ini" "Field 6" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ASSOCIATE_FILES "association.ini" "Field 3" "State"

  # Create distfiles folder if it doesn't already exist
  ${Unless} ${FileExists} "$DISTFILES_PATH\*.*"
    CreateDirectory $DISTFILES_PATH
  ${EndUnless}

  # Calculate the installation size
  ${Unless} ${FileExists} "$INSTDIR\ID1\PAK0.PAK"
  ${OrUnless} ${FileExists} "$EXEDIR\pak0.pak"
  ${OrUnless} ${FileExists} "$DISTFILES_PATH\pak0.pak"
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "qsw106.zip"
    IntOp $INSTSIZE $INSTSIZE + $0
  ${EndUnless}
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "gpl.zip"
  IntOp $INSTSIZE $INSTSIZE + $0
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "non-gpl.zip"
  IntOp $INSTSIZE $INSTSIZE + $0
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "textures.zip"
  IntOp $INSTSIZE $INSTSIZE + $0
  ${If} $ADDON_FORTRESS == 1
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-fortress.zip"
    IntOp $INSTSIZE $INSTSIZE + $0
  ${EndIf}
  ${If} $ADDON_CLANARENA == 1
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-clanarena.zip"
    IntOp $INSTSIZE $INSTSIZE + $0
  ${EndIf}
  ${If} $ADDON_TEXTURES == 1
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-textures.zip"
    IntOp $INSTSIZE $INSTSIZE + $0
  ${EndIf}

  # Find out what mirror was selected
  !insertmacro MUI_INSTALLOPTIONS_READ $R0 "download.ini" "Field 8" "State"
  ${If} $R0 == "Randomly selected mirror (Recommended)"
    # Get amount of mirrors ($0 = amount of mirrors)
    StrCpy $0 1
    ReadINIStr $1 $NQUAKE_INI "mirror_descriptions" $0
    ${DoUntil} $1 == ""
      ReadINIStr $1 $NQUAKE_INI "mirror_descriptions" $0
      IntOp $0 $0 + 1
    ${LoopUntil} $1 == ""
    IntOp $0 $0 - 2
  
    # Get time (seconds)
    ${time::GetLocalTime} $1
    StrCpy $1 $1 "" -2
    
    # Fix seconds (00 -> 1, 01-09 -> 1-9)
    ${If} $1 == "00"
      StrCpy $1 1
    ${Else}
      StrCpy $2 $1 1 -2
      ${If} $2 == 0
        StrCpy $1 $1 1 -1
      ${EndIf}
    ${EndIf}
  
    # Loop until you get a number that's within the range 0 < x =< $0
    ${DoUntil} $1 <= $0
      IntOp $1 $1 - $0
    ${LoopUntil} $1 <= $0
    ReadINIStr $DISTFILES_URL $NQUAKE_INI "mirror_addresses" $1
    ReadINIStr $0 $NQUAKE_INI "mirror_descriptions" $1
  ${Else}
    ${For} $0 1 1000
      ReadINIStr $R1 $NQUAKE_INI "mirror_descriptions" $0
      ${If} $R0 == $R1
        ReadINIStr $DISTFILES_URL $NQUAKE_INI "mirror_addresses" $0
        ReadINIStr $0 $NQUAKE_INI "mirror_descriptions" $0
        ${ExitFor}
      ${EndIf}
    ${Next}
  ${EndIf}

  # Open temporary files
  GetTempFileName $INSTLOGTMP
  GetTempFileName $DISTLOGTMP
  GetTempFileName $ERRLOGTMP
  FileOpen $INSTLOG $INSTLOGTMP w
  FileOpen $DISTLOG $DISTLOGTMP w
  FileOpen $ERRLOG $ERRLOGTMP a

SectionEnd

Section "nQuake" NQUAKE

  # Download and install pak0.pak (shareware data) unless pak0.pak can be found alongside the installer executable
  ${If} ${FileExists} "$EXEDIR\pak0.pak"
    StrCpy $R0 "$EXEDIR"
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\pak0.pak"
    StrCpy $R0 "$DISTFILES_PATH"
  ${EndIf}
  ${GetSize} $R0 "/M=pak0.pak /S=0B /G=0" $7 $8 $9
  ${If} $7 == "18689235"
    CreateDirectory "$INSTDIR\id1"
    ${Unless} ${FileExists} "$INSTDIR\id1\pak0.pak"
      CopyFiles /SILENT "$R0\pak0.pak" "$INSTDIR\id1\pak0.pak"
    ${EndUnless}
    # Keep pak0.pak and remove qsw106.zip in distfile folder if DISTFILES_DELETE is 0
    ${If} $DISTFILES_DELETE == 0
      ${Unless} ${FileExists} "$DISTFILES_PATH\pak0.pak"
        CopyFiles /SILENT "$INSTDIR\id1\pak0.pak" "$DISTFILES_PATH\pak0.pak"
      ${EndUnless}
      Delete "$DISTFILES_PATH\qsw106.zip"
    ${EndIf}
    FileWrite $INSTLOG "id1\pak0.pak$\r$\n"
    Goto SkipShareware
  ${EndIf}
  !insertmacro InstallSection qsw106.zip "Quake shareware"
  # Remove crap files extracted from shareware zip and rename uppercase files/folders
  Delete "$INSTDIR\CWSDPMI.EXE"
  Delete "$INSTDIR\QLAUNCH.EXE"
  Delete "$INSTDIR\QUAKE.EXE"
  Delete "$INSTDIR\GENVXD.DLL"
  Delete "$INSTDIR\QUAKEUDP.DLL"
  Delete "$INSTDIR\PDIPX.COM"
  Delete "$INSTDIR\Q95.BAT"
  Delete "$INSTDIR\COMEXP.TXT"
  Delete "$INSTDIR\HELP.TXT"
  Delete "$INSTDIR\LICINFO.TXT"
  Delete "$INSTDIR\MANUAL.TXT"
  Delete "$INSTDIR\ORDER.TXT"
  Delete "$INSTDIR\README.TXT"
  Delete "$INSTDIR\READV106.TXT"
  Delete "$INSTDIR\SLICNSE.TXT"
  Delete "$INSTDIR\TECHINFO.TXT"
  Delete "$INSTDIR\MGENVXD.VXD"
  Rename "$INSTDIR\ID1" "$INSTDIR\id1"
  Rename "$INSTDIR\id1\PAK0.PAK" "$INSTDIR\id1\pak0.pak"
  # Keep pak0.pak and remove qsw106.zip in distfile folder if DISTFILES_DELETE is 0
  ${If} $DISTFILES_DELETE == 0
    ${Unless} ${FileExists} "$DISTFILES_PATH\pak0.pak"
      CopyFiles /SILENT "$INSTDIR\id1\pak0.pak" "$DISTFILES_PATH\pak0.pak"
    ${EndUnless}
    Delete "$DISTFILES_PATH\qsw106.zip"
  ${EndIf}
  SkipShareware:
  # Add to installed size
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "qsw106.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0

  # Backup old configs if such exist
  ${If} ${FileExists} "$INSTDIR\ezquake\configs\config.cfg"
    ${GetTime} "" "LS" $2 $3 $4 $5 $6 $7 $8
    # Fix hour format
    ${If} $6 < 10
      StrCpy $6 "0$6"
    ${EndIf}
    StrCpy $1 "$4$3$2$6$7$8"
    Rename "$INSTDIR\ezquake\configs\config.cfg" "$INSTDIR\ezquake\configs\config-$1.cfg"
  ${EndIf}

  # Download and install GPL files
  !insertmacro InstallSection gpl.zip "nQuake setup files (1 of 2)"
  # Add to installed size
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "gpl.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0

  # Download and install non-GPL files
  !insertmacro InstallSection non-gpl.zip "nQuake setup files (2 of 2)"
  # Add to installed size
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "non-gpl.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0

  # Download and install textures
  !insertmacro InstallSection textures.zip "nQuake textures"
  # Add to installed size
  ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "textures.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0

  # Download and install Team Fortress if selected
  ${If} $ADDON_FORTRESS == 1
    !insertmacro InstallSection addon-fortress.zip "Team Fortress"
    # Add to installed size
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-fortress.zip"
    IntOp $INSTALLED $INSTALLED + $0
    # Set progress bar
    IntOp $0 $INSTALLED * 100
    IntOp $0 $0 / $INSTSIZE
    RealProgress::SetProgress /NOUNLOAD $0
  ${EndIf}

  # Download and install Clan Arena if selected
  ${If} $ADDON_CLANARENA == 1
    !insertmacro InstallSection addon-clanarena.zip "Clan Arena"
    # Add to installed size
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-clanarena.zip"
    IntOp $INSTALLED $INSTALLED + $0
    # Set progress bar
    IntOp $0 $INSTALLED * 100
    IntOp $0 $0 / $INSTSIZE
    RealProgress::SetProgress /NOUNLOAD $0
  ${EndIf}

  # Download and install high resolution textures if selected
  ${If} $ADDON_TEXTURES == 1
    !insertmacro InstallSection addon-textures.zip "High resolution textures"
    # Add to installed size
    ReadINIStr $0 $NQUAKE_INI "distfile_sizes" "addon-textures.zip"
    IntOp $INSTALLED $INSTALLED + $0
    # Set progress bar
    IntOp $0 $INSTALLED * 100
    IntOp $0 $0 / $INSTSIZE
    RealProgress::SetProgress /NOUNLOAD $0
  ${EndIf}

  # Copy pak1.pak if it can be found alongside the installer executable
  ${If} ${FileExists} "$EXEDIR\pak1.pak"
    StrCpy $R0 "$EXEDIR"
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\pak1.pak"
    StrCpy $R0 "$DISTFILES_PATH"
  ${EndIf}
  ${GetSize} "$R0" "/M=pak1.pak /S=0B /G=0" $7 $8 $9
  ${If} $7 == "34257856"
    ${Unless} ${FileExists} "$INSTDIR\id1\pak1.pak"
      CopyFiles /SILENT "$R0\pak1.pak" "$INSTDIR\id1\pak1.pak"
    ${EndUnless}
    ${If} $DISTFILES_DELETE == 0
    ${AndIf} $R0 != $DISTFILES_PATH
      ${Unless} ${FileExists} "$DISTFILES_PATH\pak1.pak"
        CopyFiles /SILENT "$R0\pak1.pak" "$DISTFILES_PATH\pak1.pak"
      ${EndUnless}
    ${EndIf}
    FileWrite $INSTLOG "id1\pak1.pak$\r$\n"
    # Remove gpl maps also
    Delete "$INSTDIR\id1\gpl_maps.pk3"
    Delete "$INSTDIR\id1\readme.txt"
  ${EndIf}

SectionEnd

Section "" # StartMenu

  # Copy the first char of the startmenu folder selected during installation
  StrCpy $0 $STARTMENU_FOLDER 1

  ${Unless} $0 == ">"
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"

    # Create links
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER\Links"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Latest News.url" "InternetShortcut" "URL" "http://www.quakeworld.nu/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Message Board.url" "InternetShortcut" "URL" "http://www.quakeworld.nu/forum/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\List of Servers.url" "InternetShortcut" "URL" "http://www.quakeservers.net/quakeworld/servers/pl=1/so=8/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Match Demos.url" "InternetShortcut" "URL" "http://www.challenge-tv.com/index.php?mode=demos&game=2"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Custom Graphics.url" "InternetShortcut" "URL" "http://gfx.quakeworld.nu/"

    # Create shortcuts
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Play QuakeWorld.lnk" "$INSTDIR\ezquake-gl.exe" "" "$INSTDIR\ezquake-gl.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Readme.lnk" "$INSTDIR\readme.txt" "" "$INSTDIR\readme.txt" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall nQuake.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    # Write startmenu folder to registry
    WriteRegStr HKCU "Software\nQuake" "StartMenu_Folder" $STARTMENU_FOLDER
  ${EndUnless}

SectionEnd

Section "" # Clean up installation

  # Write config.cfgs for each mod
  CreateDirectory "$INSTDIR\ezquake\configs"
  FileOpen $CONFIGCFG "$INSTDIR\ezquake\configs\preset.cfg" w
    # Write config to ezquake\configs\preset.cfg
    FileWrite $CONFIGCFG "// This config was auto generated by nQuake installer$\r$\n"
    FileWrite $CONFIGCFG "$\r$\n"
    FileWrite $CONFIGCFG "name $\"$CONFIG_NAME$\"$\r$\n"
    FileWrite $CONFIGCFG "$\r$\n"
    ${If} $CONFIG_INVERT == 1
      FileWrite $CONFIGCFG "m_pitch $\"-0.022$\" // invert mouse$\r$\n"
    ${Else}
      FileWrite $CONFIGCFG "m_pitch $\"0.022$\"$\r$\n"
    ${EndIf}
    FileWrite $CONFIGCFG "$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_FORWARD $\"+forward$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_BACK $\"+back$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_MOVELEFT $\"+moveleft$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_MOVERIGHT $\"+moveright$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_JUMP $\"+jump$\"$\r$\n"
  FileClose $CONFIGCFG
  FileWrite $INSTLOG "ezquake\configs\preset.cfg$\r$\n"

  # Close open temporary files
  FileClose $INSTLOG
  FileClose $ERRLOG
  FileClose $DISTLOG

  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\install.log" w
    ${time::GetFileTime} "$INSTDIR\install.log" $0 $1 $2
    FileWrite $INSTLOG "Install date: $1$\r$\n"
    FileOpen $R0 $INSTLOGTMP r
      ClearErrors
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        StrCpy $0 $0 -2
        ${If} ${FileExists} "$INSTDIR\$0"
          FileWrite $INSTLOG "$0$\r$\n"
        ${EndIf}
      ${LoopUntil} ${Errors}
    FileClose $R0
  FileClose $INSTLOG

  # Remove downloaded distfiles
  ${If} $DISTFILES_DELETE == 1
    FileOpen $DISTLOG $DISTLOGTMP r
      ${DoUntil} ${Errors}
        FileRead $DISTLOG $0
        StrCpy $0 $0 -2
        ${If} ${FileExists} "$DISTFILES_PATH\$0"
          Delete /REBOOTOK "$DISTFILES_PATH\$0"
        ${EndIf}
      ${LoopUntil} ${Errors}
    FileClose $DISTLOG
    # Remove directory if empty
    !insertmacro RemoveFolderIfEmpty $DISTFILES_PATH
  # Copy nquake.ini to the distfiles directory if "update distfiles" and "keep distfiles" was set
  ${ElseIf} $DISTFILES_UPDATE == 1
    FlushINI $NQUAKE_INI
    CopyFiles /SILENT $NQUAKE_INI "$DISTFILES_PATH\nquake.ini"
  ${EndIf}

  # Write to registry
  WriteRegStr HKCU "Software\nQuake" "Install_Dir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayName" "nQuake"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "Publisher" "Empezar (mpezar@gmail.com)"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "URLUpdateInfo" "http://sourceforge.net/project/showfiles.php?group_id=197706"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "URLInfoAbout" "http://nquake.com/"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "HelpLink" "http://sourceforge.net/forum/forum.php?forum_id=702198"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "NoModify" "1"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "NoRepair" "1"

  # Create file associations
  ${If} $ASSOCIATE_FILES == 1
    WriteRegStr HKCU "Software\nQuake" "File_Associations" "1"
    ${registerExtension} "$INSTDIR\ezquake-gl.exe" .qtv "QTV Stream Info File"
    ${registerExtension} "$INSTDIR\ezquake-gl.exe" .qwz "Qizmo Demo File"
    ${registerExtension} "$INSTDIR\ezquake-gl.exe" .qwd "Quakeworld Demo File"
    ${registerExtension} "$INSTDIR\ezquake-gl.exe" .mvd "Multi-View Demo File"
  ${Else}
    WriteRegStr HKCU "Software\nQuake" "File_Associations" "0"
  ${EndIf}

  # Create uninstaller
  WriteUninstaller "uninstall.exe"

SectionEnd

;----------------------------------------------------
;Uninstaller Section

Section "Uninstall"

  # Set out path to temporary files
  SetOutPath $TEMP

  # Read uninstall settings
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_MODIFIED_FILES "uninstall.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_ALL_FILES "uninstall.ini" "Field 6" "State"

  # Set progress bar to 0%
  RealProgress::SetProgress /NOUNLOAD 0

  # If install.log exists and user didn't check "remove all files", remove all files listed in install.log
  ${If} ${FileExists} "$INSTDIR\install.log"
  ${AndIf} $REMOVE_ALL_FILES != 1
    # Get line count for install.log
    Push "$INSTDIR\install.log"
    Call un.LineCount
    Pop $R1 # Line count
    IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
    FileOpen $R0 "$INSTDIR\install.log" r
    # Get installation time from install.log
    FileRead $R0 $0
    StrCpy $1 $0 -2 14
    StrCpy $5 1 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      # Only remove file if it has not been altered since install, if the user chose to do so
      ${If} ${FileExists} "$INSTDIR\$0"
      ${AndUnless} $REMOVE_MODIFIED_FILES == 1
        ${time::GetFileTime} "$INSTDIR\$0" $2 $3 $4
        ${time::MathTime} "second($1) - second($3) =" $2
        ${If} $2 >= 0
          Delete /REBOOTOK "$INSTDIR\$0"
        ${EndIf}
      ${ElseIf} $REMOVE_MODIFIED_FILES == 1
      ${AndIf} ${FileExists} "$INSTDIR\$0"
        Delete /REBOOTOK "$INSTDIR\$0"
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
    FileClose $R0
    Delete /REBOOTOK "$INSTDIR\install.log"
    Delete /REBOOTOK "$INSTDIR\uninstall.exe"
    ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
    DetailPrint "Removed $0 empty directories"
    # Remove directory if empty
    !insertmacro RemoveFolderIfEmpty $INSTDIR
  ${Else}
    # Ask the user if he is sure about removing all the files contained within the nQuake directory
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "This will remove all files contained within the nQuake directory.$\r$\n$\r$\nAre you sure?" IDNO AbortUninst
    RMDir /r /REBOOTOK $INSTDIR
    RealProgress::SetProgress /NOUNLOAD 100
  ${EndIf}

  # Remove start menu items and registry entries if they belong to this nQuake
  ReadRegStr $R0 HKCU "Software\nQuake" "Install_Dir"
  ${If} $R0 == $INSTDIR
    # Remove start menu items
    ReadRegStr $R0 HKCU "Software\nQuake" "StartMenu_Folder"
    RMDir /r /REBOOTOK "$SMPROGRAMS\$R0"
    # Remove file associations
    ReadRegStr $R1 HKCU "Software\nQuake" "File_Associations"
    ${If} $R1 == 1
      ${unregisterExtension} ".qtv" "QTV Stream Info File"
      ${unregisterExtension} ".qwz" "Qizmo Demo File"
      ${unregisterExtension} ".qwd" "Quakeworld Demo File"
      ${unregisterExtension} ".mvd" "Multi-View Demo File"
    ${EndIf}
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake"
    DeleteRegKey HKCU "Software\nQuake"
  ${EndIf}

  Goto FinishUninst
  AbortUninst:
  Abort "Uninstallation aborted."
  FinishUninst:

SectionEnd

;----------------------------------------------------
;Custom Pages

Function DOWNLOAD

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "download.ini"
  # Change the text on the distfile folder page if the installer is in offline mode
  ${If} $OFFLINE == 1
    !insertmacro MUI_HEADER_TEXT "Setup Files" "Select where the setup files are located."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 1" "Text" "Setup will use the setup files located in the following folder. To use a different folder, click Browse and select another folder. Click Next to continue."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 4" "Type" ""
    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 4" "State" "0"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 5" "Type" ""
    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 5" "State" "0"
  ${Else}
    !insertmacro MUI_HEADER_TEXT "Setup Files" "Select the download location for the setup files."
  ${EndIf}
  !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 3" "State" ${DISTFILES_PATH}

  # Only display mirror selection if the installer is in online mode
  ${Unless} $OFFLINE == 1
    # Fix the mirrors for the Preferences page
    StrCpy $0 1
    StrCpy $2 "Randomly selected mirror (Recommended)"
    ReadINIStr $1 $NQUAKE_INI "mirror_descriptions" $0
    ${DoUntil} $1 == ""
      ReadINIStr $1 $NQUAKE_INI "mirror_descriptions" $0
      ${Unless} $1 == ""
        StrCpy $2 "$2|$1"
      ${EndUnless}
      IntOp $0 $0 + 1
    ${LoopUntil} $1 == ""

    StrCpy $0 $2 3
    ${If} $0 == "|"
      StrCpy $2 $2 "" 1
    ${EndIf}

    !insertmacro MUI_INSTALLOPTIONS_WRITE "download.ini" "Field 8" "ListItems" $2
  ${EndUnless}

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "download.ini"

FunctionEnd

Function CONFIG

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "config.ini"
  !insertmacro MUI_HEADER_TEXT "Configuration" "Setup basic configuration."
  System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "config.ini" "Field 4" "State" "$0"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "config.ini"

FunctionEnd

Function ADDONS

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "addons.ini"
  !insertmacro MUI_HEADER_TEXT "Addons" "Choose what modifications and addons to install"
  !insertmacro DetermineSectionSize addon-fortress.zip
  IntOp $1 $SIZE / 1000
  !insertmacro MUI_INSTALLOPTIONS_WRITE "addons.ini" "Field 3" "Text" "Team Fortress ($1 MB)"
  !insertmacro DetermineSectionSize addon-clanarena.zip
  IntOp $1 $SIZE / 1000
  !insertmacro MUI_INSTALLOPTIONS_WRITE "addons.ini" "Field 4" "Text" "Clan Arena ($1 MB)"
  !insertmacro DetermineSectionSize addon-textures.zip
  IntOp $1 $SIZE / 1000
  !insertmacro MUI_INSTALLOPTIONS_WRITE "addons.ini" "Field 6" "Text" "High resolution textures ($1 MB)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "addons.ini"

FunctionEnd

Function ASSOCIATION

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "association.ini"
  !insertmacro MUI_HEADER_TEXT "File Association" "Select whether you want to associate QuakeWorld files or not."
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "association.ini"

FunctionEnd

Function ERRORS

  # Only display error page if errors occured during installation
  ${If} $ERRORS > 0
    # Read errors from error log
    StrCpy $1 ""
    FileOpen $R0 $ERRLOGTMP r
      ClearErrors
      FileRead $R0 $0
      StrCpy $1 $0
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        ${Unless} $0 == ""
          StrCpy $1 "$1|$0"
        ${EndUnless}
      ${LoopUntil} ${Errors}
    FileClose $R0

    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "errors.ini"
    ${If} $ERRORS == 1
      !insertmacro MUI_HEADER_TEXT "Error" "An error occurred during the installation of nQuake."
      !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 1" "Text" "There was an error during the installation of nQuake. See below for more information."
    ${Else}
      !insertmacro MUI_HEADER_TEXT "Errors" "Some errors occurred during the installation of nQuake."
      !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 1" "Text" "There were some errors during the installation of nQuake. See below for more information."
    ${EndIf}
    !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 2" "ListItems" $1
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "errors.ini"
  ${EndIf}

FunctionEnd

Function un.UNINSTALL

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "uninstall.ini"

  # Remove all options on uninstall page except for "remove all files" if install.log is missing
  ${Unless} ${FileExists} "$INSTDIR\install.log"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 4" "State" "0"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 4" "Flags" "DISABLED"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 5" "Flags" "DISABLED"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "Text" "Remove all files contained within the nQuake directory (install.log missing)."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "State" "1"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "Flags" "FOCUS"
  ${EndUnless}
  !insertmacro MUI_HEADER_TEXT "Uninstall nQuake" "Remove nQuake from your computer."
  !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 3" "State" "$INSTDIR\"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "uninstall.ini"

FunctionEnd

;----------------------------------------------------
;Welcome/Finish page manipulation

Function WelcomeShow
  # Remove the part about nQuake being an online installer on welcome page if the installer is in offline mode
  ${Unless} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 3" "Text" "This is the installation wizard of nQuake, a QuakeWorld package made for newcomers, or those who just want to get on with the fragging as soon as possible!\r\n\r\nThis is an online installer and therefore requires a stable internet connection."
  ${Else}
    !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 3" "Text" "This is the installation wizard of nQuake, a QuakeWorld package made for newcomers, or those who just want to get on with the fragging as soon as possible!"
  ${EndUnless}
FunctionEnd

Function FinishShow
  # Hide the Back button on the finish page if there were no errors
  ${Unless} $ERRORS > 0
    GetDlgItem $R0 $HWNDPARENT 3
    EnableWindow $R0 0
  ${EndUnless}
  # Hide the community link if the installer is in offline mode
  ${If} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_READ $R0 "ioSpecial.ini" "Field 5" "HWND"
    ShowWindow $R0 ${SW_HIDE}
  ${EndIf}
FunctionEnd

;----------------------------------------------------
;Download size manipulation

!define SetSize "Call SetSize"

Function SetSize
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_FORTRESS "addons.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_CLANARENA "addons.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADDON_TEXTURES "addons.ini" "Field 6" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_PATH "download.ini" "Field 3" "State"
  # Only add shareware if pak0.pak doesn't exist
  IntOp $1 0 + 0
  ${Unless} ${FileExists} "$INSTDIR\ID1\pak0.pak"
    ${If} ${FileExists} "$EXEDIR\pak0.pak"
      StrCpy $R0 "$EXEDIR"
    ${ElseIf} ${FileExists} "$DISTFILES_PATH\pak0.pak"
      StrCpy $R0 "$DISTFILES_PATH"
    ${EndIf}
    ${GetSize} $R0 "/M=pak0.pak /S=0B /G=0" $7 $8 $9
    ${If} $7 == "18689235"
      Goto SkipShareware
    ${EndIf}
  ${EndUnless}
  !insertmacro DetermineSectionSize qsw106.zip
  IntOp $1 $1 + $SIZE
  SkipShareware:
  !insertmacro DetermineSectionSize gpl.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize non-gpl.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize textures.zip
  IntOp $1 $1 + $SIZE
  ${If} $ADDON_FORTRESS == 1
    !insertmacro DetermineSectionSize addon-fortress.zip
    IntOp $1 $1 + $SIZE
  ${EndIf}
  ${If} $ADDON_CLANARENA == 1
    !insertmacro DetermineSectionSize addon-clanarena.zip
    IntOp $1 $1 + $SIZE
  ${EndIf}
  ${If} $ADDON_TEXTURES == 1
    !insertmacro DetermineSectionSize addon-textures.zip
    IntOp $1 $1 + $SIZE
  ${EndIf}
FunctionEnd

Function DirectoryPageShow
  ${SetSize}
  SectionSetSize ${NQUAKE} $1
FunctionEnd 

;----------------------------------------------------
;Functions

Function .onInit

  !insertmacro MULTIUSER_INIT
  GetTempFileName $NQUAKE_INI

  # Download nquake.ini
  Start:
  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait..." /TIMEOUT 5000 "${INSTALLER_URL}/nquake.ini" $NQUAKE_INI /END
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      MessageBox MB_OK|MB_ICONEXCLAMATION "Installation aborted."
      Abort
    ${Else}
      ${Unless} $RETRIES > 0
        MessageBox MB_YESNO|MB_ICONEXCLAMATION "Are you trying to install nQuake offline?" IDNO Online
        StrCpy $OFFLINE 1
        Goto InitEnd
      ${EndUnless}
      Online:
      ${Unless} $RETRIES == 2
        MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Could not download nquake.ini." IDCANCEL Cancel
        IntOp $RETRIES $RETRIES + 1
        Goto Start
      ${EndUnless}
      MessageBox MB_OK|MB_ICONEXCLAMATION "Could not download nquake.ini. Please try again later."
      Cancel:
      Abort
    ${EndIf}
  ${EndUnless}

  # Prompt the user if there are newer installer versions available
  ReadINIStr $0 $NQUAKE_INI "versions" "windows"
  ${VersionConvert} ${VERSION} "" $R0
  ${VersionCompare} $R0 $0 $1
  ${If} $1 == 2
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "A newer version of nQuake is available.$\r$\n$\r$\nDo you wish to be taken to the download page?" IDNO ContinueInstall
    ExecShell "open" ${INSTALLER_URL}
    Abort
  ${EndIf}
  ContinueInstall:

  InitEnd:

FunctionEnd

Function un.onInit

  !insertmacro MULTIUSER_UNINIT

FunctionEnd

Function .abortInstallation

  # Close open temporary files
  FileClose $ERRLOG
  FileClose $INSTLOG
  FileClose $DISTLOG

  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\install.log" w
    ${time::GetFileTime} "$INSTDIR\install.log" $0 $1 $2
    FileWrite $INSTLOG "Install date: $1$\r$\n"
    FileOpen $R0 $INSTLOGTMP r
      ClearErrors
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        FileWrite $INSTLOG $0
      ${LoopUntil} ${Errors}
    FileClose $R0
  FileClose $INSTLOG

  # Ask to remove installed files
  Messagebox MB_YESNO|MB_ICONEXCLAMATION "Installation aborted.$\r$\n$\r$\nDo you wish to remove the installed files?" IDNO SkipInstRemoval
  # Show details window
  SetDetailsView show
  # Get line count for install.log
  Push "$INSTDIR\install.log"
  Call .LineCount
  Pop $R1 # Line count
  IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
  FileOpen $R0 "$INSTDIR\install.log" r
    # Get installation time from install.log
    FileRead $R0 $0
    StrCpy $1 $0 -2 14
    StrCpy $5 1 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      ${If} ${FileExists} "$INSTDIR\$0"
        ${time::GetFileTime} "$INSTDIR\$0" $2 $3 $4
        ${time::MathTime} "second($1) - second($3) =" $2
        ${If} $2 >= 0
          Delete /REBOOTOK "$INSTDIR\$0"
        ${EndIf}
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
  FileClose $R0
  Delete /REBOOTOK "$INSTDIR\install.log"
  ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
  DetailPrint "Removed $0 empty directories"
  # Remove directory if empty
  !insertmacro RemoveFolderIfEmpty $INSTDIR
  Goto InstEnd
  SkipInstRemoval:
  Delete /REBOOTOK "$INSTDIR\install.log"
  InstEnd:

  # Ask to remove downloaded distfiles
  Messagebox MB_YESNO|MB_ICONEXCLAMATION "Do you wish to keep the downloaded distribution files?" IDYES DistEnd
  # Get line count for distfiles.log
  Push $DISTLOGTMP
  Call .LineCount
  Pop $R1 # Line count
  FileOpen $R0 $DISTLOGTMP r
    StrCpy $5 0 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      ${If} ${FileExists} "$DISTFILES_PATH\$0"
        Delete /REBOOTOK "$DISTFILES_PATH\$0"
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
  FileClose $R0
  # Remove directory if empty
  !insertmacro RemoveFolderIfEmpty $DISTFILES_PATH
  DistEnd:

  # Set progress bar to 100%
  RealProgress::SetProgress /NOUNLOAD 100

  Abort

FunctionEnd

Function .checkDistfileDate
  StrCpy $R2 0
  ReadINIStr $0 $NQUAKE_INI "distfile_dates" $R0
  ${If} ${FileExists} "$DISTFILES_PATH\$R0"
    ${GetTime} "$DISTFILES_PATH\$R0" M $2 $3 $4 $5 $6 $7 $8
    # Fix hour format
    ${If} $6 < 10
      StrCpy $6 "0$6"
    ${EndIf}
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
    ${OrIf} $DISTFILES_REDOWNLOAD == 1
      StrCpy $R2 1
    ${Else}
      ReadINIStr $1 "$DISTFILES_PATH\nquake.ini" "distfile_dates" $R0
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R2 1
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${EndIf}
FunctionEnd

Function .installDistfile
  Retry:
  ${Unless} $R2 == 0 # if $R2 is 1 then distfile needs updating, otherwise not
    inetc::get /NOUNLOAD /CAPTION "Downloading..." /BANNER "Downloading $R1 update, please wait..." /TIMEOUT 5000 "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${Else}
    inetc::get /NOUNLOAD /CAPTION "Downloading..." /BANNER "Downloading $R1, please wait..." /TIMEOUT 5000 "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${EndUnless}
  FileWrite $DISTLOG "$R0$\r$\n"
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      Call .abortInstallation
    ${Else}
      MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION "Error downloading $R0: $0" IDIGNORE Ignore IDRETRY Retry
      Call .abortInstallation
      Ignore:
      FileWrite $ERRLOG 'Error downloading "$R0": $0|'
      IntOp $ERRORS $ERRORS + 1
    ${EndIf}
  ${EndUnless}
  StrCpy $DISTFILES 1
  DetailPrint "Extracting $R1, please wait..."
  nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
FunctionEnd

Function .installSection
  Pop $R1 # distfile info
  Pop $R0 # distfile filename
  Call .checkDistfileDate
  ${If} ${FileExists} "$EXEDIR\$R0"
    DetailPrint "Extracting $R1, please wait..."
    nsisunz::UnzipToStack "$EXEDIR\$R0" $INSTDIR
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\$R0"
  ${OrIf} $OFFLINE == 1
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R2 == 0
      DetailPrint "Extracting $R1, please wait..."
      nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
    ${ElseIf} $R2 == 1
    ${AndIf} $DISTFILES_UPDATE == 1
      Call .installDistfile
    ${EndIf}
  ${ElseUnless} ${FileExists} "$DISTFILES_PATH\$R0"
    Call .installDistfile
  ${EndIf}
  Pop $0
  ${If} $0 == "Error opening ZIP file"
  ${OrIf} $0 == "Error opening output file(s)"
  ${OrIf} $0 == "Error writing output file(s)"
  ${OrIf} $0 == "Error extracting from ZIP file"
  ${OrIf} $0 == "File not found in ZIP file"
    FileWrite $ERRLOG 'Error extracting "$R0": $0|'
    IntOp $ERRORS $ERRORS + 1
  ${Else}
    ${DoUntil} $0 == ""
      ${Unless} $0 == "success"
        FileWrite $INSTLOG "$0$\r$\n"
      ${EndUnless}
      Pop $0
    ${LoopUntil} $0 == ""
  ${EndIf}
FunctionEnd

Function .LineCount
  Exch $R0
  Push $R1
  Push $R2
   FileOpen $R0 $R0 r
  loop:
   ClearErrors
   FileRead $R0 $R1
   IfErrors +3
    IntOp $R2 $R2 + 1
  Goto loop
   FileClose $R0
   StrCpy $R0 $R2
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

Function un.LineCount
  Exch $R0
  Push $R1
  Push $R2
   FileOpen $R0 $R0 r
  loop:
   ClearErrors
   FileRead $R0 $R1
   IfErrors +3
    IntOp $R2 $R2 + 1
  Goto loop
   FileClose $R0
   StrCpy $R0 $R2
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd