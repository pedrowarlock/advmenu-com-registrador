#include <GUIConstantsEx.au3>
#include <GuiRichEdit.au3>
#include <WindowsConstants.au3>

Example()

Func Example()
    Local $hGui, $hRichEdit, $iMsg
    $hGui = GUICreate("Example (" & StringTrimRight(@ScriptName, StringLen(".exe")) & ")", 320, 350, -1, -1)
    $hRichEdit = _GUICtrlRichEdit_Create($hGui, "This is a test.", 10, 10, 300, 220, _
            BitOR($ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))
    GUISetState(@SW_SHOW)
    _GUICtrlRichEdit_AppendText($hRichEdit, @CRLF & "This is appended text.")

    While True
        $iMsg = GUIGetMsg()
        Select
            Case $iMsg = $GUI_EVENT_CLOSE
                _GUICtrlRichEdit_Destroy($hRichEdit) ; needed unless script crashes
                ; GUIDelete()   ; is OK too
                Exit
        EndSelect
    WEnd
EndFunc   ;==>Example
