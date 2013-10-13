!macro BackupOld FILE
  ${If} ${FileExists} "$INSTDIR\${FILE}"
    ${Unless} ${FileExists} "$INSTDIR\backup"
      CreateDirectory "$INSTDIR\backup"
    ${EndUnless}
    CopyFiles "$INSTDIR\${FILE}" "$INSTDIR\backup"
    Delete "$INSTDIR\${FILE}"
  ${EndIf}
!macroend

# Checks if a local distfile is older than a remote one
!macro CheckDistfileDate PACKAGE
  StrCpy $R1 0
  ReadINIStr $0 $DISTFILEDATES_INI "dates" ${PACKAGE}
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}"
    ${GetTime} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}" M $2 $3 $4 $5 $6 $7 $8
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R1 1
    ${Else}
      ReadINIStr $1 "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${DISTFILEDATES_INI}" "dates" ${PACKAGE}
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R1 1
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\${PACKAGE}"
    ${GetTime} "$DISTFILES_PATH\${PACKAGE}" M $2 $3 $4 $5 $6 $7 $8
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R1 2
    ${Else}
      ReadINIStr $1 "$DISTFILES_PATH\${DISTFILEDATES_INI}" "dates" ${PACKAGE}
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R1 2
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${EndIf}
!macroend

# Installs a section of fQuake
!macro InstallSection PACKAGE
  StrCpy $R0 ${PACKAGE}
  !insertmacro CheckDistfileDate ${PACKAGE}
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}"
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R1 == 0
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}" $INSTDIR
    ${ElseIf} $R1 == 1
      inetc::get /NOUNLOAD /TRANSLATE $(NSISDL_DOWNLOADING) $(NSISDL_CONNECTING) $(NSISDL_SECOND) $(NSISDL_MINUTE) $(NSISDL_HOUR) $(NSISDL_PLURAL) $(NSISDL_PROGRESS) $(NSISDL_REMAINING) "$DISTFILES_URL/${PACKAGE}" "$DISTFILES_PATH\${PACKAGE}" /END
      FileWrite $DISTLOG "${PACKAGE}$\r$\n"
      Pop $0
      ${Unless} $0 == "OK"
        ${If} $0 == "Cancelled"
          call .abortInstallation
        ${Else}
          DetailPrint $(NSISDL_DOWNLOAD_ERROR)
        ${EndIf}
      ${EndUnless}
      StrCpy $DISTFILES 1
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$DISTFILES_PATH\${PACKAGE}" $INSTDIR
    ${EndIf}
  ${ElseIf} ${FileExists} "$DISTFILES_PATH\${PACKAGE}"
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R1 == 0
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$DISTFILES_PATH\${PACKAGE}" $INSTDIR
    ${ElseIf} $R1 == 2
      inetc::get /NOUNLOAD /TRANSLATE $(NSISDL_DOWNLOADING) $(NSISDL_CONNECTING) $(NSISDL_SECOND) $(NSISDL_MINUTE) $(NSISDL_HOUR) $(NSISDL_PLURAL) $(NSISDL_PROGRESS) $(NSISDL_REMAINING) "$DISTFILES_URL/${PACKAGE}" "$DISTFILES_PATH\${PACKAGE}" /END
      FileWrite $DISTLOG "${PACKAGE}$\r$\n"
      Pop $0
      ${Unless} $0 == "OK"
        ${If} $0 == "Cancelled"
          call .abortInstallation
        ${Else}
          DetailPrint $(NSISDL_DOWNLOAD_ERROR)
        ${EndIf}
      ${EndUnless}
      StrCpy $DISTFILES 1
      DetailPrint $(NSISUNZ_EXTRACTING_FROM)
      nsisunz::UnzipToStack "$DISTFILES_PATH\${PACKAGE}" $INSTDIR
    ${EndIf}
  ${Else}
    inetc::get /NOUNLOAD /TRANSLATE $(NSISDL_DOWNLOADING) $(NSISDL_CONNECTING) $(NSISDL_SECOND) $(NSISDL_MINUTE) $(NSISDL_HOUR) $(NSISDL_PLURAL) $(NSISDL_PROGRESS) $(NSISDL_REMAINING) "$DISTFILES_URL/${PACKAGE}" "$DISTFILES_PATH\${PACKAGE}" /END
    FileWrite $DISTLOG "${PACKAGE}$\r$\n"
    Pop $0
    ${Unless} $0 == "OK"
      ${If} $0 == "Cancelled"
        call .abortInstallation
      ${Else}
        DetailPrint $(NSISDL_DOWNLOAD_ERROR)
      ${EndIf}
    ${EndUnless}
    StrCpy $DISTFILES 1
    DetailPrint $(NSISUNZ_EXTRACTING_FROM)
    nsisunz::UnzipToStack "$DISTFILES_PATH\${PACKAGE}" $INSTDIR
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
!macroend

!macro CreateBatchFile FILE PATH FLAGS
  FileOpen $0 "$INSTDIR\${PATH}${FILE}" w
  FileWrite $0 "${FLAGS}"
  FileWrite $INSTLOG "${PATH}${FILE}$\r$\n"
  FileClose $0
!macroend

!macro DetermineSectionSize PACKAGE
  ${If} ${FileExists} "$EXEDIR\${DISTFILES_PATH_RELATIVE}\${PACKAGE}"
    ${GetSize} "$EXEDIR\${DISTFILES_PATH_RELATIVE}" "/M=${PACKAGE} /S=0K /G=0" $7 $8 $9
    StrCpy $0 $7
  ${Else}
    ReadINIStr $0 $DISTFILES_INI "size" ${PACKAGE}
  ${EndIf}
  StrCpy $SIZE $0
!macroend