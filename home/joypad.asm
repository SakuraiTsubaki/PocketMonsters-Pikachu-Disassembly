; Joypad dispatch. Japanese V1.0 uses the older call/return path.
Joypad::
IF DEF(_JAPAN) && DEF(_REV0)
	homecall_alt ReadJoypad_
	ret
ELSE
	homejp _Joypad

ReadJoypad::
	homejp ReadJoypad_
ENDC
