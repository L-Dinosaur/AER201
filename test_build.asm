      list p=16f877                 ; list directive to define processor
      #include <p16f877.inc>        ; processor specific variable definitions
      #include <rtc_macros.inc>
      __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF
	
	cblock  0x20 ; Container info
		C1
		C2
		C3
		C4
		C5
		C6
		C7
		Dis1
		Dis2
		Dis3
		Dis4
		Dis5
		Dis6
		Dis7
	endc
        cblock  0x40
		COUNTH
		COUNTM	
		COUNTL	
		Table_Counter
		lcd_tmp	
		lcd_d1
		lcd_d2
		com	
		dat
		Num_Cont
		Cont_Checked
		IR_Status
		Bumper_Status
		Sticker
		Encod_Temp1
		Encod_Temp2
		Front_Color
		Back_Color
		Key_Value
		R0
		R1
		R2
		R3
		Time
		Hundred 
		Tens 
		Units 
		bin
		Next_Cont
		Next_Dis
		time
		time_count
		time_long
	endc

	;Declare constants for pin assignments (LCD on PORTD)
		#define	RS 	PORTD,2
		#define	E 	PORTD,3
		#define	LEFTFWD PORTC,1  ;pin1 for left motor
		#define IND_LED PORTC,2  ;pin1 for right motor
		#define LEFTBWD	PORTC,0  ;pin2 for left motor

		#define	ARMFWD	PORTE,0
		#define ARMBWD	PORTE,1
		
		#define Base_IR_Front  PORTA,0  ;The 4 IR sensors
		#define Base_IR_Back   PORTA,1
		#define Arm_IR_Front   PORTA,2
		#define Arm_IR_Back    PORTA,3
		#define Encoder	       PORTA,4
		#define Bumper	       PORTA,5
		

        ORG       0x0000     ;RESET vector must always be at 0x00
        goto      init       ;Just jump to the main code section.
	ORG  0x0004  ; INTERRUPT VECTOR AREA
	call INT_SERVICE
	retfie 
;***************************************
; Look up table
;***************************************
Invalid
		addwf	PCL,F
		dt		"Invalid", 0
Operating
		addwf	PCL,F
		dt		"Operating...", 0
White
		addwf	PCL,F
		dt		"White", 0
Black
		addwf	PCL,F
		dt		"Black", 0
GoingBack  
		addwf	PCL,F
		dt		"Going Back", 0
TerminateMsg1
		addwf	PCL,F
		dt		" Containers", 0
TerminateMsg2
		addwf	PCL,F
		dt		"Checked in ", 0
MasterSel1   
		addwf	PCL,F
		dt		"1. Sticker Color", 0
MasterSel2
		addwf	PCL,F
		dt		"2. Distance", 0
Sticker_Sel
		addwf	PCL,F
		dt		"Select # 1 - ", 0
Front	    
		addwf	PCL,F
		dt		"Front: ",0
Back
		addwf	PCL,F
		dt		"Back: ",0
Detected
		addwf	PCL,F
		dt		"Detected",0


;***************************************
; Delay: ~160us macro
;***************************************
LCD_DELAY macro
	movlw   0xFF
	movwf   lcd_d1
	decfsz  lcd_d1,f
	goto    $-1
	endm


;***************************************
; Display macro
;***************************************
Display macro	Message
		local	loop_       ; What is this?????????????????? What does local mean?
		local 	end_
		clrf	Table_Counter
		clrw		
loop_	movf	Table_Counter,W
		call 	Message
		xorlw	B'00000000' ;check WORK reg to see if 0 is returned
		btfsc	STATUS,Z
		goto	end_
		call	WR_DATA
		incf	Table_Counter,F
		goto	loop_
end_
		endm

;***************************************
; Initialize
;***************************************

init    ;Initialize_LCD
         clrf      INTCON         ; No interrupts
	 movlw	   b'00110000'
	 movwf	   OPTION_REG
	 clrf	   TMR0
         bsf       STATUS,RP0     ; select bank 1
         movlw	   0x06 ; Configure all pins
	 movwf	   ADCON1 ; as digital inputs
	 movlw	   b'00011111'
	 movwf	   TRISA
	 
	 ;clrf      TRISA          ; All port A is output
         movlw     b'11110010'    ; Set required keypad inputs
         movwf     TRISB
         clrf      TRISC          ; All port C is output
         clrf      TRISD          ; All port D is output
	 clrf	   TRISE	  ; All port E is output
	 bsf	   TRISC,3
	 bsf	   TRISC,4
         bcf       STATUS,RP0     ; select bank 0
         clrf      PORTA
         clrf      PORTB
         clrf      PORTC
         clrf      PORTD

;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
         call	    i2c_common_setup   ;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂ Shen Shi Look at 
	 rtc_resetAll    ;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂ Here Hei Hei Hei
; ♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
         call      InitLCD  	  ;Initialize the LCD (code in lcd.asm; imported by lcd.inc)
	 ; testing initializations
	 ; the following registers are initialized 
	 ; so that I can test functions
	 
	 movlw	   0x00
	 movwf	   Num_Cont
	 movlw	   0x03
	 movwf	   Time
	 clrf	   C1
	 clrf	   C2
	 clrf	   C3
	 clrf	   C4
	 clrf	   C5
	 clrf	   C6
	 clrf	   C7
	 movlw	   0x33
	 movwf	   Dis1
	 movlw	   0x1F
	 movwf	   Dis2
	 movlw	   0x20
	 movwf	   Next_Cont
	 movlw	   0x27
	 movwf	   Next_Dis
	 clrf	   time
;;;;;;;;;;;;;;;added;;;;;;;;;;;;;;;
	bsf	    INTCON,GIE  ; SET GLOBAl INT ENABLE  
	bsf	    INTCON,PEIE
	; Bank 0
        bcf	    STATUS, RP1
	bcf	    STATUS, RP0
	clrf	    time_count
	clrf	    T1CON
	bcf	    PIR1,0
	movlw	    b'00110000'
	movwf	    T1CON
	;bsf	    T1CON,0
	; Bank 1
	bsf	    STATUS, RP0
	bsf	    PIE1,0
	bcf	    STATUS,RP0
;***************************************
; Main code
;***************************************
;General purpose register alloctaion
;   0x21 - Total number of barrels
;   0x22 - Total operation time
;   0x31 - 0x40	    State of barrels, starting from barrel 1
;   0x41 - 0x50	    Corresponding location of barrels
;   0x7f	    Num of the barrel that user wants to check
;   0x7c - 0x7e	    return value from fcn Binary_to_decimal

;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
	set_rtc_time
;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
	;clear LCD screen
Standby
;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
	call		Display_Time
;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
	btfsc		PORTB,1
	goto		Standby2Drive
	goto		Standby
Standby2Drive
	btfss		PORTB,1	    ;Polling while waiting for keypad
	goto		$-1
	bsf		T1CON,0
	call		Clear_Display
	Display		Operating
	btfsc		PORTB,1
	goto		$-1	 
	goto		Terminated
	;**************************
	;State2A   Drive - Forward*
	;**************************
	;Set base motor to a value and move forward

Drive	
	call		Turn_Motor_Forward
	call		Bumper_Check		;Check for Bumpers
	btfsc		Bumper_Status,0
	call		Bumper_Service		;Branch to Bumper Subroutine
	call		Base_IR_Check		;Check for Containers
	movfw		IR_Status
	bcf		STATUS,2		;Check if both IR_Detected stuff
	sublw		0x03
	btfsc		STATUS,2
	call		IR_Service		;Branch to the IR Subroutine
	movfw		TMR0
	bcf		STATUS,0
	sublw		b'01101110'
	btfss		STATUS,0
	goto		Go_Back
	goto		Drive	
	
Go_Back
	call		Clear_Display
	clrf		TMR0
	call		Stop_Motor
	Display		GoingBack
	call		HalfS
	call		Retract_Arm
	call		HalfS
	call		Turn_Motor_Backward
	
Backloop
	movfw		TMR0
	bcf		STATUS,0
	sublw		b'01110000'
	btfss		STATUS,0
	goto		Terminated
	goto		Backloop

	
	
; Termination Stage
; Interface and Read Info
Terminated
	bcf		T1CON,0
	call		Stop_Motor
	call		Clear_Display
	
	movfw		Num_Cont
	movwf		bin
	call		Binary2BCD
	
	Display		TerminateMsg1	; X containers
	
	call		Switch_Lines
	Display		TerminateMsg2	; checked in X s
	
	movfw		time
	movwf		bin
	call		Binary2BCD
	movlw		b'00100000'
	call		WR_DATA
	movlw		b'01110011'
	call		WR_DATA
	
	call		Poll4Key
Stop0	Display		MasterSel1	; 1.Sticker Color
	call		Switch_Lines	; 2.Distance
	Display		MasterSel2
	
	call		Poll4Key
	call		Read_Keypad
	; test if it's 1
	movfw		Key_Value
	bcf		STATUS,2
	sublw		0x01
	btfsc		STATUS,2
	goto		Sticker_Col
	; test if it's 2
	movfw		Key_Value
	bcf		STATUS,2
	sublw		0x02
	btfsc		STATUS,2
	goto		Container_Dis
	; if it's neither 1 nor 2, does not do anything
	goto		Stop0
	
Sticker_Col
	;This shows the message
	; Select # 1 - 4
	; 
	Display		Sticker_Sel ; Select 1-X
	movfw		Num_Cont
	movwf		bin
	call		Binary2BCD
	
	call		Poll4Key
	call		Read_Keypad
	movfw		Key_Value
	bcf		STATUS,2
	sublw		0x0E
	btfsc		STATUS,2
	goto		Stop0
	
	call		Sticker_Color
	
Stop2	call		Poll4Key
	call		Read_Keypad
	
	movfw		Key_Value
	bcf		STATUS,2
	sublw		0x0E
	btfsc		STATUS,2
	goto		Stop0
	; Make up for Clear Display 
	Display		Sticker_Sel
	movfw		Num_Cont
	addlw		b'00110000'
	call		WR_DATA
	
	goto		Stop2		
Container_Dis
	; This part shows the message
Stop3	Display		Sticker_Sel
	
	movfw		Num_Cont
	movwf		bin
	call		Binary2BCD
	
	call		Poll4Key
	call		Read_Keypad
	movfw		Key_Value
	bcf		STATUS,2
	sublw		0x0E
	btfsc		STATUS,2
	goto		Stop0
	
	
	;;;;;;;;;;;;;;;;;;;;;
	call		Clear_Display
	movfw		Key_Value
	addlw		0x26
	movwf		R0
	call		Read_Dis
Stop4	call		Poll4Key
	call		Read_Keypad
	movfw		Key_Value
	
	bcf		STATUS,2
	sublw		0x0E
	btfsc		STATUS,2
	goto		Stop3
	Display		Invalid
	goto		Stop4

doned	goto		doned	
		

;***************************************
; LCD control
;***************************************
Switch_Lines
		movlw	B'11000000'
		call	WR_INS
		return

Clear_Display
		movlw	B'00000001'
		call	WR_INS
		return
;***************************************
; Poll for key
;***************************************
Poll4Key
	;This function waits for a keypad input and 
	;Clears the display
	btfss	PORTB,1
	goto	$-1
	call	Clear_Display
	btfsc	PORTB,1
	goto	$-1
		return
;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
;♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
;***************************************
; Display_Time
;***************************************
♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂♂
Display_Time
	movlw	b'00000001'
	call	WR_INS
		;Get year
	movlw	"2"				;First line shows 20**/**/**
	call	WR_DATA
	movlw	"0"
	call	WR_DATA
	rtc_read	0x06		;Read Address 0x06 from DS1307---year
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA
	
	movlw	"/"
	call	WR_DATA
		;Get month
	rtc_read	0x05		;Read Address 0x05 from DS1307---month
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA

	movlw	"/"
	call	WR_DATA

	;Get day
	rtc_read	0x04		;Read Address 0x04 from DS1307---day
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA

	movlw	B'11000000'		;Next line displays (hour):(min):(sec) **:**:**
	call	WR_INS
	;Get hour
	rtc_read	0x02		;Read Address 0x02 from DS1307---hour
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA
	movlw			":"
	call	WR_DATA

		;Get minute		
	rtc_read	0x01		;Read Address 0x01 from DS1307---min
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA		
	movlw			":"
	call	WR_DATA
	
	;Get seconds
	rtc_read	0x00		;Read Address 0x00 from DS1307---seconds
	movfw	0x77
	call	WR_DATA
	movfw	0x78
	call	WR_DATA
		
	call	HalfS			;Delay for exactly one seconds and read DS1307 again
	call	HalfS
	call	Clear_Display
	return
;***************************************
; Read and Write
;***************************************
Sticker_Color
	; Arguments: 
	call	Read_Keypad
	movlw	0x1F ; cblock 0x20-1
	addwf	Key_Value,w

	movwf	FSR
	movfw	INDF
	movwf	R0
	call	Display_Color
		return
Display_Color
	; Arguments: R0 - Container info
	; Output:    No output
	; This function grabs the container info from R0 and Displays the color
		
	btfss	R0,0 ;When saving color, mark the register's first bit as detected
	goto	Out_of_Bound
	rrf	R0
	Display	Front
	btfsc	R0,0
	goto	Disp_Black
	goto	Disp_White
	
Disp_Black
	Display	Black
	goto	Continue
Disp_White
	Display White
	goto	Continue
	
Continue
	call	Switch_Lines
	rrf	R0
	Display	Back
	btfsc	R0,0
	goto	Disp_Blackn
	goto	Disp_Whiten

Disp_Blackn
	Display	Black
	goto	Continuen
Disp_Whiten
	Display White
	goto	Continuen
	
Continuen
	goto	Finish_Disp
	
Out_of_Bound
	Display Invalid
Finish_Disp
	return		
;***************************************
; Services
;***************************************
Bumper_Service
	call		Clear_Display
	Display		Invalid
	call		Stop_Motor
	call		HalfS
	call		Turn_Motor_Backward
	call		Stop_Motor
	call		Retract_Arm
	call		Turn_Motor_Forward
	call		HalfS
	call		HalfS
	call		HalfS
	call		HalfS
	call		Stop_Motor
	call		HalfS
	call		Expand_Arm
	call		HalfS

			return	
IR_Service
	call		Clear_Display
	movlw		0x01
	addwf		Num_Cont,f

	call		Arm_IR_Back_Check ;To check Back first so that the 
	call		Save_Color	  ;Back sticker is saved on the second
	
	call		Shift_C_Reg	  ;bit after rotation
	call		Arm_IR_Front_Check
	call		Save_Color
	
	call		Shift_C_Reg
	movlw		0x01
	movwf		IR_Status
	call		Save_Color
	
	movfw		Next_Cont
	movwf		bin
	call		Binary2BCD
	
	;;;; Save Distance ;;;;
	call		Save_Dis
	movlw		0x01
	addwf		Next_Dis
	Display		Detected
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	movlw		0x01
	addwf		Next_Cont
	call		HalfS
	call		HalfS
	call		HalfS
	call		HalfS
	return

;***************************************
; Save Sticker Color
;***************************************
Save_Color
		movfw	Next_Cont
		movwf	FSR
		movlw	0x01
		bcf	STATUS,2
		subwf	IR_Status,f
		btfsc	STATUS,2
		addwf	INDF
		return
Shift_C_Reg
		movfw	Next_Cont
		movwf	FSR
		rlf	INDF
		return
;***************************************
; Save Distance
;***************************************
; Instruction of using this function:
		;Put the value of timer zero reg into R0, and call the function
		;every time a container is detected.
Save_Dis
		clrf	R1
		;Using R0 as an input for encoder values and R1 as an output for
		;actual distances, Next_Dis has the address of the reg
Loop_Again	bcf	STATUS,2
		movfw	R0
		sublw	0x05
		incf	R1
		btfsc	STATUS,2
		goto	Sub_Done
		sublw	0x06
		incf	R1
		btfsc	STATUS,2
		goto	Sub_Done
		goto	Loop_Again
		
Sub_Done
		movfw	Next_Dis
		movwf	FSR
		movfw	R1
		movwf	INDF
		incf	Next_Dis
		return
;***************************************
; Read Distance
;***************************************
		
Read_Dis
		;Instruction: This function reads the distance of a container
		;and displays it
		;R0 ---------------------- Address of the container distance info
		;R1 ---------------------- Distance value in dm
		clrf	R1
		movfw	R0
		movwf	FSR
		movfw	INDF
		movwf	bin
		call	Binary2BCD
		movlw	b'00110000'
		call	WR_DATA
		movlw	b'00100000'
		call	WR_DATA
		movlw	b'01100011' ;display "c"
		call	WR_DATA
		movlw	b'01101101' ;display "m"
		call	WR_DATA
		return
;***************************************
; Motor Control
;***************************************		
Turn_Motor_Forward
		bsf	LEFTFWD
		bcf	LEFTBWD

			return
Turn_Motor_Backward
		bcf	LEFTFWD
		bsf	LEFTBWD
			return

Stop_Motor
		bcf	LEFTFWD
		bcf	LEFTBWD
			return

Retract_Arm	bsf	ARMBWD
		bcf	ARMFWD
		call	FiveS
		call	HalfS
		call	HalfS
		call	HalfS
		call	HalfS
		bcf	ARMBWD
			return
Expand_Arm	bsf	ARMFWD
		bcf	ARMBWD
		call	FiveS
		call	HalfS
		call	HalfS
		call	HalfS
		call	HalfS
		bcf	ARMFWD
			return
;***************************************
; LED code
;***************************************
Blink_Led
		bsf	IND_LED
			return
Shut_Led
		bcf	IND_LED
			return
;***************************************
; Sensor Check
;***************************************
Base_IR_Check
		clrf	IR_Status
		movlw	b'00000001'
		btfsc	Base_IR_Front
		addwf	IR_Status,f
		rlf	IR_Status
		btfsc	Base_IR_Back
		addwf	IR_Status,f
		return
Arm_IR_Front_Check
		; Note: When white is detected
		; The Arm_IR_Front sensor bit returns 1
		; When black is detected, it returns 0
		
		; The color - number relationship is swapped by this function
		; If black is detected, 1 is saved to IR_Status Register
		; If white, 0 is saved
		clrf	IR_Status
		movlw	0x01
		btfss	Arm_IR_Front
		addwf	IR_Status,f
		return
Arm_IR_Back_Check
		; Note: When white is detected
		; The Arm_IR_Front sensor bit returns 1
		; When black is detected, it returns 0
		
		; The color - number relationship is swapped by this function
		; If black is detected, 1 is saved to IR_Status Register
		; If white, 0 is saved
		clrf	IR_Status
		movlw	0x01
		btfss	Arm_IR_Back
		addwf	IR_Status,f
		return
		
		
Bumper_Check	
		clrf	Bumper_Status
		movlw	b'00000001'
		btfsc	Bumper
		addwf	Bumper_Status,f
		return

Read_Keypad 
		banksel PORTB
		swapf	PORTB,w
		andlw	b'00001111'
		movwf	Key_Value
		bcf	STATUS,2
		
		sublw	0x01
		btfsc	STATUS,2
		goto	Two
		
		movfw	Key_Value
		sublw	0x02
		btfsc	STATUS,2
		goto	Three
		
		movfw	Key_Value
		sublw	0x03
		btfsc	STATUS,2
		goto	Aee
		
		movfw	Key_Value
		sublw	0x04
		btfsc	STATUS,2
		goto	Four
		
		movfw	Key_Value
		sublw	0x05
		btfsc	STATUS,2
		goto	Five
		
		movfw	Key_Value
		sublw	0x06
		btfsc	STATUS,2
		goto	Six
		
		movfw	Key_Value
		sublw	0x07
		btfsc	STATUS,2
		goto	Bee
		
		movfw	Key_Value
		sublw	0x08
		btfsc	STATUS,2
		goto	Seven

		movfw	Key_Value
		sublw	0x09
		btfsc	STATUS,2
		goto	Eight

		movfw	Key_Value
		sublw	0x0A
		btfsc	STATUS,2
		goto	Nine
		
		movfw	Key_Value
		sublw	0x0B
		btfsc	STATUS,2
		goto	Cee
		
		movfw	Key_Value
		sublw	0x0C
		btfsc	STATUS,2
		goto	Star
		
		movfw	Key_Value
		sublw	0x0D
		btfsc	STATUS,2
		goto	Zero
		
		movfw	Key_Value
		sublw	0x0E
		btfsc	STATUS,2
		goto	Hash
		
		movfw	Key_Value
		sublw	0x0F
		btfsc	STATUS,2
		goto	Dee

One
		movlw	0x01
		movwf	Key_Value
		goto	exit
Two
		movlw	0x02
		movwf	Key_Value
		goto	exit
Three
		movlw	0x03
		movwf	Key_Value
		goto	exit
Four
		movlw	0x04
		movwf	Key_Value
		goto	exit
Five
		movlw	0x05
		movwf	Key_Value
		goto	exit
Six
		movlw	0x06
		movwf	Key_Value
		goto	exit
Seven
		movlw	0x07
		movwf	Key_Value
		goto	exit
Eight
		movlw	0x08
		movwf	Key_Value
		goto	exit
Nine
		movlw	0x09
		movwf	Key_Value
		goto	exit
Zero
		movlw	0x00
		movwf	Key_Value
		goto	exit
Aee
		movlw	0x0A
		movwf	Key_Value
		goto	exit
Bee
		movlw	0x0B
		movwf	Key_Value
		goto	exit
Cee
		movlw	0x0C
		movwf	Key_Value
		goto	exit
Dee
		movlw	0x0D
		movwf	Key_Value
		goto	exit
Star
		movlw	0x0E
		movwf	Key_Value
		goto	exit
Hash
		movlw	0x0F
		movwf	Key_Value
		goto	exit
exit
		movlw	0x00
		return

Binary2BCD
	    movlw	0x00
	    addwf	bin, w
	    call	bin2ascii
	    movfw	Hundred
	    call	WR_DATA
	    movfw	Tens
	    call	WR_DATA
	    movfw	Units
	    call	WR_DATA
	    return
bin2ascii
	; Input:  reg. W
	; Output: Hundred / Tens / Units (assumed in the same bank)
	; Assumed "banksel Units"
	; Used 40 instructions / 30-39 cycles (counting CALL/RETURN)
	; average 34.77 cycles (from 0..255).

	clrf Units
	clrf Hundred
	clrf Tens

	; Test if W is more than 199 (200 to 255)
	addlw .256 - .200
	btfss STATUS,C
	goto  digit100
	bsf   Hundred,1
	; Here we are in the 200 - 255 range, so it is possible to
	; skip the .100 and .80 parts
	addlw .256 - .80
	goto  digit40

	; Now, we have a number from -200 to -1 (0..199),
	; we add 100 to detect -100 to -1 (100..199).
digit100
	addlw .100
	btfss STATUS,C
	goto  $+3
	bsf   Hundred,0
	addlw .256 - .100

	; Now, we have a number from -100 to -1 (0..99),
	; we add 20 to detect -20 to -1 (80..99).
	addlw .20
	btfss STATUS,C
	goto  digit40
	bsf   Tens,3
	; We skip the 4 and 2, as the largest value is 8 + 1 = 9.
	addlw .256 - .20
	goto digit10

	; Now, we have a number from -80 to -1 (0..79),
	; we add 40 to detect -40 to -1 (40..79).
digit40
	addlw .40
	btfss STATUS,C
	goto  $+3
	bsf   Tens,2
	addlw .256 - .40

	; Now, we have a number from -40 to -1 (0..39),
	; we add 20 to detect -20 to -1 (20..39).
	addlw .20
	btfss STATUS,C
	goto  $+3
	bsf   Tens,1
	addlw .256 - .20

	; Now, we have a number from -20 to -1 (0..19),
	; we add 10 to detect -10 to -1 (10..19).
digit10
	addlw .10
	btfss STATUS,C
	goto  $+3
	bsf   Tens,0
	addlw .256 - .10

	; Now, we have a number from -10 to -1 (0..9),
	; we add 58 to bring it from 48 to 57 (0..9).
	addlw .58
	movwf Units

	movlw 0x30
	xorwf Tens,f
	xorwf Hundred,f

	return
;***************************************
; Delay Functions
;***************************************
FiveS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	call	HalfS
	return

HalfS	
	local	HalfS_0
      movlw 0x88
      movwf COUNTH
      movlw 0xBD
      movwf COUNTM
      movlw 0x03
      movwf COUNTL

HalfS_0
      decfsz COUNTH, f
      goto   $+2
      decfsz COUNTM, f
      goto   $+2
      decfsz COUNTL, f
      goto   HalfS_0

      goto $+1
      nop
      nop
		return


;******* LCD-related subroutines *******

;***********************************
InitLCD
	bcf STATUS,RP0
	bsf E     ;E default high
	
	;Wait for LCD POR to finish (~15ms)
	call lcdLongDelay
	call lcdLongDelay
	call lcdLongDelay

	;Ensure 8-bit mode first (no way to immediately guarantee 4-bit mode)
	; -> Send b'0011' 3 times
	movlw	b'00110011'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay
	movlw	b'00110010'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; 4 bits, 2 lines, 5x7 dots
	movlw	b'00101000'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; display on/off
	movlw	b'00001100'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay
	
	; Entry mode
	movlw	b'00000110'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; Clear ram
	movlw	b'00000001'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay
	return
    ;************************************

    ;ClrLCD: Clear the LCD display
ClrLCD
	movlw	B'00000001'
	call	WR_INS
    return

    ;****************************************
    ; Write command to LCD - Input : W , output : -
    ;****************************************
WR_INS
	bcf		RS				;clear RS
	movwf	com				;W --> com
	andlw	0xF0			;mask 4 bits MSB w = X0
	movwf	PORTD			;Send 4 bits MSB
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	swapf	com,w
	andlw	0xF0			;1111 0010
	movwf	PORTD			;send 4 bits LSB
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	call	lcdLongDelay
	return

    ;****************************************
    ; Write data to LCD - Input : W , output : -
    ;****************************************
WR_DATA
	bsf		RS				
	movwf	dat
	movf	dat,w
	andlw	0xF0		
	addlw	4
	movwf	PORTD		
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	swapf	dat,w
	andlw	0xF0		
	addlw	4
	movwf	PORTD		
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	return

lcdLongDelay
    movlw d'20'
    movwf lcd_d2
LLD_LOOP
    LCD_DELAY
    decfsz lcd_d2,f
    goto LLD_LOOP
    return
    
Blink
	call	    Clear_Display
	movfw	    time
	addlw	    b'00110000'
	call	    WR_DATA
	return

INT_SERVICE
	 incf	    time_count,f
	 movfw	    time_count
	 sublw	    0x05	;0x26 cycles = 1s	 
	 btfsc	    STATUS,2
	 clrf	    time_count
	 btfsc	    STATUS,2
	 incf	    time
	 bcf	    PIR1,0
	 return   
    
	END
