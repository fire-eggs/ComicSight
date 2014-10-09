; based on http://nsis.sourceforge.net/File_Association
; and http://nsis.sourceforge.net/FileAssoc
; and http://stackoverflow.com/questions/11179945/wmi-programming-to-find-job-id#11182545

!ifndef FILEASSOC_INCLUDED
!define FILEASSOC_INCLUDED

;
; delete registry key only if it is completely empty, i.e. it has no
; sub-keys, no values and no (or an empty) default value
;
!macro DeleteRegKeyIfCompletelyEmpty ROOT_KEY SUB_KEY
  Push $0
  ReadRegStr $0 ${ROOT_KEY} `${SUB_KEY}` ""
  StrCmp $0 "" +1 +4
    EnumRegValue $0 ${ROOT_KEY} `${SUB_KEY}` 0
    StrCmp $0 "" +1 +2
      DeleteRegKey /IfEmpty ${ROOT_KEY} `${SUB_KEY}`
  Pop $0
!macroend

!define DeleteRegKeyIfCompletelyEmpty `!insertmacro DeleteRegKeyIfCompletelyEmpty`


;
; register file extension association
;
!macro _FileAssoc_RegisterExt EXT PROG_ID BACKUP_KEY
  !define Label_ Label_${__LINE__}_
  Push $0
  Push $1

  ; ${Label_}checkExisting:
  ReadRegStr $0 SHCTX `Software\Classes\${EXT}` ""
  StrCmp $0 "" ${Label_}registerExt
  StrCmp $0 `${PROG_ID}` ${Label_}done
  ClearErrors
  EnumRegKey $1 HKCR $0 0
  IfErrors ${Label_}registerExt

  ; ${Label_}backupToOpenWith:
  ClearErrors
  ReadRegStr $1 SHCTX `Software\Classes\${EXT}\OpenWithProgIds` $0
  IfErrors +1 +3
    WriteRegStr SHCTX `Software\Classes\${EXT}\OpenWithProgIds` $0 ""
    Goto +2
    StrCpy $1 "_"
  StrCmp `BACKUP_KEY` "" ${Label_}registerExt
  WriteRegStr SHCTX `${BACKUP_KEY}\${EXT}` "" $0
  StrCmp $1 "" +1 +2
    WriteRegStr SHCTX `${BACKUP_KEY}\${EXT}` "OpenWithProgIdCreated" ""
  
  ${Label_}registerExt:
  WriteRegStr SHCTX `Software\Classes\${EXT}` "" `${PROG_ID}`

  ${Label_}done:
  DeleteRegKey HKCU `Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\${EXT}\UserChoice`

  Pop $1
  Pop $0
  !undef Label_
!macroend

Function FileAssoc_RegisterExt
  Push $R0
  Push $R1
  Push $R2
  Exch 3
  Pop $R2
  Exch 3
  Pop $R1
  Exch 3
  Pop $R0
  !insertmacro _FileAssoc_RegisterExt "$R0" "$R1" "$R2"
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

!macro FileAssoc_RegisterExt EXT PROG_ID BACKUP_KEY
  Push ${EXT}
  Push ${PROG_ID}
  Push ${BACKUP_KEY}
  Call FileAssoc_RegisterExt
!macroend

!define FileAssoc_RegisterExt `!insertmacro FileAssoc_RegisterExt`


;
; register file extension "Open with" association
;
!macro _FileAssoc_RegisterExtOpenWith EXT PROG_ID BACKUP_KEY
  !define Label_ Label_${__LINE__}_
  Push $0
  Push $1

  ;${Label_}checkExisting:
  ReadRegStr $0 SHCTX `Software\Classes\${EXT}` ""
  StrCmp $0 "" ${Label_}registerExtOpenWith
  StrCmp $0 `${PROG_ID}` ${Label_}done
  ClearErrors
  EnumRegKey $1 HKCR $0 0
  IfErrors ${Label_}registerExtOpenWith

  ;${Label_}backup:
  StrCmp `BACKUP_KEY` "" ${Label_}registerExtOpenWith
  WriteRegStr SHCTX `${BACKUP_KEY}\${EXT}` "" $0
  
  ${Label_}registerExtOpenWith:
  WriteRegStr SHCTX `Software\Classes\${EXT}\OpenWithProgIds` `${PROG_ID}` ""

  ${Label_}done:
  Pop $1
  Pop $0
  !undef Label_
!macroend

Function FileAssoc_RegisterExtOpenWith
  Push $R0
  Push $R1
  Push $R2
  Exch 3
  Pop $R2
  Exch 3
  Pop $R1
  Exch 3
  Pop $R0
  !insertmacro _FileAssoc_RegisterExtOpenWith "$R0" "$R1" "$R2"
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

!macro FileAssoc_RegisterExtOpenWith EXT PROG_ID BACKUP_KEY
  Push ${EXT}
  Push ${PROG_ID}
  Push ${BACKUP_KEY}
  Call FileAssoc_RegisterExtOpenWith
!macroend

!define FileAssoc_RegisterExtOpenWith `!insertmacro FileAssoc_RegisterExtOpenWith`


;
; unregister file extension association (and "Open with" association)
;
!macro _FileAssoc_UnRegisterExt EXT PROG_ID BACKUP_KEY
  !define Label_ Label_${__LINE__}_
  Push $0
  Push $1

  ;${Label_}checkCurrent:
  StrCpy $0 ""
  ReadRegStr $1 SHCTX `Software\Classes\${EXT}` ""
  StrCmp $1 `${PROG_ID}` +1 ${Label_}unregisterOpenWith

  ;${Label_}findBackup:
  StrCmp `BACKUP_KEY` "" ${Label_}unregisterExt
  ReadRegStr $0 SHCTX `${BACKUP_KEY}\${EXT}` ""
  StrCmp $0 "" ${Label_}unregisterExt
  ClearErrors
  EnumRegKey $1 HKCR $0 0
  IfErrors ${Label_}unregisterExt
  WriteRegStr SHCTX `Software\Classes\${EXT}` "" $0
  Goto ${Label_}unregisterOpenWith

  ${Label_}unregisterExt:
  DeleteRegValue SHCTX `Software\Classes\${EXT}` ""

  ${Label_}unregisterOpenWith:
  DeleteRegValue SHCTX `Software\Classes\${EXT}\OpenWithProgIds` `${PROG_ID}`
  StrCmp $0 "" +5
    ClearErrors
    ReadRegStr $1 SHCTX `${BACKUP_KEY}\${EXT}` "OpenWithProgIdCreated"
    IfErrors +2
      DeleteRegValue SHCTX `Software\Classes\${EXT}\OpenWithProgIds` $0
  ${DeleteRegKeyIfCompletelyEmpty} SHCTX `Software\Classes\${EXT}\OpenWithProgIds`
  ${DeleteRegKeyIfCompletelyEmpty} SHCTX `Software\Classes\${EXT}`

  ;${Label_}done:
  DeleteRegKey SHCTX `${BACKUP_KEY}\${EXT}`
  Pop $1
  Pop $0
  !undef Label_
!macroend

Function FileAssoc_UnRegisterExt
  Push $R0
  Push $R1
  Push $R2
  Exch 3
  Pop $R2
  Exch 3
  Pop $R1
  Exch 3
  Pop $R0
  !insertmacro _FileAssoc_UnRegisterExt "$R0" "$R1" "$R2"
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

Function un.FileAssoc_UnRegisterExt
  Push $R0
  Push $R1
  Push $R2
  Exch 3
  Pop $R2
  Exch 3
  Pop $R1
  Exch 3
  Pop $R0
  !insertmacro _FileAssoc_UnRegisterExt "$R0" "$R1" "$R2"
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

!macro FileAssoc_UnRegisterExt EXT PROG_ID BACKUP_KEY
  Push ${EXT}
  Push ${PROG_ID}
  Push ${BACKUP_KEY}
  !ifdef __UNINSTALL__
    Call un.FileAssoc_UnRegisterExt
  !else
    Call FileAssoc_UnRegisterExt
  !endif
!macroend

!define FileAssoc_UnRegisterExt `!insertmacro FileAssoc_UnRegisterExt`


;
; register ProgID for file extension associations
;
!macro FileAssoc_RegisterProgID PROG_ID DESCRIPTION ICON COMMAND
  DeleteRegKey SHCTX `Software\Classes\${PROG_ID}`
  WriteRegStr SHCTX `Software\Classes\${PROG_ID}` "" `${DESCRIPTION}`
  WriteRegStr SHCTX `Software\Classes\${PROG_ID}\DefaultIcon` "" `${ICON}`
  WriteRegStr SHCTX `Software\Classes\${PROG_ID}\shell\open\command` "" `${COMMAND}`
!macroend

!define FileAssoc_RegisterProgID `!insertmacro FileAssoc_RegisterProgID`


;
; unregister ProgID for file extension associations
;
!macro FileAssoc_UnRegisterProgID PROG_ID
  DeleteRegKey SHCTX `Software\Classes\${PROG_ID}`
!macroend

!define FileAssoc_UnRegisterProgID `!insertmacro FileAssoc_UnRegisterProgID`


;
; notify the shell that file extension associations have changed
;
!ifdef SHCNE_ASSOCCHANGED
  !undef SHCNE_ASSOCCHANGED
!endif
!define SHCNE_ASSOCCHANGED 0x08000000

!ifdef SHCNF_FLUSH
  !undef SHCNF_FLUSH
!endif
!define SHCNF_FLUSH 0x1000

!macro FileAssoc_UpdateShell
  System::Call "shell32::SHChangeNotify(i,i,i,i) (${SHCNE_ASSOCCHANGED}, ${SHCNF_FLUSH}, 0, 0)"
!macroend

!define FileAssoc_UpdateShell `!insertmacro FileAssoc_UpdateShell`


;
; launch the Windows file extension association UI
; which is available starting with Windows Vista
;
!ifdef CLSCTX_INPROC_SERVER
  !undef CLSCTX_INPROC_SERVER
!endif
!define CLSCTX_INPROC_SERVER 0x1

!ifdef CLSID_ApplicationAssociationRegistrationUI
  !undef CLSID_ApplicationAssociationRegistrationUI
!endif
!define CLSID_ApplicationAssociationRegistrationUI {1968106d-f3b5-44cf-890e-116fcb9ecef1}

!ifdef IID_IApplicationAssociationRegistrationUI
  !undef IID_IApplicationAssociationRegistrationUI
!endif
!define IID_IApplicationAssociationRegistrationUI {1f76a169-f994-40ac-8fc8-0959e8874710}

!macro FileAssoc_LaunchAssociationUI REGISTERED_APPLICATION_NAME
  Push $0
  Push $1

  ; NSIS already called CoInitialize
  System::Call 'OLE32::CoCreateInstance(\
      g "${CLSID_ApplicationAssociationRegistrationUI}",\
      i 0,\
      i ${CLSCTX_INPROC_SERVER},\
      g "${IID_IApplicationAssociationRegistrationUI}",\
      *i.r1) i.r0'
  ; LPVOID ppv is now in $1 and HRESULT result is now in $0

  IntCmp $1 0 +3
    ; IApplicationAssociationRegistrationUI::LaunchAdvancedAssociationUI
    System::Call '$1->3(w "${REGISTERED_APPLICATION_NAME}") i.r0'
    ; IUnknown::Release
    System::Call '$1->2()'

  Pop $1
  Pop $0
!macroend

!define FileAssoc_LaunchAssociationUI `!insertmacro FileAssoc_LaunchAssociationUI`

!endif ; FILEASSOC_INCLUDED
