INCLUDE Irvine32.inc
INCLUDE Macros.inc

main EQU start@0

GetFile PROTO, fileName:PTR BYTE, textTarget:PTR BYTE, textSize:DWORD
GetData PROTO, dataNum:DWORD
SLData  PROTO, dataNum:DWORD

ClearDialogue PROTO
ClearSaveText PROTO
ClearChoice   PROTO
ChangeName    PROTO, pName:PTR BYTE

Text         PROTO, pScript:PTR BYTE
OptionChioce PROTO, pScript:PTR BYTE
Condition    PROTO, pScript:PTR BYTE
Figure       PROTO, pScript:PTR BYTE

.data
; Key code =======================================
KEY_UP    WORD 4800h
KEY_DOWN  WORD 5000h
KEY_LEFT  WORD 4B00h
KEY_RIGHT WORD 4D00h
KEY_ENTER WORD 1C0Dh
KEY_ESC   WORD 011Bh
KEY_F10   WORD 4400h
; Console Variable ===============================
consoleHandle DWORD ?
fileHandle    DWORD ?
myTitle       BYTE "Toolbox", 0
consoleBuffer COORD            <81, 33>
smallRect     SMALL_RECT <0, 0, 80, 32>
isError       BYTE 0
; ANSI Panel =====================================
fileMenu   BYTE "ANSI\menu.dat", 0
textMenu   BYTE 3000 DUP(?)
fileGame   BYTE "ANSI\game.dat", 0
textGame   BYTE 3000 DUP(?)
filePause  BYTE "ANSI\pause.dat", 0
textPause  BYTE 1500 DUP(?)
fileRecord BYTE "ANSI\record.dat", 0
textRecord BYTE 3000 DUP(?)
; Script Variable ================================
fileScript  BYTE  "Script\story.dat", 0
textScript  BYTE  100000 DUP(?)
pCurrent    DWORD ?                 ; Current location of the script
pTemp       DWORD ?                 ; The next location of the script
optionList  BYTE  26 DUP("0"), 0    ; Store user's choices
quesNum     DWORD ?                 ; Question number
isChoice    BYTE  ?                 ; Whether is in choice
choiceBound BYTE  ?                 ; Choice boundary
fileFigure  BYTE  "Figure\00.dat", 0
textFigure  BYTE  1500 DUP(?), 0
; Save & Load Variable ===========================
fileData   BYTE  "Record\1.dat", 0, "Record\2.dat", 0, "Record\3.dat", 0
haveData   BYTE  "000", 0       ; Whether the record data is exists
pOffset    DWORD ?              ; Offset from the head of the script
isSave     BYTE  ?              ; In save mode (1), or in load mode (0)
saveText   BYTE  200 DUP(?), 0  ; Current text
textLength DWORD 0              ; Length of current text
saveFigure BYTE  "00", 0        ; Current figure
newLine    BYTE  0Dh, 0Ah
; Debug Mode =====================================
isDebug BYTE 0

;********************
;   Debug mode msg
;********************

.code
main PROC
;=================================================
INITIALIZE:
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov consoleHandle, eax
    INVOKE SetConsoleScreenBufferSize, consoleHandle, consoleBuffer
    INVOKE SetConsoleWindowInfo, consoleHandle, TRUE, ADDR smallRect
    INVOKE SetConsoleTitle, ADDR myTitle

    INVOKE GetFile, ADDR fileMenu, ADDR textMenu, LENGTHOF textMenu
    INVOKE GetFile, ADDR fileGame, ADDR textGame, LENGTHOF textGame
    INVOKE GetFile, ADDR filePause, ADDR textPause, LENGTHOF textPause
    INVOKE GetFile, ADDR fileRecord, ADDR textRecord, LENGTHOF textRecord

    ;INVOKE GetFile, ADDR file3C,         ADDR text3C,         LENGTHOF text3C
    ;INVOKE GetFile, ADDR fileATM,        ADDR textATM,        LENGTHOF textATM
    ;INVOKE GetFile, ADDR fileBoyFriend,  ADDR textBoyFriend,  LENGTHOF textBoyFriend
    ;INVOKE GetFile, ADDR fileCalendar,   ADDR textCalendar,   LENGTHOF textCalendar
    ;INVOKE GetFile, ADDR fileCarriage,   ADDR textCarriage,   LENGTHOF textCarriage
    ;INVOKE GetFile, ADDR fileOrdering,   ADDR textOrdering,   LENGTHOF textOrdering
    ;INVOKE GetFile, ADDR fileSolvingBot, ADDR textSolvingBot, LENGTHOF textSolvingBot
    ;INVOKE GetFile, ADDR fileTrash,      ADDR textTrash,      LENGTHOF textTrash

    INVOKE GetFile, ADDR fileScript, ADDR textScript, LENGTHOF textScript
    
    .IF isError == 1
        call Crlf
        mWrite "Press any key to quit!"
        call ReadChar
        exit
    .ENDIF
;=================================================
MENU:   call Clrscr
    mWriteString OFFSET textMenu
    ; Wait for key in
    mov dl, 61
    mov dh, 21
    call Gotoxy
MENU_KEY:
    call ReadChar
    .IF     ax == KEY_UP
        .IF dh > 21
            sub dh, 3
        .ENDIF
    .ELSEIF ax == KEY_DOWN
        .IF dh < 27
            add dh, 3
        .ENDIF
    .ELSEIF ax == KEY_ESC
        mov dh, 27
    .ELSEIF ax == KEY_ENTER
        .IF     dh == 21
            jmp GAME
        .ELSEIF dh == 24
            mov isSave, 0
            jmp SAVE_LOAD
        .ELSEIF dh == 27
            jmp END_GAME
        .ENDIF
    .ELSEIF ax == KEY_F10
        xor isDebug, 1
        mGotoxy 2, 1
        mWrite "Debug Mode:"
        movzx eax, isDebug
        call WriteDec
    .ENDIF
    call Gotoxy
    jmp MENU_KEY
;=================================================
SAVE_LOAD:   call Clrscr
    mWriteString OFFSET textRecord
    ; Check whether the record data is exists
    mov ecx, 3
    mov ebx, 1
    mov edx, OFFSET fileData
GET_DATA:
    INVOKE GetData, ebx
    add ebx, 1
    loop GET_DATA
    ; Set panel title
    mGotoxy 37, 1
    .If isSave == 0
        mWrite "[Load]"
    .ELSE
        mWrite "[Save]"
    .ENDIF
    ; Wait for key in
    mov dl, 17
    mov dh, 3
    call Gotoxy
SL_KEY:
    call ReadChar
    .IF     ax == KEY_UP
        .IF dh > 3
            sub dh, 9
        .ENDIF
    .ELSEIF ax == KEY_DOWN
        .IF dh < 21
            add dh, 9
        .ENDIF
    .ELSEIF ax == KEY_ESC
        .IF isSave == 0
            jmp MENU
        .ELSE
            jmp GAME_NO_INIT
        .ENDIF
    .ELSEIF ax == KEY_ENTER
        .IF isSave == 0
            mov edi, OFFSET haveData
            .IF dh == 3
                .IF BYTE PTR [edi] == "1"
                    INVOKE SLData, 1
                    jmp GAME_NO_INIT
                .ENDIF
            .ENDIF
            add edi, 1
            .IF dh == 12
                .IF BYTE PTR [edi] == "1"
                    INVOKE SLData, 2
                    jmp GAME_NO_INIT
                .ENDIF
            .ENDIF
            add edi, 1
            .IF dh == 21
                .IF BYTE PTR [edi] == "1"
                    INVOKE SLData, 3
                    jmp GAME_NO_INIT
                .ENDIF
            .ENDIF
            jmp SL_KEY
        .ELSE
            .IF     dh == 3
                INVOKE SLData, 1
            .ELSEIF dh == 12
                INVOKE SLData, 2
            .ELSEIF dh == 21
                INVOKE SLData, 3
            .ENDIF
            jmp SAVE_LOAD
        .ENDIF
    .ENDIF
    call Gotoxy
    jmp SL_KEY
;=================================================
GAME:
    ; Initialize the current location of the script and the optionList
    mov edi, OFFSET textScript
    mov pCurrent, edi
    mov al, "0"
    mov edi, OFFSET optionList
    mov ecx, 26
    cld
    rep stosb
    ; Print the game panel
GAME_NO_INIT:    call Clrscr
    mWriteString OFFSET textGame
    mov esi, OFFSET saveFigure
    mov edi, OFFSET fileFigure
    add edi, 7
    mov ecx, 2
    cld
    rep movsb
    mGotoxy 0, 0
    INVOKE GetFile, ADDR fileFigure, ADDR textFigure, LENGTHOF textFigure
    mov edx, OFFSET textFigure
    call WriteString
    INVOKE ChangeName, 0
    INVOKE ClearChoice
    INVOKE ClearDialogue
    INVOKE ClearSaveText
    ; Get current script
GAME_SCRIPT:
    mov edi, pCurrent
    mov al, "["
    mov ecx, 100
    cld
    repne scasb
    mov al, [edi]
    ;********************
    .IF isDebug == 1
        mGotoxy 0, 13
        call WriteChar
    .ENDIF
    ;********************

    .IF     al == "t"
        INVOKE ChangeName, 0
        INVOKE ClearChoice
        INVOKE ClearDialogue
        INVOKE ClearSaveText
        INVOKE Text, edi
    .ELSEIF al == "o"
        INVOKE ChangeName, 0
        INVOKE ClearChoice
        INVOKE ClearDialogue
        INVOKE ClearSaveText
        INVOKE OptionChioce, edi
        mov isChoice, 1
        mov dl, 5
        mov dh, 24
        call Gotoxy
    .ELSEIF al == "c"
        INVOKE Condition, edi
        mov edi, pTemp
        mov pCurrent, edi
        jmp GAME_SCRIPT
    .ELSEIF al == "f"
        INVOKE Figure, edi
        mov edi, pTemp
        mov pCurrent, edi
        jmp GAME_SCRIPT
    .ELSEIF al == "e"
        jmp MENU
    .ENDIF
    ; Wait for key in
GAME_KEY:
    call ReadChar
    .IF isChoice == 0
        .IF ax == KEY_ESC
            INVOKE ChangeName, 0
            INVOKE ClearChoice
            INVOKE ClearDialogue
            jmp PAUSE
        .ELSEIF ax == KEY_ENTER
            mov edi, pTemp
            mov pCurrent, edi
            jmp GAME_SCRIPT
        .ELSE
            jmp GAME_KEY
        .ENDIF
    .ELSE
        .IF     ax == KEY_UP
            .IF dh > 24
                sub dh, 1
            .ENDIF
        .ELSEIF ax == KEY_DOWN
            .IF dh < choiceBound
                add dh, 1
            .ENDIF
        .ELSEIF ax == KEY_ESC
            INVOKE ChangeName, 0
            INVOKE ClearChoice
            INVOKE ClearDialogue
            jmp PAUSE
        .ELSEIF ax == KEY_ENTER
            sub dh, 23
            add dh, 30h
            mov edi, OFFSET optionList
            add edi, quesNum
            mov BYTE PTR [edi], dh
            ;********************
            .IF isDebug == 1
                mGotoxy 0, 15
                mWrite "Ques List: "
                mWriteString OFFSET optionList
            .ENDIF
            ;********************
            mov isChoice, 0
            mov edi, pTemp
            mov pCurrent, edi
            jmp GAME_SCRIPT
        .ENDIF
        call Gotoxy
        jmp GAME_KEY
    .ENDIF
;=================================================
PAUSE:
    mGotoxy 0, 17
    mWriteString OFFSET textPause
    ; Wait for key in
    mov dl, 34
    mov dh, 20
    call Gotoxy
PAUSE_KEY:
    call ReadChar
    .IF     ax == KEY_UP
        .IF dh > 20
            sub dh, 3
        .ENDIF
    .ELSEIF ax == KEY_DOWN
        .IF dh < 26
            add dh, 3
        .ENDIF
    .ELSEIF ax == KEY_ESC
        INVOKE ChangeName, 0
        INVOKE ClearChoice
        INVOKE ClearDialogue
        mGotoxy 73, 28
        mWrite "Menu"
        jmp GAME_SCRIPT
    .ELSEIF ax == KEY_ENTER
        .IF     dh == 20
            jmp MENU
        .ELSEIF dh == 23
            mov isSave, 1
            jmp SAVE_LOAD
        .ELSEIF dh == 26
            jmp END_GAME
        .ENDIF
    .ENDIF
    call Gotoxy
    jmp PAUSE_KEY
;=================================================
END_GAME:
    exit
main ENDP

;=================================================
GetFile PROC USES eax ecx edx,
    fileName:  PTR BYTE,    ; Name of the file
    textTarget:PTR BYTE,    ; Where to store the file txt
    textSize:  DWORD        ; How many bytes to read from file
    ; Open file
    mov  edx, fileName
    call OpenInputFile
    .IF eax == INVALID_HANDLE_VALUE
        mov isError, 1
        mov  edx, fileName
        call WriteString
        mWriteLn " does not exist!"
    .ENDIF
    mov  fileHandle, eax
    ; Read from file
    mov  edx, textTarget
    mov  ecx, textSize
    call ReadFromFile
    ; Close file
    mov eax, fileHandle
    call CloseFile
    ret
GetFile ENDP
;=================================================
; Check and get the info of record
GetData PROC USES eax ebx ecx edx edi,
    dataNum:DWORD           ; Which record data
    LOCAL txtData[200]:BYTE ; Where to store the data txt
    ; Clear txtData with null
    mov al, 0
    lea edi, txtData
    mov ecx, 200
    cld
    rep stosb
    ; Get correct file name
    mov edx, OFFSET fileData
    mov edi, OFFSET haveData
    .IF     dataNum == 2
        add edx, 13
        add edi, 1
    .ELSEIF dataNum == 3
        add edx, 26
        add edi, 2
    .ENDIF
    ; Check and open file
    call OpenInputFile
    .IF eax == INVALID_HANDLE_VALUE
        mov BYTE PTR [edi], "0"
        jmp NO_FILE
    .ENDIF
    mov BYTE PTR [edi], "1"
    mov fileHandle, eax
    ; Read from file
    mov eax, fileHandle
    lea edx, txtData
    mov ecx, 200
    call ReadFromFile

    mov eax, fileHandle
    call CloseFile
    ; Print record info
    mGotoxy 8, 7
    .IF     dataNum == 2
        mGotoxy 8, 16
    .ELSEIF dataNum == 3
        mGotoxy 8, 25
    .ENDIF
    lea edx, txtData
    add edx, 38
    call WriteString
NO_FILE:
    ret
GetData ENDP
;=================================================
; Save to or load from record
SLData PROC USES eax ebx edx,
    dataNum:DWORD           ; Which record data
    LOCAL txtData[200]:BYTE ; Where to store the data txt
    ; Get correct file name
    mov edx, OFFSET fileData
    .IF     dataNum == 2
        add edx, 13
    .ELSEIF dataNum == 3
        add edx, 26
    .ENDIF
    ; Load from data
    .IF isSave == 0
        ; Open the file
        call OpenInputFile
        mov  filehandle, eax
        ; Read from data
        mov eax, fileHandle
        lea edx, txtData
        mov ecx, 200
        call ReadFromFile
        ; Close file
        mov eax, fileHandle
        call CloseFile
        ; Load the current offset of script
        lea esi, txtData
        mov edi, OFFSET pOffset
        mov ecx, 4
        cld
        rep movsb
        ; move the current location of the script to the correct location
        mov ebx, OFFSET textScript
        add ebx, pOffset
        mov pCurrent, ebx

        add esi, 2
        ; Load optionList
        mov edi, OFFSET optionList
        mov ecx, 26
        cld
        rep movsb

        add esi, 2
        ; Load figure code
        mov edi, OFFSET saveFigure
        mov ecx, 2
        cld
        rep movsb
    ; Save to data
    .ELSE
        ; Calculate the current offset of script
        mov ebx, pCurrent
        sub ebx, OFFSET textScript
        mov pOffset, ebx
        ; Create / Open the file
        call CreateOutputFile
        mov  fileHandle, eax
        ; Write the current offset of script
        mov eax, fileHandle
        mov edx, OFFSET pOffset
        mov ecx, 4
        call WriteToFile

        mov eax, fileHandle
        mov edx, OFFSET newLine
        mov ecx, LENGTHOF newLine
        call WriteToFile
        ; Write optionList
        mov eax, fileHandle
        mov edx, OFFSET optionList
        mov ecx, 26
        call WriteToFile

        mov eax, fileHandle
        mov edx, OFFSET newLine
        mov ecx, LENGTHOF newLine
        call WriteToFile
        ; Write figure code
        mov eax, fileHandle
        mov edx, OFFSET saveFigure
        mov ecx, 2
        call WriteToFile

        mov eax, fileHandle
        mov edx, OFFSET newLine
        mov ecx, LENGTHOF newLine
        call WriteToFile
        ; Write current text
        mov eax, fileHandle
        mov edx, OFFSET saveText
        mov ecx, textLength
        call WriteToFile
        ; Close file
        mov eax, fileHandle
        call CloseFile
    .ENDIF

    ret
SLData ENDP
;=================================================
; Clear dialogue
ClearDialogue PROC
    mGotoxy 14, 18
    mWrite "                                                                  "
    mGotoxy 0, 19
    mWrite "O============O                                                                  "
    mGotoxy 0, 20
    mWrite "                                                                                "
    mGotoxy 0, 21
    mWrite "                                                                                "
    mGotoxy 0, 22
    mWrite "                                                                                "
    mGotoxy 0, 23
    mWrite "                                                                                "
    mGotoxy 3, 21
    ret
ClearDialogue ENDP
;=================================================
; Clear saveText
ClearSaveText PROC USES eax ecx edi
    mov al, 0
    mov edi, OFFSET saveText
    mov ecx, 200
    cld
    rep stosb
    mov textLength, 0
    ret
ClearSaveText ENDP
;=================================================
; Clear choice
ClearChoice PROC
    mGotoxy 0, 24
    mWrite "                                                                                "
    mGotoxy 0, 25
    mWrite "                                                                                "
    mGotoxy 0, 26
    mWrite "                                                                                "
    mGotoxy 0, 27
    mWrite "                                                                      O========O"
    mGotoxy 3, 21
    ret
ClearChoice ENDP
;=================================================
; Change name
ChangeName PROC USES edx,
    pName:PTR BYTE  ; point to string
    ; Print name
    mGotoxy 2, 18
    mWrite "          "
    mGotoxy 2, 18
    mov edx, pName
    .IF edx > 0
        call WriteString
    .ENDIF
    ret
ChangeName ENDP
;=================================================
; Text type script
Text PROC USES eax ecx edx esi edi,
    pScript:PTR BYTE        ; current location of the script
    LOCAL tName[100]:BYTE   ; store name
    LOCAL tText[1000]:BYTE  ; store text
    ; Find the first comma
    mov edi, pScript
    mov al, ","
    mov ecx, 100
T_COMMA1:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 20h
        jmp T_COMMA1
    .ENDIF
    add edi, 1
    mov esi, edi
    ; Find the second comma
    mov al, ","
T_COMMA2:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 20h
        jmp T_COMMA2
    .ENDIF
    add edi, 1
    ; Get the name and print to screen
    mov pScript, edi
    sub edi, esi
    sub edi, 2
    .IF edi == 0
        INVOKE ChangeName, 0
    .ELSE
        mov ecx, edi
        lea edi, tName
        cld
        rep movsb
        mov BYTE PTR [edi], 0
        INVOKE ChangeName, ADDR tName
    .ENDIF
    ; Find bracket
    mov edi, pScript
    mov al, "]"
    mov ecx, 1000
T_BRACKETS:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 0Dh
        jmp T_BRACKETS
    .ENDIF
    ; Get the text and print to screen
    mov pTemp, edi
    sub edi, pScript
    sub edi, 1
    mov ecx, edi
    mov textLength, ecx
    mov esi, pScript
    mov edi, OFFSET saveText
    cld
    rep movsb
    mGotoxy 3, 21
    mov edx, OFFSET saveText
    call WriteString
    ret
Text ENDP
;=================================================
; Text with choice type script
OptionChioce PROC USES eax ecx edx esi edi,
    pScript:PTR BYTE        ; current location of the script
    LOCAL moreChoice:BYTE   ; 2 choices (0), 3 choices (1)
    LOCAL quesTxt[100]:BYTE ; question text
    LOCAL choice1[100]:BYTE ; choice text 1
    LOCAL choice2[100]:BYTE ; choice text 2
    LOCAL choice3[100]:BYTE ; choice text 3
    ; Get question number
    mov edi, pScript
    add edi, 3
    mov al, BYTE PTR [edi]
    sub al, 41h
    movzx eax, al
    mov quesNum, eax
    ;********************
    .IF isDebug == 1
        mGotoxy 0, 14
        mWrite "Ques Num: "
        mov eax, quesNum
        call WriteDec
    .ENDIF
    ;********************
    ; Check there are 2 or 3 choices
    add edi, 3
    mov al, BYTE PTR [edi]
    mov moreChoice, al
    ; Get question text
    add edi, 3
    mov esi, edi
    mov al, ","
    mov ecx, 100
O_COMMA:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 20h
        jmp O_COMMA
    .ENDIF
    add edi, 1
    mov pScript, edi
    sub edi, esi
    sub edi, 2
    mov ecx, edi
    mov textLength, ecx
    mov edi, OFFSET saveText
    cld
    rep movsb
    mGotoxy 3, 21
    mov edx, OFFSET saveText
    call WriteString
    ; Get choice 1
    mov edi, pScript
    mov esi, edi
    mov al, ","
    mov ecx, 100
O_COMMA1:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 20h
        jmp O_COMMA1
    .ENDIF
    add edi, 1
    mov pScript, edi
    sub edi, esi
    sub edi, 2
    mov ecx, edi
    lea edi, choice1
    cld
    rep movsb
    mov BYTE PTR [edi], 0
    mGotoxy 7, 24
    lea edx, choice1
    call WriteString
    mGotoxy 3, 24
    mWrite "1)"
    ; Get choice 2 if there are 3 choices
    .IF moreChoice == 33h
        mov edi, pScript
        mov esi, edi
        mov al, ","
        mov ecx, 100
O_COMMA2:
        cld
        repne scasb
        .IF BYTE PTR [edi] != 20h
            jmp O_COMMA2
        .ENDIF
        add edi, 1
        mov pScript, edi
        sub edi, esi
        sub edi, 2
        mov ecx, edi
        lea edi, choice2
        cld
        rep movsb
        mov BYTE PTR [edi], 0
        mGotoxy 7, 25
        lea edx, choice2
        call WriteString
        mGotoxy 3, 25
        mWrite "2)"
    .ENDIF
    ; Get last choice
    mov edi, pScript
    mov esi, edi
    mov al, "]"
    mov ecx, 100
O_BRACKETS:
    cld
    repne scasb
    .IF BYTE PTR [edi] != 0Dh
        jmp O_BRACKETS
    .ENDIF
    mov pTemp, edi
    sub edi, esi
    sub edi, 1
    mov ecx, edi
    lea edi, choice3
    cld
    rep movsb
    mov BYTE PTR [edi], 0
    .IF moreChoice == 32h
        mGotoxy 7, 25
        lea edx, choice3
        call WriteString
        mGotoxy 3, 25
        mWrite "2)"
        mov choiceBound, 25
    .ELSE
        mGotoxy 7, 26
        lea edx, choice3
        call WriteString
        mGotoxy 3, 26
        mWrite "3)"
        mov choiceBound, 26
    .ENDIF
    ret
OptionChioce ENDP
;=================================================
; Condition type script
Condition PROC USES eax ebx ecx esi edi,
    pScript:PTR BYTE    ; current location of the script

    mov edi, pScript
    add edi, 1
    .IF BYTE PTR [edi] == ","
        add edi, 2
        mov al, BYTE PTR [edi]
        sub al, 41h
        movzx eax, al
        mov esi, OFFSET optionList
        add esi, eax
        mov al, BYTE PTR [esi]      ; choice in optionList
        add edi, 1
        mov ah, BYTE PTR [edi]      ; choice in condition check
        .IF al != ah
            ;********************
            .IF isDebug == 1
                mGotoxy 0, 16
                mWrite "no match                                                                        "
                mGotoxy 9, 16
            .ENDIF
            ;********************
            xor ebx, ebx
C_FIND_END:
            mov al, "]"
            mov ecx, 10000
            cld
            repne scasb
            .IF BYTE PTR [edi] != 0Dh
                jmp C_FIND_END
            .ENDIF
            add edi, 3
            .IF BYTE PTR [edi] == "c"
                add edi, 1
                ;********************
                .IF isDebug == 1
                    mWrite "c"
                .ENDIF
                ;********************
                .IF BYTE PTR [edi] != "e"
                    ;********************
                    .IF isDebug == 1
                        mov al, BYTE PTR [edi]
                        call WriteChar
                        mWrite " "
                    .ENDIF
                    ;********************
                    add ebx, 1
                    jmp C_FIND_END
                .ELSE
                    ;********************
                    .IF isDebug == 1
                        mWrite "e "
                    .ENDIF
                    ;********************
                    .IF ebx != 0
                        sub ebx, 1
                        jmp C_FIND_END
                    .ENDIF
                .ENDIF
            .ELSE
                ;********************
                .IF isDebug == 1
                    mov al, BYTE PTR [edi]
                    call WriteChar
                    mWrite " "
                .ENDIF
                ;********************
                jmp C_FIND_END
            .ENDIF
        .ELSE
            ;********************
            .IF isDebug == 1
                mGotoxy 0, 16
                mWrite "is match                                                                        "
            .ENDIF
            ;********************
        .ENDIF
    .ENDIF
C_DO_NOTHING:
    mov al, "]"
    mov ecx, 1000
    cld
    repne scasb
    .IF BYTE PTR [edi] != 0Dh
        jmp C_DO_NOTHING
    .ENDIF
    mov pTemp, edi
    ret
Condition ENDP
;=================================================
; Figure type script
Figure PROC USES eax ecx edx esi edi,
    pScript:PTR BYTE    ; current location of the script
    ; Get figure code
    mov edi, pScript
    add edi, 3
    mov esi, edi
    add edi, 3
    mov pTemp, edi
    ; Store figure code
    mov edi, OFFSET saveFigure
    mov ecx, 2
    cld
    rep movsb
    ; Set correct file name
    mov esi, OFFSET saveFigure
    mov edi, OFFSET fileFigure
    add edi, 7
    mov ecx, 2
    cld
    rep movsb
    ; Get figure and print to screen
    INVOKE GetFile, ADDR fileFigure, ADDR textFigure, LENGTHOF textFigure
    mGotoxy 0, 0
    mov edx, OFFSET textFigure
    call WriteString
    ret
Figure ENDP
;=================================================
END main
