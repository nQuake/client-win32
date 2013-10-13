;nQuake NSIS Online Installer Script
;By Empezar 2007-05-31; Last modified 2007-07-03

!define VERSION "1.01"
!define SHORTVERSION "101"

Name "nQuake"
OutFile "nquake${SHORTVERSION}_installer.exe"
InstallDir "$PROGRAMFILES\nQuake"

!define INSTALLER_URL "http://nquake.sf.net" # Note: no trailing slash!
!define DISTFILES_PATH "C:\nquake-distfiles"
!define DISTFILES_PATH_RELATIVE "nquake-distfiles"

# Editing anything below this line is not recommended
;---------------------------------------------------

InstallDirRegKey HKLM "Software\$(^Name)" "Install_Dir"
!define INSTLOG "install.log"
!define DISTLOG "distfiles.log"
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
!include "VersionCheck.nsh"
!include "nQuakeMacros.nsh"

;----------------------------------------------------
;Initialize Variables

Var DISTFILES_URL
Var DISTFILES_PATH
Var DISTFILES_INI
Var DISTFILES_UPDATE
Var DISTFILEDATES_INI
Var INSTALLERVERSIONS_INI
Var MIRRORS_INI
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

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_FINISHPAGE_NOREBOOTSUPPORT

;----------------------------------------------------
;Pages

!define MUI_WELCOMEPAGE_TITLE $(WELCOMEPAGE_TITLE)
!define MUI_WELCOMEPAGE_TEXT $(WELCOMEPAGE_TEXT)
!insertmacro MUI_PAGE_WELCOME

LicenseForceSelection checkbox $(LICENSEPAGE_CHECKBOX)
!insertmacro MUI_PAGE_LICENSE "license.txt"

!insertmacro MUI_PAGE_COMPONENTS

Page custom PREFERENCESPAGE

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

!insertmacro MUI_UNPAGE_INSTFILES

;----------------------------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"
!include "nquake-lang-english.nsi"

;----------------------------------------------------
;Reserve Files

ReserveFile "iopreferences.ini"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;----------------------------------------------------
;Installation Types

InstType $(INSTTYPE_RECOMMENDED)
InstType $(INSTTYPE_FULL)
InstType $(INSTTYPE_MINIMUM)

;----------------------------------------------------
;Installer Sections

Section "" # Prepare installation

  SetOutPath $INSTDIR

  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_PATH "iopreferences.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_UPDATE "iopreferences.ini" "Field 6" "State"

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

Section !$(NQUAKE) NQUAKE

  SectionIn 1 2 3 RO

  # Download and install Quake Shareware
  ${Unless} ${FileExists} "$INSTDIR\ID1\PAK0.PAK"
    !insertmacro InstallSection qsw106.zip
    FileClose $INSTLOG
    FileOpen $INSTLOG $INSTLOGTMP w
  ${EndUnless}
  Rename "$INSTDIR\ID1" "$INSTDIR\id1"
  Rename "$INSTDIR\id1\PAK0.PAK" "$INSTDIR\id1\pak0.pak"
  FileWrite $INSTLOG "id1\pak0.pak$\r$\n"
  # Remove crap files from Quake directory
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
  ${locate::RMDirEmpty} "$INSTDIR" /M=*.* $0

  # Install nQuake base package
  !insertmacro InstallSection nquake.zip
  !insertmacro InstallSection ezquake.zip

SectionEnd

Section !$(EYECANDY) EYECANDY

  SectionIn 1 2

  !insertmacro InstallSection eyecandy.zip

SectionEnd

Section !$(FROGBOT) FROGBOT

  SectionIn 1 2

  !insertmacro InstallSection frogbot.zip

SectionEnd

Section $(MAPS) MAPS

  SectionIn 2

  !insertmacro InstallSection maps.zip

SectionEnd

Section $(DEMOS) DEMOS

  SectionIn 2

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
  WriteRegStr HKLM "Software\$(^Name)" "Install_Dir" $INSTDIR
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "DisplayName" "$(^Name)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "Publisher" "The nQuake Team"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "URLUpdateInfo" "http://sourceforge.net/project/showfiles.php?group_id=197706"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "URLInfoAbout" "http://nquake.sourceforge.net/"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "HelpLink" "http://sourceforge.net/forum/forum.php?forum_id=702198"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "NoModify" "1"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" "NoRepair" "1"

  WriteUninstaller "uninstall.exe"

SectionEnd

;----------------------------------------------------
;Uninstaller Section

Section "Uninstall"

  SetOutPath $TEMP

  # Set uninstallation progress bar to 0%
  RealProgress::SetProgress /NOUNLOAD 0

  # If install.log exists, remove all files listed
  ${If} ${FileExists} "$INSTDIR\${INSTLOG}"
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
    Delete /REBOOTOK "$INSTDIR\uninstall.exe"
    ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
    DetailPrint $(REMOVED_EMPTY_DIRECTORIES)
    RMDir /REBOOTOK $INSTDIR
  ${Else}
    MessageBox MB_YESNO|MB_ICONEXCLAMATION $(UNINSTALL_CONFIRMATION) IDNO SkipUninstall
    RMDir /r /REBOOTOK $INSTDIR
  ${EndIf}

  ReadRegStr $0 HKLM "Software\$(^Name)" "StartMenu_Folder"
  RMDir /r /REBOOTOK "$SMPROGRAMS\$0"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)"
  DeleteRegKey HKLM "Software\$(^Name)"

  Goto FinishUninstall

  SkipUninstall:
    Abort

  FinishUninstall:

SectionEnd

;----------------------------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${NQUAKE} $(DESC_NQUAKE)
  !insertmacro MUI_DESCRIPTION_TEXT ${FROGBOT} $(DESC_FROGBOT)
  !insertmacro MUI_DESCRIPTION_TEXT ${EYECANDY} $(DESC_EYECANDY)
  !insertmacro MUI_DESCRIPTION_TEXT ${MAPS} $(DESC_MAPS)
  !insertmacro MUI_DESCRIPTION_TEXT ${DEMOS} $(DESC_DEMOS)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;----------------------------------------------------
;Functions

Function .onInit

  # Download installerversions.ini and prompt the user if there are newer installer versions available
  GetTempFileName $INSTALLERVERSIONS_INI
  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading version information (1/4)..." /TIMEOUT=7000 "${INSTALLER_URL}/${INSTALLERVERSIONS_INI_REMOTE}" $INSTALLERVERSIONS_INI /END
  ReadINIStr $0 $INSTALLERVERSIONS_INI "versions" "windows"
  ${VersionCheck} ${VERSION} $0 $1
  ${If} $1 == 2
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "A newer version of nQuake is available.$\r$\n$\r$\nDo you wish to be taken to the download page?" IDNO ContinueInstall
    ExecShell "open" ${INSTALLER_URL}
    Abort
  ${EndIf}
  ContinueInstall:

  # Download mirrors.ini
  ${Unless} ${FileExists} "$EXEDIR\${MIRRORS_INI}"
    GetTempFileName $MIRRORS_INI
    inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading mirror information (2/4)..." "${INSTALLER_URL}/${MIRRORS_INI_REMOTE}" $MIRRORS_INI /END
    Pop $0
    ${Unless} $0 == "OK"
      MessageBox MB_OK|MB_ICONEXCLAMATION "Setup could not download mirrors.ini, please try again later."
      Abort
    ${EndUnless}
  ${Else}
    StrCpy $MIRRORS_INI "$EXEDIR\${MIRRORS_INI}"
  ${EndUnless}

  # Download distfiles.ini
  ${Unless} ${FileExists} "$EXEDIR\${DISTFILES_INI}"
    GetTempFileName $DISTFILES_INI
    # Download distfiles.ini from the first mirror if mirrors.ini exists in the installer directory
    ${If} ${FileExists} "$EXEDIR\${MIRRORS_INI}"
      ReadINIStr $0 "$EXEDIR\${MIRRORS_INI}" "mirrors" 1
      inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading file size information (2/4)..." "$0/${DISTFILES_INI_REMOTE}" $DISTFILES_INI /END
      Pop $0
      ${Unless} $0 == "OK"
        inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading file size information (3/4)..." "${INSTALLER_URL}/${DISTFILES_INI_REMOTE}" $DISTFILES_INI /END
        Pop $0
        ${Unless} $0 == "OK"
          MessageBox MB_OK|MB_ICONEXCLAMATION "Setup could not download distfiles.ini, please try again later."
        ${EndUnless}
      ${EndUnless}
    ${Else}
      inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading file size information (3/4)..." "${INSTALLER_URL}/${DISTFILES_INI_REMOTE}" $DISTFILES_INI /END
      Pop $0
      ${Unless} $0 == "OK"
        MessageBox MB_OK|MB_ICONEXCLAMATION "Setup could not download distfiles.ini, please try again later."
      ${EndUnless}
    ${EndIf}
  ${Else}
    StrCpy $DISTFILES_INI "$EXEDIR\${DISTFILES_INI}"
  ${EndUnless}

  # Download distfiledates.ini
  GetTempFileName $DISTFILEDATES_INI
  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake is initializing, please wait...$\r$\n$\r$\nDownloading file date information (4/4)..." /TIMEOUT=7000 "${INSTALLER_URL}/${DISTFILEDATES_INI_REMOTE}" $DISTFILEDATES_INI /END

  # Determine sizes on all the sections
  !insertmacro DetermineSectionSize qsw106.zip
  StrCpy $6 $SIZE
  !insertmacro DetermineSectionSize nquake.zip
  StrCpy $7 $SIZE
  IntOp $8 $6 + $7
  !insertmacro DetermineSectionSize ezquake.zip
  StrCpy $6 $SIZE
  IntOp $9 $8 + $6
  SectionSetSize ${NQUAKE} $9

  !insertmacro DetermineSectionSize eyecandy.zip
  SectionSetSize ${EYECANDY} $SIZE

  !insertmacro DetermineSectionSize frogbot.zip
  SectionSetSize ${FROGBOT} $SIZE

  !insertmacro DetermineSectionSize maps.zip
  SectionSetSize ${MAPS} $SIZE

  !insertmacro DetermineSectionSize demos.zip
  SectionSetSize ${DEMOS} $SIZE

  #!insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd

Function un.onInit

  #!insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd

Function PREFERENCESPAGE

  # Create the Preferences page
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "iopreferences.ini"

  ReadINIStr $0 $MIRRORS_INI "description" 1
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 3" "State" $(PREFERENCESPAGE_RANDOM_MIRROR)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 5" "State" ${DISTFILES_PATH}

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

  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 3" "ListItems" $2

  # Translate the Preferences page
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 1" "Text" $(PREFERENCESPAGE_PREFERENCES_TITLE)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 2" "Text" $(PREFERENCESPAGE_MIRROR_TEXT)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 4" "Text" $(PREFERENCESPAGE_DOWNLOAD_TEXT)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 6" "Text" $(PREFERENCESPAGE_UPDATE_DISTFILES)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 7" "Text" $(PREFERENCESPAGE_PURCHASE_TITLE)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 8" "Text" $(PREFERENCESPAGE_FULLVERSION_TEXT)
  !insertmacro MUI_INSTALLOPTIONS_WRITE "iopreferences.ini" "Field 9" "Text" $(PREFERENCESPAGE_BUYCD_TEXT)
  !insertmacro MUI_HEADER_TEXT $(PREFERENCESPAGE_HEADER) $(PREFERENCESPAGE_SUBHEADER)

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "iopreferences.ini"

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

  # Write distfiles.log
  FileOpen $DISTLOG "$DISTFILES_PATH\${DISTLOG}" w
    FileOpen $R0 $DISTLOGTMP r
    ClearErrors
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      FileWrite $DISTLOG $0
    ${LoopUntil} ${Errors}
    FileClose $R0
  FileClose $DISTLOG

  # If install.log exists, ask to remove installed files
  ${If} ${FileExists} "$INSTDIR\${INSTLOG}"
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
  ${EndIf}

  # If distfiles.log exists, ask to remove downloaded distfiles
  ${If} ${FileExists} "$DISTFILES_PATH\${DISTLOG}"
    Messagebox MB_YESNO|MB_ICONEXCLAMATION $(ABORT_REMOVE_DISTFILES) IDNO SkipDistRemoval
    # Get line count for distfiles.log
    Push "$DISTFILES_PATH\${DISTLOG}"
    Call .LineCount
    Pop $R1 # Line count
    FileOpen $R0 "$DISTFILES_PATH\${DISTLOG}" r
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
    Delete /REBOOTOK "$DISTFILES_PATH\${DISTLOG}"
    RMDir /REBOOTOK $DISTFILES_PATH
    Goto DistEnd
    SkipDistRemoval:
    Delete /REBOOTOK "$DISTFILES_PATH\${DISTLOG}"
    DistEnd:
  ${EndIf}

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
  !insertmacro MUI_INSTALLOPTIONS_READ $R0 "iopreferences.ini" "Field 3" "State"
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

    WriteRegStr HKLM "Software\$(^Name)" "StartMenu_Folder" $STARTMENU_FOLDER
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

  # Write distfiles.log
  FileOpen $DISTLOG "$DISTFILES_PATH\${DISTLOG}" w
    FileOpen $R0 $DISTLOGTMP r
    ClearErrors
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      FileWrite $DISTLOG $0
    ${LoopUntil} ${Errors}
    FileClose $R0
    # Copy the downloaded distfiledates.ini to the distfiles directory
    # IF the installer was set to update old distfiles
    ${If} $DISTFILES_UPDATE == 1
      CopyFiles $DISTFILEDATES_INI "$DISTFILES_PATH\${DISTFILEDATES_INI}"
      FileWrite $DISTLOG "${DISTFILEDATES_INI}$\r$\n"
    ${EndIf}
  FileClose $DISTLOG

  # If distfiles.log exists, ask to remove downloaded distfiles
  ${If} ${FileExists} "$DISTFILES_PATH\${DISTLOG}"
    Messagebox MB_YESNO|MB_ICONEXCLAMATION $(REMOVE_DISTFILES) IDNO SkipRemoval
    # Get line count for distfiles.log
    Push "$DISTFILES_PATH\${DISTLOG}"
    Call .LineCount
    Pop $R1 # Line count
    FileOpen $R0 "$DISTFILES_PATH\${DISTLOG}" r
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
    Delete /REBOOTOK "$DISTFILES_PATH\${DISTLOG}"
    RMDir /REBOOTOK $DISTFILES_PATH
    Goto DistEnd
    SkipRemoval:
    Delete /REBOOTOK "$DISTFILES_PATH\${DISTLOG}"
    DistEnd:
  ${EndIf}
FunctionEnd