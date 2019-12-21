;VERIFICA O SERIAL SE E IGUAL AO DO HD ENCRIPTADO
Func _CRYPT_CHECK_SAVE_KEY($KEY_SALVA, $sPassword, $iKey, $iobs2)
	Local $HDKEY =  _GET_HDD_SERIAL(StringLeft(@ScriptDir,2))
	if @error then Return SetError(-1,0,False)

	Local $iCheck = __internal_str_to_crypt(False, $KEY_SALVA, $sPassword,$iKey)
		  $iCheck = StringReplace($iCheck, $iobs2,"")

	if $iCheck = $HDKEY then Return True
	Return SetError(-2,0,False)
EndFunc

;ENCRIPTA OU DESCRIPTA
Func __internal_str_to_crypt($bEncrypt, $sData, $sPassword,$iKey)
    _Crypt_Startup()
    Local $sReturn = ''
    If $bEncrypt Then
      $sReturn =  StringReplace(_Crypt_EncryptData($sData, $sPassword, $iKey),"0x", "",1)
    Else
		Local $KEY_S = StringReplace($sData,"-","")
		$sReturn = BinaryToString(_Crypt_DecryptData("0x" & $KEY_S, $sPassword, $iKey))
    EndIf
    _Crypt_Shutdown()
    Return $sReturn
EndFunc
; #FUNCTION# ====================================================================================================================
; Name ..........: _REGISTRO_GUI
; Description ...:
; Syntax ........: _REGISTRO_GUI()
; Parameters ....: None
; Return values .: None
; Author ........: Pedro Warlock
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _REGISTRO_GUI($ikey1,$ikey2, $iencry1,$iencry2, $iobs1, $iobs2)
	Local $iFolder = @AppDataDir & "/~trcd.tmp"
	Local $TryTimes = IniRead($iFolder,"0000","00002","0")
	Local $Min  = 0
	if $TryTimes >= 5 Then
		$Min = IniRead($iFolder,"0000","00001",@MDAY & @HOUR & @MIN)
		if @MDAY & @HOUR & @MIN <= $Min+5 Then
			MsgBox(16,"Erro","Tente novamente mais tarde. " & ($Min - (@MDAY & @HOUR & @MIN)+ 5) & " Minutos restantes")
			Return
		EndIf
	EndIf

	Local $HDSERIAL = _GET_HDD_SERIAL(StringLeft(@ScriptDir,2))
	Local $iDiscoInst  = __internal_str_to_crypt(True, $iobs1 & $HDSERIAL & $iobs1, $ikey1,$iencry1)

	Local $RETORNO = False
	;-----------------------------------------
	Local $i__Button1_X =  15, $i__Button1_Y = 240, $i__Button1_W = 278,	$i__Button1_H = 49
	Local $i__Button2_X = 300, $i__Button2_Y = 240, $i__Button2_W = 278,	$i__Button2_H = 49

	FileInstall("..\img\mensa1.jpg", @TempDir & "\~msq1",1)
	FileInstall("..\img\mensa3.jpg", @TempDir & "\~msq3",1)

	Local $i__PicButton = @TempDir & "\~msq1"
    Local $i__PicBK     = @TempDir & "\~msq3"

	Local $i__JanelaW = 594
	Local $i__JanelaH = 315


	;GUI PRINCIPAL
	Local $hGUI = GUICreate("Registro",$i__JanelaW,$i__JanelaH,-1,-1,0x80000000, -1)


	;PIC BACKGROUND
		Local $i_PICBK = GUICtrlCreatePic($i__PicBK,0,0,$i__JanelaW,$i__JanelaH)
		GUICtrlSetState($i_PICBK,128)

	GUICtrlCreateLabel("REGISTRAR SISTEMA", 0, 25,$i__JanelaW , 35, 0x01+0x0200)
	GUICtrlSetFont(-1, 30, -1, -1, "impact")
	GUICtrlSetBkColor(-1, -2)

	Local $i__VERSAO = "Versão: 0.5.4.5"
	GUICtrlCreateLabel($i__VERSAO, 460, 288,100 , 20, 0x01+0x0200)
	GUICtrlSetFont(-1, 10, -1, -1, "impact")
	GUICtrlSetBkColor(-1, -2)
	GUICtrlSetColor(-1,0x3336FF)

	GUICtrlCreateLabel($__FACE & " " & $__TELEF, 0, 65,$i__JanelaW , 15, 0x01+0x0200)
	GUICtrlSetFont(-1, 13, -1, -1, "impact")
	GUICtrlSetColor(-1,0x00468C)
	GUICtrlSetBkColor(-1, -2)

	GUICtrlCreateLabel("RC Code:", 35, 100,60 , 25, 0x0000)
	GUICtrlSetFont(-1, 12, -1, -1, "impact")
	GUICtrlSetBkColor(-1, -2)

	GUICtrlCreateLabel(" (Copie o RC Code e envie para o desenvolvedor para receber o serial)", 95, 102,500 , 25, 0x0000)
	GUICtrlSetFont(-1, 11, -1, -1, "arial")
	GUICtrlSetColor(-1,0x00468C)
	GUICtrlSetBkColor(-1, -2)

	GUICtrlCreateLabel("Serial:", 35, 160,60 , 25, 0x0000)
	GUICtrlSetFont(-1, 12, -1, -1, "impact")
	GUICtrlSetBkColor(-1, -2)

	GUICtrlCreateLabel(" (Cole o serial recebido pelo desenvolvedor)", 95, 162,500 , 25, 0x0000)
	GUICtrlSetFont(-1, 11, -1, -1, "arial")
	GUICtrlSetColor(-1,0x00468C)
	GUICtrlSetBkColor(-1, -2)
	;-----------------------------------------
	;BOTÕES DE COPIAR/COLAR
		Local $i_BT_COPIAR = GUICtrlCreateButton("COPIAR", 484, 120, 73, 28)
		GUICtrlSetFont($i_BT_COPIAR, 11, 0, 0, "impact")
		GUICtrlSetColor($i_BT_COPIAR,0xFFFFFF)
		GUICtrlSetBkColor($i_BT_COPIAR, 0x000000)
		GUICtrlSetCursor($i_BT_COPIAR, 0)

		Local $i__IMPUT1 = GUICtrlCreateInput($iDiscoInst, 35, 120, 440, 28, BitOR(0x1000,0x0001,0x0008,0x0800))
		GUICtrlSetFont($i__IMPUT1, 13, 0, 0, "impact")
		GUICtrlSetBkColor($i__IMPUT1,0xFFFFFF)
		;-----------------------------------------
		Local $i_BT_COLAR = GUICtrlCreateButton("COLAR", 484, 180, 73, 28)
		GUICtrlSetFont($i_BT_COLAR, 11, 0, 0, "impact")
		GUICtrlSetColor($i_BT_COLAR,0xFFFFFF)
		GUICtrlSetBkColor($i_BT_COLAR, 0x000000)
		GUICtrlSetCursor($i_BT_COLAR, 0)



		Local $i__IMPUT2 = GUICtrlCreateInput("", 35, 180, 440, 28, BitOR(0x0080,0x0001,0x0008))
		GUICtrlSetFont($i__IMPUT2, 13, 0, 0, "impact")


	;-----------------------------------------

		;PIC BT1
		Local $i_PIC1 = GUICtrlCreatePic($i__PicButton,$i__Button1_X,$i__Button1_Y,$i__Button1_W,$i__Button1_H)
		GUICtrlSetState($i_PIC1,128)
	;-----------------------------------------
	;LABEL BT1
		Local $Label_Acc = GUICtrlCreateLabel("REGISTRAR", $i__Button1_X, $i__Button1_Y, $i__Button1_W, $i__Button1_H, 0x01+0x0200)
		GUICtrlSetFont($Label_Acc, 17, -1, -1, "arial")
		GUICtrlSetBkColor($Label_Acc, -2)
		GUICtrlSetCursor($Label_Acc, 0)
	;PIC BT2
		Local $i_PIC2 = GUICtrlCreatePic($i__PicButton,$i__Button2_X,$i__Button2_Y,$i__Button2_W,$i__Button2_H)
		GUICtrlSetState($i_PIC2,128)
	;-----------------------------------------
	;LABEL BT2
		Local $Label_exit = GUICtrlCreateLabel("SAIR", $i__Button2_X, $i__Button2_Y, $i__Button2_W, $i__Button2_H, 0x01+0x0200)
		GUICtrlSetFont($Label_exit, 17, -1, -1, "arial")
		GUICtrlSetBkColor($Label_exit, -2)
		GUICtrlSetCursor($Label_exit, 0)

	;-----------------------------------------
	FileDelete($i__PicButton)
	FileDelete($i__PicBK)


	GUISetState(@SW_SHOW, $hGUI)
	ControlClick("","",$i__IMPUT2)
    While 1
        Switch GUIGetMsg()
			Case $i_BT_COLAR
				GUICtrlSetData($i__IMPUT2,ClipGet())
			Case $i_BT_COPIAR
				ClipPut(GUICtrlRead($i__IMPUT1))
            Case $Label_Acc
				 Local $iGetImput = __internal_str_to_crypt(False, GUICtrlRead($i__IMPUT2), $ikey2,$iencry2)
					   $iGetImput = (StringInStr($iGetImput, $iobs2,0,2) > 0)? $iGetImput:"ERRO"
					   $iGetImput = StringReplace($iGetImput,$iobs2, "")

					if  $iGetImput = $HDSERIAL Then
						_REGISTRAR_SYS(_CONST_ADVMENU_INI(), GUICtrlRead($i__IMPUT2))
						$iGetImput = 0
						$RETORNO = True
						FileDelete($iFolder)
						ExitLoop
					Else
						$TryTimes +=1
						MsgBox(16,"Erro","A senha digitada está incorreta! Por favor, entre em contrato com o desenvolvedor.")
							IniWrite($iFolder,"0000","00001",@MDAY & @HOUR & @MIN)
							IniWrite($iFolder,"0000","00002",$TryTimes)
							FileSetAttrib($iFolder,"+H+T+S")
						if $TryTimes >=5 then Return
					EndIf
					Case -3,$Label_exit
				ExitLoop
        EndSwitch
    WEnd


	GUIDelete($hGUI)
	Return $RETORNO
EndFunc
