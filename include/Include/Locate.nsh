!define locate::Open `!insertmacro locate::Open`

!macro locate::Open _PATH _OPTIONS _ERR
	locate::_Open /NOUNLOAD `${_PATH}` `${_OPTIONS}`
	Pop ${_ERR}
!macroend


!define locate::Find `!insertmacro locate::Find`

!macro locate::Find _PATH_NAME _PATH _NAME _SIZE _TIME _ATTRIB
	locate::_Find /NOUNLOAD
	Pop ${_PATH_NAME}
	Pop ${_PATH}
	Pop ${_NAME}
	Pop ${_SIZE}
	Pop ${_TIME}
	Pop ${_ATTRIB}
!macroend


!define locate::Close `!insertmacro locate::Close`

!macro locate::Close
	locate::_Close /NOUNLOAD
!macroend


!define locate::GetSize `!insertmacro locate::GetSize`

!macro locate::GetSize _PATH _OPTIONS _SIZE _FILES _DIRS
	locate::_GetSize /NOUNLOAD `${_PATH}` `${_OPTIONS}`
	Pop ${_SIZE}
	Pop ${_FILES}
	Pop ${_DIRS}
!macroend


!define locate::RMDirEmpty `!insertmacro locate::RMDirEmpty`

!macro locate::RMDirEmpty _PATH _OPTIONS _REMOVED
	locate::_RMDirEmpty /NOUNLOAD `${_PATH}` `${_OPTIONS}`
	Pop ${_REMOVED}
!macroend


!define locate::Unload `!insertmacro locate::Unload`

!macro locate::Unload
	locate::_Unload
!macroend
