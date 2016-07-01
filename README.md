nquake
======

nQuake for Windows

To compile an nQuake installer, follow these steps:

1) Download NSIS (http://nsis.sourceforge.net/) - version 2.x or v3.0+ doesn't matter.<br>
2) Copy/move the folders in the `include` folder to `C:\Program Files (x86)\NSIS\`.<br>
_For NSIS v3.0+ you need to move the plugins (.dll files) to the "x86-ansi" subfolder of "Plugins"._<br>
3) Right-click the `nquake-installer_source.nsi` file and open with makensisw.exe.<br>

Tips:<br>
* Most of the code resides in `nquake-installer_source.nsi` but some code that is used often can be found in `nquake-macros.nsh`.<br>
* Edit the contents of the installer pages in the .ini files and their functions in the installer source file (e.g. Function DOWNLOAD for the download page).<br>

If you decide to fork nQuake into your own installer, I would love to get some credit, but since this is GPL I can't force you :)

-
2016-07-01
