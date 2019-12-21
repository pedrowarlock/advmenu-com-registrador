#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon\system_software_update.ico
#AutoIt3Wrapper_Outfile=autoupdate.exe
#AutoIt3Wrapper_Res_Description=Updater
#AutoIt3Wrapper_Res_Fileversion=1.0.0.88
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Updater
#AutoIt3Wrapper_Res_ProductVersion=1.0
#AutoIt3Wrapper_Res_CompanyName=@Wdiversoes
#AutoIt3Wrapper_Res_LegalCopyright=@Wdiversoes
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <MsgBoxConstants.au3>
#include <IE.au3>
#include <INet.au3>
#include <WinAPIFiles.au3>
#include <array.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiRichEdit.au3>
#include <FileConstants.au3>
#include ".\include\GUICtrlPic.au3"
FileDelete(@ScriptFullPath & "_del")

Global $iProgress1,$iProgress2,$iLbl_1,$iLbl_2,$iLbl_3,$iRich ;gui
Global $Grey_BT,$Grey_BT_HOVER,$Grey_BT_HOVER2,$blue_BT,$blue_BT_HOVER,$blue_BT_HOVER2,$aHoverBtn[5][7]	;Botões
Global $Red_BT,$Red_BT_HOVER,$Red_BT_HOVER2,$green_BT,$green_BT_HOVER,$green_BT_HOVER2,$purple_BT,$purple_BT_HOVER,$purple_BT_HOVER2,$iMG_Bk			;Botões
Global $BT_CLOSE,$BT_CLOSEh,$BT_CLOSEh2,$BT_MINI,$BT_MINIh,$BT_MINIh2									;botões IMGS

Global $LOG_RICHEDT

Global $TRY_CONNECT_COOLDOWN = 8000	;Tempo de cooldown para verificar atualização de novo
Global $TRY_CONNECT_TIMES	 = 10	;Tentativas maximas de tentativas
Global $Looping			= 1 ;Loop principal
Global $ETAPA_DOWN_FILE = 0,$START_DOWN_FILE=False ;Etapas de verificação do servidor
Global $ETAPA 					  = 0 ;0 = Verificando servidor | 1 = Pronto para baixar | 2 = Pausado | 3 = Baixando | 4 = Movendo arquivos | 5 = Acabou (Iniciar Sistema)
Global Const $iURL_FOLDER 		  = "https://canal8bits.000webhostapp.com/UPDATER/"   ;Pasta online que se encontra os arquivos de update
Global Const $UPDATE_URL 		  = $iURL_FOLDER & "/UPDATER.txt"
Global Const $iURL_LOG 			  = $iURL_FOLDER & "/log.rtf"						   ;Arquivo online em que mostra as atualizações do upload
Global $TICK_GLOBAL				  = _TICK_UPDATE()
Global $TICK_CHECK_ATT  		  = _TICK_UPDATE(), $First_try = True,$Try_times = 0
Global Const $Title 			  = "AutoUpdate.exe"
Global Const  $iARCADE_EXE 		  = "ARCADE.exe"
Global Const $iTempDir 			  = @TempDir & "\~pw_f\"
Global Const $iLog_erro 		  = "log_erro.txt"
Global Const $iLog_atualizacao    = "log_atualização.txt"
Global Const $iLocal_UPDATER_FILE = "update.lc"
Global $Lr_update 				  = False
Global $SHOW_LOG 				  = False
Global $iDownload_conect

if $CMDLINE[0] > 0 Then
	if $CMDLINE[1] = "-log" Then $SHOW_LOG = True
EndIf

Global $Need_install = True
Global $PATH_INSTALACAO = ___get_install_folder()
if not @error then $Need_install=False


;SOM CLICK
Local $dWav = __click_sound()
Local $tWav = DllStructCreate('byte[' & BinaryLen($dWav) & ']')
DllStructSetData($tWav, 1, $dWav)
Local $pWav = DllStructGetPtr($tWav)


;=========================================================
;Gui
;=========================================================
Global $hGUI = _CreateWindow("Atualizar sistema")

;LOOP
While $Looping
	_GuiCtrlPic_CheckHoverDisabled($hGui, $aHoverBtn)

	Switch GUIGetMsg()
        Case $Gui_EVENT_CLOSE
            ExitLoop

		Case $aHoverBtn[1][0] ;Fecha e faz o efeito de Hover ao apertar o botão
			_GuiCtrlPic_AnimButton($hGui, $aHoverBtn[1][0], $aHoverBtn[1][1],$aHoverBtn[1][2], $aHoverBtn[1][3],20)
			ExitLoop

		Case $aHoverBtn[2][0] ;Minimiza e faz o efeito de Hover ao apertar o botão
			_GuiCtrlPic_AnimButton($hGui, $aHoverBtn[2][0], $aHoverBtn[2][1],$aHoverBtn[2][2], $aHoverBtn[2][3],20)
			_WinAPI_PlaySound($pWav, BitOR($SND_ASYNC, $SND_LOOP, $SND_MEMORY))
			GUISetState(@SW_MINIMIZE, $hGUI)

		Case $aHoverBtn[0][0] ;Botão atualizar
			_GuiCtrlPic_AnimButton($hGui, $aHoverBtn[0][0], $aHoverBtn[0][1],$aHoverBtn[0][2], $aHoverBtn[0][3],20)
			_WinAPI_PlaySound($pWav, BitOR($SND_ASYNC, $SND_MEMORY))


			Switch $ETAPA
				Case 2	;ATUALIZAR
					if $Need_install Then
						Local $iFolder = FileSelectFolder("Selecione uma pasta para instalação", StringLeft(@ScriptDir,3),0,"",$hGUI)
						If Not @error or $iFolder <> "" Then
							$PATH_INSTALACAO = $iFolder & "\"
							_Reg_Write($PATH_INSTALACAO & "\")
							$Need_install=False

							_Changer_Button("red")
							$ETAPA 	= 3

						EndIf
					Else
							_Changer_Button("red")
							$ETAPA 	= 3
					EndIf
				Case 3	;CANCELAR
					if $Need_install Then
						_Changer_Button("purple")
					Else
						_Changer_Button("blue")
					EndIf
					$START_DOWN_FILE = False
					InetClose($iDownload_conect)

					$START_DOWN_FILE = False
					$ETAPA_DOWN_FILE = 0
					$ETAPA 			 = 2
				Case 5	;INICIAR ARCADE.exe
					_ShellOpen($iARCADE_EXE,"",$PATH_INSTALACAO) ;Executar Arcade.exe
;~ 					Sleep(1000)
					$Looping = 0 						   ;Sair
				EndSwitch
	EndSwitch

Switch $ETAPA
		Case 0	;Verifica se pode atualizar - Se não tiver internet, ele vai tentar se conectar 10 vezes até desistir (Pensando em colocar verificações infinitas)
			$FULL_LIST = _LendoLogOnline()
		Case 3	;ATUALIZANDO....
				if Not $START_DOWN_FILE Then							;Inicia um download novo
					if  IsArray($FULL_LIST) Then
						Local $iFile_remote_path = $FULL_LIST[$ETAPA_DOWN_FILE][0]
						Global $sFile_name	  	 = ___get_file_name_from_path($iFile_remote_path)
						Global $sFile_fullname 	 = $iFile_remote_path
						Global $sTemp_File 	  	 = _WinAPI_GetTempFileName($iTempDir,"~wdl_")

						Global $iDownload_conect = InetGet(StringReplace($iURL_FOLDER & $sFile_fullname, ".exe", ".exe_") , $sTemp_File, $INET_FORCERELOAD,1)
						__set_status_info("Baixando " & $sFile_name & "...")
						__set_status_Selected($ETAPA_DOWN_FILE+1 & " / " & UBound($FULL_LIST))
						__Set_Status_bar1($ETAPA_DOWN_FILE / (UBound($FULL_LIST)- 1) * 100)
					EndIf
					$START_DOWN_FILE=True
				EndIf

				if $START_DOWN_FILE Then								;Varifica se já baixou

					__set_status_bytes(_GetCurrentBytes($iDownload_conect) & " / " & _GetTotalBytes($iDownload_conect))
					__Set_Status_bar2(_GetCurrentBytes($iDownload_conect) / _GetTotalBytes($iDownload_conect) * 100)

					If InetGetInfo($iDownload_conect, $INET_DOWNLOADCOMPLETE) Then	  ;Se o download terminou
						If InetGetInfo($iDownload_conect, $INET_DOWNLOADSUCCESS) Then ;Se não deu erro, então
							Local $FILE_PATH = $PATH_INSTALACAO &"\"& $sFile_fullname

							if FileExists($FILE_PATH) and ProcessExists($sFile_name) Then
								FileMove($sTemp_File,$FILE_PATH & "_del",$FC_CREATEPATH + $FC_OVERWRITE ) ;Renomeia o arquivo de destino para "Arquivo.exe_del"
								Sleep(100)
								FileSetAttrib($FILE_PATH & "_del", "+H", $FT_RECURSIVE)
							EndIf

							FileMove($sTemp_File,$FILE_PATH, $FC_CREATEPATH +$FC_OVERWRITE )

							;Se baixar autoupdater (Ativar o fechamento e abrir programa)
							if $sFile_name = $Title Then $Lr_update = True

							;Escreve a atualização
							IniWrite($PATH_INSTALACAO & "\" & $iLocal_UPDATER_FILE,"Launcher",$FULL_LIST[$ETAPA_DOWN_FILE][0],$FULL_LIST[$ETAPA_DOWN_FILE][1])

							$ETAPA_DOWN_FILE +=1
						Else
							InetClose($iDownload_conect)
							_FileWriteLog($PATH_INSTALACAO & "\" & $iLog_erro,"Não foi possivel baixar o arquivo: " & $iFile_remote_path)
						EndIf
						$START_DOWN_FILE=False
					EndIf

					if $ETAPA_DOWN_FILE > UBound($FULL_LIST)-1 or Not IsArray($FULL_LIST) Then		;Finaliza todos downloads
						_Changer_Button("green")
						__set_status_info("Concluido!")
						FileWrite($iLog_atualizacao,_GUICtrlRichEdit_GetText($iRich))

						if $Lr_update Then
							_ShellOpen($Title,"" ,$PATH_INSTALACAO)
							$Looping = 0
						EndIf

						$ETAPA = 5
					EndIf
				EndIf
EndSwitch
Sleep(80)
WEnd
__exit_syst()

Func ___get_install_folder()
	Local $iGetInstall = _Reg_CheckInstall()
	if Not @error Then
		Return $iGetInstall
	EndIf
Return SetError(-1,0,@ScriptDir)
EndFunc


					Func ___get_file_name_from_path($iArray)
						Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
						Local $aPathSplit 	  = _PathSplit($iArray, $sDrive, $sDir, $sFileName, $sExtension)
						if @error Then Return SetError(-1,0,"")
						Return $aPathSplit[3] & $aPathSplit[4]
					EndFunc

					Func ___get_path_file_name($iArray)
						Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
						Local $aPathSplit 	  = _PathSplit($iArray, $sDrive, $sDir, $sFileName, $sExtension)
						if @error Then Return SetError(-1,0,"")
						Return $aPathSplit[1] & $aPathSplit[2]
					EndFunc

Func __Set_Status_bar1($isb)
	if GUICtrlRead($iProgress1) <> $isb Then GUICtrlSetData($iProgress1, $isb)
EndFunc

Func __Set_Status_bar2($isb)
	if GUICtrlRead($iProgress2) <> $isb Then GUICtrlSetData($iProgress2, $isb)
EndFunc

Func __set_status_Selected($inf)
	if GUICtrlRead($iLbl_3) <> $inf Then GUICtrlSetData($iLbl_3,$inf)
EndFunc

Func __set_status_bytes($inf)
	if GUICtrlRead($iLbl_2) <> $inf Then GUICtrlSetData($iLbl_2,$inf)
EndFunc

Func _GetCurrentBytes($istr)
	Return int((InetGetInfo($istr, $INET_DOWNLOADREAD)/1024)) & " bytes"
EndFunc

Func _GetTotalBytes($istr)
	Return int((InetGetInfo($istr, $INET_DOWNLOADSIZE)/1024)) & " bytes"
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _ShellOpen
; Description ...:
; Syntax ........: _ShellOpen($ir, $iCmdl, $id)
; Parameters ....: $ir                  - an integer value.
;                  $iCmdl               - an integer value.
;                  $id                  - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _ShellOpen($ir,$iCmdl ,$id)
	if FileExists($id & "/" & $ir) Then
		ShellExecute($ir,$iCmdl,$id,"open",@SW_SHOW)
	Return True
	EndIf
Return SetError(-1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _LendoLogOnline
; Description ...:
; Syntax ........: _LendoLogOnline()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _LendoLogOnline()
Local $iret, $iGetTick = Int(($TRY_CONNECT_COOLDOWN - (_TICK_UPDATE()-$TICK_CHECK_ATT))/1000)
	if  $iGetTick < 0 or $First_try Then
		$iret=_init_check_server($UPDATE_URL)
		if @error = -1 Then
			$TICK_CHECK_ATT = _TICK_UPDATE()
			$First_try = False
			$Try_times +=1
			If $Try_times > $TRY_CONNECT_TIMES Then
				$ETAPA=5
				_Changer_Button("green")
				__set_status_info("Não foi possivel se conectar com o servidor!")
			EndIf
		ElseIf @error = -2 Then
			__set_status_info("Atualização não necessária!")
			$ETAPA = 5 ;Não necessario atualizar
			_Changer_Button("green")
		Else
			$ETAPA=2
				__set_status_info("")
			if $Need_install Then
				_Changer_Button("purple")
			Else
				_Changer_Button("blue")
			EndIf
		EndIf
	Else
		__set_status_info("Tentando conectar..." & $iGetTick)
	EndIf

	Return $iret
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _TICK_UPDATE
; Description ...:
; Syntax ........: _TICK_UPDATE()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _TICK_UPDATE()
	Local $iTick = DllCall("kernel32.dll", "int", "GetTickCount")
	if @error then Return
	Return $iTick[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _init_check_server
; Description ...:
; Syntax ........: _init_check_server($iURL)
; Parameters ....: $iURL                - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _init_check_server($iURL)
	__set_status_info("Verificando atualizações...")

	if _GUICtrlRichEdit_GetText($iRich) = "" Then
		Global $LOG_RICHEDT =_INetGetSource($iURL_LOG)
		_GUICtrlRichEdit_SetText ( $iRich, $LOG_RICHEDT )
	EndIf

	Local $iS = _INetGetSource($iURL)
	if @error Then Return SetError(-1)

	Local Const $sFilePath = _WinAPI_GetTempFileName(@TempDir)
	FileWrite($sFilePath,$iS)


	$aFile_remote = __IniReadSection($sFilePath,"Launcher") ;IniReadSection($sFilePath,"Launcher")
	Local $iArr_ALL[0][2]

	if FileExists($PATH_INSTALACAO &"\"& $iLocal_UPDATER_FILE) or $Need_install Then
		For $i=UBound($aFile_remote)-1 To 1 Step -1
			__Set_Status_bar1($i / (UBound($aFile_remote)- 1) * 100)
			__Set_Status_bar2($i / (UBound($aFile_remote)- 1) * 100)
				Local $iGet_remote_nome=  $aFile_remote[$i][0]
				Local $iGet_remote_Ver =  $aFile_remote[$i][1]
				Local $iGet_Local_Ver  = IniRead($PATH_INSTALACAO &"\"& $iLocal_UPDATER_FILE,"Launcher",$aFile_remote[$i][0],"0.0.0.0")


			if ($iGet_remote_Ver) > ($iGet_Local_Ver) Then
				_ArrayAdd($iArr_ALL,$iGet_remote_nome & "|" & $iGet_remote_Ver)
			EndIf

		Next
	Else
		_ArrayDelete($aFile_remote,0)
		$iArr_ALL = $aFile_remote
	EndIf

	if $SHOW_LOG Then _ArrayDisplay($iArr_ALL,"Info","",0,Default,"Executavel Remoto|Versão Remoto|Versão Local|Pasta do arquivo Local|Arquivo Temporario|Remote folder")


	if (UBound($iArr_ALL)) <= 0 Then
		Return SetError(-2)
	EndIf
Return $iArr_ALL
EndFunc


Func _FileFindVerLocal($iArray,$iFile)
	if Not IsArray($iArray) Then Return SetError(-1,0,"0.0.0.0")

;~ 	Local $iresult = _ArraySearch($iArray,$iFile)
;~ 	if @error then Return SetError(-2,0,"0.0.0.0")
;~ 	Return $iArray[$iresult][1]
EndFunc

Func _FileGetVersion($ifile)
	Local $iSplit = StringSplit($ifile,"|", $STR_NOCOUNT )
	if Not @error or UBound($iSplit) >= 2 then Return $iSplit[1]
	Return SetError(-1,0,"0.0.0.0")
EndFunc

Func _FileGetNameLocal($ifile)
	Local $iSplit = StringSplit($ifile,"|", $STR_NOCOUNT )
	if @error or UBound($iSplit) >=2 then Return $iSplit[0]
	Return SetError(-1,0,"")
EndFunc


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __set_status_info
; Description ...:
; Syntax ........: __set_status_info($info)
; Parameters ....: $info                - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __set_status_info($info)
	Local $iget = GUICtrlRead($iLbl_1)
	if $iget <> $info Then GUICtrlSetData($iLbl_1,$info)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _Changer_Button
; Description ...:
; Syntax ........: _Changer_Button($ibt)
; Parameters ....: $ibt                 - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Changer_Button($ibt)
	If $ibt = "blue" Then
		$aHoverBtn[0][1] = $blue_BT
		$aHoverBtn[0][2] = $blue_BT_HOVER
		$aHoverBtn[0][3] = $blue_BT_HOVER2
	ElseIf $ibt = "green" Then
		$aHoverBtn[0][1] = $green_BT
		$aHoverBtn[0][2] = $green_BT_HOVER
		$aHoverBtn[0][3] = $green_BT_HOVER2
	ElseIf $ibt = "grey" Then
		$aHoverBtn[0][1] = $Grey_BT
		$aHoverBtn[0][2] = $Grey_BT_HOVER
		$aHoverBtn[0][3] = $Grey_BT_HOVER2
	ElseIf $ibt = "red" Then
		$aHoverBtn[0][1] = $Red_BT
		$aHoverBtn[0][2] = $Red_BT_HOVER
		$aHoverBtn[0][3] = $Red_BT_HOVER2
	ElseIf $ibt = "purple" Then
		$aHoverBtn[0][1] = $purple_BT
		$aHoverBtn[0][2] = $purple_BT_HOVER
		$aHoverBtn[0][3] = $purple_BT_HOVER2
	EndIf
	_GUICtrlPic_SetImage($aHoverBtn[0][0] , $aHoverBtn[0][1])
							__set_status_bytes("")
						__set_status_Selected("")
						__Set_Status_bar1(0)
						__Set_Status_bar2(0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _CreateWindow
; Description ...:
; Syntax ........: _CreateWindow($in)
; Parameters ....: $in                  - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _CreateWindow($in)
	Local $iG = GUICreate($in,770,481,-1,-1,$WS_POPUP)
	GUISetBkColor(0xDDDDDD,$iG)

	__installPNG()

	Local $Bk_img = _GUICtrlPic_Create($iMG_Bk, 0, 0, 770, 481)
	GUICtrlSetState($Bk_img,$GUI_DISABLE )

	$iRich = _GUICtrlRichEdit_Create($iG, "", 30, 66, 711, 291, BitOR($ES_READONLY,$WS_VSCROLL,$ES_AUTOHSCROLL ,$ES_NOHIDESEL ,$ES_MULTILINE), $WS_EX_WINDOWEDGE)
	_GUICtrlRichEdit_GotoCharPos($iRich, 0)
	_GUICtrlRichEdit_SetBkColor ( $iRich, 0xDDDDDD)

	$iLbl_1 = GUICtrlCreateLabel("",50,385,400,25);Downloading..
	$iLbl_2 = GUICtrlCreateLabel("",348,440,200,15,$SS_RIGHT) ;1546 Bytes
	$iLbl_3 = GUICtrlCreateLabel("",468,385,80,20,$SS_RIGHT); 1/6

	GUICtrlSetBkColor($iLbl_1,$GUI_BKCOLOR_TRANSPARENT )
	GUICtrlSetBkColor($iLbl_2,$GUI_BKCOLOR_TRANSPARENT )
	GUICtrlSetBkColor($iLbl_3,$GUI_BKCOLOR_TRANSPARENT )

	$iProgress1 = GUICtrlCreateProgress(42,403,500,16)
	$iProgress2 = GUICtrlCreateProgress(42,423,500,16)


	$aHoverBtn[0][1] = $Grey_BT
	$aHoverBtn[0][2] = $Grey_BT_HOVER
	$aHoverBtn[0][3] = $Grey_BT_HOVER2
	$aHoverBtn[0][0] = _GUICtrlPic_Create($aHoverBtn[0][1], 570, 380, 193, 78, BitOR($SS_CENTERIMAGE, $SS_NOTIFY))

	$aHoverBtn[1][1] = $BT_CLOSE
	$aHoverBtn[1][2] = $BT_CLOSEh
	$aHoverBtn[1][3] = $BT_CLOSEh2
	$aHoverBtn[1][0] = _GUICtrlPic_Create($aHoverBtn[1][1], 730, 7, 28, 27, BitOR($SS_CENTERIMAGE, $SS_NOTIFY))

	$aHoverBtn[2][1] = $BT_MINI
	$aHoverBtn[2][2] = $BT_MINIh
	$aHoverBtn[2][3] = $BT_MINIh2
	$aHoverBtn[2][0] = _GUICtrlPic_Create($aHoverBtn[2][1], 695, 7, 28, 27, BitOR($SS_CENTERIMAGE, $SS_NOTIFY))

	GUICtrlSetState($iLbl_1, $GUI_FOCUS)
	GUISetState(@SW_SHOW)
	Return $iG
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _Reg_CheckInstall
; Description ...:
; Syntax ........: _Reg_CheckInstall()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Reg_CheckInstall()
	Local $sHKLM = @OSarch = "X64" ? "HKCU64" : "HKCU"
	$iRead_Reg = RegRead($sHKLM & "\SOFTWARE\Wdiversoes\ADVMENU", "FOLDER")
	if (FileExists($iRead_Reg &"\"& $iLocal_UPDATER_FILE)) Then
		return ___get_path_file_name($iRead_Reg)
	EndIf
	Return SetError(-1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _Reg_Write
; Description ...:
; Syntax ........: _Reg_Write($ifolder)
; Parameters ....: $ifolder             - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Reg_Write($ifolder)
	Local $sHKLM = @OSarch = "X64" ? "HKCU64" : "HKCU"
	RegWrite($sHKLM & "\SOFTWARE\Wdiversoes\ADVMENU", "FOLDER", "REG_SZ",$ifolder)
EndFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __installPNG
; Description ...:
; Syntax ........: __installPNG()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __installPNG()
	DirCreate($iTempDir)
	FileSetAttrib($iTempDir, "+HS")

	$iMG_Bk 		 = $iTempDir & "\bk"
	$Grey_BT		 = $iTempDir & "\bt1"

	$blue_BT		 = $iTempDir & "\bt2"
	$blue_BT_HOVER 	 = $iTempDir & "\bt2_h"
	$blue_BT_HOVER2	 = $iTempDir & "\bt2_h2"

	$Red_BT		 	 = $iTempDir & "\bt3"
	$Red_BT_HOVER	 = $iTempDir & "\bt3_h"
	$Red_BT_HOVER2 	 = $iTempDir & "\bt3_h2"

	$green_BT		  = $iTempDir & "\bt4"
	$green_BT_HOVER  = $iTempDir & "\bt4_h"
	$green_BT_HOVER2 = $iTempDir & "\bt4_h2"

	$purple_BT		  = $iTempDir & "\bt5"
	$purple_BT_HOVER  = $iTempDir & "\bt5_h"
	$purple_BT_HOVER2 = $iTempDir & "\bt5_h2"

	$BT_CLOSE	= $iTempDir & "\close"
	$BT_CLOSEh	= $iTempDir & "\close_h"
	$BT_CLOSEh2 = $iTempDir & "\close_h2"

	$BT_MINI	= $iTempDir & "\min"
	$BT_MINIh	= $iTempDir & "\min_h"
	$BT_MINIh2	= $iTempDir & "\min_h2"

	FileInstall(".\img\background.png",		$iMG_Bk,1)
	FileInstall(".\img\bt1.png",			$Grey_BT,1)
	FileInstall(".\img\bt2.png",			$blue_BT,1)
	FileInstall(".\img\bt2_hover.png",		$blue_BT_HOVER,1)
	FileInstall(".\img\bt2_hover2.png",		$blue_BT_HOVER2,1)
	FileInstall(".\img\bt3.png",			$Red_BT,1)
	FileInstall(".\img\bt3_hover.png",		$Red_BT_HOVER,1)
	FileInstall(".\img\bt3_hover2.png",		$Red_BT_HOVER2,1)
	FileInstall(".\img\bt4.png",			$green_BT,1)
	FileInstall(".\img\bt4_hover.png",		$green_BT_HOVER,1)
	FileInstall(".\img\bt4_hover2.png",		$green_BT_HOVER2,1)

	FileInstall(".\img\bt5.png",			$purple_BT,1)
	FileInstall(".\img\bt5_hover.png",		$purple_BT_HOVER,1)
	FileInstall(".\img\bt5_hover2.png",		$purple_BT_HOVER2,1)

	FileInstall(".\img\close.png",			$iTempDir & "\close",1)
	FileInstall(".\img\close_hover.png",	$iTempDir & "\close_h",1)
	FileInstall(".\img\close_hover2.png",	$iTempDir & "\close_h2",1)
	FileInstall(".\img\min.png",			$iTempDir & "\min",1)
	FileInstall(".\img\min_hover.png",		$iTempDir & "\min_h",1)
	FileInstall(".\img\min_hover2.png",		$iTempDir & "\min_h2",1)
EndFunc


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __exit_syst
; Description ...:
; Syntax ........: __exit_syst()
; Parameters ....: None
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __exit_syst()
;~ 	DirRemove($iTempDir, $DIR_REMOVE)
;~ 	For $i=0 To UBound($FULL_LIST)-1
;~ 		FileDelete($FULL_LIST[$i][4])
;~ 	Next

	FileDelete($iMG_Bk)
	FileDelete($Grey_BT)
	FileDelete($blue_BT)
	FileDelete($blue_BT_HOVER)
	FileDelete($blue_BT_HOVER2)
	FileDelete($Red_BT)
	FileDelete($Red_BT_HOVER)
	FileDelete($Red_BT_HOVER2)
	FileDelete($green_BT)
	FileDelete($green_BT_HOVER)
	FileDelete($green_BT_HOVER2)

	FileDelete($purple_BT)
	FileDelete($purple_BT_HOVER)
	FileDelete($purple_BT_HOVER2)


	FileDelete($aHoverBtn[1][1])
	FileDelete($aHoverBtn[1][2])
	FileDelete($aHoverBtn[1][3])
	FileDelete($aHoverBtn[2][1])
	FileDelete($aHoverBtn[2][2])
	FileDelete($aHoverBtn[2][3])
EndFunc


Func __IniReadSection($sFile, $sSection)
    Local $hRead = FileRead($sFile), $aSplit = StringSplit($hRead, @LF)
    Local $sSectionNames = '', $iStart = 0, $iEnd = 0
    For $iCount = 1 To UBound($aSplit) - 1
        $aSplit[$iCount] = StringStripWS($aSplit[$iCount], 7)
       	If StringLeft($aSplit[$iCount], 1) = '[' Then
            $aString = StringSplit($aSplit[$iCount], '[')
            $sValue = StringReplace($aString[2], ']', '')
			If @extended = 1 Then
                If $sValue = $sSection Then
                    $iStart = $iCount + 1
                ElseIf $iStart Then
                    $iEnd = $iCount - 1
                    ExitLoop
                EndIf
            EndIf
        EndIf
    Next

    If $iStart And Not $iEnd Then
        $iEnd = UBound($aSplit) - 1
    ElseIf Not $iStart Then
		Return SetError(0, 0, 0)
    EndIf
    Local $sKeyName = '', $sValueReturn = '', $sLine = '', $nSeperator = ''
    For $xCount = $iStart To $iEnd
        $sLine = FileReadLine($sFile, $xCount)
        $nSeperator = StringInStr($sLine, '=', 0, 1)
        If $nSeperator Then
            $sKeyName &= StringLeft($sLine, $nSeperator - 1) & @LF
            $sValueReturn &= StringTrimLeft($sLine, $nSeperator) & @LF
        Else
            $sKeyName &= '' & @LF
            $sValueReturn &= StringTrimLeft($sLine, $nSeperator) & @LF
        EndIf
    Next
    $sKeyName = StringSplit(StringTrimRight($sKeyName, 1), @LF)
    $sValueReturn = StringSplit(StringTrimRight($sValueReturn, 1), @LF)
    Local $aReturn[UBound($sKeyName)][2]
    $aReturn[0][0] = $sKeyName[0]
    For $iCount = 1 To $sKeyName[0]
        $aReturn[$iCount][0] = $sKeyName[$iCount]
        $aReturn[$iCount][1] = $sValueReturn[$iCount]
    Next

    Return $aReturn
EndFunc


Func __click_sound()
Local $bData = "0x5249464654D8000057415645666D7420100000000100020044AC000010B10200040010004C49535428000000494E464F49474E52060000004F7468657200495346540E0000004C61766635382E32372E313033006461746100D80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000100010001000100010000000000FFFF0000FFFF0000FFFF0000FFFF0000FFFF000000000000000000000000FFFF0000FFFF0000FEFF0000FFFF0000FFFF000000000000000000000100010001000100010001000000000000000000FFFFFFFFFFFF000000000000000000000000010001000100010000000100FFFF0100FFFF0000FFFF0000FFFF0000FFFFFFFF0000FFFF0000FFFF0000000000000000FFFF0000000000000000010001000100020002000300020003000100020000000000FFFFFEFFFEFFFEF"
	$bData &= "FFDFFFEFFFDFFFFFFFEFF0000FFFF020001000300020003000200020002000100010000000000FDFF0000FCFF0000FBFF0000FBFFFFFFFDFFFFFF0000FEFF0000FFFF0000FFFF020000000300020005000300050003000200030000000100FEFFFFFFFDFFFEFFFDFFFEFFFEFFFEFFFEFF0000FFFF0000FEFFFFFFFDFFFEFFFDFFFEFFFFFFFEFF0000FFFF01000000000001000000020000000200010000000100FDFF0200FAFF0400F9FF0400FBFF0400FEFF030002000200050000000700FEFF0700FDFF0600FEFF0500FFFF040000000400020004000200050001000300FEFF0100FBFFFEFFFAFFFDFFFAFFFDFFFBFFFEFFFEFFFFFFFFFFFFFF"
	$bData &= "0100FFFF0200FCFF0300F9FF0300F8FF0300F8FF0100F9FFFFFFFCFFFDFFFFFFFBFF0200FBFF0300FFFF0400020004000300040002000400010003000100020000000200FEFF0300FCFF0300FCFF0200FDFF0100FEFF0100FDFF0100FCFF0100FEFFFFFF0200FEFF0500FCFF0800FAFF0900FAFF0600FCFF0400FEFF02000000FFFF0100FDFF0000FCFFFEFFFBFFFBFFFBFFFAFFFAFFFBFFFBFFFFFFFBFF0300FDFF0600FEFF0900FFFF0A00FFFF0B00FFFF090000000700000004000100020000000000FFFFFEFF0000FDFF0300FDFF0600FDFF0700FDFF0600FDFF0400FDFF0100FCFFFEFFFBFFFDFFFBFFFEFFFBFF0000FBFFFFFFFBFFFFFFF"
	$bData &= "CFFFEFFFDFFFFFFFEFFFFFFFDFFFFFFFDFF0100FFFF0300010000000500FBFF0900F9FF0D00FBFF0F00FFFF0D0002000A0001000500FFFF0100FEFFFDFFFEFFF9FFFFFFF9FF0000FAFFFFFFFBFF0000FCFF0200FDFF0000FDFFFDFFFDFFFCFFFCFFFAFFFAFFFCFFF8FFFFFFF7FF0000F6FF0000F7FF0300FAFF0400FEFF0200030000000900FEFF0F00FDFF1300FEFF130000000E0002000800040002000400FEFF0400FBFF0400FAFF0300FAFF0200FAFF0000FBFFFEFFFBFFFDFFFBFFFCFFFBFFF9FFFCFFF6FFFDFFFAFFFFFFFFFF000003000000050000000500FEFF0300FDFF0100FDFF0100FDFF0300FFFF040003000500070004000B0003"
	$bData &= "000C0003000B0000000800FFFF02000100FDFF0300F8FFFFFFF6FFFBFFF5FFF8FFF4FFF5FFF7FFF7FFFAFFFCFFFCFFFFFFFFFF01000100010003000000040000000500FDFF0700FCFF090000000A0004000A0007000900070007000600040003000200FDFFFFFFF7FFFCFFF7FFFBFFFCFFFAFF0000F8FF0400F5FF0700F2FF0400F2FF0000F6FFFCFFFAFFF9FFFFFFFBFF0500050009000B000D000C0010000C00100008000D0000000C00FBFF0B00FAFF0A00FCFF080002000500070001000600FBFF0300F6FFFEFFF2FFF7FFEFFFF5FFEEFFF8FFEEFFFCFFF0FF0100F3FF0500F6FF0300F9FFFEFFFBFFF9FFFDFFF4FF0100F6FF0800FDFF0D0"
	$bData &= "002001000080012000D0012000A000F0001000B00FDFF0500FBFFFFFFFCFFFBFF0200F9FF0700F9FF0800F9FF0900F7FF0400F6FFFCFFF6FFF7FFF6FFF8FFF7FFFBFFFAFFFFFFFEFF04000100090005000A0007000600080001000800010008000100090002000A0004000A00070009000A000600080002000000FCFFFAFFF9FFF7FFF5FFF6FFF2FFF9FFF2FFFEFFF6FFFCFFFBFFFBFF0100FDFF0700FEFF0A00FEFF0B0000000900010006000200040002000100000000000000000002000100060002000A0003000D0004000B00030004000200FEFF0000FDFFFFFFFDFFFEFFFBFFFDFFF9FFFAFFFAFFF7FFFBFFF3FFFCFFEFFFFEFFECFF0100"
	$bData &= "EDFF0500F1FF0700FBFF070008000500110001001600FEFF1800FDFF1700FCFF130000000F000600090006000400050001000900FFFF0900FEFF0300FEFF0000FDFFFCFFFEFFFBFFFEFF0000FDFF0400FBFF0200F8FF0200F2FF0300EBFF0200E9FF0000E9FFFEFFECFFFFFFF4FF0400FEFF090008000800100002001300FAFF1200F7FF1000FDFF0E0001000C00FFFF0C00FEFF0B00FFFF0900FFFF0600FEFF0300FEFF00000000FFFF0100FDFFFDFFFCFFF6FFFDFFF5FFFCFFF7FFFBFFFBFFF9FF0100F8FF0800F6FF0C00F2FF0A00EFFF0500EEFF0300EFFF0600F1FF0800F5FF0900FDFF0800050007000C000600120007001500060014000"
	$bData &= "3000F0002000600FFFFFFFFFCFFFCFFF9FFFEFFF7FF0200F3FF0600F0FF0700F0FF0600F2FF0300F6FFFEFFFDFFFAFF0700F9FF0E00F9FF1000FAFF1000FCFF0A00FBFF0400F8FF0500F7FF0500F8FF0200FBFFFDFFFDFFF8FFFCFFF8FFFCFFFCFFFFFFFEFF0300FFFF060005000B000C000F000D00130007001600FEFF1500F9FF0F00F7FF0800F6FFFFFFFAFFF7FF0000F3FF0400F5FF0700F9FF0B00FAFF0D00FAFF0E00F8FF0D00F3FF0500EDFFFCFFE9FFF4FFEDFFEEFFF3FFF2FFF8FFFBFFF9FF0200FBFF0500FDFF04000000FFFF0800F8FF1300F0FF1D00EBFF2100EFFF1F00F4FF1600FAFF07000100F9FF0800F1FF0B00F0FF0900F6"
	$bData &= "FF0600FDFF050003000400060004000700080003000C00FCFF0E00F7FF0A00F6FF0100FBFFFCFF010001000300040001000100FEFFFCFFF9FFF3FFF6FFEAFFF9FFE5FFFFFFE5FF0600F0FF0C0001000E000D000A00140005001500FFFF1400FAFF1700F9FF1600FAFF0A00FAFFFFFFFAFFF4FFF9FFE7FFF8FFE2FFFAFFE5FF0000EBFF0800F7FF1100040015000D00120013000A00110000000500F6FFF7FFECFFEBFFE8FFE6FFECFFECFFF5FFF6FFFEFF010004000B0008001100080012000700100005000C0005000800060008000500080003000600020002000100FBFFFEFFF3FFFDFFF1FFFDFFF3FFFFFFF8FF03000000080004000A00050"
	$bData &= "00800070003000700F9FFFFFFF2FFF7FFF1FFF8FFF2FFFDFFF7FFFFFF0000FFFF0700FEFF0A0002000C0008000B000E0007000F000300090000000400FEFF0400FEFF0400FDFF0100FBFF0200F8FF0100F5FFFFFFF1FFF8FFF2FFE4FFF5FFD8FFF9FFE6FF0000F8FF080002000D0009000D000E00090010000400120001000D00050003000C00FAFF1100F1FF1200ECFF0F00F0FF0A00F8FF0400FEFFFEFF0400F9FF0800F8FF0C00FAFF0D00FDFF0A00FFFF0700FFFF0200FEFFF8FFFEFFF1FFFFFFF0FFFFFFF3FFFFFFFBFFFDFF0300FBFF0B00F8FF1300F7FF1200F7FF0B00F9FF0600FDFF0500030005000800050008000200050002000100"
	$bData &= "0400FDFF0400FBFF0200FDFF010002000300060001000700FCFF0500F7FF0200F1FFFDFFEAFFF7FFE9FFF4FFECFFF7FFEAFFFFFFEBFF0700F4FF0B00F9FF0F00FAFF1200FDFF1400030013000C00100013000C0014000800110003000800FEFF0000F8FF0100F3FF0900EDFF1200ECFF1900EEFF1800EDFF0F00EBFF0600ECFFFCFFEFFFF3FFF4FFEEFFFDFFEAFF0600EBFF0F00F0FF1600F2FF1800F3FF1600F9FF1300FAFF1100F9FF0F0000000F0009000F000D0010000E00100012000B00150000001500F8FF1200F4FF1000F2FF0B00F2FF0500F4FFFFFFF6FFFBFFF6FFFAFFF4FFF8FFF1FFF6FFF0FFFCFFF1FF0400F4FF0200FBFFFEFF0"
	$bData &= "200FBFF0600F4FF0700F0FF0800F3FF0A00F8FF0E0002000F000A0010000C0011000A00100003000F00F5FF0D00EBFF0700E7FF0400EAFF0300FCFF00000E00FDFF0F0000000A00020006000100030000000000FDFF0200F7FF0700EDFF0A00E1FF0C00DAFF1100DCFF1300E0FF1100E7FF1100F7FF0A000700FAFF1000F0FF1500F1FF1300FBFF0B00090004001000020009000400FFFF0B00F9FF1100F5FF1100F8FF1100FDFF100000000D0004000A0006000B00FFFF0E00F9FF1300F6FF1400F3FF1100F6FF0E00FFFF08000800FFFF0D00F5FF0E00EEFF0900E8FF0100E4FFFAFFE0FFF5FFE0FFF2FFE5FFEFFFECFFEEFFF3FFF2FFF8FFFB"
	$bData &= "FFFCFF0000020004000B0004001400FCFF1900FAFF1D0001001C00040018000300140003000B00FDFF0000F5FFF9FFF2FFF5FFF7FFF1FFFCFFEEFFFDFFEAFFFCFFE6FF0000E8FF0600EFFF0D00F4FF1400FAFF0F00FEFF0500FCFFF9FFFBFFE2FFFEFFD9FF0100EFFF0800FCFF1400FBFF1A000400180004001200F6FF0700F5FFF9FFF2FFF0FFE6FFEFFFF2FFFAFF07000D00120018001F001B00260018001B000D000F00FEFF0800F4FF0600EFFF0700F0FF0600F6FF0100F9FFFDFFF8FFF5FFF5FFE9FFEFFFDEFFEAFFDEFFEEFFE9FFF9FFF1FF0200F2FF0700F7FF0B00FEFF0D0000000B000200050001000300F9FF0400F4FF0300F2FFFEF"
	$bData &= "FEEFFFCFFEEFFFEFFF5FF020002000500100004001B0004001C0003001700FDFF1000F5FF0B00F1FF0400F2FFFBFFF5FFF5FFF7FFFAFFFAFF0400FCFF0C00FFFF1000020015000B0019001600150019000D00130006000E0000000700FAFFFBFFF2FFF0FFE5FFEBFFDBFFEEFFD8FFF5FFDCFFF9FFEAFFF8FFF8FFF7FFF9FFF5FFF2FFF5FFEAFFFCFFEAFF0800F4FF1000010015000A001900130017001C00130022001000250010002B0012003200170033001C002B0019001D0008000B00F3FFF8FFE2FFE6FFD9FFD6FFD4FFC8FFD4FFC1FFD8FFC1FFDDFFCBFFE3FFDAFFE8FFE3FFEBFFEAFFEDFFF5FFF6FF0100070009001C000A0029000400"
	$bData &= "2D0005002F001300310023002E0035002300460016004A000F0042000B00350004002600F9FF1700F0FF0600E7FFF1FFDEFFE0FFD4FFD4FFCBFFCAFFC5FFC7FFCBFFCBFFE1FFD3FFFBFFE2FF0D00F1FF1700FAFF1C0000001A000A001000170005002000FEFF2400FFFF230006001C000C000E001100040014000200120001000B00020004000500FEFF0800FAFF0F00F4FF1B00EAFF1F00E0FF1200E0FFFAFFEBFFE5FFF9FFD8FF0600D4FF1000DDFF1A00EFFF2400FEFF260008001F001100150013000B00130002001100FAFF0500F0FFF5FFE3FFEEFFDEFFE9FFE7FFE3FFF4FFEAFFFAFF0700FBFF2600FFFF35000500380008002A0006000"
	$bData &= "D000400F6FF0000F0FFF4FFF9FFE6FF0C00E0FF1E00EDFF210008001300220001003200F6FF3700F3FF2E00F5FF1A00030009000E00010001000000E7FFFEFFD8FFF7FFD8FFEBFFE5FFE1FFF9FFD9FF0500D0FF0300CBFFFBFFD4FFEFFFE9FFE6FF0200ECFF160004001F0020001E00320010003B0001002F00FBFF0C00F6FF0100F2FF12000E00F7FF4B00BDFF7B00CAFF80000A0070000F006300CAFF4E0082FF1A0072FFC7FFB1FF76FF330047FFD30054FF6201AAFFAC013A008C01D600100156016D009B01EFFF8E01C8FF3301EBFFBA0029005A005F0031007500370059004B00F8FF4A0064FF2A00DEFEEDFF9BFE9BFF9AFE42FFC6FEF5"
	$bData &= "FE01FFCBFE29FFC1FE2DFFC6FE1CFFD2FE16FFEBFE31FF0DFF78FF30FFE7FF67FF6000C5FFBD004300ED00C600F0003A01C6008D018000A5014200770122001F011D00C10024006C00240027000C00F2FFDFFFC1FFA3FF8FFF57FF68FF02FF4BFFBCFE26FF8EFEF1FE7CFEBBFE93FE97FEDAFE8DFE3FFFA2FEA0FFE8FEEAFF64FF190004002C00A4002A00200128005F014300670180005601D2003F011401270120010F01F000F6009B00DF003900BF00D7FF82008CFF23006EFFBFFF77FF73FF88FF43FF8DFF2FFF85FF3BFF74FF65FF5FFF94FF53FFADFF56FFACFF69FFA1FF82FF9AFF97FF98FFA3FFA0FFA3FFB8FF96FFDAFF8BFFF9FF94F"
	$bData &= "F0800B2FF0700DAFFF9FF0100E4FF1A00D5FF1E00D1FF0800D4FFE4FFD5FFC4FFD9FFB9FFE3FFBDFFEAFFC0FFE6FFBCFFE5FFBDFFF5FFD3FF1000010029002F0036004B0037005800310061002D0068003000620035004D003D00320048001E004E000F004600F7FF3500D6FF2200C3FF0A00BFFFE9FFB2FFC8FF9CFFB1FF8FFFA7FF91FFA8FF98FFB2FF9BFFC3FF96FFD5FF85FFDCFF7CFFD1FF90FFBCFFAFFFACFFB9FFA7FFB7FFA8FFC3FFA9FFD8FFACFFE8FFB6FFF3FFC4FFFCFFD3FFFDFFE1FFF4FFEDFFE0FFF5FFBCFFFCFF93FF060078FF0F006CFF160066FF1B0071FF1C008CFF0D00A9FFEDFFBDFFCFFFD0FFCDFFDDFFE1FFD9FFF6FF"
	$bData &= "D7FF0300E4FF0A00F5FF0C00FEFF08000600FDFF0D00F2FF0800ECFFFCFFF5FFF6FF0700F4FF1400F0FF1700E5FF1C00CFFF2500B4FF2200A0FF0D0098FFEFFF99FFCFFFA4FFB0FFB1FFA0FFAFFFA4FFA3FFB1FFA3FFBAFFB3FFC1FFC3FFCDFFC7FFDCFFC7FFECFFD0FFFEFFE4FF1000F5FF1D00F5FF2200E6FF1B00DAFF0B00D1FFF5FFC0FFDAFFB0FFB7FFADFF9CFFB2FF98FFB4FFA3FFB7FFAFFFBDFFC2FFBAFFE0FFB0FFF8FFA7FFFBFFA6FFF6FFACFFF9FFB6FFFDFFC6FFFEFFDBFF0900F3FF220008003C000E004E0009005D0009007200180089003200930050008C006700780074005C0070003900530015002300FCFFFAFFF0FFE9FFE"
	$bData &= "DFFEBFFF1FFF5FFFEFF07000900110006000700F7FFEFFFEDFFD7FFEBFFBDFFEAFFA6FFEBFFA3FFF3FFB7FFFAFFCBFFF6FFCCFFE6FFBAFFD7FF9EFFCEFF87FFCDFF83FFD3FF93FFDFFFAAFFF0FFC4FF0000DEFF0700F1FF0000FCFFEDFF0800DCFF1300D6FF1800D5FF1900D8FF2300E2FF3600F6FF42000E003E0027002F00400021004C0018003F000F00240004000700F9FFEDFFEAFFD5FFD7FFCDFFC6FFDBFFC0FFF3FFC1FF0800C7FF1500D1FF1800DEFF0F00E4FF0300DFFFFDFFD3FFF9FFCBFFF3FFC8FFEBFFC3FFE0FFBFFFD2FFC9FFC7FFE6FFC1FF0400C0FF1500CBFF1E00E5FF2900FFFF2D000B0021000B000F0008000400FDFFFD"
	$bData &= "FFECFFF4FFE6FFF1FFF2FFFBFF0400FFFF1400EDFF2300D0FF2700BEFF2100BDFF1E00CAFF2500E3FF2900FBFF200000001200F5FF0700EDFFFBFFE7FFEFFFDBFFE9FFD5FFEBFFDDFFF0FFEBFFF0FFF7FFE9FF0500DFFF0F00D6FF0700D4FFF0FFDBFFDDFFE7FFDCFFF0FFECFFF1FFFFFFEEFF0900E8FF0600E0FFF9FFDDFFE0FFE4FFC8FFF4FFCAFF0400E6FF1300F9FF2300F6FF2F00F1FF3000F5FF2B00F7FF2600F6FF1E00F3FF1300E5FF0A00D6FF0100D9FFF3FFE4FFDEFFDCFFCAFFC7FFBCFFC4FFB6FFD1FFB7FFDAFFBCFFE1FFBFFFEBFFC0FFEBFFC3FFD8FFC9FFBEFFD1FFA9FFD7FF9DFFDEFF9EFFEAFFAFFFFDFFC9FF0F00DEFF150"
	$bData &= "0E8FF0E00EBFF0500EEFF0400F0FF0300F0FFFCFFF1FFF8FFF8FFFFFF020003000300F8FFF9FFE7FFEBFFDFFFE3FFDAFFE0FFD1FFD7FFD0FFC7FFDCFFBFFFE2FFC4FFDCFFCAFFDEFFCEFFEEFFDAFFFAFFEAFFFDFFEFFF0600EAFF1100E5FF0900DEFFF4FFD1FFE9FFCDFFE6FFD8FFE0FFE8FFD6FFF6FFD5FF0600D9FF1100DDFF0E00DAFF0100CEFFF2FFBAFFE3FFA5FFD2FF93FFC2FF8BFFB6FF94FFB0FFABFFACFFBFFFA1FFC8FF90FFD0FF85FFE0FF86FFF1FF8EFFFCFFA0FF0400BFFF0B00DBFF0800E2FFFAFFD9FFE8FFD3FFDAFFD0FFD2FFC8FFCFFFBDFFD0FFB9FFCCFFBFFFBDFFC9FFAAFFD5FFA4FFE3FFB4FFEDFFC7FFE2FFC9FFC1FF"
	$bData &= "BCFFA3FFAFFF9AFFA2FFA3FF95FFB1FF8FFFC1FF98FFC7FFA8FFBDFFBAFFADFFCFFFA4FFE2FF9FFFEEFFA4FFFAFFBEFF0D00E6FF1E000A0021001C0019001B0009000800F1FFEBFFD4FFCFFFBCFFB7FFAEFFAAFFABFFB3FFB4FFCCFFC6FFDCFFD6FFD7FFDAFFCBFFD3FFC3FFCAFFBBFFC4FFB8FFC1FFC5FFC1FFE1FFC4FFF4FFCCFFF1FFD4FFE4FFD6FFDBFFD9FFD5FFE3FFD3FFF1FFE0FFF6FFFAFFECFF0C00DCFF0100CAFFE2FFB7FFC0FFAAFFA7FFA9FF99FFAEFF96FFB1FF9CFFB7FFAAFFC4FFB9FFCEFFBDFFCBFFB2FFC5FFA1FFC8FF97FFCAFF96FFC2FFA0FFB6FFB5FFB0FFD1FFA9FFE9FFA1FFF4FFA2FFEFFFB1FFE4FFC5FFDDFFD9FFD"
	$bData &= "9FFE8FFD6FFEAFFD6FFDEFFD3FFCFFFC6FFC3FFB0FFBBFF9FFFBCFF98FFC4FF9CFFC4FFAEFFBBFFCAFFB7FFDCFFBDFFDDFFC2FFD9FFC4FFD1FFC9FFBEFFCCFFABFFC6FFAAFFC0FFBBFFC4FFD1FFC8FFE5FFC8FFF2FFC9FFF4FFC9FFEBFFC0FFDEFFB3FFCDFFADFFBCFFABFFB2FFA9FFB2FFB1FFB5FFC5FFB6FFD7FFB1FFDCFFA9FFDAFFA4FFDAFFADFFDEFFBEFFE4FFCDFFEAFFD3FFEAFFD4FFE2FFD5FFD7FFD9FFD3FFDDFFD5FFE3FFD9FFE8FFDFFFEAFFEDFFECFFFFFFEEFF0500EFFFFBFFEBFFE9FFE4FFDDFFE2FFD9FFE5FFD5FFE8FFD1FFE4FFCFFFE0FFD1FFDFFFCFFFDDFFC9FFD6FFC8FFD0FFCBFFD2FFCCFFD8FFCBFFDCFFD0FFDDFFDE"
	$bData &= "FFD9FFE8FFCDFFE6FFC1FFDFFFC0FFDCFFCBFFDEFFD9FFE3FFE5FFEBFFEEFFF0FFF1FFEEFFE6FFE7FFD3FFE6FFC6FFE9FFC4FFE5FFC9FFD6FFD0FFC3FFD7FFB7FFDDFFB6FFE2FFB8FFE3FFBCFFD9FFC8FFC9FFDAFFC0FFE7FFC7FFE8FFD8FFE1FFE6FFDEFFEBFFDEFFEAFFDDFFE6FFDFFFDEFFE6FFD4FFEEFFD0FFF1FFD9FFEFFFE3FFEAFFE2FFE3FFDBFFDEFFDBFFDEFFE4FFE1FFE9FFE3FFE5FFE4FFE0FFE3FFE1FFE0FFE2FFDCFFDFFFD6FFD9FFD0FFD6FFCFFFD7FFD6FFD9FFE1FFDAFFE7FFD9FFE5FFDAFFDFFFE1FFD8FFEEFFD2FFF5FFCEFFF0FFCFFFE5FFD7FFDEFFE1FFDEFFE6FFDBFFE3FFD3FFDDFFD0FFD3FFD2FFC8FFD4FFBDFFD0F"
	$bData &= "FBAFFCAFFC1FFC2FFCEFFB9FFD9FFB6FFDEFFBEFFDCFFCBFFD3FFD2FFC9FFD2FFC3FFD3FFC1FFD8FFC3FFDAFFCCFFD3FFD9FFCCFFE6FFCCFFE7FFCDFFDDFFCAFFD0FFC9FFC6FFCFFFBFFFD7FFB9FFD5FFB9FFC9FFC4FFBFFFD5FFBFFFE1FFC4FFE1FFC8FFD9FFCBFFD1FFD2FFC9FFDAFFC5FFDBFFC7FFD7FFD1FFD3FFDAFFD9FFDDFFE6FFD9FFEBFFD4FFE2FFD4FFD4FFD7FFD2FFDDFFDBFFE3FFE4FFE1FFE1FFD8FFDAFFCEFFD8FFCBFFD8FFCEFFD8FFCFFFD5FFCAFFD1FFC5FFCDFFC8FFC8FFD1FFC5FFD6FFC7FFD3FFCBFFCAFFCAFFBFFFC5FFB8FFC1FFBBFFBFFFC3FFBEFFCAFFB9FFCFFFB0FFD7FFA9FFE1FFB0FFE2FFC2FFD5FFD4FFC3FF"
	$bData &= "D9FFBAFFD8FFC3FFDAFFD4FFDDFFDFFFDDFFE2FFD8FFE4FFD6FFE2FFDAFFD6FFE0FFC3FFE1FFB8FFDBFFBAFFD7FFC0FFD5FFC4FFD0FFCCFFC7FFD4FFC0FFD5FFBDFFCFFFB8FFC8FFB5FFC1FFC3FFBAFFDBFFB7FFE4FFB9FFD8FFBDFFC8FFC3FFC4FFD2FFC7FFDDFFC7FFD1FFC3FFBCFFC2FFB9FFBFFFCAFFBCFFD6FFC4FFC8FFCBFFB1FFC4FFAAFFB4FFB1FFACFFB9FFAEFFBCFFADFFB5FFA3FFB3FFA1FFC1FFB2FFD0FFC9FFD5FFD9FFD5FFD7FFD4FFC6FFD3FFB8FFCEFFBBFFC2FFD0FFB9FFEAFFBCFFF5FFCBFFE5FFE2FFC8FFF3FFB5FFF1FFB7FFDEFFCCFFC1FFE1FFADFFE6FFABFFDCFFB1FFBDFFB6FF96FFC1FF8AFFC9FFA3FFC6FFC4FFB"
	$bData &= "9FFD2FFA7FFD5FFA9FFE1FFD0FFE8FFF5FFD0FFE9FFB1FFBBFFB2FFAFFFC9FFDAFFE3FFF5FFEEFFCEFFD1FFA8FFA3FFB0FFA1FFBFFFDBFFC5FF0C00D2FFEEFFD2FFA6FFBAFF8EFFAAFFA0FFB8FFAAFFD4FFB9FFDDFFD5FFD0FFDDFFB3FFC8FF78FFAFFF55FFB1FF99FFD0FF0300CDFF0D0092FFBAFF59FF82FF48FFAAFF7AFFE3FFEAFFCEFF33009CFF1100A7FFD6FFDAFFE4FF04000E00F4FFE8FF90FF7AFF4FFF3FFF9AFF6BFF0100D8FF02005700C1FF72009DFFEDFFBAFF5AFFF8FF2DFF1C0054FFF4FFCAFF7AFF470032FF300095FF90FF2F001AFF66004FFF4900F9FFFFFF7000A8FF820075FF5B0061FFCFFF90FF22FF210020FF8200BF"
	$bData &= "FF4F003300BDFF300011FF260004FF81000800A700EA00C4FF6B0090FE55FF3EFE50FFD9FE6700F5FFB800D70070FF9A0079FEC1FF09FF98FFE0FF3C004300D200980097009800D3FF030093FF86FF81FFC6FFECFE580043FF2600320156FF1A02F3FE4700E0FEE7FD3CFFC9FDC50096FF9701DA00A9FFB800A2FDFEFFA0FEE0FE010101FEC5019FFEBD001F00A7FF530166FF44024CFF350220FF2D0096FF7BFD70006AFC8200E4FD45FF6800DDFD6A0179FEF4000C01D200B6026300F501AAFE86FFD4FDCEFC82FF5EFC5E011AFFC4007A01BEFEF400C1FDA8FF08FE7AFF39FFC1FF9801430026034001850141018DFEFAFEF8FC75FCAAFC91F"
	$bData &= "CB0FD8FFE3B00460016029F01AF0177029C0095014D0008FF18006AFC95FFB6FB67FF07FE45FFC6017CFEBB03EAFDAC0249FE1E00D9FE1DFE99FF82FDDD0041FE4E01ECFF910039016C00EE00D1009CFFB1FF8FFEB2FD53FED8FD33FFD5FFDD003D00ED0112FF3E017CFF1AFF5101F4FC25022AFCE50181FD1301430151FF4B0589FD6D0508FD080198FD3AFC94FE97FAADFF8FFC1B000D004CFF8602F2FECF03F900FF034C030101F402C0FBCE00C8F9F0FD23FDE3FA39014CFBFA01F2FF83003B03C2FEEB02E3FCDE0198FDE0FFE0026AFC4406CAFBC201E3FFDFFAFB02E2F8FA00CBFB76FE4C014CFF940592FFB203EDFD84FD5EFFBCFAB103"
	$bData &= "2CFEE504DD0214015B035FFB6A00B9F837FE0BFC65FD950147FC0304CFFBFA02D8FEB4FF0B05F3FB620730FBC500DEFD62F94B01E1FA3C0492005D05EB02DB010C0397FA29022EF761FF45FD3FFD7405A5FDBB04A4FE6CFEB7FE69FCB1FE6FFE6FFF84FF200032FFFC00F5FEB9039EFF3B050A009900D3FE26FA07FFECF96D03EBFEEB070B02CB0622004CFF6DFDA3F65EFFD6F4100355FBBD015A02CCFCA403A3FAF500A2FD5EFF36035C00AF05A0005D02BBFE75FE94FDBBFE25FE860064FFEDFFCA019AFD24041FFD1304D1FFE7010D0267FE9400DDFA30FDDDFA02FB05FFB2FBEF02DBFEED02FA00B4FFA5FF2CFDAEFDB3FD75FE15FFEC006"
	$bData &= "4FFCE019BFFBA006EFF4D0033FE7B005CFE2EFF6B01A9FE780407011304CA01F1FF0CFF40FAB3FE9EF65A0213F94C036F0178FED707E5F8430484F810FA70FE8EF525059AFC0505720673FE8106CBF9BAFD94FB42F93501BCFD4406AC015C053F016AFC580397F47C06C2F89402AA03BBFC0808CFFD38062E00500521FE9D0022FE97F5980206F3CD030100DEFEDB0BB5F9A70985F821019BF97EFC60FB50FBB1FE9AF97C0228F91805D4FDB7076703E709C703E007B80111FF4C00FFF236FEEEEFEDFD15FC5100F707F4FEA20572F894FEE0F5F0FCC4FD3EFE2409F7015F0C6C066B075F04D1FF2BFDC3F68CF907F4F1FAA6FE77FC27093FFEBB"
	$bData &= "065504BBFF5F081DFD2200B2FE52F5E00210F837046D03EBFE410B89F78D0B04F4C6025BF8CEF6BD0224F22E094FF62F06CEFF9DFEC70749FBF105CA0091004B069F02FF036F060604E102AD0895FB60033AFBD9F66E05A7F3C30B6EFAF001CF011EF5630574F3730791F938099F035102220CD1F3A007CAEF5CF7EBF663ED6DFB93F81802620D170FCD0E5D12ADFD1D044FF664F34EFB45F26DFEAC00AF00990E55FF801076F65E02CBF5ADEABF045EE4491077F6200658FC4FE885EA75CA23E5ABC47BF910E69D0F6E24F9121250BEFC4F437CDAB41CD5CF200AC0F3FD03F72DACF7FC47CFEFB430F6F2AA12DAF1AD0BBFE0250B99D3390736E"
	$bData &= "B2607251A57017E2E11E8C91793CB85EB69D3D9C79C0437CECE278600331B432C7106012B6F098D19690F19236906113264F38F17FBE19AEB19E4BFE3A2FDABF2F2132FF6A31086F4400678F05A0FCDE513146FEBCAF2CD08F1D0A71E6AE1C31D2C098F142E18D704990F59EAE00110E69BFB3917D508024E38225249D82D47256F243C1CAB1F231EB72D4605632DDADE410860CB21E542D311E2D6E77EE406F65CD982F2DDD1C4DE4BD531D068D785D9A7D9BFE721EA3AE3CCFBB9DABBEEDDDF6FCF0DEA8CCC49F1EEEC8EF81E13CC017127250D031B801D64FBB23569F73249241E82421B450F25D3479A05EB30DCEA3717ACDA03FB7BE350DF"
	$bData &= "730534DCDD2E0EF40B472B0A833A5B153F0ED61E9EDCE81C6EC2BF029BCEF3DDBBEB81CD05F413E0F3EDA1FDB5FFEA064225FFFEB83009F869139BF857F2310316E83111D6E677103FEA2100BF0086F9A81AA00CF11E3F257B185D29C311B121D8FE651D1DE6DB0C07DE2AE7AAE866C6CFFBB6C2BC126CDC43214C02A0137C15A6F0B00566DDDFEAD9E68DE6FBF1A6F622F04FFED5EA0BF539E5DFED27E489ED5BF1C5E7350086E39BFD0AEEFBF3A7FC7BF8BF0229040B0612FDCE099EE576057CE4F8F9D10735F8C42807043327E50994136004AF0A3405F30D4D0C110DA10A5205340906048617D40B62263B12D11D1A11A704CC044DF67BF0F"
	$bData &= "4FA7EE7E30053F3F8FC7604C9FA060F6B08F4151C1F7A19B224FF13BE0D6F04BCF6E6F591FD55F83313C60B4218AF1D1E0CE21A80FF8A0011F43FE408E367DD9AD44EE6C2D9D0EF51F0CBFB580353070608E302F504BDEFE70034E333FBD0EA57F29AFCC1EA4E071BEB580BDEF2D80FD9FD310E7F0B1805B7184203301F2A0DB21EF5157C1AA812B813E8070D0DFA06D508FD1267040A1710FD5C0900F668FA19F5B3F867FAA9002B0036043F055DFC6A0B33F4F10BD3F5A1FFC4FAACEE3BFBFAE9AFF700F862F6570CB1FD3B14EE04D40DCFFE8507EBF5EA0668FDC7031C1267FBB6215EF86620F304AC13201A200968223702BA1211FB80F8F0"
	$bData &= "F89EE9E7FC56ECD7FE60F3ABF908F417EE7FF5CFE535FD3AECCCFFA0F94FF636FE99EB73FBE1EBDFFBD2F7EB00630562026C07BBFC22FC1AFCE4F17E07D6F6AD0EB706A0054B10E4F6CA0DA8EFFC080DF4ED049BFF1FFC59075BF3080736F50E045C01F5015C0C69FF8708C4F886F35EEFCBDEA2ED45DE8DF636F19DFFFB05D2024310ED01E1128EFFEF11B300AB09C90571FD170894FA5B06EA0215050D0B6E05DC0C53051A0AB203BC04C703E5FD290732F84B06C7F780FE7AFC9CFAFBFF4BFEE3FE34FFA0FA6DF818F487F0CBEE36EEE9EF77F0F9F5D8F289FBEEF6FCFDB4FE13FD7902ABF9F0FC41F5F3F537F370F5A8F87EF96B033BFD190"
	$bData &= "95D00FE055E0514014B093F003E066702E1FFFC02F2FE25018902BA015F04B0052504F4062A050703C70635FE1C0467FC96FCA8FD8AF8170047FD62036103FA061402B405CCFB9EFD92F830F776FA81F88BFDD6FBBF009DFBDD05E2FB390928028705760A01FE100B2CF9190318F8F0FB83FAE9FA7A012DFD75099AFF7E0B9701C7060D04D20127072E00AC0784FE8C0398FB7CFEF9FB8DFCC7005FFD67049BFE720357FF3401BC008201C10213037802000266FF32FEF5FCA2FB01FCB9FB26FAD0FBA4F710FBA6F899FBA5FF80FD9B0756FEC20821FE6504EFFFA3025804DE04CB0716051F08BD003A0789FC670608FE5904FA035501E7071C00"
	$bData &= "36073C01D404CD01DC02DE00B300B3016BFD2F05AAF9FF0565F8DA003AFCE7FA2304E1F94B0BF7FB310B19FD8302E4FEEDF9F204EFF9210C70FFB80C0E038305A4040EFEF20774FC300BF7FE26081B0101FF090213F9290307FC4A031202C5FF7C0347FAD9FF2CF84AFB0BFB6BF8B7FE01F753FF02F76CFD6BF951FBBDFCB8F9A7FDB8F843FC80F9F8FB79FCD3FEA2FF4003EB00A805D700F0049D011D03340487006307D0FC7C0981FBF40805006A048507C6FDA50BACFA140987FD550235026FFC7804D2F99904C9FA7F0302FF89FF5503ABF89403F7F3CCFF42F67DFB43FD5DF99202E5F947034DFC6601F6FFFDFF7503FAFFF20337005B012"
	$bData &= "200BAFFB5008E011502FE048002B2060F01DC041300DF001002D2FD300502FD5305A2FDD001B6FE44FDA9FFDCF9CEFFC7F80AFE4FFAC5FA0FFD13F90FFF8EFA70FF25FD74FE21FFC2FCE8FF4FFB1FFE80FB8FFAA4FD44F9A3FF56FCEBFF2A0186FFEB03DAFE8203EDFC58011EFBB9FE1DFCD3FC24FF36FDBE0057FFFFFF9900A0FF36004F016AFFF40286FE4B02FBFC29009EFB99FED1FC38FE220162FEAD04E3FEFD02300046FDB60168F9120298FA5801E2FD8C0026FF9AFFB9FE41FE6AFF7AFD740159FE8D0219005C01300051FF9BFDFCFEF8FA760027FB2A018FFDCDFF87FFDEFDDAFF2BFDADFF63FE2C00E30041003C026FFE4200F3FBBD"
	$bData &= "FC3CFBD4FB6DFCE2FD02FE14FF6FFF0FFEBF00C1FD310183FFCD00B20018017CFFFE01FFFD8C01B4FEE1FFC3002BFF2D02DDFFA702B700650258015A0108027C005602D100BE01C801B7002A02ACFFA7015CFEF50094FDC500B5FED400D2007F00A001E8FFD000B6FFA9FFDFFFD5FE1BFF4CFEDBFC36FE7FFBF8FE64FD5A00C5004A015702F10007029CFF980191FE0001F6FE29FF810017FD250226FD83038FFF58046A02F90343046E028204B5003303E3FF580138001B00E000190065010C0113029D013A024901F0004B0153FFC30141FFFD009500EBFE4701E0FD160015FF62FED9002EFE280109FF4F005AFF82FF4DFFC7FE1B00E9FD950"
	$bData &= "197FD2D029BFE1501BE004FFF8D0262FEED0225FFA4024C01A4023303220283036C00C5021AFF01023A009001CB02B901AD0357029E02C2023C02E002E9020503AC02E7025001CE014700F3FF1100FEFE6500DBFF48012501A30249018F0382005503E5FF90025200D901C701DC001503D5FF1203B4FFAE019C00BDFFBF0152FE1602B8FD050198FDF4FE3BFEA3FC1200B7FA100264FA3E0273FC04004DFF09FD4B0044FB14FFF9FACDFDC9FB71FDDDFDABFC480066FBE800EDFB4AFFD1FE96FD8201AFFDDA01DFFE890057FF93FF22FFE0FFA4FFBD00C8006201F400CF01B9FFF501CBFE5601D4FF0600230213FF7F0329FFDA02A5FF0401FCFF"
	$bData &= "32FF920017FE260107FE6C00DBFE46FEADFF8DFCB5FFCAFC55FF5FFE20FFB4FF93FE74006AFD3E01DCFCF001D2FDEE0170FF450170005E00BF0081FF1E01CFFEAE0135FEB001BDFD0B01E0FD9A00D3FE7A00E5FFE0FF5E000FFF45003AFFCEFF2100D4FE2A0091FD1AFF0AFD3FFEF5FD05FE86FFA3FD23000AFD4FFF26FDFEFD2CFE3BFD2DFF48FD6AFFEDFD07FFB3FE89FE39FF64FE7CFFB1FE91FF2EFF56FFB2FFE3FE1B00DBFEF1FFAAFF34FF8C00A7FE5E0084FE53FF34FE65FED0FDD6FD39FE99FD46FF0BFEACFF25FF39FF030019FF080073FFB6FF47FFB5FF85FEC8FFF9FDB7FFEEFDD8FF6DFE1900AFFF2D007D016200D102B300A9028"
	$bData &= "500750101009200E1FF5400300057003F00D000BAFFA3014BFFBD01A0FF7B00360080FE820019FDF5001BFD460107FE3F00D4FE4EFE4AFF83FDBAFF8DFE3900F0FFB1004B00DA00EAFF7700DDFF090075004C001201F5001A01330198000B010A00F700C7FFEF00A1FFCC0050FFB7002BFF9500C5FFF0FFCD00F0FE390169FEB300A7FE000011FFDBFF30FF280026FF46000FFFCCFFCDFE03FFB4FED2FE71FFC6FFFE0028015202D7019602D001EE01F0011A016F02EA0069029E0155016F025A008D02A500160270018E01B6013801E201F6001502770088010F0063006200B0FFFB00C5FF09012000DF0065000501BB00350105010B01A70098"
	$bData &= "00E6FF5900D2FFA2006A001301E2005F01EF00BA019700EF012400630131000000C20081FE3B01E2FD250123FE810059FEB8FF5BFE2DFFABFEFAFE10FF18FF27FF22FF39FFDCFE88FFDCFEE2FF40FFF7FF21FFD5FF7CFEC5FF6DFE8DFF60FF14FF900024FFD900C6FF0C00F6FF4EFFDBFF3DFF65003AFF38012CFF47018EFF6E00FFFF8DFFF5FF99FF0C005E002001D7006C02AB00E401380097FFE9FF68FE3100ACFF02013301840135012001B1004000ED00D2FF85013C009C01EF003F015001ED007D019B007B011000BC0090FF3EFF8AFF13FEEAFF26FE260030FFE7FF360071FFA20027FF9B001FFF7F006DFF62000D00090073007FFF1D0"
	$bData &= "046FF6DFF5CFFF4FE08FF8BFE5AFE02FE7AFEE7FD9BFFB4FE6900B1FF2B00CBFF92FF20FF17FF9DFE65FE71FEADFD12FEA9FD94FD1BFEB3FD06FE9AFE8FFD98FFD5FD1700C0FE40000DFF8000B8FEBE0016FF87005600DBFF1B0141FFBF0028FF1A0097FFF4FF290018001A00140019FFE8FF04FEBDFFD4FD6BFF6CFEE4FE41FF9CFE1000CCFE8B00F4FE7800EAFE11004FFF98FF52002AFF3501F1FE4801FBFE910056FFB0FF3E0046FF8B0197FF6402B800F9010802A9001C02EBFFB4006E0098FF1E01F7FF0701B40089006C00160081FFA6FF16FF5EFF21FF62FFC2FEA1FF14FE1D00F6FD96006AFE5400E7FE36FF76FF56FE5B00A1FE3301"
	$bData &= "5DFF560167FFD2001FFF66009DFF7800F000C2002102ED006202D900E601B7006901CB00DB00E400B3FFC20074FEA60057FECB008BFFEB00E00096004D01BEFF100124FFBE00A4FF4600DF00CBFFAD01DFFF9C0143000E0144007E0029002F009F000C007301E4FFD901BBFF8401AFFF0401D1FF0301FBFF4001F0FFE400E4FFD7FF6400EFFE5B01C1FEED0113FF8A0188FF9F00EAFFECFFF9FFA0FFE5FF95FF7900DCFFCE018F00BD025B016A02A00166013801A900CA004A00D900EDFF0C01A8FF0201CFFF0601860069019D01D1014002BD01AD014701930008016900410146018501CE01340150012F00730024FFDEFFF2FEA4FFC4FFBDFFE"
	$bData &= "A00F6FF8101FFFF4B01080098006D00ABFFE900DDFEDD00D4FEFEFF90FFBEFE2E0007FE21004AFE99FF4DFF1BFF8E0013FF3B0148FFC90040FFB5FF2DFFACFE84FFFCFD3200FDFD8400E2FEC3FF590070FEA401FDFDCF01A2FEA10083FF32FF9100A2FEDC012DFF79024100C001C1004D004D000EFFECFF3BFE3E00C6FD820045FE3D00F8FF110092016100AD019A00AF005D00EDFF3800F9FF660070005B00A100220069005E006300AF00F00021006A0104FFF100A4FEBAFF5BFFD1FE3A00AAFE7900DEFE2900F4FEA3FFD7FE2EFFDEFEF8FE63FF25FF0D00E0FF1100D90051FF2801B5FE7F0016FF90FF2500E5FEE70089FE0801D3FEE6001C"
	$bData &= "00D2009E01C000E5014E00C4004CFF81FF48FEDEFE15FE8AFEC9FE57FE99FF82FEB0FF13FF2FFF87FFD2FE37FFC1FE5AFE9CFE19FE5DFEFAFE72FE0F002EFF2C003C0064FFDF00E3FEDE003CFF7E00F2FF0400C8000500DD01DE00AC02C401B002F1012002D9016C0129020F01AC025A01B502E2010B02FE012F017D0199009B003900E1FF1600C5FF4B00200084006E0078005F004900F1FF0B007EFFD3FF80FFE5FF10005700D100F0003401500101012101C7008E0014012B007E0149004A01BD008E003B01ECFF7B01D2FF53014C00E800FC009100650153006B01DBFF3F0139FFC50024FFB3FFFBFF92FE1C016DFE960153FF39015D00A90"
	$bData &= "0000175002C015E00C000FCFF1500C7FF2E007C005301B201660235026B02AD01F1011B01ED015601E401D6010801B90123003501660002015001380186015301EE00DA00A20020002301FBFF89014D00F5001400D1FF49FFF1FEF1FEB9FE77FF40FF4D001B00E000880017017E000501A800B3004C018100D601DB007B01670164007E01BDFF00013A0025002D0152FF630125FFAA00BFFF3D009900DF0032015B01560172000B0128FF98002FFF30002300C5FF3B0048FF13FFF3FE39FE0AFFC0FE55FFCEFF66FF4A005CFF570078FF56007BFFFFFF53FF42FF77FFEFFEE7FFACFF0A00C600AFFF250157FFEA007BFFD6002100C300EE003500"
	$bData &= "6A01A0FF7801B6FF7D012A00B4014C00B60115000C01DAFFF5FFC3FF2DFF000028FFB700A6FF6701EBFF22016BFFD5FF8FFEA8FE6FFE86FE49FFFAFE20001EFF3A00D9FECAFFC7FE31FF34FFB6FE7CFF98FEFAFEBDFE52FEC5FE8FFEA0FE5BFFBAFE96FF69FF32FF310024FF3400ABFF66FFBAFF92FED2FE66FE2DFEE1FEBBFE80FF91FFFEFFA6FF800057FFBA005EFF1F009BFF1DFFB8FFACFE2F00E6FE56012AFFFA0130FFEE0049FF43FFC8FFDDFE8400ADFF2B013800A0011600D9014300DF012F01CD01040299011A023A01A101D700D100AE00D9FFDE0040FF19015EFFD400C6FF1100DEFF61FFDEFF0CFF6900F7FE240137FFF500F4FFB"
	$bData &= "EFFB00084FE860012FE95FF6DFEF9FE51FFF2FE9800CCFEBF018DFEBF01F1FE6B0000003CFFFA0098FF620134017901BE028D0151038B01EC029101F001FC01A8008A027BFF9302EDFE250244FFCC0169008101B101A200ED0142FFD10098FE9AFF56FF57FF6C008EFF730077FF6EFF6CFF64FEEAFF23FE3200AAFE7CFF59FFBBFEC7FF6BFF4D00320145015D0212022702DD015A01FC00F0008B000001CD00F7001C01950022016C0021011C0148012F0283018C02AA01FD017B014701F600E600A3009700D800310015010700E30036008E00670077007600860077007A0052003E001600F4FF1D00E0FF6600160070003F00060002008DFF99"
	$bData &= "FF61FF87FF4CFFA4FF28FF6DFF78FF1FFF750055FF5A01EDFF5701570088006E00B0FF79006FFFA700C8FFBC0054007C00A900370089004F0015009B00D3FFA4000C0050009600100036013D009001830022016700E5FF060091FEB9FFF5FDA5FF2DFEC7FFAAFECEFF11FF50FF65FF71FE7CFFECFD40FF34FE3DFFD8FED0FF12FF5C00E8FE2E0021FF8EFFE4FF2FFF690013FF5300CEFE30008EFE4E00E4FE1400BDFF2CFF680065FE930090FE790058FF54000C000F00AC00A5FF5A018CFFB001400054013E0196004E01EAFF3F0071FF74FF4FFFF0FFD3FFC200CC0093004201B1FF8D003EFF53FF43FFBDFE14FFF7FEB0FE2CFF98FE02FFEEF"
	$bData &= "E0AFF65FF67FF9DFF57FF7AFFB9FE4FFF78FE91FFF7FE3D008EFFB300BEFF8E00C0FF4400E9FF410042001900BD0078FF4701E1FE9201D8FE4B012FFF93007FFFC1FFAEFFFCFED7FF6BFEE7FF3DFE97FF59FEF9FE9AFE7AFEF9FE4CFE3BFF55FE25FF96FEE6FE37FFD8FE320015FF0B0187FF37010300D2005A008B006E00B7005D00FD007E00DF00F60054007E01D0FFBD01BDFFA10116004C019B00EA00270185009D012500B901F8FF3E012F007C00AD001D00160147001A017C00B9006D004C00540043005D00AD005F00170168002C01D8001801A00109012C02CF003D026E0010027500B20128011B01F301A100160291008D019700E900"
	$bData &= "5C009C002900A7004400CC006D00D2007A00AE00A2006100E100F9FFEC00BAFFAC00DBFF3E002700CFFF5300C5FF670074007A0061016C00990130000801200086007C005500F100F7FF190183FF16019AFF12011D00DF004B00780001002C00F7FF2100A80038009A015A00F90177009F01710014014F00B7005C006E00C10037001F016C00FD000C01800062013700FF0060006500BB003500F6005200F0006900AD006A0043003900D5FF9FFF84FFC2FE57FF2AFE4BFF36FE65FFD8FE94FFADFFAEFF3100ACFF2900B7FFE4FFD6FFC3FFD3FFB7FF9CFFA3FF66FFC6FF5CFF30007BFF5E00A6FFFAFFC7FF90FFDDFFCDFF050081003F0004014"
	$bData &= "000FF00D7FF920072FF0B00A5FFBAFF4600B0FFAD00B0FFC000A6FFF200DAFF5001430057014000CC008EFF0D00F7FE78FF4FFF14FF3D00D0FEAC00B5FE2800D3FE37FF35FFABFEC4FFDBFE320068FF3300ACFFCFFF85FF53FF6CFFF7FE9AFFDFFEBAFF36FFA4FFE4FFC8FF5B0067002600FD008DFFF5003DFF6D0078FFE2FF010075FF9800FDFE00019DFEE100B5FE1B0041FF29FFACFFB8FE89FFE4FE1DFF3AFFE2FE70FFDDFEA3FFE4FEE2FF18FFE7FF92FF7EFFF8FFEBFEF6FFAAFEC6FFD3FEC0FF0FFFCAFF2FFFAAFF64FF8BFFCFFFC0FF2A0044003400BE001600D70018007C003300E8FF3E0075FF44004FFF61006AFF700095FF35008B"
	$bData &= "FFB5FF2BFF3AFFBCFEF3FEBCFECCFE36FFAFFEABFFAFFEB8FFDEFE77FF2AFF3AFF81FF29FFE8FF45FF400082FF4700D2FFF4FF2B008FFF720058FF6F005DFF1D00A7FFE7FF3D003D00E40003014101A2013901B10102014D01DA00EE00D500FE00F0007C012C01F8017601030293019A015D01070125018D0067015B00070286005602EF00FE014D0163016801E60033017500AF0000000A00C1FFA5FFC1FFB0FFADFFF1FF70FF2D0072FF7700EEFFC6006F00B0006C000B00160076FF1200A8FF88007500EA002301D100530194003301B000F1000801990029015100130153000D019C00F100D10067009C00B7FF200092FFE6FF0E002300890"
	$bData &= "05E009C0033008400FAFF88001A0081003D003100FAFFBBFFBEFF86FF1500B5FF9A00FFFF9300250019005600D8FFD100F9FF53012D0060016100F100D00077006F014D00C20179006E01D900D1004501B8008D0155018B0100025501370235012F024601F4015001000131017DFF1101D1FE0201C8FFD5003101880077016300AB007800E8FF86008AFF75002FFF5800E4FE1C0023FFB4FFE2FF5EFF7F003FFFA50027FF850002FF4600FEFECEFF17FF32FF1BFFCEFE2AFFB5FE84FFA4FEF7FF9EFE210001FF1500D5FF160094000500D600BDFFA70096FF3800EBFFA7FF750035FFA1002CFF5A0093FF06002000DAFF6800B1FF480078FF1C00"
	$bData &= "5BFF3F0072FF660087FF090072FF75FF71FF73FFC3FFE6FF2100E4FF0C0042FF7AFFD9FEE1FE0FFFAAFE53FFF9FE43FFB1FF3EFF5A0095FF7000FEFFFEFF210090FF040079FFCCFF92FF7FFFB3FF2CFFD9FF0BFFE5FF45FFBAFFB3FF62FFF6FF04FFE7FFC6FEC9FFDCFEDDFF5CFF120011004F00A600A200E400DA00AC0072002F0077FFF5FFD0FE4E001EFFCF00F9FFDE00A7007D00F800040000019AFFC0004AFF58003BFFF8FF74FF87FFB3FFE1FEC5FF63FEC7FF89FEE1FF1DFF01006FFF050066FFF4FF9EFFE9FF5300DAFFDA00AAFFA2006AFF1E0055FF05008EFF3200000013007F00CEFFD5001300EA00D500E2003401E200CE00CB004"
	$bData &= "5008500370052006C0073007A00A80082008C00B8002F00D300FBFF91001600440053004400780058006E00370058001C0073005300CB00A1001101A40008017000C200630062008F00FFFFA600DAFF8700220078008400AC009300D4007100A200770061007B0065003D005D001600E6FF660056FFC4004FFF9500BEFFFFFF1F009EFF5600A5FFAA00E4FF160140003401BE00E5003D0189007201720037018400CD009400A300C000D500150113014E011E01400100011E01C7000F017200F1002C00A80024003E003800BDFF260042FFF5FF0DFFD2FF38FFC3FF85FFA8FFB6FF7EFFDFFF65FF0F0081FF0F00C5FFBEFFECFF62FFCEFF58FFA3"
	$bData &= "FFA8FFB3FF2100F1FF97003400CE0084009C00D3004800DF0056009900C1004900EF000C00A000C1FF3C0084FF2200AAFF2D0020001A007200E7FF6600ACFF240076FFDBFF5EFF96FF81FF61FFCCFF54FFFBFF80FFECFFCEFFCCFFFFFFCAFFF4FFBCFFE7FF67FF010001FFF2FFF1FE7DFF38FF11FF8EFF28FFD2FF70FFF6FF56FFE4FF10FFB2FF38FF90FFAFFF75FFD3FF44FF94FF1CFF73FF29FF98FF51FFADFF72FF99FFA3FFA0FFFCFFCFFF5A00E5FF8300D7FF5900D3FF0200E4FFD2FFFBFFD2FF2200A9FF470036FF2600E8FEB4FF23FF50FFB2FF40FF290066FF63009FFF6C00FBFF40006D00FAFFAD00E2FF9F0011007A00450063003E0"
	$bData &= "030001D00C4FF2C0066FF6B0075FF8700DBFF4F002B00FCFF2600EDFFEDFF3600B9FF7A00AEFF5900E0FFEAFF3E00ABFF8D00D4FF9B001E007000450040005E00270089001B00AD001D00B7004F00C800A600E900D700E200C1009D00A0005D00A7006400BA009200B000AE009200B6007600BF006C00BB0078009A008B006C0095003400A600EFFFB500C6FF8100F1FF08005F00B6FFC700D4FFFD002A0005017B00F200D600DF002801DD002501E700D200F0009600E800A100B400C0005E00C7002C00C5003600BB003F008200310020005600E4FFB500FFFFD8003E0082005E000C006300D7FF6600E5FF58001C0020007100D5FFAB00B2FF"
	$bData &= "8A00D1FF360015001E005600520097006800D8001900EC00BEFFBC00DEFF8E0077009A000D01A6005A0170007C012500890111006801350024017C00EC00D800C40026018E003A01600018017700DF00BA009D00C8005B008D001E005900E6FF4D00D5FF32000600EFFF4A00C1FF6300CDFF6800E4FF8200E7FF82000E0035007400E5FFBB00FAFF860062001F00BA002700DE00B000FB002A0117014801FC0044019B0039013F00DD002100260024009EFF1800AFFF0D0015001F004F002F0048000D004500C4FF5C0091FF52009CFFF8FFCAFF82FFE3FF48FFE6FF5DFFF9FF8DFF2200CAFF39003B003600CE003A002B0155002F016B0008016"
	$bData &= "000D20044007F004D00300093002000DE003100E0000F009A00BCFF41008AFFE5FFA2FF8BFFEAFF52FF340041FF52003CFF20003CFFC2FF4CFF7FFF6AFF61FF8EFF40FFB3FF35FFBBFF8AFFA4FF4300AFFFFC000100520155002C017100C4007B007500A1006A00CE007F00EF0088000C019E001A01D900F80002019800D50023008000F1FF6400310077009E006100CB001B00A400FBFF5E0016000F001900C0FFD1FF94FF75FF91FF4EFF97FF64FF9DFF8FFFB2FFC1FFC5FF0E00B4FF680095FF7F009CFF3000D8FFD1FF2900D0FF5B0035005300AD002C00E7001700CC001B008600280056004C0047008F003500BA0028008C004B002D008D"
	$bData &= "000500AD002E00A100580086005E0068006400500063004E0019004D00A4FF1F008EFFCDFFFEFF98FF7B00AEFF9F0009008C007B007700C9005500CC0017007C00D5FFF2FFA8FF84FF9CFF91FFC3FF0D001D0084007600AB007F00950027006100CFFF2900D2FF2B0016008C004B000D016D003F019800FB00A300880070004800510053008F006A00E7006900EF007C00B000BB007A00ED006600DF005C00A80056006900680032008800190084002B00480052000E006C00130061003E0029005400EAFF5100E2FF470011001A003A00C1FF380083FF150092FFD6FFC2FF8AFFDEFF68FFEEFFA4FF000032000100C700E9FF1301CEFFF300C6F"
	$bData &= "F8200E0FF09001400CDFF3300E3FF17002100DFFF3600C6FFFDFFDAFF9DFFFAFF56FF040056FFEDFFB0FFC1FF3C009DFFA40093FFAA00A1FF4D00D3FFB9FF270052FF6E007EFF6E00190033007E00F5FF5C00CDFF0D00BCFFEBFFCCFFEFFFFBFF020025002B002A005F0009007F00DDFF7200CAFF2E00E3FFD5FF1200B8FF3100F7FF2E004F000E007800D5FF660096FF280071FFC9FF76FF71FF8EFF51FFA2FF76FFB4FFC7FFC8FF1A00CCFF4700AFFF3B0096FF0600B2FFCEFFF8FFBFFF2500D9FF2700EFFF2800F1FF3900020035001C0007000300D1FFB4FFBAFF8DFFBCFFBFFFB3FF09009EFF2500A4FF1000CCFFE7FFDAFFCAFFB8FFD6FF"
	$bData &= "ADFF0900D7FF3D00EDFF5000C4FF4900B5FF4000FAFF3F0042002F003900EFFF0200A0FFE4FF97FFDAFFF1FFC6FF5C00BCFF8700DBFF760000004800F5FFFCFFCEFFB1FFC3FFA1FFC9FFC8FFB5FFD7FFACFFBDFFF1FFCDFF5A0034007D009E004C00A30019005C00140030002A00430041005E0054006000640060006B006B005C0072002D007E00F7FFA000DCFFA100E4FF280001005FFF0F00E3FEEEFFFFFEA8FF68FF77FFD3FF64FF29003CFF4200F2FEF2FFC1FE74FFD5FE37FF20FF50FF89FF76FFE8FF81FF060092FFDCFFCAFFB2FF1300BFFF3600EAFF310002003500070051001900540047002C006B0018005900380025004F000B002"
	$bData &= "E0013000300160004000D001F00130031001B00490002006D00E1FF7900EFFF5F001D0045002C0049001300470005001A001F00E5FF4100E6FF500027005B007400690099006000960035008A0005007F00E0FF6000CAFF3100D6FF25001400490061005D00780036004900F3FFFBFFB1FFB6FF6CFF95FF49FFA8FF7EFFD9FFEAFFF2FF2F00D5FF2900A0FF04007AFFE0FF62FFB6FF50FF9AFF63FFBEFFB7FF2100260076006400880054007700280077001D0070003100450037001B00280020002F0042004F005F00570070003C006F00300046003E0008002E00E5FFF2FFEFFFBDFF1400A5FF2B008CFF160074FFE6FF8BFFD1FFD2FFD4FF0F"
	$bData &= "00B5FF21007EFF17008AFF0000ECFFD8FF4800ACFF4B00A1FFFEFFBDFF98FFDAFF45FFDDFF2AFFD0FF53FFBFFFADFFA3FF0B0088FF450082FF4D007EFF33005AFF0D0036FFE4FF50FFAFFF9EFF6DFFDAFF34FFEBFF33FFEBFF7BFFDEFFD2FFA7FFEBFF59FFD0FF36FFCAFF5CFFEFFF9DFF0600C1FFF1FFC9FFD8FFD3FFDDFFE0FFE8FFDEFFDCFFCCFFD2FFC0FFF3FFD6FF28000B003700360015002D00EFFFFFFFDAFFD8FFBEFFC2FFA1FFA3FFAFFF66FFE7FF18FFF1FFE8FE90FF0CFF14FF7DFF03FFE7FF61FF0D00B2FFFCFFBDFFD1FFC3FF87FFE5FF32FFE0FF0DFF95FF31FF54FF73FF62FF9DFFA8FFA6FFEAFFA2FF11009EFF150093FFF2F"
	$bData &= "F88FFBCFF97FF8CFFBFFF69FFDBFF5AFFCAFF67FF9EFF82FF86FF89FF99FF7CFFC2FF86FFCAFFC6FF9DFF1C0073FF3E0080FF0C00A3FFBAFFADFF93FFA9FFA2FFAFFFB4FFB1FFB2FFA4FFBEFF94FFE2FF7EFFF5FF67FFDBFF7BFFB8FFCBFFB0FF1900BAFF2600C7FF0000DFFFD6FF0500C3FF2100CBFF2100E0FF1F00EEFF3400EDFF5100ECFF5A00F7FF52000D004B002D0036004500F8FF4100B3FF2400AEFF0400F4FFE8FF4500C1FF640094FF4F008EFF1900D4FFC9FF3D0081FF6B0080FF4000DAFFFDFF4400D9FF5C00C8FF1800BFFFBEFFCBFF84FFE6FF76FFEAFFA0FFCEFF0400AAFF6A0089FF950078FF870097FF6300EEFF29004A00"
	$bData &= "CDFF78007CFF730076FF4B00B8FF0F00FBFFD2FF0900B1FFFDFFB0FF0500B5FF1500AFFF0100ACFFDDFFBEFFE0FFE4FF0A000C00280026002D002A00320017003E00FBFF3E00ECFF2200F0FFF5FFFAFFD3FFFFFFD5FF0200F4FF0700130006002500EDFF2100C0FFFEFFA6FFCFFFC0FFC3FFFCFFDBFF2300E4FF1F00D0FF0800CBFFEDFFF4FFC4FF2E0094FF480086FF2900ACFFE9FFDFFFC0FFF6FFCDFFFAFFF9FF02001D0004002700E8FF0600BEFFC0FFB4FF8FFFD9FF9EFF0500CCFF1C00DEFF1D00DAFF0800DFFFD4FFDDFF97FFB2FF7CFF72FF8DFF53FF9DFF69FF8AFF9BFF5FFFCEFF47FFF6FF5CFF090090FFF5FFB4FFC2FFAAFF9EFF9"
	$bData &= "4FFAFFFAAFFE7FFE2FF1900050026000B001700110001001700EAFF0300C6FFD9FF96FFAFFF79FF94FF8CFF90FFBDFFA8FFE7FFC9FFFCFFC9FFFDFF9FFFE1FF6BFFA4FF52FF5EFF5FFF36FF87FF42FFB9FF75FFE0FFAAFFDEFFBCFFABFFABFF69FF9AFF48FFA1FF5BFFB3FF90FFB9FFCDFFB2FF0400A3FF260099FF1F00AAFFE7FFDAFF9CFF040076FF0A0096FF0000D7FF0100FEFFFAFFFAFFD8FFE0FFB6FFBEFFB8FF9DFFD6FF93FFF6FFA1FF0200B1FFECFFBEFFBAFFDBFF9EFF0200C5FF16001B000C006500F2FF8100D5FF7100CFFF4100F9FF05004500DEFF7D00DCFF7F00F6FF57001D0024004300F9FF4E00E3FF2E00F0FF0500230008"
	$bData &= "00630036008C0053008A0033006100F4FF1A00D8FFC7FFFEFF91FF3F0096FF5700C6FF3400EDFF0300FEFFE7FF1500D5FF3700C1FF3D00C4FF1600ECFFE9FF2100DDFF4A00EAFF6400F6FF5C0005001D002400D0FF4B00C0FF5C00F9FF4C0034001B003900D5FF17009CFFF6FF9EFFE0FFEBFFD8FF4F00EAFF79001A004D004900FAFF5200BDFF3200A6FF0A00A6FFF7FFBEFFFFFFFEFF10004C0016006D000B004400F9FF0000ECFFDEFFEAFFE8FFF0FF0600EDFF2900D2FF4900B2FF4300B6FF0700E6FFBBFF16009CFF1500ADFFEAFFC2FFC1FFBFFFB7FFB5FFD5FFC1FF1200E4FF4D0007005500170020001A00E8FF1D00E8FF1D001200210"
	$bData &= "039003C005400670070007100770044004D00120005000400D2FF0B00CDFF0E00E7FF13000E0019002A0008001D00E0FFDCFFB7FF96FF94FF85FF7CFFA5FF87FFC7FFB9FFDCFFE4FFF8FFE5FF1300D3FF0600CFFFD8FFCEFFB7FFC3FFB1FFC9FFB4FFF8FFB8FF2E00C8FF3800D9FF1C00E2FFFDFFEEFFE0FF0800B8FF0F009EFFEAFFB2FFB3FFE1FF99FF0100A2FF0B00B2FF1300C2FF1100DDFFF2FFF3FFC1FFEAFF9AFFD2FF90FFDDFFA3FF1500C0FF4900CBFF4F00BFFF2300BAFFDAFFD2FF90FFFCFF6AFF20007EFF2D00C3FF1F001F00FEFF6E00E0FF8000D3FF3A00E1FFC9FF0D0082FF45008FFF5E00D4FF3B002300F6FF5900C2FF6700"
	$bData &= "B4FF4D00BBFF1C00C9FFEBFFE4FFCAFF1100CBFF4200F9FF570039004400580026003C001B0009001F00E8FF1700DCFF0700D1FF0900C5FF1D00C9FF2100DCFF0800EFFFEFFF0400E7FF1800DDFF1700C1FFFCFFB3FFE8FFCFFFF3FF02000D0021001E00250026002200270026001C0034000D00450012004B00390042007C003D00C0004F00DE006700C300750081007F0041008C0019008A00090072000D0054001F003F0038002C004300180026000800E8FFF4FFC1FFCCFFDDFF9EFF130094FF1700BAFFE5FFE9FFBDFF0100BBFF0C00C5FF2100D3FF3700090033005D0013008900F0FF6500E5FF2100FEFFF5FF3800E8FF7300EBFF84000"
	$bData &= "0005D001C001D002000E6FF0F00C8FF0900CDFF0E00F8FF01002000E7FF1800E0FFEDFFEAFFCEFFE8FFC5FFD8FFBBFFCDFFBDFFCCFFEBFFDBFF330001005400250034002300FFFF1200EDFF21000700430028004900330034002B0029001F001D001300F2FF0700C1FFF8FFBDFFE6FFD8FFD5FFE1FFCDFFD1FFC5FFBFFFB1FFABFF98FF92FF92FF93FFAAFFB7FFCBFFC9FFD5FFA9FFBEFF8CFFA0FFAEFFA6FFF7FFDAFF23001B0021004000110034000800F9FF0200B8FFFDFFAAFFF9FFD3FFEAFFFAFFC4FFF8FF93FFE9FF72FFE4FF71FFCDFF8AFF93FFA5FF5BFFB7FF57FFC6FF81FFD2FFAFFFC0FFBFFF91FFB2FF73FF97FF86FF88FFACFF9B"
	$bData &= "FFC3FFCAFFD3FFF1FFE3FFF6FFE7FFF1FFE6FF0000FCFF1A002000200030000C001F00F3FF0000E6FFD5FFDDFF9CFFCEFF70FFB9FF81FFB4FFC9FFCFFF0400FAFF03000E00E7FFFFFFE8FFEAFFFBFFE0FFF2FFDBFFD6FFDAFFD6FFE8FFF3FFF9FFFCFFF3FFE3FFDAFFD9FFC9FFF8FFCEFF1B00E5FF1F0001001300170019001F002700230027002B00220031002B0024002E0007001100EBFFE7FFDDFFD2FFDFFFD1FFEFFFC9FF0600BEFF1600C5FF1300E2FFFFFF0000EFFF1300F2FF1E00FEFF210001001500FFFF07001000170031004000420052003700380020001C001400200018002800270016003800FAFF4400F1FF4200F9FF2C00FEF"
	$bData &= "FFFFF0000D4FF0800C8FF0900D6FFF0FFE0FFC5FFDDFFADFFDAFFBCFFDEFFD1FFE0FFCCFFDFFFBBFFE2FFBBFFE9FFCAFFEDFFD1FFEBFFDCFFE8FF0700E2FF4000D5FF5400C1FF3C00BBFF2100CFFF1600F3FF03001800E2FF3600DCFF4700FBFF3E0010002200FEFF0600E7FFEEFFF0FFDEFF0900DDFF0E00E5FFFCFFDFFFEFFFCDFFFFFFCDFF1C00E6FF1A000200ECFF0F00BCFF1000B0FF0700C1FFF6FFCCFFE9FFC3FFE1FFB1FFD6FFA6FFCCFFA0FFC8FF92FFC2FF82FFB1FF89FF9EFFA9FF97FFCCFF97FFE3FFA0FFF1FFBDFFF0FFE3FFDAFFEDFFBBFFD4FFAFFFC4FFC2FFDBFFE8FFF9FF0200EFFFF3FFCAFFCAFFB7FFB9FFB9FFD2FFB6FF"
	$bData &= "F8FFADFF1300B2FF1F00C5FF1500D3FFECFFDAFFB9FFE1FF9CFFE6FFA0FFE5FFB4FFDAFFCAFFC2FFD4FFA2FFC1FF95FF91FFA5FF69FFBAFF72FFC2FFAAFFBEFFD8FFB1FFD8FF99FFBBFF83FFA6FF81FFA3FF92FFA0FFA5FF97FFB4FF99FFC6FFB5FFDCFFD3FFF6FFCAFF0A00A1FF050090FFDFFFAAFFAFFFC8FF97FFCEFF98FFC5FF9AFFAFFF8FFF82FF87FF5DFF8FFF6DFF92FFA3FF79FFC2FF4EFFB3FF39FF8EFF4DFF6CFF79FF58FFA4FF5CFFB9FF7EFFB4FFB2FFA2FFDEFF9DFFF0FFAFFFE2FFCEFFC0FFEBFFADFF0600BEFF1400E5FF05000A00DAFF2900ABFF380094FF1B009BFFD9FFAEFFAAFFC7FFAFFFEBFFCFFF0E00E6FF1400EFFFF"
	$bData &= "CFFEDFFE5FFDEFFDEFFCDFFD5FFC2FFBFFFBFFFB2FFCBFFBAFFECFFCAFF0A00DAFFFFFFEFFFC5FFFDFF7FFFF2FF5CFFD5FF79FFBEFFBDFFB1FFE7FF9FFFCDFF8FFF89FF96FF51FFACFF49FFACFF68FF8DFF94FF69FFB4FF57FFC2FF51FFBDFF5BFFA9FF7EFF9AFFB1FFA8FFD4FFCCFFD9FFEDFFCEFF0A00C6FF2B00C9FF3B00E1FF24000D00FEFF3700F0FF4300F7FF2600EBFFF1FFCAFFC6FFBCFFB5FFCFFFB5FFD4FFAEFFABFF9CFF85FF8BFF94FF8BFFBAFF9CFFCAFFB0FFD5FFC4FFEEFFE1FFF1FF0700CFFF1B00B7FF0E00CEFFF1FFF8FFE1FF0D00E7FF0900F4FF0100F9FFFBFFF8FFEEFFFEFFD9FF0F00D9FF1B0008001A0043000F0050"
	$bData &= "0000002900EDFFF8FFDFFFDAFFDFFFD1FFE1FFDEFFD4FFF2FFBEFFF5FFB2FFF0FFB5FFF8FFB9FF0100BEFFEDFFCAFFC7FFDBFFB2FFDEFFACFFCAFF99FFB1FF7BFFA7FF71FFA3FF8CFF9CFFACFFA3FFAFFFC4FFA4FFE7FFB5FFEBFFE6FFD7FF0E00CAFF1200D2FF0900E6FF0B00FCFF18001200260023003A00270057001A00660005004E00FDFF25000D00100028000E00300002001C00F0FF0500FBFF040020000B00300006001000FDFFDFFFF7FFC6FFECFFCDFFDBFFE2FFDAFFF5FFEAFFFDFFF5FFEEFFF5FFC9FFF7FFA6FFF5FFA2FFE2FFBFFFC7FFF1FFB6FF2C00B6FF5400C4FF4200E1FFFCFF0100C8FF1600DEFF21001F0020004C00050"
	$bData &= "05500D4FF5100B6FF4100CBFF1400FFFFD0FF1E00A3FF1B00A8FF1800C9FF2200E0FF1E00E4FFFDFFE1FFDAFFD8FFCEFFC7FFD1FFBAFFC8FFC4FFB7FFDEFFB0FFEEFFB4FFEDFFAEFFEDFF99FFF0FF92FFDFFFADFFBFFFCEFFB3FFD9FFC4FFDCFFD9FFEDFFECFFF4FF0C00E0FF2A00C8FF2000C8FFF1FFDDFFCFFFFFFFD7FF1E00F6FF22000B0007000E00E4FF0700CEFFFAFFC2FFE5FFC1FFCEFFCBFFC4FFD4FFCBFFD8FFD7FFDCFFDDFFDAFFE6FFCBFFEEFFBCFFE4FFB2FFC4FFA3FFA4FF92FF95FF95FF95FFA6FF95FFB3FF90FFBBFF8FFFC4FF96FFCCFF9EFFC8FFA7FFB7FFBAFFA2FFD2FF99FFD2FFA4FFB6FFB5FF9AFFB9FF96FFB0FFA6FF"
	$bData &= "9FFFBEFF8AFFD8FF7DFFEFFF88FFFBFFA6FFF4FFC2FFD9FFCAFFBEFFBFFFBBFFB1FFCEFFABFFD8FFA7FFCBFF9CFFB8FF96FFB1FF9AFFB7FFA6FFC1FFB8FFC1FFD1FFB2FFDAFFA6FFC3FFB4FFA5FFD3FFA3FFE3FFB4FFD7FFC3FFBFFFD4FFAEFFEEFFABFF0100B6FFFDFFCBFFE5FFE1FFC9FFF3FFB8FF0300BAFF0D00CCFF0A00E2FFFAFFECFFE9FFE2FFEAFFD9FF0000ECFF1C0015002500340015003B00040033000C001E002B00FFFF4700E8FF5800ECFF5F0005005000240025004200FFFF4E00FFFF3E0017001D002B0002003D00FBFF5100090053001F003400210009000500E4FFE6FFD0FFDFFFDEFFEDFF1500F7FF4D00FBFF570003003"
	$bData &= "A000B001C0008001100FEFF1200FFFF15000A000F001600060020000B0029001F00250025000F001500F4FF0900E5FF0B00E6FF0500F0FFF0FFFAFFDAFF0000CFFFFFFFD4FFFAFFF3FFF0FF1D00EBFF3000F9FF240014001B00240031002A005500390064004C00580055004E005A0063006B008100780079006E0050005800420048006A003D0096002B0098001200800001006E0003005D000D00390019000D002D00F7FF4300FAFF4500FEFF2A00FDFF02000300DBFF0E00B1FF080093FFE9FF98FFC0FFBEFFA3FFE5FF99FFFEFF9FFF0500B7FFF8FFE0FFD6FF0700AAFF090082FFE2FF73FFB6FF85FFA4FFACFFA0FFD0FF92FFDEFF88FFD3"
	$bData &= "FF98FFB9FFC0FFA7FFE9FFABFFF9FFBFFFEBFFCFFFD7FFCCFFDAFFB9FFEFFFA8FF0000AAFF0600BAFF0900CEFF0600E9FFF6FF0500E0FF0D00D6FFFDFFEAFFECFF1D00E8FF4F00EBFF5500FAFF350019001C00340019003B0019002D00130011001100F3FF1000EBFF0400FAFFF7FF0900F7FF0A0006000700240000004900F7FF5B00FCFF440012001A0029000A0034001E003600410027005E000C006E000100620015003400330000004000EBFF3900FBFF1F001700F4FF2800C8FF2000B6FF0200C6FFE0FFEAFFCBFF0400C8FF0000D7FFE1FFF4FFBDFF0400A2FFF2FF92FFD1FF93FFC3FFB1FFCBFFDFFFDAFFFDFFF5FFF3FF1F00D5FF360"
	$bData &= "0CCFF1C00E0FFE1FFF5FFBCFFFEFFC6FF0000E8FFF1FFF9FFCAFFF2FFACFFE7FFB4FFE2FFD0FFD5FFDFFFBFFFE0FFBDFFE3FFDEFFE5FF0900E1FF1900DDFF0800E4FFEBFFF5FFE0FF0600ECFF05000600F1FF2100DEFF2C00E1FF1F00FDFF0E001F0016002F00370023005C000A00740005007C0019007200360057005300370073002A00870045007A00790056009A003B0092003B0075004F00590069003A0070002100530021002400350000003D00EFFF2D00E6FF0F00E3FFE9FFE8FFCAFFE8FFCDFFE1FFF1FFE0FF1000E8FF0C00E9FFE8FFDCFFBFFFCCFFA8FFC3FFA4FFC2FFAEFFC7FFC3FFCDFFDDFFCDFFE6FFC5FFD4FFBBFFC3FFB1FF"
	$bData &= "C9FFA7FFD6FFA3FFDAFFA4FFDAFFA3FFD8FFA1FFC9FFAAFFB6FFC1FFB1FFD4FFBDFFD2FFD0FFC1FFE6FFB3FFFCFFB3FF0C00BAFF1500C0FF1900C6FF1300D2FF0200E3FFF0FFF6FFECFF0600FDFF12001C001E00320025003800190037000600300005001A00170000001D00FBFF0B000D00FAFF1B00F8FF1200F4FFF5FFE7FFD3FFE4FFBBFFF1FFB3FFFAFFBDFFEFFFD8FFDCFFFBFFCEFF0E00C2FF0A00B0FFF7FFA0FFDFFFA0FFC1FFAEFFA4FFB8FF8DFFB3FF82FFAFFF88FFB1FF96FFABFF9DFF90FF97FF6CFF97FF56FF9EFF50FF9CFF52FF8EFF5DFF87FF7DFF91FFABFFA2FFCAFFB1FFC8FFB9FFB7FFBEFFB7FFC6FFC0FFCFFFBAFFD0FFA"
	$bData &= "BFFCAFFA9FFC9FFB9FFCDFFC6FFCAFFC2FFC3FFB4FFC5FFB2FFD4FFC6FFE6FFDCFFECFFDCFFEAFFD0FFEAFFD5FFEFFFECFFF1FFFAFFEAFFF7FFE5FFF4FFECFFF6FFF9FFF9FF0000F8FFFBFFF7FFEFFFF7FFEAFFFCFFF8FF09000F0019001F00200022001D00210012001D0002001300F4FF0500F4FFFAFFFEFFFBFF0600050006000C0002000C00F8FF0F00E8FF1700D7FF1D00D0FF1700D6FF0800DFFFF9FFE3FFEEFFE5FFE1FFECFFD5FFECFFD3FFDBFFDCFFC0FFE5FFAFFFE2FFA7FFDAFFA3FFD3FFA6FFBDFFB3FF99FFBBFF84FFB5FF91FFACFFABFFAEFFB6FFB5FFB6FFB4FFC0FFB0FFD0FFB5FFD3FFC2FFCAFFCBFFCAFFCBFFD7FFCFFFD8"
	$bData &= "FFE0FFC9FFEEFFC6FFE2FFD9FFC0FFE5FFA5FFDBFFA0FFD6FFA8FFE1FFB2FFEAFFC1FFE5FFDAFFDBFFEAFFCEFFE7FFBFFFD9FFBFFFD5FFCAFFD8FFCAFFD6FFBBFFD2FFB8FFD7FFCCFFDCFFE5FFD4FFF2FFC7FFF7FFC2FFFEFFC4FF0300C6FFF8FFC7FFDBFFC9FFC1FFCAFFC0FFCEFFD0FFDAFFD8FFE7FFD1FFEBFFC5FFDDFFB3FFC0FF97FFA3FF7AFF8CFF70FF7DFF79FF7CFF7DFF8DFF7BFF9FFF87FF9FFF99FF91FF8CFF86FF61FF7EFF46FF72FF52FF6BFF67FF68FF6EFF5BFF73FF4AFF78FF49FF7AFF5BFF84FF6CFF91FF73FF87FF7CFF69FF8DFF59FF9EFF65FFA1FF7AFF95FF90FF86FFA4FF7DFFA6FF77FF94FF71FF85FF79FF80FF93F"
	$bData &= "F80FFACFF8AFFB6FFA4FFB4FFBEFFAFFFCDFFA5FFD3FF98FFD5FF93FFD1FF9CFFC7FFB2FFBFFFC8FFB9FFD3FFB8FFD4FFBEFFD2FFBDFFCAFFABFFBFFF90FFB6FF83FFB1FF8EFFA9FFA5FFA3FFB8FFA5FFC1FFA8FFC7FFAAFFCEFFAAFFC9FFA6FFB7FF9EFFABFFA3FFAFFFB8FFB7FFC7FFC0FFC3FFCBFFBAFFCDFFB5FFBEFFABFFAEFF9AFFB0FF8FFFBBFF94FFBBFFA8FFA8FFC0FF8BFFCCFF77FFC3FF77FFB2FF7AFFA5FF73FFA1FF70FFA1FF86FF9CFFA8FF8DFFBAFF7CFFB6FF72FFABFF6AFF9CFF65FF8CFF71FF84FF91FF88FFABFF93FFAEFF9EFFA5FFA8FF9EFFB1FFA1FFBDFFB2FFC9FFC8FFCBFFD2FFC5FFD1FFC3FFD4FFCEFFDBFFDAFF"
	$bData &= "DCFFDBFFDAFFD8FFE1FFDDFFEDFFE4FFF5FFDBFFF7FFC3FFF1FFB8FFE9FFC9FFECFFE9FFFFFF02000F0007000F00F3FF0800D2FFFFFFBAFFF7FFBAFFF7FFD0FF0000F1FF07000E0000001600ECFF0700D7FFEEFFCEFFCCFFD4FFA2FFE7FF8EFFF8FFA8FFF4FFCDFFDDFFCFFFC5FFBEFFB3FFC1FFA8FFC9FFA2FFBAFFA3FFA7FFA2FFA4FF97FF9AFF89FF7FFF85FF70FF8EFF80FF9FFF9CFFB3FFB4FFBDFFCEFFB5FFE4FFA5FFE1FFA2FFC5FFB6FFA7FFDAFFA0FFFAFFB2FF0600C8FFFEFFD1FFECFFD7FFD5FFEAFFBFFFFAFFB6FFEDFFBDFFD1FFCBFFC4FFD8FFBEFFE4FFA4FFE8FF82FFDAFF7DFFC2FF97FFB7FFB2FFBEFFBFFFC6FFCCFFC2FFD"
	$bData &= "DFFBBFFE7FFBFFFDFFFCAFFCFFFCFFFC6FFCDFFCAFFD1FFD4FFDEFFDCFFE3FFE1FFD3FFDDFFBDFFC7FFB8FFADFFC8FFAAFFD9FFC0FFDFFFDAFFDEFFEBFFDEFFEEFFDBFFDDFFD6FFBEFFD7FFA7FFDCFFA8FFD9FFB8FFCEFFCAFFCAFFD7FFCEFFDAFFCEFFD0FFCAFFBBFFCAFF9CFFC9FF77FFB8FF5CFF9AFF5DFF84FF72FF7CFF8BFF79FF9EFF76FFAAFF7EFFA7FF99FF9DFFB6FFA1FFC1FFB6FFBFFFC8FFC3FFCBFFCDFFC6FFCCFFBCFFC3FFAAFFC9FF97FFDCFF96FFE9FFA7FFE8FFB8FFE3FFBBFFE0FFBBFFE0FFC7FFE5FFDDFFEFFFEFFFF8FFF0FF0000E3FF0000D3FFF6FFC8FFF0FFC3FFFAFFC2FF0000C9FFF1FFDBFFE1FFF0FFE8FFF7FFF5"
	$bData &= "FFE2FFEFFFBAFFE5FF9EFFE9FFA7FFEEFFCBFFE7FFEEFFDDFF0600D7FF1800CEFF1900C9FFFBFFD7FFD5FFF7FFC8FF0C00DAFF0700ECFFF4FFEAFFE1FFDFFFD4FFD8FFD2FFD4FFDBFFC6FFE8FFAFFFF0FFA2FFF4FFA6FFF2FFABFFE2FFA5FFC3FFA1FFA8FFA6FF9FFFA8FFA0FFA1FFA0FFA3FF9DFFAAFF96FFA2FF88FF8EFF7DFF89FF7FFF93FF88FF98FF8EFF92FF92FF89FF97FF81FF9CFF79FF9EFF78FFA5FF83FFB3FF93FFBBFFA2FFB5FFADFFA6FFB2FF9DFFB6FF9BFFBDFF9BFFBEFFA3FFB7FFB6FFB5FFCFFFC0FFE2FFC9FFF0FFC8FFFAFFCAFFFDFFD1FFF6FFCFFFECFFC7FFE5FFCDFFDFFFDFFFD7FFE0FFCDFFCDFFC3FFB7FFB6FFA8F"
	$bData &= "FADFF9BFFB0FF98FFC2FFA3FFD2FFAFFFD2FFB5FFCCFFB4FFCEFFADFFD4FFA3FFD2FFA4FFCEFFBAFFD3FFD8FFDEFFF0FFE5FFF9FFE7FFF3FFE8FFE5FFE3FFDDFFDAFFD9FFD8FFCFFFE1FFC1FFE9FFB7FFE8FFAEFFE1FFA3FFDFFFA2FFE6FFABFFE8FFAEFFDDFFA7FFCBFFA6FFBEFFB0FFB8FFB4FFB5FFABFFB4FFA6FFB4FFB3FFB8FFCAFFC4FFD4FFD3FFCFFFE2FFC8FFF0FFC6FFFDFFC4FF0800C4FF1100D4FF1000ECFFFCFFECFFE1FFD0FFDCFFB8FFF1FFC0FFFFFFDAFFF8FFEEFFF3FFFBFFFBFF0900FAFF1200EAFF0D00E0FF0000E8FFF2FFF4FFE5FFFCFFD8FF0A00DBFF1A00F5FF1F000F0018001500170012001F0014001F0016000E00"
	$bData &= "130004000F00120004002A00F0FF3300DDFF2E00D7FF2300DCFF0A00E5FFE4FFF0FFC3FFF8FFB8FFFCFFBAFF0200B9FF0200B5FFF1FFBAFFD7FFCAFFC8FFD5FFBCFFD6FFA7FFD9FF9AFFE4FFA6FFEAFFBFFFDDFFCDFFCBFFC9FFC4FFC1FFC4FFC2FFC8FFCAFFD2FFC9FFDCFFB8FFE1FFA1FFE2FF99FFE1FFA0FFDBFFA9FFD4FFADFFCEFFB1FFC1FFB5FFADFFADFFA1FF9AFFA1FF8FFF9AFF9BFF8EFFAAFF92FFADFFA7FFABFFB7FFACFFBAFFA5FFB5FF9AFFB1FFA2FFB6FFBCFFD3FFCFFFF9FFD3FF0900D5FF0000D8FFF6FFD2FFF6FFC7FFF4FFC6FFEDFFD1FFF0FFDBFFF7FFD8FFE9FFCBFFC6FFC2FFACFFC7FFAAFFD0FFB4FFCDFFBDFFC0FFC"
	$bData &= "7FFB3FFCFFFADFFD2FFA9FFD3FFA1FFD2FF9BFFCCFFA2FFCDFFB3FFDDFFC0FFEDFFCBFFF0FFD5FFE8FFDBFFE0FFDFFFDFFFF0FFE8FF0000F8FFF4FF0200DCFF0600D5FF0F00D6FF1400C6FF0500B4FFEDFFB9FFDEFFC7FFD8FFC9FFD1FFC5FFCDFFBCFFCCFFAAFFC9FF9CFFC7FFA1FFCBFFB0FFD0FFBBFFCCFFC2FFBFFFC7FFB6FFC5FFBEFFC4FFD6FFC7FFF1FFC9FF0200CEFF0B00DEFF0B00F3FFFCFFFDFFDFFFFCFFC8FFF5FFC6FFE3FFD1FFCEFFE1FFC3FFF2FFCBFFFEFFD9FFFBFFE0FFEAFFE3FFD7FFECFFCCFFFCFFCDFFFFFFDAFFECFFEBFFD3FFFDFFC7FF0900CCFF0900DAFFFDFFEDFFE8FFFBFFCFFFFDFFBEFFF5FFBFFFE9FFCEFFD9"
	$bData &= "FFDFFFC8FFEDFFC2FFF5FFC4FFF3FFC6FFDFFFC6FFBFFFC6FFA4FFC1FF9CFFBBFFA3FFB7FFAAFFB2FFAAFFA7FFAFFFA3FFB8FFADFFBCFFB8FFBBFFB7FFBEFFADFFBFFFA3FFB6FF9EFFB0FFA2FFB8FFB2FFC1FFC5FFBEFFD1FFBBFFD5FFC4FFD4FFCCFFCCFFCBFFBEFFD0FFB3FFE2FFB7FFEEFFC6FFECFFCFFFE7FFC8FFDFFFBBFFD0FFB3FFC5FFB3FFCDFFB9FFDCFFC4FFE0FFD3FFDAFFDCFFD5FFDEFFD2FFDBFFD2FFD7FFD6FFCFFFDCFFC8FFE0FFC6FFEBFFC8FFF8FFCDFFF9FFD7FFECFFE0FFE5FFDCFFEFFFD2FF0500D7FF1800EDFF200000001A0003001300F6FF1300E3FF0900D9FFF2FFE5FFE4FFFDFFF1FF0900090001001E00F3FF320"
	$bData &= "0EBFF4600E4FF4C00DBFF4500D9FF3700E5FF2900FBFF23000E002400170027001900280016002F00100038000F003A001700340020002F00200028001C001E001D001A001E0020001D0028001B002A0014002500090021000500200012001F0025001B002D001A0026001C0019001A001200170011001A000E00210003001C00F3FF0C00E6FFFBFFDDFFEFFFD9FFE1FFDDFFD3FFE3FFCBFFDFFFCCFFD2FFD3FFC7FFD5FFC8FFCAFFD1FFBEFFDDFFB9FFE7FFB5FFEAFFB3FFE0FFC0FFD1FFDDFFC7FFEEFFC3FFEBFFBEFFE6FFBBFFE5FFC7FFDFFFDCFFDBFFE7FFE3FFDBFFECFFC0FFE5FFA9FFD2FFA2FFC0FFAEFFB5FFBEFFB2FFBFFFB0FFAFFF"
	$bData &= "AAFFA0FF9FFF9BFF97FF9EFF94FF9DFF93FF8FFF8FFF76FF83FF65FF78FF6BFF7CFF7FFF8FFF8FFF9CFF9AFF98FFA3FF98FFA4FFA7FF9FFFB8FF9EFFBCFFA2FFB7FFABFFB6FFB6FFB6FFBDFFB1FFB6FFAAFFA6FFACFF9CFFB4FF99FFB2FF98FFACFF9FFFB5FFB6FFCAFFCDFFD2FFC8FFCBFFA9FFC9FF92FFD1FF9BFFD4FFACFFCEFFA6FFC0FF95FFADFF97FF9EFFA9FFA4FFA7FFB3FF8BFFB4FF76FFAAFF80FFAAFF9DFFAEFFAFFFA6FFAFFF9CFFA7FFA1FFA5FFB2FFA8FFC2FFAAFFCBFFAEFFCAFFB3FFBBFFBBFFA7FFC5FFA1FFCDFFABFFCAFFBBFFBDFFCCFFB6FFDCFFC0FFEAFFD2FFF4FFDBFFF5FFD9FFECFFD1FFE5FFCDFFE8FFD0FFEAFFD"
	$bData &= "9FFDCFFE5FFC9FFF3FFBFFFFEFFBEFFFAFFC7FFE3FFDDFFCAFFFCFFC1FF1200CBFF1600DBFF1000ECFF0700F9FFFBFFFAFFF3FFF3FFF4FFF3FFFAFFFBFFFBFF0000F5FFFDFFF0FFF8FFF2FFF2FFFAFFE7FF0600DFFF1600E2FF2200ECFF1F00FAFF10000B00080013000A0009000D00FAFF0F00F6FF1000F7FF0C00F3FFF9FFEBFFE1FFE1FFD5FFCFFFDAFFB9FFE4FFA9FFDFFF9DFFC9FF98FFB0FF9DFF9CFFA7FF8CFFA7FF81FF9DFF85FF91FF94FF88FF9EFF88FF9EFF9DFF99FFBFFF94FFCEFF93FFC1FF9CFFABFFADFF9EFFBCFF9AFFC6FF9BFFCBFFA3FFCAFFB1FFC6FFBBFFC7FFB8FFC9FFB1FFC9FFB3FFC9FFC0FFCBFFCBFFCCFFD1FFCA"
	$bData &= "FFDBFFC4FFE3FFBDFFD7FFBBFFBBFFC1FFA5FFC7FFA0FFC3FFA8FFB9FFBCFFAEFFCCFFA6FFC7FFAAFFAFFFB9FF9BFFC1FF98FFB7FF9EFFA3FFA5FF9AFFAAFF9DFFA9FFA4FFA3FFACFFA1FFB6FFA3FFC0FFA9FFC2FFB4FFB5FFC0FFA2FFBDFF9BFFAAFFA6FF97FFBDFF8CFFD6FF88FFE2FF8FFFD6FFA3FFBAFFB8FFACFFBFFFB1FFB7FFB7FFABFFB5FFA1FFB4FFA1FFBBFFADFFC5FFC1FFCFFFCEFFD2FFC7FFCEFFADFFD0FF94FFD7FF91FFD6FFA1FFCDFFB5FFCAFFC2FFD1FFC8FFD6FFCBFFD7FFCCFFDEFFD4FFE5FFDCFFE4FFDAFFDCFFCFFFD6FFC5FFD8FFBFFFE6FFBEFFFCFFC5FF0D00CFFF0B00D0FF0100CBFFFCFFCDFFF9FFD0FFECFFCDF"
	$bData &= "FDEFFD1FFDBFFE6FFE1FFFAFFEAFFFBFFF7FFE9FF0600D4FF0F00CCFF0F00D7FF0B00EAFF0100FBFFEEFF0600E3FF0500EDFFF1FF0200D9FF1100DBFF1900F5FF160009000A000C0000000A00FFFF06000000FEFFFFFFF6FF0000FBFF03000E0003002300FEFF2900F3FF1600E7FFF5FFE2FFD7FFE7FFC1FFE9FFB4FFDCFFBAFFCBFFCFFFBDFFDDFFB2FFDAFFAEFFCFFFB1FFC5FFAAFFBDFF98FFB6FF8FFFB1FF97FFB1FFA3FFB9FFAAFFC6FFB3FFCCFFB8FFCAFFB5FFC7FFB0FFC4FFAEFFBFFFB3FFBEFFC2FFBEFFD3FFB5FFD0FFA8FFBAFFA9FFABFFB7FFACFFBBFFAFFFADFFB0FFA0FFB3FF9FFFB3FFA2FFACFFA0FFA7FF9DFFA4FF96FF9BFF"
	$bData &= "8BFF8FFF84FF8AFF89FF89FF8DFF89FF8AFF8DFF8BFF8FFF96FF8DFFA2FF98FFAEFFB0FFC1FFBBFFCFFFB0FFC9FFA8FFBCFFAFFFBCFFB5FFC0FFB9FFB7FFC9FFA6FFD4FF9FFFC6FFA6FFAFFFB2FFA3FFB8FF9AFFAEFF8EFF9DFF93FF95FFB1FF9AFFCEFFA1FFD9FFA3FFD2FFA7FFC3FFAEFFB6FFB4FFB4FFBAFFB8FFB9FFBEFFB0FFC5FFA7FFCCFFA7FFC8FFB2FFBDFFBFFFBBFFC0FFC2FFB3FFC6FFA8FFC7FFACFFCEFFB5FFDBFFB8FFE1FFBBFFDCFFCCFFD1FFE2FFC8FFEDFFC7FFE6FFCFFFCFFFD9FFBDFFE6FFBEFFF5FFCAFFFEFFD0FF0000D4FF0000DEFFFFFFE7FFFAFFE5FFF5FFDCFFF9FFD8FF0100DAFF0600E6FF0B00FAFF0E000E000"
	$bData &= "6001600F9FF1300F4FF0700F7FFF8FFFCFFECFF0400EBFF1000F0FF1D00F7FF24000400240015001F0022001F00250028001F00320015003A0011004900170059002100580023004B00220047002D00500043005600520054004E00550041005A0036005B002E005C0028005F0025005C002300500022003E002A002D003D0022004A001F00470022003700260023002A000E002E00FAFF2C00F1FF2300F4FF1C00FCFF1C00FFFF1B00FEFF0E00FEFF000001000000F9FF0600E6FF0100DEFFF6FFEDFFF4FFFEFFFAFFF8FFFBFFE7FFF8FFE3FFF7FFEDFFF4FFF5FFF0FFF7FFF2FFF1FFFBFFE6FFFFFFDFFFFBFFE7FFF5FFF7FFEDFF0000E1FFFF"
	$bData &= "FFD4FFF7FFD1FFEDFFDBFFE9FFE7FFE9FFECFFE4FFEDFFDEFFF1FFE6FFF2FFFDFFE6FF0600D3FFF4FFC4FFDEFFBEFFD9FFC2FFD8FFCCFFCFFFCEFFD0FFC7FFE5FFC3FFFDFFCCFF0400D9FFF3FFDBFFD6FFD8FFC5FFDCFFCCFFE5FFDEFFE9FFEAFFE1FFF0FFD7FFFAFFD4FFFCFFD8FFEBFFDCFFD3FFDFFFC3FFE2FFBFFFE1FFC6FFDAFFD7FFCFFFE8FFC3FFEEFFBCFFEBFFBCFFE6FFC2FFDEFFC7FFD5FFD1FFCFFFDCFFCDFFDAFFCBFFCAFFC8FFC3FFC5FFCBFFC4FFD2FFC4FFCCFFC0FFC5FFB8FFC0FFB4FFB6FFB4FFA7FFB6FF9BFFB8FF96FFB2FF99FFA2FFA1FF91FFABFF8EFFB3FF9AFFB7FFAEFFB0FFC4FFA0FFD0FF98FFC8FFA1FFB3FFACF"
	$bData &= "FA7FFB1FFAAFFBBFFB1FFC6FFB8FFC6FFBCFFBDFFBEFFBCFFBFFFC1FFC0FFC1FFBCFFC1FFB5FFCBFFB6FFD6FFBBFFD9FFB8FFDAFFB5FFE1FFC0FFE5FFCDFFE0FFCDFFD8FFC7FFD6FFC8FFDBFFCAFFE1FFC4FFE8FFC0FFF3FFCDFFF9FFE7FFFBFF010003000D00120008001D00FBFF2100F8FF2B0000003E000B004A0015003E002100270029001B00260020001D002E0019003B001C00450021004C0027004A002A003F00260035002100300028003200330034003100370025003B00210044001D00480010003F000900330012002D001F002C00240029001F002D0013003E0007004C000B004F001F004C0031004000390026003A0013002F00"
	$bData &= "1A001A002F0008003A0006003D000A003C000E002C000F00150006000E00F0FF1100DFFF0E00DDFF0A00E7FF0F00F4FF0E000100FFFF0700F2FF0100ECFFF9FFE7FFF5FFE8FFF4FFF7FFF4FF0C00F6FF1100F6FF0A00F4FF0600F4FF0700FCFF0600040001000100F7FFF2FFEAFFE0FFE3FFD6FFE8FFD9FFF9FFE4FF0600EAFF0000E7FFE6FFE2FFCCFFE0FFC7FFDDFFD1FFD5FFD9FFCDFFD7FFCCFFCDFFCEFFC0FFD0FFB5FFD3FFB3FFD1FFB8FFC3FFBFFFB2FFC3FFACFFC7FFB2FFC7FFB5FFC1FFB3FFBDFFAFFFBAFFB0FFB7FFB6FFB1FFBBFFB0FFBBFFB6FFB5FFBFFFB3FFC9FFB4FFCEFFBCFFD0FFCAFFD4FFDAFFD7FFDFFFD6FFDDFFD0FFD"
	$bData &= "FFFCDFFE1FFCEFFDFFFD3FFE3FFE1FFEFFFF3FFF3FFF8FFE8FFECFFDCFFE1FFD5FFE3FFCCFFEBFFC4FFF0FFC6FFEFFFCCFFE8FFD0FFE3FFD7FFE1FFE4FFDEFFE8FFD8FFDDFFD9FFD1FFE2FFCEFFEAFFCFFFECFFD0FFEEFFD1FFEEFFD4FFE9FFDAFFE5FFE6FFE9FFF1FFECFFF3FFEBFFF0FFF0FFF1FFFBFFF8FF0400FDFF0400FFFF00000300FFFF0800050008000E0003001700FCFF2100FFFF2A0011002900270019003300070030000800230016001300240009002D000B00350014003C001A003C00170031000F0024000A001F00110020001C00200018001B0007001800FEFF1D000200240005002200050014000A0007000D000200080001"
	$bData &= "000400FFFF0600040005001400FEFF2300FAFF1E00FBFF0C000200FEFF0800FEFF01000800EDFF1000E3FF0D00F0FF0200FFFFF5FFFDFFEAFFF2FFE3FFE3FFE3FFCDFFEAFFBFFFF0FFC7FFF0FFD3FFECFFD2FFE0FFD2FFCFFFDDFFC2FFE2FFC0FFD6FFC5FFC3FFD0FFB7FFDBFFB7FFDBFFCAFFCEFFE8FFC2FFF6FFBEFFE4FFBDFFC7FFC0FFB6FFC7FFADFFC9FFA3FFC1FFA1FFB7FFADFFB7FFBCFFBFFFC1FFC4FFBDFFC4FFB6FFC1FFAFFFBFFFAEFFBAFFB7FFB7FFC2FFBDFFC2FFCDFFBEFFD6FFC3FFD3FFCBFFCEFFCCFFCDFFCEFFCCFFD3FFCCFFD6FFD6FFD7FFEAFFDFFFFAFFEAFF0100F0FF0000F3FFFDFFF4FFFCFFF0FFFDFFEAFFFEFFE7F"
	$bData &= "F0200EBFF0900F0FF0E00F5FF0B00FAFF0500FDFF0200FFFF0100FFFFFFFFFFFFFFFF0000040006000D000F00190019002200230028002B002D002F002D00340024003D00190041001D0039002C002C003500280033002B0031002B003200270033002000310019002E001A00260027001C00340015003300110027000C001B000F000D001E00FDFF2B00F5FF2F00FBFF3400070037001300270020000A002A00FEFF26000C001E001E001C0022001C001C0016000D001100FAFF1200F4FF1000FFFF08000A0000000B00FDFF0A00FFFF0E0007000D000D0008000600FFFFF9FFF3FFFBFFE6FF0900E2FF1300E1FF0E00DFFF0300E5FFFCFFF1FF"
	$bData &= "0300F5FF1200EFFF1700E8FF0E00DFFF0500D3FF0200CFFFF9FFD9FFE4FFDFFFD6FFD6FFDEFFCDFFEBFFC8FFE9FFBEFFDCFFB3FFD5FFAFFFD3FFAFFFD1FFAAFFCFFFA8FFCFFFACFFC8FFB2FFBCFFB8FFB9FFC2FFC5FFCFFFD5FFD7FFE3FFDCFFF0FFE4FFF8FFECFFF7FFEFFFF5FFEEFFF7FFF0FFFEFFF6FF0A00FBFF1700FCFF2300FCFF2900000028000800210017001C002700220030002A002C002900210028001A002F001A0033001B002D001200280006002E000400330004002C00FAFF2200F3FF2000030020001A001B001B00160010001B001400240022002900280029002A002A002E0028002C0021001F001D0018001D001C001D002"
	$bData &= "5001D002B0021003100220036001B0034001A002B002300240027002400200027001C002900210029002300270021002200200018001B0012000D00160006001E000F001F00190016001E001000250013002A00190027001B0022001F002200290022002D001E0026001E001E0021001B0022001D001E00240019002E000E0032000500280009001B00170016001D0016001C0018001F001D00200024001400280006002C000800300015002D001F00220026001A0030001900360019002D0018001D00190012001C0011002000110024001100250017001F0020001300230007001B0000000C00FCFFFDFFFBFFF1FFFBFFECFFF5FFF2FFEBFFFF"
	$bData &= "FFE3FF0900E2FF0E00E3FF0900E0FFF7FFDFFFE4FFE9FFE0FFFAFFE2FF0200DFFFFAFFE3FFE9FFF5FFDEFF0300DFFFFAFFDEFFE8FFD4FFDAFFD1FFCAFFE2FFBBFFF7FFBEFFF5FFCEFFDCFFDBFFC7FFE3FFC4FFE7FFCCFFDDFFD9FFC7FFEAFFBCFFF9FFC8FFFCFFDBFFF5FFE2FFF0FFDFFFF0FFDBFFF1FFE0FFF3FFEFFFFCFF020002000D00FCFF0C00F2FF0D00F3FF1900FDFF2C00060035001300310025002F002F003300330037003C003900430042003E004E00380051003E004D0048004A004A00460049003C004B00380050003C0055003E004F003500340029001200230009001C001C00120033000F0040001B004600280044002800390"
	$bData &= "02200290024001C00250012001500110000001C00FCFF2600050021000900130002000F00F6FF1200E6FF0C00DBFFFEFFDEFFFAFFEDFF0400FBFF0900010000000100F7FF0000FAFF0300FEFF0600F6FFFEFFEBFFE7FFE6FFD2FFE6FFCCFFEAFFD4FFF0FFE2FFEBFFEDFFD8FFEEFFBFFFE7FFB2FFE4FFB9FFEDFFCEFFF2FFDFFFE7FFE1FFDBFFDCFFE3FFDBFFFBFFDEFF1000DBFF1D00DAFF2600E4FF2800F0FF1E00F6FF1600FCFF1C000C002A00210037002D003D002E003A00340034004500310054002B00530021004500230039003100380033003C0020004400140048001F003F002A002700280008002C00F1FF3C00E8FF4100E9FF2C00"
	$bData &= "F1FF0D00FBFFFDFFFFFF0900FDFF2700FCFF3A00FCFF2E00000011000600FFFF1000000018000300180007000D001600FAFF2C00E4FF3500D6FF2300D5FF0200E0FFF1FFF6FFFCFF0D0012001200160003000800F4FFF4FFF4FFDFFFF6FFCCFFF0FFC1FFEAFFC4FFECFFCFFFEDFFD8FFE5FFD9FFD5FFD4FFCCFFCFFFD2FFD7FFE4FFE6FFEBFFEAFFD8FFDBFFBDFFC9FFBAFFBEFFD1FFBBFFE9FFC3FFEFFFD8FFE4FFE8FFCEFFE5FFB8FFD6FFB1FFCFFFBEFFD5FFD5FFE3FFE8FFF6FFF4FF0400FAFF0800FEFF02000600F8FF1000F1FF1400F7FF13000800170014001E000B001700F0FF0700D1FF0100BDFF0500BCFFFDFFCAFFEBFFDCFFE6FFE"
	$bData &= "9FFF0FFECFFF8FFE4FFFAFFE1FFFCFFF7FFFAFF1B00FCFF27000C0014001F0002001B00020004000400FAFF020006000100130000001500F4FF1800F1FF22000C002800320021003C001700290018001D002500280034003600330037001F00300005002300FFFF0C001200F8FF2600FAFF26000B001E001B0023002C00340043003F004C004400390048001D004600170039002C002D0048002B0054002D004B002F0037003400280038001800310008001B000400080010000A0019001B0016002100130013001B00050026000F0030002D003E0042004200380032001F00200015002100260029003900200035000B001E00FAFF0F00EAFF14"
	$bData &= "00D6FF1E00D0FF1A00E7FF0B000C0008001900160000002300DEFF1C00DBFF0400F9FFEDFF1A00DFFF2500DCFF2600E6FF2D00F9FF2F000D001C002000FEFF3100EFFF3A00FCFF3100180019002700FDFF1A00F3FF03000200FEFF1600090012000800F3FFF2FFD8FFE4FFD4FFF4FFDFFF0C00EFFF07000100E7FF1200D5FF1A00E5FF1900FDFF1400FEFF1100F1FF1C00F3FF3A000700580016005E00130053000500510000005500060048000C002C0008001500FFFF0900010000000D000100140013000D002200F8FF1F00DFFF1500D6FF1600E8FF1D00FEFF1B00FCFF0B00F2FFF3FFFFFFE4FF1F00EBFF2E0001002400100012000A00020"
	$bData &= "0F9FFF3FFEDFFF3FFEFFF0B00060026002F003100520039005A00490051005100530044005B0030004E0021002D00180016001C001500340019004C001C00490024002F00380012004B0000004E0001003C001A0022003D001B0050002E004E00420041004B00340057002D006C00370071004C0058005400340046001F0031001E001F00270011002B0010002100200019002E0026002B003F00270042002C0032002A0034001D004800210043003A001B00440003003500140034002A0048002900480028002E002F0024002800380010004300FFFF2E00F6FF0E00DFFFF1FFC5FFDFFFC4FFEEFFD5FF1800E7FF2800FFFFFFFF1C00CDFF1B00"
	$bData &= "CBFFF2FFECFFCFFF0A00CAFF1900CEFF1D00D4FF0D00F3FFEDFF2200D8FF2A00E0FF0400FCFFE2FF1700DDFF1800DDFFF8FFDBFFD1FFEDFFC8FF1700DAFF3500E4FF2F00E2FF1000EDFFF6FF0200F5FF05000500FEFF08000A00F5FF1700EAFFF5FFF9FFB7FF0000A2FFE6FFCFFFC7FF0F00C9FF2F00E3FF2700FBFF09001100F4FF260004002F002A0031003A003800260035000D0019000800000014000D0025002200320013002900F5FF0B00F6FFF5FF0D00FEFF0C001B00FDFF3600090047002D004C003A0042002800370017003C001B00420027003A0028002D0020002B00200020003100FCFF4100D8FF3600D4FF1600EBFF0400FCFF0"
	$bData &= "B00FEFF1600FEFF140006000C000D0000000000F2FFD9FFF0FFB2FFFFFFB2FF0D00D9FF0800FEFFF6FF0300EAFFF6FFE4FFF0FFE6FFF3FFF3FFF9FF0100FDFF0300FDFF0700FDFF1B000B002C002F002300520014005F00160059001B004F000A004500F0FF3C00EEFF33000A001C002700F0FF2800C7FF0C00C2FFEFFFD9FFF0FFEEFF0C00F4FF1600F5FF0200F3FFF2FFF1FF0100F8FF130000000D00FEFFFFFFF9FF010002000D0009001600F8FF1C00E3FF1B00E8FF1000FFFF07000D0007002100080047000900570015002E002300F5FF1900F1FF05002300120055003B006D004B0079003D0088003F009000540084004D006400270041"
	$bData &= "001A0033003A003D005B0046006000430060004300680049006200430047002E002F001D002F0011003600FBFF2B00E2FF1200E2FF0100FCFF03000F0013000A002500FAFF3700F6FF410002003B00130030001A003B0019005200230046003C0014004C00FAFF4200190034003500380018003C00E4FF2800D8FF0500F2FFECFF0C00E2FF1E00E4FF2A00F0FF2300FEFF0D000E000400340006006800FAFF7800E7FF4C00F2FF1F0011002700190043000A0038000D001900290015003C00290038002E0035002700470025005B001F00570008003300E6FF0F00C8FF0C00B4FF2100BAFF1D00E1FFF9FF0E00E5FF1E00F5FF1000FEFFF7FFEFF"
	$bData &= "FD9FFF1FFC2FF1600C3FF3000D6FF2200E2FF1700E0FF3700E3FF5F00ECFF5B00F3FF25000700E6FF2C00CAFF3D00DFFF2200FFFFFFFFF9FFFBFFD8FFFFFFDEFFF5FF0C00FAFF1C002300FEFF400002002B004B00130087002D0079006700530084004F00760051005B003700540021006C002E0087003E007300380031003A0007005900200074004C00690047004F001D004900FDFF4F00EAFF4000DAFF1900E9FFFEFF280015006A0049007B005800610026004100EDFF2900F9FF23003C0043006C00790072008B007800680090003D00960034006C00390027002500FBFF01000800F3FF40000C006A0038005B004D003600340036000200"
	$bData &= "4800E5FF2800EAFFE3FFF3FFDAFFEBFF1C00E6FF3B00FAFFFFFF1D00CCFF3E00FEFF4D00510042005000260004001700D3FF2500E4FF31000C002400230029002200600011009500060083001B004800460037005D0052005200550043003200420027003A00470021006000100050001B002F0032001B004400130055000E0069000C00730004006100F0FF3800DBFF1000CEFFFFFFC3FF0300B2FF1200A6FF2E00AEFF5800CCFF7400EBFF6800FBFF3C00FDFF12000700FBFF2500F4FF4D000200720029008A004C0085005200540048000D003C00E9FF2100F5FFFBFF0300F3FFFFFF0B000C000B003400E6FF4800DBFF2D00000007001500F"
	$bData &= "BFF0200FBFF1400FDFF63000A008E0011005300FBFF0700EEFF120018005400540074005B0072003B007D00360085003F00600025002A000C00230042004400A2004D00BF002E009200230079004A00880069006F0041002700FCFF1400F8FF5F003C00970073005B006C00EDFF5200CFFF4F000200460020001C000500FBFFF3FF10000700410012005F0004006A000B0081003200A1004800AC004500980064007C00AD007200D3007700B5007500930062009C005900A7006D00910091007D00AB008C00B900A800C600BD00D700D800F800F7002901FB004A01DC002E01BA00EE00AF00D000B200E600BE00F200D000C800D6007C00BB0032"
	$bData &= "008700F7FF5800DDFF3E00EFFF3E00100053001C00730015008E000B009200F1FF8400C8FF7500BCFF6E00EDFF610037004B006100490064005E005200530025001000D4FFEFFF7BFF3B004EFFA2005DFF9F0082FF4D009AFF1E00AEFF0800C2FFBAFFADFF6DFF4FFF99FFDEFE07008DFE150039FEBAFFFEFD65FF93FE1DFF0E00A7FEF60050FE2400B3FE05FFC4FFC8FFD200970138018101C8004DFFE2FF38FE60FFDCFFD2FFBC01CA007C0173016500A8018400A70102015401F6FFE500ECFD590115FDB20211FEF102B3FFD100150179FE3902D8FEFC025301AB02E302A700A60249FD36024CFA0702E6F9C50099FC84FE68006EFDF4028DF"
	$bData &= "E97035200B802F3005F007B00EBFCE6FF0CFAC1FF47F911004BFA83000CFC8A00ADFEF0FFBA021BFF100764FE3409CBFDD607D9FD4504C5FF6601AF0365018307F603A708A306B9063707F903D005EF0212040804DE026E05B1013305F6FF6603DBFDB501E6FB10018DFA940025FA00FFA2FA70FC7BFB1BFA46FC06F931FD7CF95CFE30FB32FF59FDF1FE16FF92FDEDFFE3FBC4FFF2FA98FE69FBE0FC15FDEEFBDFFEE6FCAFFF46FF59FF490170FED50189FD290118FDDEFFAAFD39FE61FFB4FC5B014FFC5E02BEFD17028E0034014B037D00720455007803D2004701A10194FF050265FF8E016500CA00A701BE00A102B1012903D40211032903"
	$bData &= "550270025E012C01A5000200300026FFBEFF65FE40FFAEFDE2FE57FDB4FEAEFD8CFE67FE3FFED1FECCFD90FE5BFDEFFD2EFD78FD72FD86FD18FE4BFED8FED4FF74FFDD01F4FFCE03970022058801C405B802D605E1033B059F04A203880432016B03DDFEA50197FDF9FF57FDE0FE2EFD0BFE5CFCE8FC04FB81FBB2F960FABEF8AFF953F8EDF8AAF8BDF7D1F98AF661FB2EF6BEFC28F79CFD53F930FE1AFCD8FECBFEC3FFDB00CE001E02BD01B5026902DB02C002C702AE02A8023F029C02DE01AC022502D6023B030403980401038E05A902D205350276051302B0046102D303CA0260030903B8034003B704AA03AE053604D5059204E20490044"
	$bData &= "9034504D801E10300017203A100DD02760019027A004001C60077004101C3FF9A0129FF8001B7FED40064FEC7FF03FEBBFE8EFDEFFD39FD54FD15FDDFFCD1FCC4FC31FC1FFD80FB96FD3BFBBBFD7DFBA8FD0CFCD7FDAFFC77FE3EFD34FF92FDC1FFCDFD380061FEDA0090FFA701F5004602E80158022502EA01EB016F0199014E017301720192018A01C8017601BA015C0138016001860083012A00C20171000302380113020E02E0018E02B0019402D90135024A02A101A00216019302E7002E0241019F01EA01FF00570265001B02EAFF3D01A8FF2A00A9FF5CFFE8FF06FF4D00FCFEA900F3FEC300D6FE8500C4FE2100C8FEF3FFC4FE2C00A3"
	$bData &= "FE960081FECF0079FEA5008BFE2A00AFFE85FFE5FEE3FE0EFF72FEF7FE3FFE9AFE22FE32FEF8FDE6FDE2FDACFDFBFD80FD0EFE80FDD9FDB6FD84FDECFD74FDE7FDB0FDB5FDDEFD9BFDDAFDBEFDDCFD06FEF6FD3BFEE6FD41FE9BFD2AFE77FD26FECDFD4DFE5DFE9AFEABFE07FFA2FE8DFF9FFE0B00EAFE460066FF3500CDFF0F001000FFFF5000FCFFA300FAFFE5000A00EA002F00B40033007300FAFF4D00BBFF4F00BFFF6C000200860046007F0069005F007E004A0093004400990018007B00ADFF3F0050FF0A0059FF0000AEFF0C00DDFFE5FFA6FF68FF32FFC9FEC8FE68FE8BFE64FE7EFE93FE84FEC5FE78FEF4FE62FE2EFF7FFE78FFE8F"
	$bData &= "EBAFF5FFFDEFFA2FFEDFFCAFF070013003900670061006D00670013006700B0FF820093FF9900A2FF770095FF2D0058FFF6FF1CFFCDFF0BFF6AFF21FFC1FE54FF41FE9AFF4FFEC9FFC5FE99FF23FFFCFE2BFF56FE17FF1FFE34FF6FFE79FF05FFB1FFA9FFD9FF390025008100A8004C003201C4FF89016DFFA101A1FF880140004701E100E900390199003F0183000F01A100D300C800A200CE007200AB0032006C00FBFF2900F7FFFDFF1400F8FF09000F00B3FF340056FF690047FFAB0071FFD40089FFBB0092FF6C00D2FF28004400140080000B005600F6FF2200FFFF3500420057006C0036001D00EDFF8EFFD3FF60FFE9FFB5FFE7FF0600"
	$bData &= "AEFFF2FF60FFBDFF20FFC4FF03FFEAFF20FFDAFF69FF9BFF9BFF78FF8CFFA2FF64FF210058FFE20061FF970165FFD20174FF7C01B4FFF3001F009C0083007E00AE0076009C00800073009D005900AB004A0088002D0040001000F7FF0F00B9FF15007BFFE6FF4DFF86FF4FFF45FF7EFF55FFA1FF83FF8AFF79FF55FF2BFF42FFDFFE6CFFD7FEB1FF1EFFF0FF8FFF2D00F6FF610029005E00280016001100CEFFFAFFCCFFE6FFF3FFDBFF0100DDFFF7FFD3FF0700A8FF340079FF58006DFF650071FF540053FF0D000FFFA5FFD1FE81FFBAFED6FFD6FE470031FF5400BFFF0B004400E6FF8B0013009C004B009800650080007E0057009F0046009"
	$bData &= "B00680067009B004100B7005700B8008700A200960060007900FBFF4C00AEFF2200A3FFEBFFB8FF9DFFA8FF53FF55FF29FFE4FE0CFF94FED7FE91FE98FEDCFE81FE3DFF9FFE5EFFC7FE14FFE5FE95FE19FF47FE74FF5CFEBFFFB6FEBEFF14FF83FF53FF58FF77FF68FF9DFFA1FFCAFFE0FFE3FF0700D3FFF8FFA8FFADFF7FFF49FF64FFFFFE59FFE4FE62FFE8FE7AFF07FF90FF5AFF9AFFD7FF9AFF38009EFF4A00AEFF3600C8FF3F00E3FF6900FEFF92001A00BA003000E7003D00F1004700B8004A0056003B0001002200D7FF1D00D7FF3500FBFF540030005C00540037004300DDFFFEFF6DFFABFF2DFF78FF52FF84FFB8FFCFFFFFFF2E00FE"
	$bData &= "FF4E00E0FF0900CEFFA0FFC0FF6CFFBFFF7DFFE6FFA0FF2000AEFF3000A8FF1300AFFFFEFFE3FF0A002B001B004C001D003A0018001E00120010000700F5FFF5FFCCFFEDFFC1FFF5FFEBFF00002500FBFF4800F2FF5B00FCFF6D00190076002F0071003000750023008E001600A5001100A9000E00A7000000A200F5FF7D0012003B0054001800850036008C0072007F0098007100A9006800BC007A00CA00B400C000F000A300FF009200E500A600C000CE009C00E8008000E4008300D900B300E400EE00F8000101E300DF00A000AA006F00870083008900B200B000BD00D700AB00CB00AF008900D4004700FC002B0008012100E70017009E0"
	$bData &= "024005C004C004F00640071004D009D002B00BE003B00D5007700E400A100E3009200CD006F00B7006800B3008200AA009B0085009500660067007A002700A3000600A3001A007C0050005700850036009E000B008500F0FF440002000C002C00020042001400390010002600E4FF2B00B6FF4C00C0FF6800F7FF60000B003800DDFF0C00B2FFF1FFBEFFE3FFCEFFD2FFB5FFB8FF97FFADFFA5FFBEFFCEFFD8FFE0FFD6FFC2FFB7FF8CFFA4FF7CFFBEFFAEFFEFFFF4FF02001400F6FF260002005B003D009D007000AD006B008000470042003500190037000F002E0018000A001F00E2FF0A00DDFFCCFFF4FF6EFF02001AFFFFFFF7FE070004FF"
	$bData &= "120030FFF4FF69FFB4FFA0FF83FFCBFF6FFFF1FF73FF1800ADFF2A0027001B009A000C00B300140077001D001E001300D8FF0400B9FFFAFFC1FFDDFFD8FFA0FFDAFF63FFBCFF50FF91FF68FF6AFF93FF3DFFB9FF03FFC5FFDEFE9DFFEDFE51FF15FF18FF21FF0CFF16FF15FF1DFF20FF43FF38FF76FF5EFFA8FF75FFCCFF74FFD9FF6EFFDEFF74FFECFF87FFF7FF96FFE1FF8EFFB4FF72FF97FF62FFA2FF7AFFC3FFAFFFDFFFD4FFE9FFC0FFE1FF84FFCAFF5BFFADFF59FF91FF5EFF77FF5EFF65FF72FF6CFF91FF8AFF8FFFA4FF74FFAAFF79FFB0FFA4FFC2FFCBFFD4FFDCFFE8FFE3FF0800E0FF1D00D2FF0900C3FFD7FFB7FFB3FFADFFB6FFB"
	$bData &= "2FFD5FFC2FFE8FFC7FFDDFFB9FFC6FFADFFC1FFB2FFD0FFC8FFE3FFDEFFF2FFE1FFF0FFCBFFD5FFAEFFB3FF9FFFAAFFA3FFB6FFC4FFC3FF0500CCFF4F00D4FF7300D5FF6500D0FF4500D0FF3500E4FF3F0014004C0054003E007F0007008000C2FF6B0095FF520091FF2E009EFF00009EFFE1FF85FFDBFF62FFDEFF49FFD1FF44FFA3FF4CFF69FF56FF5AFF68FF91FF90FFDDFFC4FF0400E3FF1200EBFF2C00FBFF4C001E005C003B005B00410057003C00550033005500220055001500490015003200190024001B002D0026003F003C0048004B004000440023002700F6FF0D00D0FF1400CFFF3300F1FF460014003E0026002C003000190035"
	$bData &= "0004002A00FAFF11000500F7FF1300E9FF0C00EEFFF1FF0900CCFF2900B0FF3200ACFF2200BEFF1300D1FF1600D5FF1E00CCFF0D00BCFFE0FFA6FFB3FF93FFA8FF8CFFB6FF8DFFC0FF97FFC2FFADFFD1FFC6FFF1FFD5FF0B00DCFF0D00DCFFFEFFD1FFEDFFC7FFE9FFD6FFF5FFF7FF00000800F6FF0300D7FFFDFFBCFFF8FFBDFFE9FFD4FFDBFFE6FFE0FFDEFFE2FFC4FFBDFFA5FF81FF8BFF60FF84FF70FF99FF9FFFBAFFC5FFCEFFC9FFCEFFB9FFC9FFBDFFCCFFD6FFD8FFDFFFE3FFD4FFE9FFD6FFF4FFE9FF0700EEFF0B00E5FFF4FFDFFFD9FFDAFFD0FFCAFFD3FFB7FFD2FF9FFFCAFF7BFFB5FF62FF8AFF68FF52FF6FFF2FFF5BFF34FF41F"
	$bData &= "F56FF39FF76FF29FF7DFF05FF6CFFEDFE54FF01FF3FFF33FF2BFF65FF2BFF82FF4DFF88FF83FF83FFABFF85FFBDFF8EFFC4FF95FFC4FF9DFFBDFFB1FFBDFFCFFFD3FFEBFFF2FFFAFF0800F7FF1300E4FF1F00D5FF2D00E2FF34000B002B00340013004600FAFF4B00F2FF560006005D002B004B004F002C00600024005A00330047003D0038003C0030003F00290041002A0027004100F9FF5E00D8FF5D00D5FF3800E3FF0900F6FFE0FF0500BBFF0600A5FFF7FFA8FFE4FFBAFFD0FFC3FFBEFFBFFFB7FFBFFFBAFFC4FFB5FFBDFFA9FFA8FFABFF99FFC1FF9CFFD8FFA1FFE8FFA0FFEAFFA6FFD1FFBAFFA8FFC7FF94FFC0FFA0FFB2FFB5FFAAFF"
	$bData &= "D0FFA7FFFBFFA4FF1E00AAFF1800C3FFFAFFEBFFE7FF0D00E7FF1800EEFF1100FCFF070011000700270013003900260045003800420042002F004A0015004F0000004400F5FF2A00F8FF17000B0014002E00130057000F006C00110057001D002D00310014004500160049001B003100190013001C00080023000F0017001A00F3FF2200CFFF2700C3FF1E00C4FF0100C3FFDAFFC5FFC1FFD2FFC0FFE2FFC9FFEFFFCDFFF2FFCCFFE6FFCFFFCEFFCFFFBEFFCEFFC1FFD8FFC9FFECFFCCFFF2FFCFFFE3FFD7FFD8FFDFFFDCFFE9FFE3FFF3FFE1FFF4FFDDFFEDFFDFFFE8FFE0FFEAFFD8FFEFFFC7FFF1FFB8FFE8FFB3FFD2FFB5FFB8FFB9FFA7FFB"
	$bData &= "7FF9DFFABFF8EFF9BFF7BFF90FF6DFF8EFF6CFF8EFF77FF92FF86FFA0FF95FFB2FFA8FFC2FFC5FFCDFFE5FFD3FF0100D2FF1100D0FF1300D6FF0C00E5FF0300F7FFFFFF0B00FDFF1A00FCFF1300F9FFF3FFF3FFD4FFE8FFC9FFD2FFCDFFB0FFCDFF8FFFC9FF86FFC3FF94FFB1FFA4FF8BFFAEFF69FFB8FF6BFFC0FF8FFFC1FFBFFFBAFFEBFFAAFF04009BFFFBFFA3FFDCFFC6FFC9FFE5FFC5FFF1FFBEFFFAFFB9FF0300C4FFF6FFCEFFD3FFC5FFBDFFB1FFC5FF9FFFD5FF90FFD8FF8AFFD2FF93FFC9FF9FFFBBFFA0FFA1FF9BFF85FF98FF77FF91FF75FF88FF78FF86FF83FF8DFF9BFF96FFAEFF96FFAEFF87FFA7FF78FFA9FF7DFFB0FF93FFB8"
	$bData &= "FFA3FFC3FFACFFD5FFB7FFE7FFBFFFF4FFBCFFF8FFB5FFF0FFB4FFE4FFB9FFE0FFC0FFDFFFC4FFDDFFC4FFDCFFC7FFDAFFD5FFD2FFE8FFD0FFF3FFDBFFF4FFE4FFE9FFE2FFD9FFE4FFD7FFF7FFEEFF110009002100150029001C003500280045002D0045001C002E00F8FF1B00DEFF2500E8FF3C000B004200210036001D00240018000B001900F5FF1100F6FFFFFF0F00F6FF2A00F4FF3E00EDFF5000EBFF5900F9FF53000A004C00150053002500620040006E004D007300370074001900720018006A0035005900570042006D00300074002F0064003F003B0056000F006C00FDFF790007007700190067002B00520040003F00540032005D0"
	$bData &= "0310050003E00340050001B005900160052002D0049005300510076006C0086008B0082009B0074009900620097005300A0004D00A2004F008A004F0061004D003E00510028004D001E003200210010002600F7FF1F00E2FF1200D7FF0800E0FF0200E8FF0100DBFF0500CBFF0400CCFF0000D2FF0400CBFF1000C1FF1600C0FF0E00C1FFFAFFC4FFE4FFC2FFDFFFAEFFEEFF96FFFDFF9AFFF6FFB0FFE6FFB9FFE3FFB0FFEEFFA7FFF7FF9DFFF8FF8AFFEBFF7DFFD5FF88FFC0FF9AFFB7FF9CFFC0FF99FFCEFF9DFFD6FFA4FFDBFFA7FFE6FFA4FFF5FFA3FFF4FFB1FFE3FFC8FFE2FFDCFF0000EFFF2300FCFF3A00F9FF4F00EBFF5600E5FF4400"
	$bData &= "E9FF2F00EAFF2200EBFF0E00F7FFF9FF0200F8FFF5FFF9FFC8FFE2FF92FFCEFF78FFDBFF83FFEDFF95FFDDFF98FFB1FF90FF8AFF85FF80FF7EFF92FF7BFFAFFF6EFFC9FF62FFD8FF6FFFD8FF91FFCCFFBBFFB8FFDFFFA2FFE6FFA6FFC2FFC8FF98FFE5FF9CFFE7FFC4FFE3FFD9FFDEFFD0FFC2FFC7FF9BFFBBFF92FF9DFFAEFF7FFFC8FF79FFCDFF8AFFCCFF9DFFCDFFA9FFCAFFB9FFC1FFCCFFC8FFD0FFEBFFCFFF1A00DCFF2C00F0FF1F0009001200210014002F001D003100270024002C000A002B00F8FF2200F8FF0F00F9FFFDFFECFFEAFFD8FFC6FFC7FFAFFFB6FFD1FFAAFF0400BBFF0B00DDFFF5FFECFFF4FFFBFF0300170004001C00F"
	$bData &= "FFF02001800F5FF4B000C0069003600660050005900560053006C004F0086003E006E002D00320035000F00450017004B00240048001B00310012000F000E000E00F8FF2600DFFF2B00DDFF2200E2FF2000E7FF2500F2FF250002000E002100040046002A004E0053004700550053004C006F005F007E0083006C007B004C004B0040004C004D007E00690088007E006E006F005F0053006600580087006A009C0065008300580072005B007E006B008C00720088006A005900610031004D004E00360067003C00530049003B003E0001002C00CBFF0E00F4FFECFF3600E6FF3D00D7FF2F00B6FF1B00C9FFF7FFFFFFCCFF0F009EFF0A009AFFFF"
	$bData &= "FFBFFFCDFFE3FF98FF0F00A3FF2700E8FF1000260005003900F3FF3400CCFF2800DAFF1E00F3FF0B00EEFFD6FF0B00ADFF1400D7FFF6FF1F0008002D0007001500D1FFEAFFBBFFA1FFABFF78FF9FFF9DFFB8FFE0FFBEFF0700EAFF0B003300F9FF0100EBFFCDFF03000A00380009003C00DBFFF7FF0400BEFF4400C0FF5F00C6FF2600B2FFB2FF9AFF9CFF86FF94FF96FF4AFFD9FF5CFFE1FF8DFF8FFF7CFF88FF98FFC1FFA4FF8FFF99FF71FFE0FFCFFFE7FFBEFFD2FF61FF0100A4FF8DFFD4FF1CFF83FFAFFF81FF0F00B1FF4500BBFFB400E7FFEFFFE3FF0EFFD3FFE0FF4A0091007F00470022002E003B002900980072006E00E9002300850"
	$bData &= "02A001B004800FEFF010065FF74FF71FF68FFFBFF94FFAEFF75FFE6FFCCFFB30036004E00DDFFAAFFE2FF9BFF350094FF94FFBAFF32FF68FFC7FF00FF0A00E8FF06007500FDFFEBFFBCFF2E00F7FF480011009FFF40FF02000BFF9C000B006E003A013400B30176FF7600E8FEE1FE68FF5BFF91FF5000DCFF4200B4007C006D00850050002100180190008D008900FDFFABFF8C00B2FF3300C4FF1100ADFFCD00AA00450023012600F4007D01B701970187010D0143006101B200430161019500AA000700BC0044007F018201E0002A0181FF27FF3CFF42FF3900CB00A100E1001B0034009E00A0FF3A01A4FF73005500B9005300F3019E009C01"
	$bData &= "C30177012E01210229005101CD006100A6003100030055FF6F0062FFFDFF6900BFFFFEFFE40093FF8C004900BFFFA200920017018D00D400E8FF92FE2600D9FD7FFF2B008FFE2502FAFE7B02D0FF8201B700FDFFC300370092FF7A01DBFF7B01010132018A000801A1006200B6013C0016011600CEFFABFFBDFF77004300E3002C00D3FFCAFEF2FF6DFEC2007A0010001C0175FFF1FF94FF48001EFF3900DAFEBDFE53FF9BFE91FFD5FE46FFC8FE65FF1200C000A9003801B8FF68FF28FF28FFE9FEE1003D00FEFF630268FE770095FF41FD9D0064FED20026000801F6FF39FF370023FEA0FFDBFFB0FE7BFFD1FF11FE350039008BFFB201C300F"
	$bData &= "AFF740163FF0000DFFF0EFFBAFF07FF5C006DFF0A010F008600BCFFEEFF4EFFCBFFABFFE4FF83FFDCFFB6FEC6FF4AFE4E004EFF7400FA00B8FF1700C4FFD0FE3100050112008201FAFFC2FE7DFF9AFF14004301A2026BFF7D02EAFFD0FFD30110005600C800F9FF7AFF8E006E00F1FDE7012AFD2A006AFF37FF6BFFAD00B3FEAD0122FFB701FDFE35006FFFF2FD9200D0FDF500C2FEBA0073FF6DFFF500E8FEE601B600930131012F016200EDFF18013BFF02014A014400D402A1002C02B3FF44024BFFD90232012C02FC00A401E8FFF5010901E301DF007B010300D701CE004202CE003801FE007100A7017801390033011600F9FE9901B8FE7B"
	$bData &= "002D00C7FF7F00A9008C004E001701F9013E01F304500108068401FB070302D0064B03A102BC0493067B0698062709E9F3630ADAEBCB0826023006C3121200F105E7F405F7BAF2E5FB75047504F11471FFD70C7BFA06FD66059CFFE10EDD0CB503A90F5CF19C03DEE8CEF378E6AFED3AE4BEF0FDE78AF4AAF854FC180A9F0538083AFF37FDDBEF72FFF7F160050C00B60350FE4F09FAEDBF13DEE94F0749FAE0E0530BADBF961034BCA110C1CAFD03BCD75DDCF9F169B3562437B6474496E4822F7515DD07792FB0F8F336ACFEF62C1808110BB816A6E50A2D37E3F63A41073133612DE51AF635BDF6AC1FA6D17E00A0CBDAED75E839EBB6F7B1E"
	$bData &= "FD2DE6AF0EAC330EC93D37AF08D0294FE401C9E00AD0F45F03E099AE3C22065EC78313E070426E422FB177E333B11173B8EFB453303DB9C148CD7E3F823F38DF6C8FCB4F458F029E1E6FC4FD90718B2F07D10C709F3F69E0439F376ED1DF41FE2A3E3EAE37DDA5EE85CF042F6200EAF0AA20A100FFCE55C0123C761F57BC0C1EEBCC84AE26BE0DBD377066ED7B221F3F11E1E230BCC09AC0DAF01D3011B0D0BF88D1AB7F3302173F5612D7F01AE3FE415A73C68262916D82603ECCB199ADFA70EC9E1000BA0DAEF0216DBC7F3F0F7D7F0FF1F64020335FE14892D991B4C18891C4A09EA1629061B04940C29EF3E1AFAEEDE241E0CFB220B314016"
	$bData &= "8B3D1702322EA1EC9116D6DFCBFD72DF68E5CBEBA1DAE9FDD3E51305D0FD65027B0EB803E7097A00A6F957F06DED34E550E45DE95DDE16F33EE1A0FC01E72505DEED8108F4FC3B00FD09FDEBB70803DD3105AAE18509B0EDDF09C8F590FB5102E3E75E15E5E29D2548F1992E1C01792FE006E927BD0A9A187C1118059514FCF80F10B9FA9F0868FFE8074FFEDC0F04FC901500FDB3120002C30C540809072B0AE6017C0A8901361059079014D70EBE0FD312CA0A4E10420F1F09D6165703F9170D0475137E0C4A0D3D1735043A1997F9230D78F53AFAE8F888ECBFFBC2E9BDFBC2EDBBFB34F103F877F104EDE7EE87E186EA74DD0EE8B7DF55EAE"
	$bData &= "7E562EFC1F2B1F3ED020FF5E208EEF4C50057F8C6F734FFD0F5E1026BF5CB01D5F5650096FCBDFFAD0543FDEF0659F78700ECEE89FC8CE8A7FF1DE93502ECF00EFCCFFC16F3340824F48F0DECFEED09FC05310190039DFC3D0088014802B4091205910B1E0516080B06F80696093A09530DA70814108502AC1055FD630D7801CF08DE0CAC067E146F05B2121F03820B060259037202EFFA330116F4FEFE76F330FF52FB5500B705D5FE62078DFA1DFDA5F499F1DDEEB4EEBBECEEF0DEEE27F1B2F1D1EFCBF340F108F7A8F7B0FBABFFB3FE59008BFC45F714F706F085F6C0F328FFA5FB360A39FEE10D0BFDED0753FD38FEB2FE55F732FFD9F343"
	$bData &= "FF94F1F8FDF0F21BFAC0FBBBF7810812FBC20F77018E0C51077104180C8600480D1A02F2081A04EB0242058FFF0708F6FF4A0BD503CD0AF907BF05E407C1008A04B3FFB50299FF5003E6FB330300F7BC0010F6B1FD01F9F5FBC2FC38FB94FFD9FAB400B9FA3601E5F928036CF8FE044EF9F40319FFC202FF078C05EC0EDC095510F30A9D0D3E09C50A4307EA092C058C0AE302B10A82017C08B50108050A030A03E1030D029B0271FFE3FFC2FABCFDEBF563FC96F35DFB86F5DFFB2CFA16FEACFDBAFEAFFD49FC90FA9DFA14F757FC6FF7F4FE99FC1201DA01B8030603CC041E02CD01FA027EFD3E059CFB3A0650FC44053FFF2F035E045A00980"
	$bData &= "8FFFD89078AFE1702DA01A5FEFE034E004D02220333FF26041DFFDC052C0352096507370A33078B05F70325FFFD021FFD1A05F2FF8E06160377052504E9024A044500D5030BFE58011CFC9BFCA1FB2CF815FE71F7EA0074FA11004EFDCCFC34FD8DFB79FB38FDFAFA2EFE7DFCD1FAC2FD88F5EEFCC8F5F1FB3AFDFEFCF2032CFE4B0309FDF8FD4EFB04FB0AFC09FDB4FE5100D7FF54010CFE290152FC5B0120FED700610213FFDB0490FD260411FE4B036E0026048E01A9030CFF4FFF8AFBB3FA40FBC9FA56FE34FE7C016FFFA801F2FC17FFB7FA1BFDE8FB53FDB3FE44FD71FF31FBD5FDC6F943FD67FCF2FF01027F03600518040E03D0014FFD"
	$bData &= "3E00CDF82D01C3F7EA014BFA0EFFECFF1FFA600656F86A095FFB70063EFF090037003AFC27FFE6FD21FFD801E7007F032D023202AC019800D401DE00B2042A029507E40176061500D701E5FFCBFD750245FCA0049BFB160380FA45FE5CFA92F979FC65F70AFFE2F6E1FE88F667FBDBF68DF725F880F6A2F814F87DF7B4F907F775FAC0F9B7FB68FECBFD19011EFF6200DAFEE5FEE0FD71FF8DFDFB01A8FE6704BA008404AA0252022F049C007E059301ED05F103950448053302250521017E04D40219042F062D0455092604700B6003890BEE02930864049903A806F3FE0E07F4FB22056CFB6702CCFDAFFF380145FD51021DFCE5FFC1FC14FCF"
	$bData &= "9FD8DF917FE0DF9BDFCD9F9B9FA59FB65F98CFD49FA3D006FFD1D02AA00670142027DFE9F0277FC9F026CFD5902EFFF8101A70121006A0239FF3D03AAFF120482000A046F00F80225008F01FD00E6008D02D6016003BE032D0301052A033805FA0320059204C804F803AE03DD02F301960265009503ACFFDE0482FFB00445FF900264FF2C00AC0036FF390233FF5B02B1FE3801BEFD850086FDFB0012FE96017FFE8801E1FE2D01D8FFCF0035013800170285FF9D01E9FE0E0078FE97FFCDFEC2013B00CC049E01F605BB0117050B01F70329018B03BB021E039D041102820545019805EB019605BE034A054B054B042605FE02FF0220021C0083"
	$bData &= "01E7FD26005BFCEEFD31FB09FC1FFB48FB5EFC5CFB76FD72FB11FDE3FA17FC1EFA39FC43FA36FD50FB9BFD88FC69FD16FEC0FD5700E3FECC022D006E0419015D04930103030A02EF013503B301E904A201A505810179048701B102DA010E02A7026102610379022B031A027F02DC015602EF0157029401DB012C003F0192FE080134FEDB0020FF2E001C0037FF0E0040FE03FF11FD20FEE8FB20FE88FB6BFEFDFB2AFEDCFC00FDE4FD49FB45FE67FA1DFD49FB44FBEAFCB5FADAFD1BFCDCFD27FE4FFD63FFA0FCD4FF16FCFBFFDBFB5AFF8EFCA6FD96FE12FCA900EAFB09010AFDE9FF5FFE13FF21FF89FF6CFF8900F8FF25010C017201DB018A0"
	$bData &= "16E011D01470062000600CAFF06012FFFEC0175FEC001E6FDD700C3FDC1FF1EFE88FEB4FEDEFC1FFF0EFB2BFF58FA76FE4FFBC6FCABFC02FBEDFC62FA33FC17FBC1FB63FC4BFC58FD2AFDC6FD95FD81FE0EFEB3FF67FF520033010F005A02EBFF9F02A1008A02C20146026C029D01BC02000192031F016104AE018B03F2013601CF0145FF5A01F4FE8F00EBFF96FFC300AAFE6B002DFE60FF8BFED4FE6DFF15FF250060FFB900E7FE4101F9FD2E01CEFD3B00B1FE1EFFDBFFB2FEE400DEFE7A01D7FEE00055FE40FFD0FDE8FD9DFDACFDB5FD41FEFCFDF2FE74FE4DFF60FF5AFFC4005AFFF501A2FF780279007902A60132029B02EA013D031902"
	$bData &= "BD03AA02E203E0028003690246030D02E3038A029D041E032C04B202B202CF01760191011901F60114017C028000A50210FFF501ACFDC80077FDE5FF30FE1EFFC6FEF8FDC0FEBDFC1DFEFBFB1BFD0EFCA3FCC6FC5FFD48FD83FE06FDE4FE5CFCA1FEEEFB85FE66FCAFFEFAFDF6FED7FF8DFF3901660059020A015D036801D203EB01A403D9027F0304040404F704C9046205C4045705FE03E2046F03E6031103B902470203028201D3016501AD017701660137011E01F700B0002E01EDFFDF0129FF7A02EBFE510267FF6201630020007601CBFE2F02C8FD0F028EFDB400B5FD8EFE8EFDDFFC67FD88FCC9FD69FD60FEB3FE89FE24FF4BFE26FE7"
	$bData &= "DFEFDFCDEFF4CFDB101E4FE6E027700EB017A012F012E02BD009F0292008F02BF0031021B010A026501FC01A401A201B8014D01440160017300810112005B019200FD005701850097011B006C01BCFF43014AFFF2001CFF380057FF61FF41FFBEFE85FE2AFEE7FD7BFDFBFDEAFC5FFEA6FC6DFE7BFC09FE5FFCB8FDC1FCEAFDBBFD7FFEBDFE57FF91FF5600BF00DA0051026B002B03C9FFB1021600070246013602410274024402DA018B01EA00D6002900AD006EFFD200D6FE8200B4FE9DFFF6FEE8FE4AFFCCFE52FFD2FEF4FE82FE7BFEEFFD0EFE7AFDACFD64FD8AFD67FD91FD28FD5CFDF2FC2EFD3FFD6DFDE7FD91FD6CFE16FD81FE95FC37"
	$bData &= "FE07FDEEFD5AFE17FE66FFCDFE6AFF9FFFFFFEC5FFE1FE27FF15FFA2FEB2FFA4FEC200E9FEA0017EFFE1014800C901A9006A01FA00D200030285001003C800F7026301FF01ED012501DE0109012D01B50167006C02ACFF4802E6FE1D018FFE46FFE0FE88FD37FFC4FC15FF06FDA6FE9AFD56FEFEFD55FE05FE82FEDDFDCAFEEBFD15FF1DFEDBFE30FEF7FD4BFE4EFD59FE6BFD1CFEB5FDFCFDC8FD5EFE0DFEFCFEB7FE8FFF59FFE9FF87FFE6FF8FFFF6FF160086000D011A01F0013501B2022501620368019A03210246030803EF028403D3023C03A7026C022C02A401760180019E000F028AFF8D0280FE350247FEF30005FF3CFFF0FFDDFD9A0"
	$bData &= "0ADFD4B01BAFEE9013000E20136012A018C017E0072017C003601E000F6001701D0000201F200B30048012A006A01C2FF1901D9FFAC0038008E009C0093002D016500DF01370035026A00F401FE00AF01A3011A02E601E70293010B0325014D023F015E01E301A0007702FCFF51026AFF4D01E9FE210076FE87FF39FE69FF60FE58FFCDFE1DFF0FFFAFFEE2FE2FFEAFFEB7FDE1FE65FD3BFFABFD84FFC8FEF9FF0400820082009D002C0035008AFFCEFF55FFCFFFD7FFF9FF6B00DCFF7900A3FF4C00B9FF3F00F2FF2F000700FBFF3800A9FFA3006EFFEE00ACFFEF006300DF000601F3002A012701E6004D019A0044017E00F3004C002400CCFF"
	$bData &= "F2FE65FFF2FD66FF6FFD6FFF3BFD14FF43FD60FE85FDABFDCAFD3BFDE2FDFBFCCDFDB7FCADFDA7FCB3FD1AFDF1FDDAFD4CFE7FFEACFEEAFEECFE2EFF06FF51FF37FF55FF84FF43FF81FF3DFF16FF61FFD6FEADFF22FFFDFF98FF1800A3FFD7FF4AFF72FF1DFF3DFF5FFF43FFC0FF5DFF04007BFF4500A1FF9300CAFFC700E1FFA200CFFF06009FFF2DFF68FF85FE31FF2DFE06FFE6FDF3FE85FDE9FE41FDD6FE63FDB6FECFFD73FE23FEFCFD49FE83FD87FE63FDFAFEB6FD6DFF27FEB7FF57FEDDFF59FEE6FF7AFEB9FFC9FE54FF2CFFE9FE9EFFAAFE000096FE12009CFECBFFB9FE81FFEDFE76FF4BFF75FFD8FF2EFF5C00D4FE8800DDFE63005"
	$bData &= "6FF4400E6FF5B0057008300AA008900D2006200B7000B007E0074FF6D00CEFE830085FE8300BAFE53001FFF120068FFB6FF85FF14FF6EFF5FFE14FF26FEA5FEA0FE89FE50FFE6FE8EFF67FF4DFFABFFF4FEC8FFCAFE1200E9FEA2007DFF21017E0024015F01AE009501410041014100EF007C00CA009100930094005400C3007500F0000101CE007C0194009501C0008A0148019001C4017A0122023A017D02240187025D01EC017D0119013201C700C500EC008B00F1005600AB00EBFF56009DFFE0FFBDFF1DFFE7FF64FE8FFF32FEF3FE75FEC0FED4FE0CFF54FF6CFF0D00D2FFAE007800F0002C01150178015D0165018B015E016D01730151"
	$bData &= "0165016501420146014401B9003D013800E00035005B006500210061003A00520068008B009C00E200CC00FA00B200D20037009700C0FF49009FFFE2FFA4FF86FF9DFF50FFAEFF27FFDFFF01FFE2FF03FFA6FF34FF82FF6CFF8FFF88FF81FF91FF56FF90FF76FF8AFFDCFF98FFF7FFC5FF9DFFF1FF51FF070066FF2F0088FF790065FF880026FF0C0016FF5CFF4FFF2CFFC7FF93FF3E00F1FF3B00CDFF8BFF5DFFC0FE1AFFA9FE27FF63FF62FF5900AEFFF500F0FFFB0005007200F5FFAEFFEDFF35FF010047FF040096FFCDFFB0FF6EFF85FF17FF4AFFDDFE24FFB2FE0DFF8CFEFAFE72FEE7FE79FED6FEA9FECFFEE6FECAFE06FFBCFEFCFEB9F"
	$bData &= "EF0FEDFFE10FF1FFF53FF3EFF93FF38FFBAFF5AFFD9FFC4FFFEFF2D001E00430023000A001200B5FFF9FF68FFD2FF49FF8EFF84FF3FFFF2FF12FF1C0003FFCFFFE9FE64FFCAFE3BFFF3FE2BFF7BFFDDFE020069FE1C0037FECDFF72FE62FFE0FE13FF4CFFF1FEA8FFFAFEE5FF05FFE4FFE6FEB1FFB4FE83FFB9FE79FFFAFE80FF3DFF80FF73FF80FFC7FF8BFF33009EFF7800AFFF9400C3FFC600F4FF130156002A01DC00DE005D015500AD01CBFFA90174FF2E017BFF3F00CDFF43FF0100D6FECFFF31FF83FFD7FF93FF1600F5FFB9FF44001CFF5A00BAFE7000E2FEA300A0FFC300B3009D0091014600BE0101003101FDFF62002700ECFF5500"
	$bData &= "12006C008A006700BC00280059009FFFA3FF09FF0BFFD7FEC6FE2AFFC7FEAEFF0AFF000083FF0B00FAFFE1FF2400A2FFF1FF86FFA2FFC8FF95FF5000E9FFB4005F00A90098004C007900EFFF3F00D1FF1400F2FFE2FF1800AAFF0B00ABFFDAFF0400CBFF6800EAFF8000F7FF4F00D2FF0E00B7FFEDFFD5FF0A0003005B000E0088000F0041003600BFFF670088FF6C00B0FF4B00D5FF3900D7FF3800F8FF11004300BEFF5E007EFF1A0084FFBFFFB5FF94FFDEFF9BFFFBFFC9FF20001E00420071004A008200480048005700FCFF6900DAFF6100EDFF4100200014004400D2FF320088FFE7FF72FF85FFB3FF26FF0C00E0FE2400E3FEF1FF4EFFB"
	$bData &= "2FFF6FF9CFF7C00B7FF9B00E9FF44000600A4FFEBFF2BFFB7FF53FFADFF1300CCFFC300C6FFC90083FF360058FF92FF8AFF45FFE4FF60FF0500C5FFF3FF3F00F4FF93001500A100290076002D0034005E000900BC001C00ED005B00A9007100180027009BFFB2FF5BFF6AFF4CFF57FF6DFF41FFB2FF20FFE1FF2AFFC3FF74FF7FFFCDFF69FFFBFF8BFFFBFFACFFEDFFBBFFDEFFE1FFBCFF1D0076FF31001DFFFFFFDCFEB1FFDDFE78FF29FF4EFF95FF1EFFD5FFF4FEBEFFEEFE74FF14FF4AFF4CFF6DFF71FFBBFF77FFF5FF81FF0000B2FFE8FFF8FFBCFF1A0082FF050057FFE7FF66FFDCFFA7FFD5FFD6FFC5FFC8FFCAFFA8FFF1FFC0FF110012"
	$bData &= "0001005100CAFF4C0096FF180073FFE2FF58FFB2FF4AFF7DFF65FF4EFFADFF31FFF2FF1CFFF6FF08FFB4FF15FF6FFF65FF66FFDAFF9AFF2A00D2FF3600DFFF2100B6FF0F0076FFF9FF48FFD2FF3FFFAAFF50FF88FF78FF58FFBEFF19FF0F0007FF3F0057FF4700E9FF510064006E009A007A00A8006E00BD007C00EC00C600210123012D015201F6003D019D00E000610048005300B4FF4B0085FF3700D1FF27003D0013006C00DEFF6D00ADFF8300DBFFBC007200EF00FA000B010C011601D2000501B600C200DF0063001E011D003B010B001201120098001300FDFF0700A2FFF7FFBCFFF1FF13000200490036003E007400180094000F008D0"
	$bData &= "0370083006C007C00760051004A00FDFF1500CBFFF4FFF4FFE2FF4200E5FF51000F001D003D0001003900300019007A0029009E0074009500AF008000AE006F008F006800690071002F008000F4FF7500F8FF4E0046002900900015008B00F5FF4700C3FFFEFFB4FFD2FFF1FFC3FF4A00D0FF6600F4FF34000F00F2FFF5FFCAFF98FFB0FF2AFF9DFFFAFEB5FF2DFFF3FF98FF0D00FDFFCFFF49006CFF730033FF520031FFD5FF41FF56FF58FF53FF78FFC5FF8FFF1E008FFFF0FF7CFF60FF61FFD9FE5AFF9DFE8EFFBDFEE8FF2DFF0200B6FFA6FFFEFF30FFE2FF25FF95FF7BFF57FFC7FF36FFD5FF2BFFBDFF3AFF7EFF5DFF02FF67FF7DFE3AFF"
	$bData &= "5CFEF9FEB5FEDBFE29FFEAFE5CFFFAFE4CFFF0FE24FFEBFEFAFE24FFE9FE9AFF1FFF0900A2FF2F00290010006200D5FF51009DFF310080FF1A0098FFF8FFD3FFC6FFF7FF9FFFE7FF94FFBBFF8EFF8CFF80FF64FF7CFF60FF8BFFA5FFA4FF1700CDFF6C000D0084004400840041007F0013005600FDFFFEFF0D00ABFF0E0091FFEFFFB0FFDDFFF3FFE6FF3900DCFF4600A6FFF1FF6FFF74FF60FF48FF72FF85FF8FFFCAFFAEFFD0FFB7FFBEFF9FFFC6FF9FFFCCFFF1FFA7FF690071FF900064FF4900A7FFF0FF3700D2FFD700E0FF1E01FEFFD30031002D006800A8FF770096FF6100F0FF55006F005900C3004B00B80033005B004200E9FF7600A"
	$bData &= "2FF8B00A4FF5800E0FF03002600C5FF4700B0FF3F00B4FF3D00C7FF6000DFFF8200E8FF6900C9FF15008EFFC1FF6AFFA1FF8EFFB7FFEFFFE4FF53000B0083001D007A001C0066001A006F002C008E005A00970090007600AD003D00AB000A00AC00F2FFC2000400CF002E00B10049007800430047003B001F004D00F2FF6C00C7FF8700B3FFA000B9FFB500D1FFA400EEFF59000400F7FF1600B8FF3600B1FF6300D0FF7B000000670029004100300025000B000C00DAFFF0FFD2FFE6FF0100020042002C00650044005300550021006D00FAFF6600F6FF0E00000098FFF7FF78FFE6FFD6FFE8FF5000F1FF8000D3FF590091FF080070FFA9FF98"
	$bData &= "FF60FFDAFF6DFFFCFFE9FF160089005600DC009C00BD00A90074008900590084006F009C0079008F005F004B0045000B005100F4FF6F00EDFF7000E3FF3F00E5FFF6FFF7FFB8FF010093FFFCFF88FFFDFF9DFF0900D2FF0A000600F1FF0400D0FFCBFFBCFF95FFB5FF96FFBAFFC9FFD9FF0C000F0048003200620022004C00F4FF1D00D7FF0700DDFF0E00F6FF02001200CFFF2200B0FF1E00D8FF170029001F00520030003E00330014002100F3FFFCFFD9FFCDFFCCFFA0FFF3FF8AFF45008BFF660092FF050091FF5DFF85FF00FF75FF1FFF70FF55FF84FF57FFA1FF55FFA8FF8EFF90FFCEFF67FFCAFF3CFF99FF1AFF85FF1CFFA1FF53FFCDF"
	$bData &= "F9DFFEDFFBEFFEAFFA9FFBDFF88FF86FF87FF6DFF9EFF66FFACFF59FFA8FF59FFABFF84FFC4FFB7FFDFFFB6FFDFFF91FFCDFF8EFFCCFFBCFFECFFE7FF0800EBFFF7FFDCFFC4FFD3FF9EFFD1FF98FFD4FFA3FFE1FFB0FFF0FFC5FFEFFFDBFFE3FFD6FFE8FFB3FFF6FF8FFFEBFF87FFBCFF9EFF87FFC6FF66FFF4FF69FF1A0098FF2000E4FFFFFF1F00D5FF3100C6FF3600D6FF4B00EFFF5F000D00550031003F0046003B003100470002004300E5FF2F00E9FF2400FCFF2F0012003A002F003E004C004F00570073004F008300480063005100310065001C006C001F005F0014004B00F3FF3400DDFF1000EEFFE9FF2900DBFF7800FDFFB6003B00"
	$bData &= "BA007100850085004A0080003B0086005700A9007700C5007E00B400640083003A005F002A00530056004900A0003700B90026008A0019004900170028002A001C005000110073000E0081001E0073002E004A00300010003800E6FF5800EBFF83001600980043008600550058004A0025003100FDFF1900E7FF0B00E3FF0500E5FFFEFFE2FFF4FFE3FFF1FFFDFFF9FF2800FCFF4600EFFF4900D9FF3E00C4FF2E00B3FF1A00B2FFFCFFD4FFCDFF0D0096FF2E007AFF1C008FFFF4FFB7FFD8FFCBFFC7FFD6FFB9FFEEFFBEFF0400DBFFFCFFECFFEEFFD2FF0000ACFF2000B1FF1800DDFFDDFF0100A6FF0E00A4FF1900CBFF1900E5FFF3FFD4FFB"
	$bData &= "4FFABFF85FF83FF6AFF65FF51FF51FF45FF4CFF5FFF5BFF8EFF73FFA0FF83FF86FF81FF5CFF70FF4AFF63FF5DFF69FF7DFF79FF8AFF82FF7FFF87FF79FF95FF8AFFABFFA2FFBAFFAEFFBFFFB2FFC5FFBBFFCFFFC0FFDBFFBBFFEDFFBBFF0C00D4FF2000F6FF0A000100DDFFF5FFD6FFFCFF0A002400480043005D003800510018004A0000004700F0FF3200E2FF0E00DEFFEEFFE3FFE2FFE2FFDFFFE4FFDDFFFBFFDDFF1A00DFFF1D00DEFF0A00DCFF0300E4FF1100F4FF1600FBFFFEFFF0FFD2FFE2FFAEFFDAFF9EFFCFFF9CFFB8FF97FFA2FF90FFA0FF9CFFB6FFC7FFD7FFFFFFEEFF2000F1FF2400EEFF2B00FCFF470017005F0027004E0025"
	$bData &= "0024001E000D001E0019002800230039000F004500E7FF3D00D2FF2400E0FF1000FFFF1100170022001C003300170038001A00300034002E005E0041007C0063007C0087006A00A8005F00BE006000BA005D009C004E0072003D004E0036003C0040003F0052004B005A0045004B002700290009000C00FFFF0700FFFF1500FBFF1C00FCFF18000C001A0026002D003B003F00440043004100450038004B00300040003100220036000D0033000E0022000C000700FCFFEBFFF0FFCDFFF1FFB5FFEEFFAAFFE1FFB7FFD4FFD6FFCCFFF4FFCFFFFFFFE2FFF4FFF8FFE8FFF7FFEAFFE3FFF2FFD9FFF1FFE0FFEEFFE3FFF5FFDCFFFBFFDBFFF2FFE9F"
	$bData &= "FE6FFF4FFF7FFEDFF2800E1FF5500DDFF5E00E1FF4500ECFF250008000D003000F7FF4E00ECFF5000FAFF41001F002F003A001D0037000B00210005001500100020001E003600240040002200330016001E00F9FF1200D8FF0B00D1FFFAFFEEFFE6FF1A00DCFF3400DBFF3100E2FF2200FAFF1B001B001C002E0013002600FDFF1100E2FFFAFFC7FFDFFFAAFFC2FF97FFAEFF9DFFABFFB3FFB3FFBFFFBBFFBAFFBFFFBCFFC3FFD3FFC9FFEFFFD0FF0000D9FF0B00ECFF1700090015002100FAFF2600D6FF1200BEFFEDFFB8FFCDFFC1FFC5FFD6FFD5FFF0FFEEFF020008000900200003002300F2FF0400E2FFE0FFE5FFD9FFF6FFE5FF0300E8FF"
	$bData &= "FEFFE8FFEAFFF4FFD0FFF4FFC2FFCEFFCBFF9FFFE1FFA0FFEBFFD0FFE3FF0000D9FF1600DBFF1900EAFF0E000400FCFF2000FAFF2C0012002500280019002300100010000B0005000F00FAFF1600E6FF0E00DAFFF0FFE8FFCAFFFFFFACFF0600A4FFFBFFB9FFE8FFE4FFD2FF0900C5FF1400D5FF0B00FFFFFFFF1F00F5FF1500F0FFEFFFFAFFE0FF1600090034004F003E007800320066001A002E000300F3FFFFFFD0FF1E00D2FF5300FAFF6F0033005500630020007A00FAFF6B00F2FF3C00020008002400EFFF4900FAFF51001500370025001E0024001D001E0025001B0023001B001D001E001A002B00190043001C0052002E00450041002"
	$bData &= "1003700FCFF0E00E8FFEDFFEAFFEAFFFAFFEAFF0A00D9FF1000CBFF1000D4FF0C00E3FF0300E6FFFAFFE8FFFEFFFDFF09001B000B002E00FFFF3700F4FF3F00FDFF42001C003100430011005400F6FF3F00EDFF1200EFFFEEFFF2FFE5FFFBFFF4FF0E0012001A0028000E001F00F5FFFBFFF2FFDDFF0700E2FF1C00FEFF220014001C0019000C001400F3FF0B00DFFF0100DEFFF3FFEDFFE1FFF9FFD1FFF4FFD3FFE4FFF4FFDEFF2300ECFF3C00FEFF30000400150006000E0018002500310044003600540023004B000F0031000E000A001B00DEFF2500C4FF1E00D2FF0B00FEFFF4FF1E00D5FF1C00B4FF0A00ACFFFEFFCBFFFDFFF8FF05000A"
	$bData &= "00140001001F00F7FF1400F0FFF4FFE4FFD4FFDAFFC2FFE5FFBFFFF6FFC2FFE8FFC3FFBAFFBEFF95FFB8FF95FFB6FFAAFFB9FFBAFFC3FFC1FFDBFFC5FFF8FFC5FF0400C6FFF5FFD4FFD8FFECFFC5FFFEFFC3FFFDFFCBFFEBFFD9FFD1FFF3FFC3FF1100CDFF1F00E4FF0E00EDFFF3FFE2FFECFFDBFFFEFFE5FF1500F9FF1D00080014001500FFFF2200EDFF2300E7FF1300ECFFFEFFEEFFF3FFE6FFF2FFD5FFF2FFC9FFEEFFCDFFE9FFDEFFE0FFF3FFD1FF0400C5FF0D00C5FF0A00D1FF0300E1FF0900EEFF1E00F2FF2A00EFFF1B00EEFFFBFFF7FFE1FF0200D0FF0700CAFF0700DAFF0600000004002200FFFF2900F8FF1C00F1FF1100F0FF0C0"
	$bData &= "000000B0016000B00200007001C00FAFF1600ECFF1400EEFF0D00FEFF01000800FDFF0800030013000C002D001500430019004200160030000F001A000C000B000D0007000F000D000D00120007000F0002000700080000001500F6FF1C00EDFF1800EEFF1300F7FF1600FFFF1700010010000000060002000500090008000F0004000F00F7FF0600EAFFFEFFE4FF0000EAFF0800F7FF0B000500FEFF0800EFFF0000F2FFF9FF0200FFFF08000E00FAFF1A00EEFF1E00F9FF1C001200160025000C002A0000002300F7FF0D00F6FFECFFFBFFD6FF0000D9FFFEFFF3FFF7FF1100EEFF2500E8FF2800E7FF2000F4FF19000C001B00210023002900"
	$bData &= "2E0028003B0027004A0028004F002B003F0034001F003F000700430008003C001B0030002B00270032002200370025003A00310034003C00210035000F001F0008000E0008000B0006000800FAFFF9FFEBFFE9FFE4FFE8FFE9FFEEFFF1FFEDFFF6FFE4FFF8FFDCFFF5FFD8FFF2FFDBFFF4FFE7FFFFFFF5FF0D00FAFF1100F8FF0A00FBFFFDFF0700F5FF1100F8FF140009001400250018003B001C003C0018002B000D001D00070020000C002C0014003600140039000C0038000400320001002500050016000E000900190003001F000200190003000F0009000A0014000C001A000D00120004000500F4FF0300E8FF0900E7FF0B00ECFF0200F"
	$bData &= "3FFF3FFF8FFE5FFFBFFD9FFF9FFD3FFF0FFD9FFE5FFE4FFDFFFE8FFE1FFDFFFE5FFD4FFE4FFD2FFE0FFDCFFDCFFE8FFD9FFEDFFD6FFEEFFD1FFF2FFCBFFFDFFCAFF0E00D4FF1E00E4FF2000F0FF0E00F4FFF7FFF8FFEBFF0200EFFF0D00F8FF1100FEFF0C0000000400FCFFF9FFF5FFEBFFF2FFE0FFFCFFDCFF0B00DEFF0D00DBFFFDFFD3FFEDFFD1FFECFFDDFFF8FFECFF0300F8FF0600050004001200FEFF1700FBFF0E00FFFF03000B00020014000A0014000E000E000B00080004000400FCFFFEFFF7FFF8FFF9FFF3FF0300EAFF0B00DCFF0800D2FFFCFFD6FFF1FFE4FFECFFEEFFEBFFEDFFEEFFEBFFF3FFEFFFF7FFFBFFF6FF0C00F2FF18"
	$bData &= "00F1FF1B00F1FF1300F3FF0800F6FF0300FCFF0500020004000400FEFF0100F7FFFDFFF7FFFCFFFDFFFFFF060003000C0004000F0000000A00FAFF0000F6FFF9FFF5FFFDFFF7FF0700FBFF10000100130008001300100010001900090022000300260003002600080024000C0023000C001F000D00140012000D00180011001B001E00190027001700260017002400190022001A001C00170013000F000D0004000E00FBFF0C00F9FF0300FEFFF9FF0500F7FF0C00FCFF10000000150003001A000D001E001B001F0023001C001D0016000F000E0002000900FEFF04000200FEFF0B00F8FF0F00F5FF0B00F6FFFFFFF8FFF4FFFAFFEEFFFBFFEFF"
	$bData &= "FFFFFF4FF0200FCFF02000100FCFF0300F9FF0100FBFF0000FEFF0300FBFF0A00F4FF1200F4FF1400FFFF12000D000C001200070011000300110000001500FDFF1900FDFF1B0001001A00070015000C000A001000FEFF1100F5FF1000F1FF0B00F2FF0500F7FF0000FFFFFCFF0400F8FF0200F5FFFEFFF3FFFEFFF1FF0100EFFF0100EEFFFCFFF0FFF6FFEFFFF2FFECFFECFFEAFFE3FFEBFFD9FFECFFD4FFE9FFD3FFE6FFD8FFE5FFE2FFE6FFEAFFE4FFEDFFE3FFE9FFE8FFE8FFEEFFEFFFF0FFFAFFEAFF0300E5FF0600E5FF0400E6FFFBFFE8FFF0FFE9FFECFFEDFFF3FFF0FFFAFFF0FFFAFFF2FFF7FFF6FFF7FFFBFFFAFFFDFFFBFFFDFFFAFF"
	$bData &= "FEFFFDFFFFFF0300FEFF0A00FBFF0F00F8FF0D00F5FF0300F1FFF3FFEEFFE8FFEFFFEAFFF2FFF3FFF6FFF7FFF8FFF1FFF8FFE9FFF8FFE5FFF8FFE8FFF9FFF0FFFDFFFCFF0100030002000300FFFFFEFFF8FFFCFFF1FFFFFFECFFFEFFEAFFF8FFEBFFF1FFECFFECFFEBFFECFFEBFFEFFFEDFFF5FFF2FFFCFFF4FFFFFFF4FFFFFFF4FFFFFFF9FFFFFF0300FCFF0A00FAFF0C00FFFF0B000A000800120004000F00FDFF0700F6FF0200F2FF0200F3FF0000F8FFFAFFFFFFF7FF0500FCFF0700040005000800030005000400FEFF0700FCFF0900020006000B000300100000000E00FFFF0700FFFF0000FEFFFDFF0000FFFF060003000E00040013000"
	$bData &= "30013000300100007000F000C00100010001100100011000E0011000C00100009000E0008000C0009000A000C0008000B00060007000400030004000200080004000F00080011000B000F000D000A000C0008000900090006000C0004000F000200100002000D000200090005000500080002000B0000000C00FDFF0A00FBFF0500FBFF0100FEFFFFFF03000100080003000800030002000200F9FF0100F4FF0100F6FF0100FCFFFEFF0100FAFF0300F6FF0400F5FF0500F7FF0600FAFF0600FCFF0800FDFF0900FEFF0B00FEFF0A00FFFF080000000600010002000000FEFFFBFFF8FFF5FFF4FFF2FFF4FFF5FFF8FFFAFFFDFFFDFF0000FDFFFE"
	$bData &= "FFFBFFFBFFFAFFFBFFFAFFFDFFFCFFFFFFFEFFFEFFFFFFFAFFFDFFF6FFFBFFF6FFFBFFF9FFFCFFFBFFFDFFF9FFFCFFF4FFFCFFF2FFFDFFF6FFFDFFFCFFFEFF0100FFFF0200010000000100FDFFFEFFFCFFFCFFFCFFFDFFFDFFFDFFFDFFFAFFFCFFF7FFFCFFF7FFFFFFF9FFFEFFF9FFF9FFF7FFF4FFF6FFF4FFF6FFF8FFF7FFFDFFF7FF0200F9FF0500FBFF0700FCFF0400FEFFFFFF0100FBFF0300FAFF0200FBFFFEFFFBFFF9FFFAFFF7FFF9FFF7FFF7FFF8FFF7FFF9FFF8FFF9FFF9FFF9FFFAFFF8FFF9FFF9FFF8FFFBFFF8FFFEFFFAFF0000FCFF0200000000000200FBFF0300F7FF0300F7FF0400FAFF0500FEFF0300000001000000FEFFFFF"
	$bData &= "FFDFFFDFFFDFFFDFFFDFF0000FFFF03000300050005000500020005000000060000000600020004000200020000000200FEFF040000000300030001000400000003000200FFFF0300FBFF0400FCFF040002000400080003000A0001000700000003000000030000000600FFFF0800FDFF0800FDFF0500FEFF0100FFFFFEFF0100FEFF0100FEFF0000FEFFFEFFFEFFFEFFFFFF00000100030003000400040004000400030004000200050000000400FDFF0200FCFF0000FEFFFFFF0000FFFF02000000030000000400FFFF0400FEFF0400FDFF0400FDFF0400FCFF0400FEFF040001000400040002000300FFFF0000FFFFFDFF0100FCFF0400FEFF"
	$bData &= "050001000400040001000500FFFF0400FEFF0200FDFF0000FDFF0000FEFFFFFFFFFFFFFF0000FFFF0000FEFF0000FDFFFFFFFCFFFEFFFDFFFFFFFEFFFFFFFEFFFFFFFDFFFFFFFDFFFFFFFEFFFFFFFFFFFFFF0000FFFF0000010000000200000001000000FFFF0000FEFF0100FEFF0200FFFF0200FFFF0100FFFF0000000000000100FFFF0100FFFF0000FEFFFFFFFFFFFFFF000000000000010000000100FFFFFFFF0000FDFF0000FDFF0000FEFFFDFFFFFFFBFF0000FBFF0000FDFF0000FEFF0100FDFF0300FBFF0400FAFF0200FCFF00000000000003000200040002000200FEFF0000FBFFFEFFFDFFFEFF0000FEFF0100FDFF0000FCFFFFFFF"
	$bData &= "CFF0000FEFF01000000020000000100FFFF0000FFFFFFFF0000FFFF000001000100030001000200020000000200FFFF0200000001000000010000000100FFFF0100FFFF0200FFFF0200FFFF0200010002000200010001000100000000000000FFFF0200FFFF0400000003000000020000000000FFFF0000FEFF0100FEFF0200FDFF0200FEFF0100FFFFFFFFFFFFFEFFFFFFFFFFFEFF0000FFFF00000000000001000100010002000000030000000200FFFF0100FFFF00000000FFFF0000FFFFFFFF0000FEFF0100FEFF010000000000010000000100FFFF0000FFFF0000FFFF0100FFFF0100000001000000020000000100000000000000FFFF00"
	$bData &= "00FFFF0000010000000200010002000100020000000100FFFF0100FFFF010000000200000002000000020000000100FFFF0100FFFF0000000000000000000000000100FFFF0000FFFF00000000FFFF0000FFFF0000FFFFFFFF00000000FFFF0100FFFF0100FFFFFFFF0000FFFF0100FFFF010000000000FFFFFFFFFFFFFFFFFFFFFEFF0000FFFF0100FFFF0000000000000000000000000000FFFF0000FFFF0000FFFF000000000000010000000100000000000000FFFF0000FFFF00000000000000000100000000000000000000000000000000000000010000000100010000000100000000000000FFFFFFFFFFFF0000FFFF000000000000000"
	$bData &= "000000000FFFF0000FFFF0000FFFF0000FFFF000000000000000000000000000000000000FFFF0000FFFF00000000FFFF0100FFFF0100FFFF0100000000000000000000000000000000000000FFFF0000FFFF00000000FFFF0000FFFF0000FFFF0000FFFF0100FFFF010000000100010001000100010001000000000000000000FFFF0000FFFF0000FFFF00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFF0100FFFF0000000000000000FFFF0000000000000000FFFF0000FFFF0100FFFF0000000000000000"
	$bData &= "FFFF0000FFFF0000FFFF000000000000000000000000FFFF0000FFFF00000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFF0000FFFF0000000001000000010000000000000000000000FFFF0000FFFF0000FFFF00000000000000000000010001000000000000000000010000000100000001000000010001000100010000000000000000000000000001000000000000000000010000000100FFFF0100FFFF01000000010000000100000000000000000000000000FFFF0000FFFF000000000000000001000000000001000000010000000000FFFF00000000F"
	$bData &= "FFF0000FFFF0000FFFF000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001000000010000000000000000000000FFFF0000FFFF0000FFFF00000000000000000000000000000000FFFF0000FFFF0100FFFF01000000010000000000000000000000FFFFFFFFFFFFFFFFFFFF0000FFFF0000FFFF0100FFFF0100FFFF0000000000000000FFFF0000FFFF000000000000000000000000000000000000FFFF0000000000000000000000000000000000000000000000000000000000000000FFFF0000FFFF0000FFFF0000000000000000000000000000000000000000FF"
	$bData &= "FF0000FFFF0000FFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000FFFF0000FFFFFFFF0000FFFF000000000000010000000100FFFF0100FFFF0000000000000000FFFF00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000010000000000000"
	$bData &= "000000000FFFF0000FFFF010000000100000000000000000000000000000000000000000000000000000000000000000000000000FFFF0000FFFF000000000000000000000000000000000000FFFF0000FFFF0000FFFFFFFFFFFF0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFF0000FFFF00000000000000000000000000000000000000000000FFFF0000FFFF0000000000000000000000000000000000000000FFFF0000FFFF00000000FFFF0000FFFF0000000001000000000000000000000000000000000000000000FFFF"
	$bData &= "0000FFFFFFFFFFFFFFFF0000FFFF000000000000000000000000000000000000000000000000FFFF0000FFFF00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFF0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000FFFF0000FFFF0000000001000000010000000000000000000000000000000"
	$bData &= "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFF000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	$bData &= "000000000000000000000000000000000000000000000000000000000"
Return $bData
EndFunc