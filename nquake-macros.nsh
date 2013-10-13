# Backups a file to the backup folder
!macro BackupOld FILE
  Push 0
  ${If} ${FileExists} "$INSTDIR\${FILE}"
    ${Unless} ${FileExists} "$INSTDIR\backup"
      CreateDirectory "$INSTDIR\backup"
    ${EndUnless}
    CopyFiles "$INSTDIR\${FILE}" "$INSTDIR\backup"
    Delete "$INSTDIR\${FILE}"
    Pop $R9
    Push 1
  ${EndIf}
!macroend

# Checks if a local distfile is older than a remote one
!macro CheckDistfileDate PACKAGE
  Push ${PACKAGE}
  Call .checkDistfileDate
!macroend

# Downloads and extracts an fQuake distfile
!macro InstallDistfile PACKAGE
  Push ${PACKAGE}
  Call .installDistfile
!macroEnd

# Installs a section of fQuake
!macro InstallSection PACKAGE
  Push ${PACKAGE}
  Call .installSection
!macroend

# Creates a batch file
!macro CreateBatchFile FILE PATH FLAGS
  FileOpen $0 "$INSTDIR\${PATH}${FILE}" w
  FileWrite $0 "${FLAGS}"
  FileWrite $INSTLOG "${PATH}${FILE}$\r$\n"
  FileClose $0
!macroend

# Determines the size of an fQuake section
!macro DetermineSectionSize PACKAGE
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}"
    ${GetSize} "$EXEDIR\${DISTFILES_PATH_RELATIVE}" "/M=${PACKAGE} /S=0K /G=0" $7 $8 $9
    StrCpy $0 $7
  ${Else}
    ReadINIStr $0 $DISTFILES_INI "size" ${PACKAGE}
  ${EndIf}
  StrCpy $SIZE $0
!macroend