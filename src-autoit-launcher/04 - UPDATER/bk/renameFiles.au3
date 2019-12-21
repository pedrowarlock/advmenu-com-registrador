#include <GUIConstantsEx.au3>
#include <File.au3>
#include <Array.au3>

Opt("MustDeclareVars", 1)

Global $sPathToFiles = "F:\SCRIPTS AUTOIT\ProjetArcade\UPDATER\instalação - Copia"
Global $newFileName = 1000
Global $aFilesToRename = ""


_Main()



Func _Main()
    _GetFileNamesToRename()

    _ArrayDisplay($aFilesToRename) ;Show me found files

    _RenameTheFiles()

	_GetFileNamesToRename()

    _ArrayDisplay($aFilesToRename)
EndFunc ;==> _Main()





Func _GetFileNamesToRename()
    Global $aFolder = _FileListToArrayRec($sPathToFiles, "*", $FLTAR_FOLDERS  ,$FLTAR_RECUR,0,$FLTAR_FULLPATH  )
    Global $aFiles = _FileListToArrayRec($sPathToFiles, "*", $FLTAR_FILES   ,$FLTAR_RECUR,0,$FLTAR_FULLPATH  )

    If $aFiles = 0 Then
        Select
            Case @error = 1
                Msgbox(48, "Error", "Path not found or invalid." & @CRLF & "Terminating script")
                Exit
            Case @error = 2
                Msgbox(48, "Error", "Invalid file filter. [$sFilter]." & @CRLF & "Terminating script")
                Exit
            Case @error = 3
                Msgbox(48, "Error", "Invalid Flag. [$iFlag]" & @CRLF & "Terminating script")
                Exit
            Case @error = 4
                Msgbox(48, "Error", "No File(s) Found" & @CRLF & "Terminating script")
                Exit
        EndSelect
    EndIf
EndFunc ;==> _GetFileNamesToRename()



Func _RenameTheFiles()

    ;Loop through file names to Rename
    For $i = 1 To $aFolder[0]

		DirMove($aFolder[$i],$aFolder[$i] & "_",$FC_OVERWRITE )

		DirMove($aFolder[$i] & "_", StringLower($aFolder[$i]),$FC_OVERWRITE )
	Next

 For $i = 1 To $aFiles[0]
		FileMove($aFiles[$i], $aFiles[$i] & "___", $FC_OVERWRITE )
		if @error then MsgBox("","","")
		FileMove($aFiles[$i] & "___", StringLower($aFiles[$i]), $FC_OVERWRITE )
Next

EndFunc ;==> _RenameTheFiles()