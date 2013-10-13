Function VersionConvert
	!define VersionConvert `!insertmacro VersionConvertCall`
 
	!macro VersionConvertCall _VERSION _CHARLIST _RESULT
		Push `${_VERSION}`
		Push `${_CHARLIST}`
		Call VersionConvert
		Pop ${_RESULT}
	!macroend
 
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
 
	StrCmp $1 '' 0 +2
	StrCpy $1 'abcdefghijklmnopqrstuvwxyz'
	StrCpy $1 $1 99
 
	StrCpy $2 0
	StrCpy $7 'dot'
	goto loop
 
	preloop:
	IntOp $2 $2 + 1
 
	loop:
	StrCpy $3 $0 1 $2
	StrCmp $3 '' endcheck
	StrCmp $3 '.' dot
	StrCmp $3 '0' digit
	IntCmp $3 '0' letter letter digit
 
	dot:
	StrCmp $7 'dot' replacespecial
	StrCpy $7 'dot'
	goto preloop
 
	digit:
	StrCmp $7 'letter' insertdot
	StrCpy $7 'digit'
	goto preloop
 
	letter:
	StrCpy $5 0
	StrCpy $4 $1 1 $5
	IntOp $5 $5 + 1
	StrCmp $4 '' replacespecial
	StrCmp $4 $3 0 -3
	IntCmp $5 9 0 0 +2
	StrCpy $5 '0$5'
 
	StrCmp $7 'letter' +2
	StrCmp $7 'dot' 0 +3
	StrCpy $6 ''
	goto +2
	StrCpy $6 '.'
 
	StrCpy $4 $0 $2
	IntOp $2 $2 + 1
	StrCpy $0 $0 '' $2
	StrCpy $0 '$4$6$5$0'
	StrLen $4 '$6$5'
	IntOp $2 $2 + $4
	IntOp $2 $2 - 1
	StrCpy $7 'letter'
	goto loop
 
	replacespecial:
	StrCmp $7 'dot' 0 +3
	StrCpy $6 ''
	goto +2
	StrCpy $6 '.'
 
	StrCpy $4 $0 $2
	IntOp $2 $2 + 1
	StrCpy $0 $0 '' $2
	StrCpy $0 '$4$6$0'
	StrLen $4 $6
	IntOp $2 $2 + $4
	IntOp $2 $2 - 1
	StrCpy $7 'dot'
	goto loop
 
	insertdot:
	StrCpy $4 $0 $2
	StrCpy $0 $0 '' $2
	StrCpy $0 '$4.$0'
	StrCpy $7 'dot'
	goto preloop
 
	endcheck:
	StrCpy $4 $0 1 -1
	StrCmp $4 '.' 0 end
	StrCpy $0 $0 -1
	goto -3
 
	end:
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd