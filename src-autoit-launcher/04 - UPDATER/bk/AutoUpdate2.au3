#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon\system_software_update.ico
#AutoIt3Wrapper_Outfile=D:\ADVMENU\ADVMENU_01\ADVMENU_VENDA\AutoUpdate.exe
#AutoIt3Wrapper_Res_Description=Updater
#AutoIt3Wrapper_Res_Fileversion=1.0.0.67
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

Sleep(800)

Global $iProgress1,$iProgress2,$iLbl_1,$iLbl_2,$iLbl_3,$iRich ;gui
Global $Grey_BT,$Grey_BT_HOVER,$Grey_BT_HOVER2,$blue_BT,$blue_BT_HOVER,$blue_BT_HOVER2,$aHoverBtn[5][7]	;Botões
Global $Red_BT,$Red_BT_HOVER,$Red_BT_HOVER2,$green_BT,$green_BT_HOVER,$green_BT_HOVER2,$purple_BT,$purple_BT_HOVER,$purple_BT_HOVER2,$iMG_Bk			;Botões
Global $BT_CLOSE,$BT_CLOSEh,$BT_CLOSEh2,$BT_MINI,$BT_MINIh,$BT_MINIh2									;botões IMGS

Global $TRY_CONNECT_COOLDOWN = 8000	;Tempo de cooldown para verificar atualização de novo
Global $TRY_CONNECT_TIMES	 = 10	;Tentativas maximas de tentativas

Global $Looping			= 1 ;Loop principal
Global $ETAPA_DOWN_FILE = 0,$START_DOWN_FILE=False ;Etapas de verificação do servidor
;LEITURA DO SISTEMA
Global $ETAPA 			= 0 ;0 = Verificando servidor | 1 = Pronto para baixar | 2 = Pausado | 3 = Baixando | 4 = Movendo arquivos | 5 = Acabou (Iniciar Sistema)
Global $UPDATE_URL 		= "https://canal8bits.000webhostapp.com/UPDATER/UPDATER.txt"
Global $iURL_LOG 		= "https://canal8bits.000webhostapp.com/UPDATER/log.rtf"
Global $iURL_FOLDER 	=  "https://canal8bits.000webhostapp.com/UPDATER/"
Global $TICK_GLOBAL		= _TICK_UPDATE()
Global $TICK_CHECK_ATT  = _TICK_UPDATE(), $First_try = True,$Try_times = 0
Global $Title 			= "AutoUpdate.exe"
Global $iARCADE_EXE 	= "ARCADE.exe"
Global $iTempDir 		= @TempDir & "\~pw_f\"
Global $iDownload_conect

Global $SHOW_LOG = False

if $CMDLINE[0] > 0 Then
	if $CMDLINE[1] = "-log" Then $SHOW_LOG = True
EndIf

FileDelete(@ScriptFullPath & "_del")
Global $PATH_INSTALACAO = @ScriptDir
Global $Need_install = True
Local $iGetInstall = _Reg_CheckInstall()
if Not @error Then
	$Need_install=False
	$PATH_INSTALACAO =	$iGetInstall
EndIf

Global $iARR_LOCAL_FILES_VERSION =_LoadLocalFileVersion($PATH_INSTALACAO & "\Server.txt")



Func _FileGetVersion($iArray,$iFile)
	if Not IsArray($iArray) Then Return SetError(-1,0,"0.0.0.0")
	Local $iresult = _ArraySearch($iArray,$iFile)
	if @error then Return SetError(-2,0,"0.0.0.0")
	Return $iArray[$iresult][1]
EndFunc

Func _LoadLocalFileVersion($iPath)
	Local $iFile = FileOpen($iPath)
	Local $iArray[0][2]
	Local $iVar = FileRead($iFile)
	if @error Then Return SetError(-1)

	_ArrayAdd ($iArray,$iVar)
	Return $iArray
EndFunc

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
			GUISetState(@SW_MINIMIZE, $hGUI)

		Case $aHoverBtn[0][0] ;Botão atualizar
			_GuiCtrlPic_AnimButton($hGui, $aHoverBtn[0][0], $aHoverBtn[0][1],$aHoverBtn[0][2], $aHoverBtn[0][3],20)

			Switch $ETAPA
				Case 2	;ATUALIZAR
					if $Need_install Then
						Local $iFolder = FileSelectFolder("Selecione uma pasta para instalação", StringLeft(@ScriptDir,3),0,"",$hGUI)
						If Not @error or $iFolder <> "" Then
							_Reg_Write($PATH_INSTALACAO)
							$PATH_INSTALACAO = $iFolder & "\"
							$FULL_LIST = _LendoLogOnline()
							$ETAPA = 3
							_Changer_Button("red")
							__set_status_info("")

						EndIf
					Else
						_Changer_Button("red")
						__set_status_info("")
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
					__set_status_info("")
					__set_status_bytes("")
					__set_status_Selected("")
					__Set_Status_bar1(0)
					__Set_Status_bar2(0)

					$START_DOWN_FILE = False
					$ETAPA_DOWN_FILE = 0
					$ETAPA 			 = 2
				Case 5	;INICIAR ARCADE.exe
					_ShellOpen($iARCADE_EXE,"",$PATH_INSTALACAO) ;Executar Arcade.exe
					Sleep(1000)
					$Looping = 0 						   ;Sair
				EndSwitch
	EndSwitch

Switch $ETAPA
		Case 0	;Verifica se pode atualizar - Se não tiver internet, ele vai tentar se conectar 10 vezes até desistir (Pensando em colocar verificações infinitas)
			$FULL_LIST = _LendoLogOnline()
			_ArrayDisplay($FULL_LIST)
		Case 3	;ATUALIZANDO....

				if Not $START_DOWN_FILE Then							;Inicia um download novo
					Global $iDownload_conect = InetGet(StringReplace($FULL_LIST[$ETAPA_DOWN_FILE][5], ".exe", ".exe_") , $FULL_LIST[$ETAPA_DOWN_FILE][4], $INET_FORCERELOAD,1)
					__set_status_info("Baixando " & $FULL_LIST[$ETAPA_DOWN_FILE][0] & "...")
					$START_DOWN_FILE=True
					__set_status_Selected($ETAPA_DOWN_FILE+1 & " / " & UBound($FULL_LIST))
					__Set_Status_bar1($ETAPA_DOWN_FILE / (UBound($FULL_LIST)- 1) * 100)
				EndIf

				if $START_DOWN_FILE Then								;Varifica se já baixou
					__set_status_bytes(_GetCurrentBytes($iDownload_conect) & " / " & _GetTotalBytes($iDownload_conect))
					__Set_Status_bar2(_GetCurrentBytes($iDownload_conect) / _GetTotalBytes($iDownload_conect) * 100)
					If InetGetInfo($iDownload_conect, $INET_DOWNLOADCOMPLETE) Then
						$START_DOWN_FILE=False
						$ETAPA_DOWN_FILE +=1
					EndIf

					if $ETAPA_DOWN_FILE > UBound($FULL_LIST)-1 Then		;Finaliza todos downloads
						__set_status_info("Movendo...")
						__set_status_bytes("")
						__set_status_Selected("")
						__Set_Status_bar1(0)
						__Set_Status_bar2(0)
						_Changer_Button("grey")
						$ETAPA = 4
					EndIf
				EndIf

			Case 4	;Transferir arquivos
				_Transferir_arquivos($FULL_LIST)
EndSwitch
Sleep(80)
WEnd
__exit_syst()



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
; Name ..........: _Transferir_arquivos
; Description ...:
; Syntax ........: _Transferir_arquivos($iArr)
; Parameters ....: $iArr                - an integer value.
; Return values .: None
; Author ........: Your Name
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Transferir_arquivos($iArr)
Local $Lr_update = False, $Lr_Path
Local $iTRANS_ETAPA = 1



	For $MOVENDO_STATUS=0 To UBound($iArr)-1
		__Set_Status_bar1($iTRANS_ETAPA / (UBound($iArr)- 1) * 100)
		__Set_Status_bar2(0)
			Local $iFileTempPath  = $iArr[$MOVENDO_STATUS][4]									;PATH DO ARQUIVO NA PASTA TEMPORARIA
			Local $iFileLocalPath = $iArr[$MOVENDO_STATUS][3] & $iArr[$MOVENDO_STATUS][0]		;PATH DO ARQUIVO NA PASTA DE INSTALAÇÃO
			Local $iFileName	  = $iArr[$MOVENDO_STATUS][0]									;NOME DO ARQUIVO BAIXADO
			__set_status_info("Instalando " & $iFileName &"..." )

			;Se o processo tiver em execução, então renomear o arquivo de destino para substituir
			if FileExists($iFileLocalPath) and ProcessExists($iFileName) Then
				FileMove($iFileTempPath,$iFileLocalPath & "_del",$FC_CREATEPATH + $FC_OVERWRITE ) ;Renomeia o arquivo de destino para "Arquivo.exe_del"
				Sleep(100)
				 FileSetAttrib($iFileLocalPath & "_del", "+H", $FT_RECURSIVE)
			EndIf

			if ProcessExists($iFileName) and $iFileName <> $Title Then _FileWriteLog ( $PATH_INSTALACAO,"Processo " & $iFileName&  " Não pode ser substituido, pois o mesmo está em execução" )
			;Se baixar autoupdater (Ativar o fechamento e abrir programa)
			if $iFileName = $Title Then
				$Lr_update = True
				$Lr_Path   = $iFileLocalPath
			EndIf

			;Move arquivo da pasta TEMP para a pasta de instalação
			FileMove($iFileTempPath, $iFileLocalPath,$FC_CREATEPATH + $FC_OVERWRITE )
			Sleep(100)
			$iTRANS_ETAPA += 1
			__Set_Status_bar2(100)
			Sleep(100)
	Next

	if $Lr_update Then
		_ShellOpen($Title,"" ,$PATH_INSTALACAO)
		$Looping = 0
	EndIf


	$ETAPA = 5
	_Changer_Button("green")
	__set_status_info("Concluido!")
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
		if @error Then
			$TICK_CHECK_ATT = _TICK_UPDATE()
			$First_try = False
			$Try_times +=1
			If $Try_times > $TRY_CONNECT_TIMES Then
				$ETAPA=5
				_Changer_Button("green")
				__set_status_info("Não foi possivel se conectar com o servidor!")
			EndIf
		Else
			$ETAPA=2
				__set_status_info("Pronto para atualizar!")
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
		Local $LOG =_INetGetSource($iURL_LOG)
		_GUICtrlRichEdit_SetText ( $iRich, $LOG )
	EndIf

	Local $iS = _INetGetSource($iURL)
	if @error Then Return SetError(-1)
;~ 	Local $aArray [0][6]
;~ 	_ArrayAdd($aArray,$iS,0,"|",@CRLF,  $ARRAYFILL_FORCE_STRING )
	Local $aArray = StringSplit ($iS, @CRLF, $STR_NOCOUNT)

	_ArrayDisplay($aArray)

	For $i=UBound($aArray) To 0 Step -1
			Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
			Local $aPathSplit = _PathSplit($aArray[$i], $sDrive, $sDir, $sFileName, $sExtension)

			Local $file_name_Remote = $aPathSplit[3] & $aPathSplit[4]
			Local $file_url_item 	= $aPathSplit[2] & $aPathSplit[3] & $aPathSplit[4]
			Local $file_vers_Remote = $aArray[$i][1]
			Local $file_local_folder= $PATH_INSTALACAO & "\" & $aPathSplit[1] & $aPathSplit[2]

			$aArray[$i][0] 	= $file_name_Remote
			$aArray[$i][3] 	= $file_local_folder

			Local $file_vers_local	= _FileGetVersion($iARR_LOCAL_FILES_VERSION, $aPathSplit[0])

			;FileGetTime(_PathFull($aArray[$i][3] & $aArray[$i][0]),  $FT_MODIFIED, 1) 	;Pega data da modificação dos arquivos ;
			;FileGetVersion(_PathFull($aArray[$i][3] & $aArray[$i][0])) 				;Pegava a versão do arquivo...não dava pra pegar arquivos normais.

			$aArray[$i][2] = $file_vers_local
			$aArray[$i][5] = $iURL_FOLDER & StringReplace($file_url_item,"\","/")

		if $file_vers_Remote > $file_vers_local Then
			$aArray[$i][4] = _WinAPI_GetTempFileName($iTempDir,"~wdl_")
		Else
			 _ArrayDelete($aArray,$i)
		EndIf
	Next

	if $SHOW_LOG Then _ArrayDisplay($aArray,"Info","",0,Default,"Executavel Remoto|Versão Remoto|Versão Local|Pasta do arquivo Local|Arquivo Temporario|Remote folder")


	if Not IsArray($aArray) or (UBound($aArray)) <= 0 Then
		__set_status_info("Atualização não necessária!")
		$ETAPA = 5 ;Não necessario atualizar
		Return True
	EndIf
Return $aArray
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
	if (FileExists($iRead_Reg & "\" & $iARCADE_EXE)) Then
		return $iRead_Reg
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
	For $i=0 To UBound($FULL_LIST)-1
		FileDelete($FULL_LIST[$i][4])
	Next

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