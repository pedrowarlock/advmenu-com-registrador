#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#NoTrayIcon

Exit
	Local $iARRAY_PRINCIPAL[0][2]
    Local $sAutoItDir = StringLeft(@AutoItExe, StringInStr(@AutoItExe, "\", Default, -1))
    If StringRight($sAutoItDir, 5) = "beta\" Then
        $sAutoItDir = StringTrimRight($sAutoItDir, 5)
    EndIf
    ConsoleWrite($sAutoItDir & @CRLF)

	Local $FFPEN  = FileSelectFolder("Select a folder to generate a update log","","",@ScriptDir)
	Local $aArray = _FileListToArrayRec($FFPEN, "*",  $FLTAR_FILES , $FLTAR_RECUR, $FLTAR_SORT)
	if @error then exit MsgBox(16,"Error!","Selecta a folder")

 ProgressOn("Progress Meter", "Increments every second", "0%", -1, -1, BitOR($DLG_NOTONTOP, $DLG_MOVEABLE))
 _ArrayAdd($iARRAY_PRINCIPAL, "[Launcher]" ,0)
For $i = 1 To UBound($aArray)-1

	_ArrayAdd($iARRAY_PRINCIPAL,  StringLower($aArray[$i]) & "|" & "0.0.0.1" ,0)
  ProgressSet($i / (UBound($aArray)- 1) * 100,$i & "/" & UBound($aArray)-1 & "%","....." )


Next
_ArrayDisplay($iARRAY_PRINCIPAL)
_FileWriteFromArray("UPDATER.txt",$iARRAY_PRINCIPAL)
ShellExecute("updater.txt","",@ScriptDir, $SHEX_EDIT )
Exit MsgBox("","DONE!","Updater.txt generated!")