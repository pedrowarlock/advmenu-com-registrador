#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\icons\0015_padlock.ico
#AutoIt3Wrapper_Outfile=04 - Criptogafia do Sistema.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include "..\includes\AuConstantes.au3"
#include "..\includes\Encrypt.au3"

Local $sUserKey = BinaryToString("0x31333531326B3335686975313268357569313235313267753575693179326735")
Local $CRYPT, $CRYPANO, $iKEY
Switch @MON
	Case 01 to 04
		$CRYPT = 100
	Case 05 to 08
		$CRYPT = 200
	Case 09 to 12
		$CRYPT = 300
EndSwitch

Switch @YEAR
	Case 2019
		$CRYPANO = 100
	Case 2020
		$CRYPANO = 200
	Case 2021
		$CRYPANO = 300
	Case 2022
		$CRYPANO = 400
	Case 2023
		$CRYPANO = 500
	Case 2024
		$CRYPANO = 600
EndSwitch

$iKEY = $CRYPANO & $CRYPT
Local $chave = "HKCU"
If @OSArch = "X64" Then $chave = "HKCU64"

Local $sVar = RegRead($chave & "\SOFTWARE\microsoft\Active Setup" , "keytimer")
If $sVar = "" Then
	RegWrite($chave & "\SOFTWARE\microsoft\Active Setup" ,"keytimer","REG_SZ",$iKEY)
	$sVar =	$iKEY
EndIf


;~ if @Compiled Then
;~ 	_Crypt_Startup()
;~ 	if $sVar > $iKEY Then
;~ 		Exit MsgBox(48,"Erro","Erro!")
;~ 	Else
;~ 		RegWrite($chave & "\SOFTWARE\microsoft\Active Setup" ,"keytimer","REG_SZ",$iKEY)
;~ 	EndIf


;~ 	Local $iP = InputBox("Digite a senha", "Senha:", "", "*", 200, 130)
;~ 	Local $iK = _Crypt_DecryptData("0x" & $iP, $sUserKey, $CALG_AES_128)
;~ 	_Crypt_Shutdown()

;~ 	if  $iK <> $iKEY  Then
;~ 		Exit MsgBox(48,"Erro","Senha inváda!")
;~ 	EndIf
;~ EndIf

    Local $hGUI = GUICreate("Registro",500,280)

	Local $iLbl1 = GUICtrlCreateInput("",100,20,300,20)

	GUICtrlCreateLabel("RC CODE:",2,20,98,20)

 	Local $iLbl2 = GUICtrlCreateInput("Não entregar caso o valor for 0 ou um valor estranho",100,50,300,20)
	GUICtrlCreateLabel("HD:",2,50,98,20)

 	Local $iLbl3 = GUICtrlCreateEdit("",0,100,400,100,$ES_READONLY)
	GUICtrlCreateLabel("Serial Gerado:",2,80,98,20)




    Local $idOK2 = GUICtrlCreateButton("Gerar Serial", 310, 225, 85, 25)
    Local $idcolar = GUICtrlCreateButton("Colar", 410, 18, 85, 25)
    Local $idcopiar = GUICtrlCreateButton("Copiar", 410, 100, 85, 25)

	Local $idOK3 = GUICtrlCreateButton("Gerar Login", 10, 225, 85, 25)
	Local $iLbl4 = GUICtrlCreateInput("",100,228,200,20)

	if @Compiled Then
		GUICtrlSetState($idOK3,$GUI_HIDE)
		GUICtrlSetState($iLbl4,$GUI_HIDE)
    EndIf
	; Display the GUI.
    GUISetState(@SW_SHOW, $hGUI)

    ; Loop until the user exits.
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
			Case $idOK3
				Local $dEncrypted = _Crypt_EncryptData($iKEY, $sUserKey, $CALG_AES_128)
				GUICtrlSetData($iLbl4, $dEncrypted)
			Case $idcolar
				GUICtrlSetData($iLbl1 ,ClipGet())
			Case $idcopiar
				ClipPut(GUICtrlRead($iLbl3))
			Case $idOK2
				Local $iSenha1 = GUICtrlRead($iLbl1)
				if $iSenha1 <> "" then
					Local $iDescrip = __internal_str_to_crypt(False, $iSenha1, $O__UserKey1,$O__ENCRYPTKEY1)
					$iDescrip = StringReplace($iDescrip,$i__obs1,"")
					GUICtrlSetData($iLbl2,$iDescrip)
					GUICtrlSetData($iLbl3,__internal_str_to_crypt(True, $i__obs2 & $iDescrip & $i__obs2, $O__UserKey2,$O__ENCRYPTKEY2))
				EndIf
		EndSwitch
    WEnd


    GUIDelete($hGUI)

