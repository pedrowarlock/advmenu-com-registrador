#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\icons\joystick.ico
#AutoIt3Wrapper_Outfile=..\..\..\ATTRACT_PROJETOS\ATTRACKT1\ConfigurarControle.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ComboConstants.au3>
#include <FontConstants.au3>
#include <Misc.au3>

#include"..\includes\AuConstantes.au3"
#include "..\includes\encrypt.au3"
#include"..\includes\auJoystick.au3"
#include"..\includes\auSDL.au3"

Opt("MustDeclareVars",1)


If _Singleton("Configurar Joystick", 1) = 0 Then
   _CALL_WRITE_LOG("(ERRO) - Programa já em execução")
   Exit
EndIf

;-----------------------------------------------------------------------------------
;Checar encipitação

if Not _CRYPT_CHECK_SAVE_KEY($O__GetSerial, $O__UserKey2, $O__ENCRYPTKEY2,$i__Obs2) Then
	if Not _REGISTRO_GUI($O__UserKey1, $O__UserKey2, $O__ENCRYPTKEY1, $O__ENCRYPTKEY2,$i__Obs1,$i__Obs2) Then
		_CALL_WRITE_LOG("Sistema não registrado")
		Exit
	EndIf
EndIf

; #FUNCTION# ====================================================================================================================
; Name ..........: _INTARNAL_TEST_JOYSTICK
; Description ...:
; Syntax ........: _INTARNAL_TEST_JOYSTICK()
; Parameters ....: None
; Return values .: None
; Author ........: Pedro Warlock
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
_INTARNAL_TEST_JOYSTICK()
Func _INTARNAL_TEST_JOYSTICK($indexJoy=0)

;Inicia os Joysticks
_JOY_START($__DIR_SDL)
if @error Or Not FileExists($__DIR_SDL) then
	_CALL_WRITE_LOG("SDL1.dll não foi encontrada no diretorio do sistema")
	Return
EndIf

Global $TIMER,$TIMER2,$SETA,$SAVE_COUNT,$LABEL_NUMB_A[9],$LABEL_NUMB_B[9],$PIC_IMG[9],$BT_SAVE_JOY[10][2]
Global $JOYSTK[3] 	 	= [_JOY_OPEN($___JOY_1), _JOY_OPEN($___JOY_2), _JOY_OPEN($___JOY_3)]
Global $looping	  	  	= 1
Global $font	  	  	= "Arial"
Global $RETTICK_SETA 	= _TICK_UPDATE()
Global $RETTICK_TIMER	= _TICK_UPDATE()
Global $ETAPA 			= 1


FileInstall("..\img\test_joysticks\red_normal.png",   @TempDir & "/~tag1a",1)
FileInstall("..\img\test_joysticks\green_normal.png", @TempDir & "/~tag1b",1)
FileInstall("..\img\test_joysticks\disable.png",      @TempDir & "/~tag1c",1)

FileInstall("..\img\test_joysticks\background.png", @TempDir & "/~tag1e",1)
FileInstall("..\img\test_joysticks\seta.png",        @TempDir & "/~tag1g",1)

if @Compiled Then
	Global $imagem_botao_vermelho = @TempDir & "/~tag1a"
	Global $imagem_botao_verde	  = @TempDir & "/~tag1b"
	Global $imagem_botao_disable  = @TempDir & "/~tag1c"

	Global $imagem_background_gui = @TempDir & "/~tag1e"
	Global $imagem_seta			  = @TempDir & "/~tag1g"
Else
	Global $imagem_botao_vermelho = "..\img\test_joysticks\red_normal.png"
	Global $imagem_botao_verde	  = "..\img\test_joysticks\green_normal.png"
	Global $imagem_botao_disable  = "..\img\test_joysticks\disable.png"
	Global $imagem_background_gui = "..\img\test_joysticks\background.png"
	Global $imagem_seta			  = "..\img\test_joysticks\seta.png"
EndIf

;=========================================>
;GUI PRINCIPAL
;=========================================>
Local $GUI_PRINCIPAL=GUICreate("", 739,414, -1, -1, $WS_POPUP,BitOR($WS_EX_COMPOSITED,$WS_EX_TOPMOST,$WS_EX_TOOLWINDOW))
If @error Then
	MostraMensa(@LF & "Não foi possivel cria a interface", 10000)
	Return
EndIf
GUISetBkColor(0xAAAAAA)
;--------------------------------------------------------------------------------------------------------------------------



_CREATE_LABEL()


;--------------------------------------------------------------------------------------------------------------------------
;DUMMY
GUICtrlCreateButton("", 1, 1, 1, 1,BitOR($GUI_HIDE,$GUI_DISABLE))
;BACKGROUND
_GUICtrlPic_Create($imagem_background_gui,0,0,739,414)
GUICtrlSetState (-1, $GUI_DISABLE)
;--------------------------------------------------------------------------------------------------------------------------
GUISetState (@SW_SHOW,$GUI_PRINCIPAL)
Local $aPos = WinGetPos($GUI_PRINCIPAL)
Global $g_iWidth = $aPos[2]
Global $g_iHeight = $aPos[3]
Local $hRgn = _WinAPI_CreateRoundRectRgn(0, 0, $g_iWidth, $g_iHeight, 78, 78)
        _WinAPI_SetWindowRgn($GUI_PRINCIPAL, $hRgn)
;------------------------------------------------------------------------------------
While $looping
	_JOY_UPDATE($JOYSTK)

        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
		EndSwitch

	Switch $ETAPA
		Case 1
			ControlMove($GUI_PRINCIPAL,"",$SETA,510,75)
		Case 2
			ControlMove($GUI_PRINCIPAL,"",$SETA,510,145)
		Case 3
			ControlMove($GUI_PRINCIPAL,"",$SETA,435,215)
		Case 4
			ControlMove($GUI_PRINCIPAL,"",$SETA,585,215)
		Case 5
			ControlMove($GUI_PRINCIPAL,"",$SETA,435,290)
		Case 6
			ControlMove($GUI_PRINCIPAL,"",$SETA,585,290)
		Case 7
			ControlMove($GUI_PRINCIPAL,"",$SETA,435,360)
		Case 8
			ControlMove($GUI_PRINCIPAL,"",$SETA,585,360)
		Case 9
			GUICtrlSetState($SETA,$GUI_HIDE)
			_SALVAR()
			ExitLoop
	EndSwitch

	if $ETAPA <= 8 Then
		;SALVA O BOTÃO PRESSIONADO
		For $i = 0 To _JOY_GET_NUMBER()-1
			For $k = 0 To _JOY_GET_NUMBER_BUTTONS($JOYSTK[$i])
				if _JOY_GET_BUTTON($JOYSTK[$i],$k) then
					$BT_SAVE_JOY[$ETAPA][0] = $i+1
					$BT_SAVE_JOY[$ETAPA][1] = $k+1
					GUICtrlSetData($LABEL_NUMB_A[$ETAPA],"CONTROLE " & $i+1 & @CRLF & "Botão " & $k+1)
					GUICtrlSetData($LABEL_NUMB_B[$ETAPA],"CONTROLE " & $i+1 & @CRLF & "Botão " & $k+1)
					_GUICtrlPic_SetPic($PIC_IMG[$ETAPA],$imagem_botao_verde)
					$RETTICK_TIMER = _TICK_UPDATE()
					GUICtrlSetColor($TIMER,0xF0F0E1)
					$ETAPA += 1
					Sleep(1000)
				EndIf
			Next
		Next

		;CASO O TIMER CHEGUE A ZERO, SALVAR O BOTÃO COMO "NÃO CONFIGURADO"
		if int((_TICK_UPDATE() - $RETTICK_TIMER)/1000) >= 20 Then
			$RETTICK_TIMER = _TICK_UPDATE()
;~ 			$BT_SAVE_JOY[$ETAPA][0] = 100
;~ 			$BT_SAVE_JOY[$ETAPA][1] = 100
			GUICtrlSetData($LABEL_NUMB_A[$ETAPA],"Não configurado")
			GUICtrlSetData($LABEL_NUMB_B[$ETAPA],"Não configurado")
			_GUICtrlPic_SetPic($PIC_IMG[$ETAPA],$imagem_botao_vermelho)
			GUICtrlSetColor($TIMER,0xF0F0E1)
			$ETAPA += 1
;~ 			Sleep(500)
		Elseif int((_TICK_UPDATE() - $RETTICK_TIMER)/1000) = 15 Then
			GUICtrlSetColor($TIMER,0xFF0000)
		EndIf

		;COLOCA OS VALORES DO TIMER
		Local $COUNT = int(StringTrimLeft(_TICK_UPDATE() - $RETTICK_TIMER - 21000,1)/1000)
		if $COUNT <> $SAVE_COUNT Then
			GUICtrlSetData($TIMER, StringFormat("%02d", $COUNT))
			GUICtrlSetData($TIMER2,StringFormat("%02d", $COUNT))
			$SAVE_COUNT = $COUNT
		EndIf

		;PISCA A SETA
		If _TICK_UPDATE() - $RETTICK_SETA >= 300 and _TICK_UPDATE() - $RETTICK_SETA <= 400 Then
			GUICtrlSetState($SETA,$GUI_HIDE)
		ElseIf _TICK_UPDATE() - $RETTICK_SETA >= 600 Then
			GUICtrlSetState($SETA,$GUI_show)
			$RETTICK_SETA = _TICK_UPDATE()
		EndIf
	EndIf
	Sleep(70)
Wend
GUIDelete($GUI_PRINCIPAL)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SALVAR
; Description ...:
; Syntax ........: _SALVAR()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SALVAR()

	Local $iFileRead 	 = _CONST_ADVMENU_RC()
	Local $iFileRead_ini = _CONST_ADVMENU_INI()
	;------------------------------------------------------------------------------------------------------------------------------
	;BOTÃO COIN
	if $BT_SAVE_JOY[1][0] <> "" then
		_ESCREVER_TECLAS($iFileRead, "custom2", "Joy" & $BT_SAVE_JOY[1][0]-1 & " Button" & $BT_SAVE_JOY[1][1]-1,True)
		_ESCREVER_TECLAS($iFileRead, "custom2", "Numpad7",False)

		IniWrite($iFileRead_ini, "CONTROLES", "ADICIONAR_FICHA", "Joy_" & $BT_SAVE_JOY[1][0]-1 & " Button_" & $BT_SAVE_JOY[1][1]-1)
	EndIf

	;------------------------------------------------------------------------------------------------------------------------------
	;SALVA O BOTÃO COMANDO
	if $BT_SAVE_JOY[2][0] <> "" then
		_ESCREVER_TECLAS($iFileRead, "configure", "Joy" & $BT_SAVE_JOY[2][0]-1 & " Button" & $BT_SAVE_JOY[2][1]-1,True)
		_ESCREVER_TECLAS($iFileRead, "configure", "Tab",False)
	EndIf
	;------------------------------------------------------------------------------------------------------------------------------
	;VOLTA EMULADOR
	if $BT_SAVE_JOY[7][0] <> "" then
		Local $BT_JOY1 = ""
		If $BT_SAVE_JOY[7][0] <> "" Then $BT_JOY1= "Joy" & $BT_SAVE_JOY[7][0]-1 & " Button" & $BT_SAVE_JOY[7][1]-1
		_ESCREVER_TECLAS($iFileRead, "next_display", $BT_JOY1,True)
		_ESCREVER_TECLAS($iFileRead, "next_display", "F6",False)
	EndIf
	;------------------------------------------------------------------------------------------------------------------------------
	;AVANÇA EMULADOR
	if $BT_SAVE_JOY[8][0] <> "" then
		Local $BT_JOY2 = ""

		If $BT_SAVE_JOY[8][0] <> "" Then $BT_JOY2= "Joy" & $BT_SAVE_JOY[8][0]-1 & " Button" & $BT_SAVE_JOY[8][1]-1
		_ESCREVER_TECLAS($iFileRead, "prev_display", $BT_JOY2,True)
		_ESCREVER_TECLAS($iFileRead, "prev_display", "F7",False)
	EndIf
	;------------------------------------------------------------------------------------------------------------------------------
	;SAIR DO JOGO

	;SALVA O BOTÃO (VOLTAR MENU SYSTEM)
	if $BT_SAVE_JOY[3][0] <> "" Or $BT_SAVE_JOY[4][0] <> "" then
		Local $BT_JOY1 = "",$BT_JOY2 = ""

		If $BT_SAVE_JOY[3][0] <> "" Then $BT_JOY1= "Joy" & $BT_SAVE_JOY[3][0]-1 & " Button" & $BT_SAVE_JOY[3][1]-1
		If $BT_SAVE_JOY[4][0] <> "" Then $BT_JOY2= "Joy" & $BT_SAVE_JOY[4][0]-1 & " Button" & $BT_SAVE_JOY[4][1]-1

		_ESCREVER_TECLAS($iFileRead, "custom1", $BT_JOY1,True)
		_ESCREVER_TECLAS($iFileRead, "custom1", $BT_JOY2,False)
		_ESCREVER_TECLAS($iFileRead, "custom1", "Numpad8",False)
		_ESCREVER_TECLAS($iFileRead, "custom1", "Numpad9",False)

		Local $iBT1 = "",$iBT2 = ""
		If $BT_SAVE_JOY[3][0] <> "" Then $iBT1 = " Joy_" & $BT_SAVE_JOY[3][0]-1 & " Button_" & $BT_SAVE_JOY[3][1]-1
		If $BT_SAVE_JOY[4][0] <> "" Then $iBT2 = " Joy_" & $BT_SAVE_JOY[4][0]-1 & " Button_" & $BT_SAVE_JOY[4][1]-1
		IniWrite($iFileRead_ini, "CONTROLES", "SAIR_DO_JOGO", $iBT1 & $iBT2)
	EndIf
	;------------------------------------------------------------------------------------------------------------------------------
	;TRANSFERIR A FICHA
	if $BT_SAVE_JOY[5][0] <> "" Or $BT_SAVE_JOY[6][0] <> "" then
		Local $iBT1 = "",$iBT2 = ""
		If $BT_SAVE_JOY[5][0] <> "" Then $iBT1 = " Joy_" & $BT_SAVE_JOY[5][0]-1 & " Button_" & $BT_SAVE_JOY[5][1]-1
		If $BT_SAVE_JOY[6][0] <> "" Then $iBT2 = " Joy_" & $BT_SAVE_JOY[6][0]-1 & " Button_" & $BT_SAVE_JOY[6][1]-1
		IniWrite($iFileRead_ini, "CONTROLES", "TRANSFERIR_FICHA", $iBT1 & $iBT2)
	EndIf

		_DELETE_BLANK_LINES($iFileRead)

EndFunc


func _ESCREVER_TECLAS($iFile, $iFindLine, $iBt, $iDeleteLine)

	Local $Linha = 1, $Chars = "", $Search
	Local $File = FileOpen($iFile, 0)
	If @error Then Return SetError(-1)
	if $BT_SAVE_JOY[1][0] <> "" then
		While 1
			$Chars = FileReadLine($File, $Linha)
			If @error Then ExitLoop
			$Search = StringInStr($Chars, $iFindLine) ; linha a ser procurada no arquivo
			If $Search <> 0 Then
				_FileWriteToLine($iFile, $Linha, @TAB & $iFindLine & $iBt , $iDeleteLine)
				ExitLoop
			EndIf
			$Linha += 1
		WEnd
	EndIf
EndFunc

Func _DELETE_BLANK_LINES($iFile)
	Local $iVarRet
	_FileReadToArray($iFile,$iVarRet)
	For $i = UBound($iVarRet)-1 To 1 Step -1
		if $iVarRet[$i] = "" Then _ArrayDelete($iVarRet,$i)
	Next
	_FileWriteFromArray($iFile,$iVarRet)
EndFunc
; #FUNCTION# ====================================================================================================================
; Name ..........: _CREATE_LABEL
; Description ...:
; Syntax ........: _CREATE_LABEL()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _CREATE_LABEL()
;INFO TELEFONE
GUICtrlCreateLabel($__FACE & " Tel: " & $__TELEF,15,15,600,30)
GUICtrlSetFont(-1,17,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0x00B2B2)

$SETA= _GUICtrlPic_Create($imagem_seta,510,75, 25,25)

GUICtrlCreateLabel($__FACE & " Tel: " & $__TELEF,17,17,600,30)
GUICtrlSetFont(-1,17,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

GUICtrlCreateLabel("Tempo:",490,10,90,40,$SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,20, $FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)

GUICtrlCreateLabel("Tempo:",492,12,90,40,$SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,20, $FW_BOLD )
GUICtrlSetColor(-1,0)

Global $TIMER = GUICtrlCreateLabel("",590,10,60,40,$SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,20,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)

Global $TIMER2 = GUICtrlCreateLabel("",592,12,60,40,$SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,20,$FW_BOLD)
GUICtrlSetColor(-1,0)


GUICtrlCreateLabel("",590,10,60,40)
GUICtrlSetBkColor(-1, 0xAAAAAA)
GUICtrlCreateLabel("", 5,52,729,3, $SS_SUNKEN) ;Separador

Local $info = "(FICHA)" & @CRLF & " Adicionar Ficha ao sistema"
GUICtrlCreateLabel($info,10,70,330,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)
GUICtrlCreateLabel($info,12,72,330,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)
GUICtrlCreateLabel("", 5,122,729,3, $SS_SUNKEN) ;Separador

Local $info = "(DIPSWITCH)"  & @CRLF & "Botão que abre o menu de configurações"
GUICtrlCreateLabel($info,10,140,500,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)
GUICtrlCreateLabel($info,12,142,500,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)
GUICtrlCreateLabel("", 5,192,729,3, $SS_SUNKEN) ;Separador

Local $info = "(SAIR DO JOGO / ENTRAR NO JOGO)"  & @CRLF & "Botão usado para sair do emulador" & @CRLF & "e usado para entrar no jogo"
GUICtrlCreateLabel($info,10,200,500,65)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,13,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)
GUICtrlCreateLabel($info,12,202,500,65)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,13,$FW_BOLD)
GUICtrlSetColor(-1,0)
GUICtrlCreateLabel("", 5,262,729,3, $SS_SUNKEN) ;Separador

Local $info = "(TRANSFERIR FICHA)" & @CRLF &  "Botão usado para transferir ficha ao jogo"
GUICtrlCreateLabel($info,10,280,500,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)
GUICtrlCreateLabel($info,12,282,500,45)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)
GUICtrlCreateLabel("", 5,332,729,3, $SS_SUNKEN) ;Separador

Local $info = "(VOLTAR MENU SYSTEM)" & @CRLF & "Botão usado para voltar para o MENUSYSTEM" & @CRLF & "se estiver desativado, será usado para trocar de emulador"
GUICtrlCreateLabel($info,10,345,500,65)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,13,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)
GUICtrlCreateLabel($info,12,347,500,65)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,13,$FW_BOLD)
GUICtrlSetColor(-1,0)


$LABEL_NUMB_A[1] = GUICtrlCreateLabel("",530,70,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[1] = GUICtrlCreateLabel("",532,72,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[2] = GUICtrlCreateLabel("",530,140,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[2] = GUICtrlCreateLabel("",532,142,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[3] = GUICtrlCreateLabel("",455,210,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[3] = GUICtrlCreateLabel("",457,212,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[4] = GUICtrlCreateLabel("",605,210,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[4] = GUICtrlCreateLabel("",607,212,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[5] = GUICtrlCreateLabel("",455,280,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[5] = GUICtrlCreateLabel("",457,282,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[6] = GUICtrlCreateLabel("",605,280,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[6] = GUICtrlCreateLabel("",607,282,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

$LABEL_NUMB_A[7] = GUICtrlCreateLabel("",455,350,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[7] = GUICtrlCreateLabel("",457,352,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)


$LABEL_NUMB_A[8] = GUICtrlCreateLabel("",605,350,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0xF0F0E1)

$LABEL_NUMB_B[8] = GUICtrlCreateLabel("",608,352,116,55,$SS_CENTER)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor(-1,0)

GUICtrlCreateLabel("E",575,235,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)

GUICtrlCreateLabel("E",577,237,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)

GUICtrlCreateLabel("OU",575,305,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)

GUICtrlCreateLabel("OU",577,306,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)

GUICtrlCreateLabel("OU",575,375,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0xF0F0E1)

GUICtrlCreateLabel("OU",577,377,25,25,$SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1,14,$FW_BOLD)
GUICtrlSetColor(-1,0)


$PIC_IMG[1]= _GUICtrlPic_Create($imagem_botao_disable,555,55, 66,66)
$PIC_IMG[2]= _GUICtrlPic_Create($imagem_botao_disable,555,125, 66,66)
$PIC_IMG[3]= _GUICtrlPic_Create($imagem_botao_disable,480,195, 66,66)
$PIC_IMG[4]= _GUICtrlPic_Create($imagem_botao_disable,630,195, 66,66)
$PIC_IMG[5]= _GUICtrlPic_Create($imagem_botao_disable,480,265, 66,66)
$PIC_IMG[6]= _GUICtrlPic_Create($imagem_botao_disable,630,265, 66,66)
$PIC_IMG[7]= _GUICtrlPic_Create($imagem_botao_disable,480,335, 66,66)
$PIC_IMG[8]= _GUICtrlPic_Create($imagem_botao_disable,630,335, 66,66)
EndFunc