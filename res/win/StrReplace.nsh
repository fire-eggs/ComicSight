; based on http://nsis.sourceforge.net/Another_String_Replace_(and_Slash/BackSlash_Converter)

!ifndef STRREPLACE_INCLUDED
!define STRREPLACE_INCLUDED

Function StrReplace
  Exch $R4 ; $R4 = Replacement String
  Exch
  Exch $R3 ; $R3 = String to replace (needle)
  Exch 2
  Exch $R1 ; $R1 = String to do replacement in (haystack)
  Push $R2 ; Replaced haystack
  Push $R5 ; Len (needle)
  Push $R6 ; len (haystack)
  Push $R7 ; Scratch reg
  StrCpy $R2 ""
  StrLen $R5 $R3
  StrLen $R6 $R1
loop:
  StrCpy $R7 $R1 $R5
  StrCmp $R7 $R3 found
  StrCpy $R7 $R1 1 ; - optimization can be removed if U know len needle=1
  StrCpy $R2 "$R2$R7"
  StrCpy $R1 $R1 $R6 1
  StrCmp $R1 "" done loop
found:
  StrCpy $R2 "$R2$R4"
  StrCpy $R1 $R1 $R6 $R5
  StrCmp $R1 "" done loop
done:
  StrCpy $R3 $R2
  Pop $R7
  Pop $R6
  Pop $R5
  Pop $R2
  Pop $R1
  Pop $R4
  Exch $R3
FunctionEnd

!macro StrReplace OUTPUT INPUT MATCH REPLACEMENT
  Push "${INPUT}"
  Push "${MATCH}"
  Push "${REPLACEMENT}"
  Call StrReplace
  Pop ${OUTPUT}
!macroend
 
!define StrReplace '!insertmacro "StrReplace"'

!endif ; STRREPLACE_INCLUDED
