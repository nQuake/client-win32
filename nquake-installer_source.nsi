;nQuake NSIS Online Installer Script
;By Empezar 2007-05-31; Last modified 2007-07-14

!define VERSION "1.3"
!define SHORTVERSION "13"

Name "nQuake"
OutFile "nquake${SHORTVERSION}_installer.exe"
InstallDir "$PROGRAMFILES\nQuake"

!define INSTALLER_URL "http://nquake.sf.net" # Note: no trailing slash!
!define DISTFILES_PATH "C:\nquake-distfiles"
!define DISTFILES_PATH_RELATIVE "nquake-distfiles"

# Editing anything below this line is not recommended
;---------------------------------------------------

InstallDirRegKey HKLM "Software\nQuake" "Install_Dir"
!define INSTLOG "install.log"
!define DISTFILES_INI "distfiles.ini"
!define DISTFILES_INI_REMOTE "distfiles.ini" # distfiles.ini filename on remote server
!define DISTFILEDATES_INI "distfiledates.ini"
!define DISTFILEDATES_INI_REMOTE "distfiledates.ini" # distfiledates.ini filename on remote server
!define INSTALLERVERSIONS_INI_REMOTE "installerversions.ini" # installerversions.ini filename on remote server
!define MIRRORS_INI "mirrors.ini"
!define MIRRORS_INI_REMOTE "mirrors.ini" # mirrors.ini filename on remote server

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
!include "nquake-macros.nsh"

;----------------------------------------------------
;Initialize Variables

Var DISTFILES_URL
Var DISTFILES_PATH
Var DISTFILES_INI
Var DISTFILES_UPDATE
Var DISTFILES_KEEP
Var DISTFILEDATES_INI
Var INSTALLERVERSIONS_INI
Var MIRRORS_INI
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

!define MUI_WELCOMEPAGE_TITLE $(WELCOMEPAGE_TITLE)
!define MUI_WELCOMEPAGE_TEXT $(WELCOMEPAGE_TEXT)
!insertmacro MUI_PAGE_WELCOME

LicenseForceSelection checkbox $(LICENSEPAGE_CHECKBOX)
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
!define MUI_FINISHPAGE_SHOWREADME $(FINISHPAGE_SHOWREADME_LINK)
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT $(FINISHPAGE_SHOWREADME_TEXT)
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM

UninstPage custom un.REMOVEFOLDER

!insertmacro MUI_UNPAGE_INSTFILES

;----------------------------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"
!include "nquake-lang-english.nsi"

;----------------------------------------------------
;Reserve Files

ReserveFile "fullversion.ini"
ReserveFile "distfilefolder.ini"
ReserveFile "mirrorselect.ini"
ReserveFile "keepdistfiles.ini"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;----------------------------------------------------
;Installation Types

#InstType $(INSTTYPE_RECOMMENDED)
#InstType $(INSTTYPE_FULL)
#InstType $(INSTTYPE_MINIMUM)

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

  # Backup old config if such exists
  ${If} ${FileExists} "$INSTDIR\ezquake\configs\config.cfg"
    Rename "$INSTDIR\ezquake\configs\config.cfg" "$INSTDIR\ezquake\configs\config.bak"
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

  StrCpy $0 $STARTMENU_FOLDER 1

  ${Unless} $0 == ">"
    Call .createStartMenuItems
  ${EndUnless}

SectionEnd

Section "" # Clean up installation

  FileClose $INSTLOG

  Call .cleanupInstallation

  # Registry
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

  # Associate .qtv files
  WriteRegStr HKCR ".qtv" "" "QuakeWorld.QTV"
  WriteRegStr HKCR "QuakeWorld.QTV" "" "QTV Stream Info File"
  WriteRegStr HKCR "QuakeWorld.QTV\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "QuakeWorld.QTV\shell" "" "open"
  WriteRegStr HKCR "QuakeWorld.QTV\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'

  # Associate .mvd files
  WriteRegStr HKCR ".mvd" "" "QuakeWorld.MVD"
  WriteRegStr HKCR "QuakeWorld.MVD" "" "Multi View Demo File"
  WriteRegStr HKCR "QuakeWorld.MVD\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "QuakeWorld.MVD\shell" "" "open"
  WriteRegStr HKCR "QuakeWorld.MVD\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'

  # Associate .qwd files
  WriteRegStr HKCR ".qwd" "" "QuakeWorld.QWD"
  WriteRegStr HKCR "QuakeWorld.QWD" "" "QuakeWorld Demo File"
  WriteRegStr HKCR "QuakeWorld.QWD\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "QuakeWorld.QWD\shell" "" "open"
  WriteRegStr HKCR "QuakeWorld.QWD\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'

  # Associate .qwz files
  WriteRegStr HKCR ".qwz" "" "QuakeWorld.QWZ"
  WriteRegStr HKCR "QuakeWorld.QWZ" "" "QuakeWorld Zipdemo File"
  WriteRegStr HKCR "QuakeWorld.QWZ\DefaultIcon" "" "$INSTDIR\ezquake-gl.exe,0"
  WriteRegStr HKCR "QuakeWorld.QWZ\shell" "" "open"
  WriteRegStr HKCR "QuakeWorld.QWZ\shell\open\command" "" '$INSTDIR\ezquake-gl.exe "%1"'

  WriteUninstaller "uninstall.exe"

SectionEnd

;----------------------------------------------------
;Uninstaller Section

Section "Uninstall"

  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_MODIFIED_FILES "removefolder.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_ALL_FILES "removefolder.ini" "Field 4" "State"

  SetOutPath $TEMP

  # Set uninstallation progress bar to 0%
  RealProgress::SetProgress /NOUNLOAD 0

  # If install.log exists and user didn't check "remove all files", remove all files listed in install.log
  ${If} ${FileExists} "$INSTDIR\${INSTLOG}"
  ${AndIf} $REMOVE_ALL_FILES != 1
    # Get line count for install.log
    Push "$INSTDIR\${INSTLOG}"
    Call un.LineCount
    Pop $R1 # Line count
    IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
    FileOpen $R0 "$INSTDIR\${INSTLOG}" r
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
    Delete /REBOOTOK "$INSTDIR\${INSTLOG}"
    Delete /REBOOTOK "$INSTDIR\uninstall.exe"
    ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
    DetailPrint $(REMOVED_EMPTY_DIRECTORIES)
    RMDir /REBOOTOK $INSTDIR
  ${Else}
    ${If} $REMOVE_ALL_FILES != 1
      MessageBox MB_YESNO|MB_ICONEXCLAMATION $(UNINSTALL_CONFIRMATION) IDNO SkipUninstall
    ${EndIf}
    RMDir /r /REBOOTOK $INSTDIR
    RealProgress::SetProgress /NOUNLOAD 100
  ${EndIf}

  ReadRegStr $0 HKLM "Software\nQuake" "StartMenu_Folder"
  RMDir /r /REBOOTOK "$SMPROGRAMS\$0"

  # Removing file associations
  ReadRegStr $R0 HKCR ".qtv" ""
  StrCmp $R0 "QuakeWorld.QTV" 0 +2
    DeleteRegKey HKCR ".qtv"

  ReadRegStr $R0 HKCR ".mvd" ""
  StrCmp $R0 "QuakeWorld.MVD" 0 +2
    DeleteRegKey HKCR ".mvd"

  ReadRegStr $R0 HKCR ".qwd" ""
  StrCmp $R0 "QuakeWorld.QWD" 0 +2
    DeleteRegKey HKCR ".qwd"

  ReadRegStr $R0 HKCR ".qwz" ""
  StrCmp $R0 "QuakeWorld.QWZ" 0 +2
    DeleteRegKey HKCR ".qwz"

  DeleteRegKey HKCR "QuakeWorld.QTV"
  DeleteRegKey HKCR "QuakeWorld.MVD"
  DeleteRegKey HKCR "QuakeWorld.QWD"
  DeleteRegKey HKCR "QuakeWorld.QWZ"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake"
  DeleteRegKey HKLM "Software\nQuake"

  Goto FinishUninstall

  SkipUninstall:
    Abort

  FinishUninstall:

SectionEnd

;----------------------------------------------------
;Functions

Function .onInit

  GetTempFileName $INSTALLERVERSIONS_INI
  GetTempFileName $MIRRORS_INI
  GetTempFileName $DISTFILES_INI
  GetTempFileName $DISTFILEDATES_INI

  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait..." /TIMEOUT=7000 "${INSTALLER_URL}/${INSTALLERVERSIONS_INI_REMOTE}" $INSTALLERVERSIONS_INI \
"${INSTALLER_URL}/${MIRRORS_INI_REMOTE}" $MIRRORS_INI \
"${INSTALLER_URL}/${DISTFILES_INI_REMOTE}" $DISTFILES_INI \
"${INSTALLER_URL}/${DISTFILEDATES_INI_REMOTE}" $DISTFILEDATES_INI /END

  # Prompt the user if there are newer installer versions available
  ReadINIStr $0 $INSTALLERVERSIONS_INI "versions" "windows"
  ${VersionCompare} ${VERSION} $0 $1
  ${If} $1 == 2
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "A newer version of nQuake is available.$\r$\n$\r$\nDo you wish to be taken to the download page?" IDNO ContinueInstall
    ExecShell "open" ${INSTALLER_URL}
    Abort
  ${EndIf}
  ContinueInstall:

  # Prompt the user if mirrors.ini could not be downloaded
  ReadINIStr $0 $MIRRORS_INI "mirrors" "1"
  ${If} $0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Setup could not download mirrors.ini, please try again later."
    Abort
  ${EndUnless}

  # Download distfiles.ini
  ReadINIStr $0 $DISTFILES_INI "size" "qsw106.zip"
  ${If} $0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Setup could not download distfiles.ini.$\r$\n$\r$\nThe download size displayed will be inaccurate."
    SectionSetSize ${NQUAKE} 86508
  ${Else}
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
  ${EndIf}

FunctionEnd

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
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "fullversion.ini"

FunctionEnd

Function DISTFILEFOLDER

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "distfilefolder.ini"
  !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select where you want the distribution files to be downloaded."
  !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 5" "State" ${DISTFILES_PATH}
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "distfilefolder.ini"

FunctionEnd

Function MIRRORSELECT

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "mirrorselect.ini"
  !insertmacro MUI_HEADER_TEXT "Mirror Selection" "Select a mirror from your part of the world."
  ReadINIStr $0 $MIRRORS_INI "description" 1
  !insertmacro MUI_INSTALLOPTIONS_WRITE "mirrorselect.ini" "Field 3" "State" $(PREFERENCESPAGE_RANDOM_MIRROR)

  # Fix the mirrors for the Preferences page
  StrCpy $0 1
  StrCpy $2 $(PREFERENCESPAGE_RANDOM_MIRROR)
  ReadINIStr $1 $MIRRORS_INI "description" $0
  ${DoUntil} $1 == ""
    ReadINIStr $1 $MIRRORS_INI "description" $0
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

FunctionEnd

Function KEEPDISTFILES

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "keepdistfiles.ini"
  !insertmacro MUI_HEADER_TEXT "Distribution Files" "Choose if you want the distribution files removed or not."
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "keepdistfiles.ini"

FunctionEnd

Function un.REMOVEFOLDER

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "removefolder.ini"
  !insertmacro MUI_HEADER_TEXT "Remove Everything" "Choose if you want the entire nQuake folder removed."
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "removefolder.ini"

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

Function .abortInstallation

  FileClose $INSTLOG

  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\${INSTLOG}" w
    ${time::GetFileTime} "$INSTDIR\${INSTLOG}" $0 $1 $2
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
  Messagebox MB_YESNO|MB_ICONEXCLAMATION $(ABORT_REMOVE_INSTFILES) IDNO SkipInstRemoval
  # Get line count for install.log
  Push "$INSTDIR\${INSTLOG}"
  Call .LineCount
  Pop $R1 # Line count
  IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
  FileOpen $R0 "$INSTDIR\${INSTLOG}" r
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
  Delete /REBOOTOK "$INSTDIR\${INSTLOG}"
  ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
  DetailPrint $(REMOVED_EMPTY_DIRECTORIES)
  RMDir /REBOOTOK $INSTDIR
  Goto InstEnd
  SkipInstRemoval:
  Delete /REBOOTOK "$INSTDIR\${INSTLOG}"
  InstEnd:

  # Ask to remove downloaded distfiles
  Messagebox MB_YESNO|MB_ICONEXCLAMATION $(ABORT_KEEP_DISTFILES) IDYES DistEnd
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
  ReadINIStr $0 $DISTFILEDATES_INI "dates" $R0
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\$R0"
    ${GetTime} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\$R0" M $2 $3 $4 $5 $6 $7 $8
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R1 1
    ${Else}
      ReadINIStr $1 "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${DISTFILEDATES_INI}" "dates" $R0
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R1 1
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\$R0"
    ${GetTime} "$DISTFILES_PATH\$R0" M $2 $3 $4 $5 $6 $7 $8
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R1 2
    ${Else}
      ReadINIStr $1 "$DISTFILES_PATH\${DISTFILEDATES_INI}" "dates" $R0
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R1 2
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
    inetc::get /NOUNLOAD /TRANSLATE $(NSISDL_DOWNLOADING_UPDATE) $(NSISDL_CONNECTING) $(NSISDL_SECOND) $(NSISDL_MINUTE) $(NSISDL_HOUR) $(NSISDL_PLURAL) $(NSISDL_PROGRESS) $(NSISDL_REMAINING) "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${Else}
    inetc::get /NOUNLOAD /TRANSLATE $(NSISDL_DOWNLOADING) $(NSISDL_CONNECTING) $(NSISDL_SECOND) $(NSISDL_MINUTE) $(NSISDL_HOUR) $(NSISDL_PLURAL) $(NSISDL_PROGRESS) $(NSISDL_REMAINING) "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${EndUnless}
  FileWrite $DISTLOG "$R0$\r$\n"
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      Call .abortInstallation
    ${Else}
      DetailPrint $(NSISDL_DOWNLOAD_ERROR)
      MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION "$R0 Download error: $0" IDIGNORE Ignore IDRETRY Retry
      Call .abortInstallation
      Ignore:
    ${EndIf}
  ${Else}
    Pop $R9
    Push 1
  ${EndUnless}
  StrCpy $DISTFILES 1
  DetailPrint $(NSISUNZ_EXTRACTING_FROM)
  nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
FunctionEnd

Function .installSection
  Pop $R0
  !insertmacro CheckDistfileDate $R0
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\$R0"
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R1 == 0
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$EXEDIR\${DISTFILES_PATH_RELATIVE}\$R0" $INSTDIR
    ${ElseIf} $R1 == 1
      !insertmacro InstallDistfile $R0
    ${EndIf}
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\$R0"
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R1 == 0
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
    ${ElseIf} $R1 == 2
      !insertmacro InstallDistfile $R0
    ${EndIf}
  ${Else}
    !insertmacro InstallDistfile $R0
  ${EndIf}
  Pop $0
  ${If} $0 == "Error opening ZIP file"
  ${OrIf} $0 == "Error opening output file(s)"
  ${OrIf} $0 == "Error writing output file(s)"
  ${OrIf} $0 == "Error extracting from ZIP file"
  ${OrIf} $0 == "File not found in ZIP file"
    DetailPrint $(NSISUNZ_EXTRACTION_ERROR)
  ${Else}
    ${DoUntil} $0 == ""
      ${Unless} $0 == "success"
        FileWrite $INSTLOG "$0$\r$\n"
        DetailPrint $(NSISUNZ_EXTRACT)
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
    ReadINIStr $1 $MIRRORS_INI "description" $0
    ${DoUntil} $1 == ""
      ReadINIStr $1 $MIRRORS_INI "description" $0
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
    ReadINIStr $DISTFILES_URL $MIRRORS_INI "mirrors" $1
    ReadINIStr $0 $MIRRORS_INI "description" $1
  ${Else}
    ${For} $0 1 1000
      ReadINIStr $R1 $MIRRORS_INI "description" $0
      ${If} $R0 == $R1
        ReadINIStr $DISTFILES_URL $MIRRORS_INI "mirrors" $0
        ReadINIStr $0 $MIRRORS_INI "description" $0
        ${ExitFor}
      ${EndIf}
    ${Next}
  ${EndIf}

  DetailPrint "Using mirror: $0"
FunctionEnd

Function .createStartMenuItems
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"

    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER\Links"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\$(SHORT_NEWS).url" "InternetShortcut" "URL" "http://www.quakeworld.nu/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\$(SHORT_FORUM).url" "InternetShortcut" "URL" "http://www.quakeworld.nu/forum/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\$(SHORT_SERVERS).url" "InternetShortcut" "URL" "http://www.quakeservers.net/quakeworld/servers/pl=1/so=8/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\$(SHORT_DEMOS).url" "InternetShortcut" "URL" "http://www.challenge-tv.com/index.php?mode=demos&game=2"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\$(SHORT_GFX).url" "InternetShortcut" "URL" "http://gfx.qwdrama.com/"

    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\$(SHORT_EZQUAKE).lnk" "$INSTDIR\ezquake-gl.exe" "" "$INSTDIR\ezquake-gl.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\$(SHORT_UNINSTALL).lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    WriteRegStr HKLM "Software\nQuake" "StartMenu_Folder" $STARTMENU_FOLDER
FunctionEnd

Function .cleanupInstallation
  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\${INSTLOG}" w
    ${time::GetFileTime} "$INSTDIR\${INSTLOG}" $0 $1 $2
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

  # Ask to remove downloaded distfiles
  ${If} $DISTFILES_KEEP == 1
    Goto DistEnd
  ${EndIf}
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
  DistEnd:
FunctionEnd