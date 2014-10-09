; based on http://nsis.sourceforge.net/Add_uninstall_information_to_Add/Remove_Programs#Computing_EstimatedSize

!ifndef INSTALLATIONSIZE_INCLUDED
!define INSTALLATIONSIZE_INCLUDED

!include LogicLib.nsh

Function GetInstalledSize
  Push 0
  Push $0
  Push $1
  Push $2
  StrCpy $0 0
  ClearErrors
  ${ForEach} $1 0 256 + 1
    ${If} ${Errors}
      ${Break}
    ${EndIf}

    ${If} ${SectionIsSelected} $1
      SectionGetSize $1 $2
      IntOp $0 $0 + $2
    ${EndIf}
  ${Next}

  IntFmt $0 "0x%08X" $0

  Push $0
  Exch 4
  Pop $0

  Pop $2
  Pop $1
  Pop $0
FunctionEnd

!macro GetInstalledSize SIZE
  Call GetInstalledSize
  Pop ${SIZE}
!macroend

!define GetInstalledSize `!insertmacro GetInstalledSize`

!endif ; INSTALLATIONSIZE_INCLUDED
