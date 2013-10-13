;nQuake NSIS Online Installer Script
;By Empezar 2007-05-31; Last modified 2007-07-17

!define VERSION "1.5"
!define SHORTVERSION "15"

Name "nQuake"
OutFile "nquake${SHORTVERSION}_installer.exe"
InstallDir "$PROGRAMFILES\nQuake"

!define INSTALLER_URL "http://nquake.sf.net" # Note: no trailing slash!
!define DISTFILES_PATH "C:\nquake-distfiles" # Note: no trailing slash!

# Editing anything below this line is not recommended
;---------------------------------------------------

InstallDirRegKey HKLM "Software\nQuake" "Install_Dir"

;----------------------------------------------------
;Header Files

!include "MUI.nsh"
!include "FileFunc.nsh"
!insertmacro GetSize
!insertmacro GetTime
!include "LogicLib.nsh"
!include "Time.nsh"
!include "Locate.nsh"
!include "VersionCompare.nsh"
!include "VersionConvert.nsh"
!include "nquake-macros.nsh"

;----------------------------------------------------
;Initialize Variables

Var NQUAKE_INI
Var DISTFILES_URL
Var DISTFILES_PATH
Var DISTFILES_UPDATE
Var DISTFILES_KEEP
Var PAK_LOCATION
Var REMOVE_MODIFIED_FILES
Var REMOVE_ALL_FILES
Var STARTMENU_FOLDER
Var INSTLOGTMP
Var INSTLOG
Var DISTLOGTMP
Var DISTLOG
Var DISTFILES
Var SIZE
Var OFFLINE

;----------------------------------------------------
;Interface Settings

!define MUI_ICON "quake.ico"
!define MUI_UNICON "quake.ico"

!define MUI_HEADERIMAGE
!define MUI_WELCOMEFINISHPAGE_BITMAP "nquake-welcomefinish.bmp"
!define MUI_HEADERIMAGE_BITMAP "nquake-header.bmp"

!define MUI_FINISHPAGE_NOREBOOTSUPPORT

;----------------------------------------------------
;Pages

!define MUI_WELCOMEPAGE_TITLE "nQuake Installation Wizard"
!define MUI_WELCOMEPAGE_TEXT "This is the installation wizard of nQuake, a QuakeWorld package made for newcomers, or those who just want to get on with the fragging as soon as possible!\r\n\r\nThis is an online installer and therefore requires a stable internet connection."
!insertmacro MUI_PAGE_WELCOME

LicenseForceSelection checkbox "I agree to these terms and conditions"
!insertmacro MUI_PAGE_LICENSE "license.txt"

Page custom FULLVERSION
Page custom DISTFILEFOLDER
Page custom MIRRORSELECT
Page custom KEEPDISTFILES

!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_STARTMENU "Application" $STARTMENU_FOLDER

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN "$INSTDIR/ezquake-gl.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch QuakeWorld"
!define MUI_FINISHPAGE_SHOWREADME "http://www.quakeworld.nu"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Visit the leading QuakeWorld community site"
!insertmacro MUI_PAGE_FINISH

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

ReserveFile "fullversion.ini"
ReserveFile "distfilefolder.ini"
ReserveFile "mirrorselect.ini"
ReserveFile "keepdistfiles.ini"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;----------------------------------------------------
;Installer Sections

Section "" # Prepare installation

  SetOutPath $INSTDIR

  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_PATH "distfilefolder.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_UPDATE "distfilefolder.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $PAK_LOCATION "fullversion.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_KEEP "keepdistfiles.ini" "Field 2" "State"

  ${Unless} ${FileExists} "$DISTFILES_PATH\*.*"
    CreateDirectory $DISTFILES_PATH
  ${EndUnless}

  # Find out what mirror was selected
  Call .determineMirror

  GetTempFileName $INSTLOGTMP
  GetTempFileName $DISTLOGTMP
  FileOpen $INSTLOG $INSTLOGTMP w
  FileOpen $DISTLOG $DISTLOGTMP w

SectionEnd

Section "nQuake" NQUAKE

  SectionIn 1 RO

  # Download and install pak0.pak (shareware data)
  ${Unless} ${FileExists} "$INSTDIR\ID1\PAK0.PAK"
    !insertmacro InstallSection qsw106.zip
    FileClose $INSTLOG
    FileOpen $INSTLOG $INSTLOGTMP w
  ${EndUnless}
  Rename "$INSTDIR\ID1" "$INSTDIR\id1"
  Rename "$INSTDIR\id1\PAK0.PAK" "$INSTDIR\id1\pak0.pak"
  FileWrite $INSTLOG "id1\pak0.pak$\r$\n"

  # Copy pak1.pak if it was found or specified (registered data), and doesn't already exist
  ${If} $PAK_LOCATION != ""
  ${AndUnless} ${FileExists} "$INSTDIR\id1\pak1.pak"
    CopyFiles /SILENT $PAK_LOCATION "$INSTDIR\id1\pak1.pak"
    FileWrite $INSTLOG "id1\pak1.pak$\r$\n"
  ${EndIf}

  # Remove crap files extracted from shareware zip
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
  #${locate::RMDirEmpty} "$INSTDIR" /M=*.* $0

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

  # Download and install nQuake
  !insertmacro InstallSection nquake.zip
  !insertmacro InstallSection ezquake.zip
  !insertmacro InstallSection eyecandy.zip
  !insertmacro InstallSection frogbot.zip
  !insertmacro InstallSection maps.zip
  !insertmacro InstallSection demos.zip

SectionEnd

Section "" # StartMenu

  RealProgress::SetProgress /NOUNLOAD 100

  StrCpy $0 $STARTMENU_FOLDER 1

  ${Unless} $0 == ">"
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"

    # Create links
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER\Links"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Latest News.url" "InternetShortcut" "URL" "http://www.quakeworld.nu/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Message Board.url" "InternetShortcut" "URL" "http://www.quakeworld.nu/forum/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\List of Servers.url" "InternetShortcut" "URL" "http://www.quakeservers.net/quakeworld/servers/pl=1/so=8/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Match Demos.url" "InternetShortcut" "URL" "http://www.challenge-tv.com/index.php?mode=demos&game=2"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Custom Graphics.url" "InternetShortcut" "URL" "http://gfx.qwdrama.com/"

    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Start ezQuake.lnk" "$INSTDIR\ezquake-gl.exe" "" "$INSTDIR\ezquake-gl.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall nQuake.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    WriteRegStr HKLM "Software\nQuake" "StartMenu_Folder" $STARTMENU_FOLDER
  ${EndUnless}

SectionEnd

Section "" # Clean up installation

  FileClose $INSTLOG

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

  # Copy nquake.ini to the distfiles directory
  ${If} $DISTFILES_UPDATE == 1
    CopyFiles $NQUAKE_INI "$DISTFILES_PATH\nquake.ini"
    FileWrite $DISTLOG "nquake.ini$\r$\n"
  ${EndIf}

  FileClose $DISTLOG

  # Remove downloaded distfiles
  ${If} $DISTFILES_KEEP == 0
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
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
    FileClose $R0
    ${Unless} ${FileExists} "$DISTFILES_PATH\*.*"
      RMDir /REBOOTOK $DISTFILES_PATH
    ${EndUnless}
  ${EndIf}

  # Write to registry
  WriteRegStr HKLM "Software\nQuake" "Install_Dir" $INSTDIR
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayName" "nQuake"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "Publisher" "The nQuake Team"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "URLUpdateInfo" "http://sourceforge.net/project/showfiles.php?group_id=197706"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "URLInfoAbout" "http://nquake.sourceforge.net/"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "HelpLink" "http://sourceforge.net/forum/forum.php?forum_id=702198"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "NoModify" "1"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake" "NoRepair" "1"

  # Associate files
  WriteRegStr HKCR ".qtv" "" "ezQuake.qtv"
  WriteRegStr HKCR ".mvd" "" "ezQuake.demo"
  WriteRegStr HKCR ".qwd" "" "ezQuake.demo"
  WriteRegStr HKCR ".qwz" "" "ezQuake.demo"
  WriteRegStr HKCR ".lst" "" "txtfile"
  WriteRegStr HKCR "ezQuake.qtv" "" "QTV Stream Info File"
  WriteRegStr HKCR "ezQuake.qtv\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "ezQuake.qtv\shell" "" "open"
  WriteRegStr HKCR "ezQuake.qtv\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'
  WriteRegStr HKCR "ezQuake.demo" "" "QuakeWorld Demo"
  WriteRegStr HKCR "ezQuake.demo\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "ezQuake.demo\shell" "" "open"
  WriteRegStr HKCR "ezQuake.demo\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'

  WriteUninstaller "uninstall.exe"

SectionEnd

;----------------------------------------------------
;Uninstaller Section

Section "Uninstall"

  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_MODIFIED_FILES "uninstall.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_ALL_FILES "uninstall.ini" "Field 6" "State"

  SetOutPath $TEMP

  # Set uninstallation progress bar to 0%
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
      ${If} ${FileExists} "$INSTDIR\$0"
      ${AndUnless} $REMOVE_MODIFIED_FILES == 1
        # Only remove file if it has not been altered since install
        ${time::GetFileTime} "$INSTDIR\$0" $2 $3 $4
        ${time::MathTime} "second($1) - second($3) =" $2
        ${If} $2 >= 0
          Delete /REBOOTOK "$INSTDIR\$0"
        ${EndIf}
      ${ElseIf} $REMOVE_MODIFIED_FILES == 1
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
    RMDir /REBOOTOK $INSTDIR
  ${Else}
    RMDir /r /REBOOTOK $INSTDIR
    RealProgress::SetProgress /NOUNLOAD 100
  ${EndIf}

  ReadRegStr $0 HKLM "Software\nQuake" "StartMenu_Folder"
  RMDir /r /REBOOTOK "$SMPROGRAMS\$0"

  # Remove file associations
  ReadRegStr $R0 HKCR ".qtv" ""
  StrCmp $R0 "ezQuake.qtv" 0 +2
    DeleteRegKey HKCR ".qtv"

  ReadRegStr $R0 HKCR ".mvd" ""
  StrCmp $R0 "ezQuake.demo" 0 +2
    DeleteRegKey HKCR ".mvd"

  ReadRegStr $R0 HKCR ".qwd" ""
  StrCmp $R0 "ezQuake.demo" 0 +2
    DeleteRegKey HKCR ".qwd"

  ReadRegStr $R0 HKCR ".qwz" ""
  StrCmp $R0 "ezQuake.demo" 0 +2
    DeleteRegKey HKCR ".qwz"

  ReadRegStr $R0 HKCR ".lst" ""
  StrCmp $R0 "txtfile" 0 +2
    DeleteRegKey HKCR ".lst"

  DeleteRegKey HKCR "ezQuake.qtv"
  DeleteRegKey HKCR "ezQuake.demo"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake"
  DeleteRegKey HKLM "Software\nQuake"

SectionEnd

;----------------------------------------------------
;Custom Pages

Function FULLVERSION

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "fullversion.ini"
  !insertmacro MUI_HEADER_TEXT "Full Version Quake Data" "Find pak1.pak for inclusion in nQuake."

  ${If} ${FileExists} "C:\Quake\id1\pak1.pak"
    StrCpy $0 "C:\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\Quake\id1\pak1.pak"
    StrCpy $0 "D:\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\Quake\id1\pak1.pak"
    StrCpy $0 "E:\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Games\Quake\id1\pak1.pak"
    StrCpy $0 "C:\Games\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\Games\Quake\id1\pak1.pak"
    StrCpy $0 "D:\Games\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\Games\Quake\id1\pak1.pak"
    StrCpy $0 "E:\Games\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Program Files\Quake\id1\pak1.pak"
    StrCpy $0 "C:\Program Files\Quake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\eQuake\id1\pak1.pak"
    StrCpy $0 "C:\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\eQuake\id1\pak1.pak"
    StrCpy $0 "D:\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\eQuake\id1\pak1.pak"
    StrCpy $0 "E:\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Games\eQuake\id1\pak1.pak"
    StrCpy $0 "C:\Games\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\Games\eQuake\id1\pak1.pak"
    StrCpy $0 "D:\Games\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\Games\eQuake\id1\pak1.pak"
    StrCpy $0 "E:\Games\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Program Files\eQuake\id1\pak1.pak"
    StrCpy $0 "C:\Program Files\eQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\fQuake\id1\pak1.pak"
    StrCpy $0 "C:\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\fQuake\id1\pak1.pak"
    StrCpy $0 "D:\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\fQuake\id1\pak1.pak"
    StrCpy $0 "E:\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Games\fQuake\id1\pak1.pak"
    StrCpy $0 "C:\Games\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\Games\fQuake\id1\pak1.pak"
    StrCpy $0 "D:\Games\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\Games\fQuake\id1\pak1.pak"
    StrCpy $0 "E:\Games\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Program Files\fQuake\id1\pak1.pak"
    StrCpy $0 "C:\Program Files\fQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\nQuake\id1\pak1.pak"
    StrCpy $0 "C:\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\nQuake\id1\pak1.pak"
    StrCpy $0 "D:\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\nQuake\id1\pak1.pak"
    StrCpy $0 "E:\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Games\nQuake\id1\pak1.pak"
    StrCpy $0 "C:\Games\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "D:\Games\nQuake\id1\pak1.pak"
    StrCpy $0 "D:\Games\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "E:\Games\nQuake\id1\pak1.pak"
    StrCpy $0 "E:\Games\nQuake\id1"
    Goto FullVersion
  ${ElseIf} ${FileExists} "C:\Program Files\nQuake\id1\pak1.pak"
    StrCpy $0 "C:\Program Files\nQuake\id1"
    Goto FullVersion
  ${Else}
    Goto FullVersionEnd
  ${EndIf}
  FullVersion:
  ${GetSize} $0 "/M=pak1.pak /S=0B /G=0" $7 $8 $9
  ${If} $7 == 34257856
    !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 1" "Text" "The full version of Quake is not included in this package. However, setup has found what resembles the full version pak1.pak on your harddrive. If this is not the correct file, click Browse to locate the correct pak1.pak. Click Next to continue."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 3" "State" "$0\pak1.pak"
  ${EndIf}
  FullVersionEnd:
  ${If} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 4" "Type" ""
  ${EndIf}
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "fullversion.ini"

FunctionEnd

Function DISTFILEFOLDER

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "distfilefolder.ini"
  ${If} $OFFLINE == 1
    !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select where the distribution files are located."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 1" "Text" "Setup will use the distribution files (used to install nQuake) located in the following folder. To use a different folder, click Browse and select another folder. Click Next to continue."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 4" "Type" ""
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 4" "State" "0"
  ${Else}
    !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select where you want the distribution files to be downloaded."
  ${EndIf}
  !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 5" "State" ${DISTFILES_PATH}
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "distfilefolder.ini"

FunctionEnd

Function MIRRORSELECT

  ${Unless} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "mirrorselect.ini"
    !insertmacro MUI_HEADER_TEXT "Mirror Selection" "Select a mirror from your part of the world."

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

    !insertmacro MUI_INSTALLOPTIONS_WRITE "mirrorselect.ini" "Field 3" "ListItems" $2
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "mirrorselect.ini"
  ${EndUnless}

FunctionEnd

Function KEEPDISTFILES

  ${Unless} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "keepdistfiles.ini"
    !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select whether you want to keep the distribution files or not."
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "keepdistfiles.ini"
  ${EndUnless}

FunctionEnd

Function un.UNINSTALL

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "uninstall.ini"

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
;Functions

Function .onInit

  GetTempFileName $NQUAKE_INI

  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait..." /TIMEOUT=7000 "${INSTALLER_URL}/nquake.ini" $NQUAKE_INI /END

  # Prompt the user if nquake.ini could not be downloaded
  ReadINIStr $0 $NQUAKE_INI "mirror_addresses" "1"
  ${If} $0 == ""
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "Are you trying to install nQuake offline?" IDNO Online
    StrCpy $OFFLINE 1
    Goto InitEnd
    Online:
    MessageBox MB_OK|MB_ICONEXCLAMATION "Could not download nquake.ini. Please try again later."
    Abort
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

  # Determine sizes on all the sections
  !insertmacro DetermineSectionSize qsw106.zip
  StrCpy $R0 $SIZE
  !insertmacro DetermineSectionSize nquake.zip
  StrCpy $R1 $SIZE
  !insertmacro DetermineSectionSize ezquake.zip
  StrCpy $R2 $SIZE
  !insertmacro DetermineSectionSize eyecandy.zip
  StrCpy $R3 $SIZE
  !insertmacro DetermineSectionSize frogbot.zip
  StrCpy $R4 $SIZE
  !insertmacro DetermineSectionSize maps.zip
  StrCpy $R5 $SIZE
  !insertmacro DetermineSectionSize demos.zip
  StrCpy $R6 $SIZE
  IntOp $0 $R0 + $R1
  IntOp $0 $0 + $R2
  IntOp $0 $0 + $R3
  IntOp $0 $0 + $R4
  IntOp $0 $0 + $R5
  IntOp $0 $0 + $R6
  SectionSetSize ${NQUAKE} $0

  InitEnd:

FunctionEnd

Function .abortInstallation

  FileClose $INSTLOG

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

  FileClose $DISTLOG

  # Ask to remove installed files
  Messagebox MB_YESNO|MB_ICONEXCLAMATION "Installation aborted.$\r$\n$\r$\nDo you wish to remove the installed files?" IDNO SkipInstRemoval
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
  RMDir /REBOOTOK $INSTDIR
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
  RMDir /REBOOTOK $DISTFILES_PATH
  DistEnd:

  RealProgress::SetProgress /NOUNLOAD 100

  Abort

FunctionEnd

Function .checkDistfileDate
  Pop $R0
  StrCpy $R1 0
  ReadINIStr $0 $NQUAKE_INI "distfile_dates" $R0
  ${If} ${FileExists} "$DISTFILES_PATH\$R0"
    ${GetTime} "$DISTFILES_PATH\$R0" M $2 $3 $4 $5 $6 $7 $8
    # Fix hour format
    ${If} $6 < 10
      StrCpy $6 "0$6"
    ${EndIf}
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R1 1
    ${Else}
      ReadINIStr $1 "$DISTFILES_PATH\nquake.ini" "distfile_dates" $R0
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R1 1
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${EndIf}
FunctionEnd

Function .installDistfile
  Pop $R0
  Push 0
  Retry:
  ${Unless} $R1 == 0
    inetc::get /NOUNLOAD /TRANSLATE "Downloading %s (update)" "Connecting ..." "second" "minute" "hour" "s" "%dkB (%d%%) of %dkB @ %d.%01dkB/s" " (%d %s%s remaining)" "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${Else}
    inetc::get /NOUNLOAD "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${EndUnless}
  FileWrite $DISTLOG "$R0$\r$\n"
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      Call .abortInstallation
    ${Else}
      DetailPrint "Error downloading $R0: $0"
      MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION "Error downloading $R0: $0" IDIGNORE Ignore IDRETRY Retry
      Call .abortInstallation
      Ignore:
    ${EndIf}
  ${Else}
    Pop $R9
    Push 1
  ${EndUnless}
  StrCpy $DISTFILES 1
  DetailPrint "Extracting from: $R0"
  nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
FunctionEnd

Function .installSection
  Pop $R0
  !insertmacro CheckDistfileDate $R0
  ${If} ${FileExists} "$DISTFILES_PATH\$R0"
  ${OrIf} $OFFLINE == 1
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R1 == 0
      DetailPrint "Extracting from: $R0"
      nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
    ${ElseIf} $R1 == 1
    ${AndIf} $DISTFILES_UPDATE == 1
      !insertmacro InstallDistfile $R0
    ${EndIf}
  ${ElseUnless} ${FileExists} "$DISTFILES_PATH\$R0"
    !insertmacro InstallDistfile $R0
  ${EndIf}
  Pop $0
  ${If} $0 == "Error opening ZIP file: $R0"
  ${OrIf} $0 == "Error opening output file(s)"
  ${OrIf} $0 == "Error writing output file(s)"
  ${OrIf} $0 == "Error extracting from ZIP file"
  ${OrIf} $0 == "File not found in ZIP file"
    DetailPrint "Extraction error: $0"
  ${Else}
    ${DoUntil} $0 == ""
      ${Unless} $0 == "success"
        FileWrite $INSTLOG "$0$\r$\n"
        DetailPrint "Extract: $0"
      ${EndUnless}
      Pop $0
    ${LoopUntil} $0 == ""
  ${EndIf}
FunctionEnd

Function .determineMirror
  !insertmacro MUI_INSTALLOPTIONS_READ $R0 "mirrorselect.ini" "Field 3" "State"
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

  DetailPrint "Using mirror: $0"
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