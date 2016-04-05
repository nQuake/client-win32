nquake
======

nQuake for Windows

To compile an nQuake installer, follow these steps:

1) Download NSIS (http://nsis.sourceforge.net/) - version 2.46 or v3.0+ doesn't matter.
2) Copy/move the Plugins and Include folders to C:\Program Files (x86)\NSIS\.
3) * For NSIS v3.0+ you need to move the plugins (.dll files) to the "x86-ansi" subfolder of "Plugins".
3) Right-click the nquake-installer_source.nsi file and open with makensisw.exe.

Tips:
* Most of the code resides in nquake-installer_source.nsi but some code that is used often can be found in nquake-macros.nsh.
* Edit the contents of the installer pages in the .ini files and their functions in the installer source file (e.g. Function DOWNLOAD for the download page).

If you decide to fork nQuake into your own installer, I would love to get some credit, but since this is GPL I can't force you :)

-
2014-03-16
