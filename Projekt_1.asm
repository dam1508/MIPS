		.data
	
fileNameWin:	.asciiz "C:/Users/damia/OneDrive/Pulpit/Studia/Arko/MIPS/test.txt"
fileNameLin:	.asciiz "/home/dam1508/Pulpit/Arko/test.txt"
fileError:	.asciiz "file not found"
incNumber:	.space 128
newLine:	.space 1024
buffer:		.space 1024
#newLine:	.asciiz "\n"

		.text
		
main:
		
	li $v0, 13			#opening file to read
	la $a0, fileNameLin
	li $a1, 0
	li $a2, 0
	syscall
	
	#bltz $v0, no_file		#instructions if it doesn't exist
	
	move $s0, $v0
	
read_file:

	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 1023
	syscall
	
	la $s5, buffer			#storing buffer in s5
	la $s6, newLine			#here a line to copy will be stored
	la $s7, incNumber		#here incremented number will be stored
	move $s3, $s5			#s3 will remember address of current line
	li $t1, 0			#t1 stores length of last number
	li $t2, 0			#t2 remembers after how many characters the number started
	li $t3, 0			#is it a number? 0 - maybe, 1 - yes, 2 - no
	li $t4, 0			#number length
	li $t5, 0			#number of dots in a number sequence
	li $t6, 0			#line length counter
	li $t7, 0			#flag to check if line has a number
	li $t8, 0			
	li $t9, 0			#checks if saved number has a dot
	
load_byte:

	lb $t0, 0($s5)	
	
	beq $t0, $0, increment_setup	#EOF
	#seq $t9, $t0, '\n'
	beq $t0, '\n', new_line		#end of line
	
	addiu $t6, $t6, 1		#line length increase
	
	
	beq $t0, '\r', next
	beq $t0, ' ', new_word		#end of word
	beq $t0, '\t', new_word	
	
	beq $t3, 2, next_nan		#it's already not a number, so go to next
	beq $t0, '.', next_dot		#it's a dot
	bltu $t0, '0', next_nan		#if it's less than 0 go to next step (not a number)
	bgtu $t0, '9', next_nan		#if it's greater than 9 go to next step (not a number)
	
	#b next_num 			#if non of these happened, it's a number


	
next_num:

	li $t3, 1
	addiu $t4, $t4, 1
	
	b next
	
next_dot:

	beq $t3, 0, next_nan
	
	addiu $t5, $t5, 1
	
	bgtu $t5, 1, next_nan
	b next_num
	
next_nan:
	
	li $t3, 2			#current word is not a number
	
	b next
	
new_line:

	beq $t3, 1, save_num_address2	#if current word was a number remember it
	
	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t5, 0			#resetting number of dots
	
	addiu $s5, $s5, 1		#next char address
	move $s3, $s5			#save address of a new line
	
	beq $t7, 1, save_line_length	
	
	li $t6, 0			#resetting line length
	
	b load_byte

new_word:

	beq $t3, 1, save_num_address	#if current word was a number remember it
	
	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t5, 0			#resetting number of dots
	
	b next
		
save_line_length:

	#move $t8, $t6			#saves line length
	li $t6, 0			#resetting line length
	
	beq $t5, 1, number_has_dot	#remembers that number has a dot
	li $t9, 0			#remembers that the new number didnt have a dot
	li $t5, 0			#resetting number of dots
	
	b load_byte
	
next:

	addiu $s5, $s5, 1		#next char address
	
	b load_byte

number_has_dot:

	li $t9, 1
	b load_byte
	
save_num_address:
	
	subu $t2, $t6, $t4		#saves number place in line
	subu $t2, $t2, 1
	subu $s2, $s5, 1
	move $s4, $s3			#saves address of a line with a number
	move $t1, $t4
	
	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t7, 1			#line has a number 
	addiu $s5, $s5, 1		#next char address
	
	beq $t5, 1, number_has_dot	#remembers that number has a dot
	li $t9, 0			#remembers that the new number didnt have a dot
	li $t5, 0			#resetting number of dots
	
	b load_byte
	
save_num_address2:

	subu $t2, $t6, $t4		#saves number address
	subu $t2, $t2, 1
	subu $s2, $s5, 2
	move $s4, $s3			#saves address of a line with a number
	move $t1, $t4

	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t7, 0			#resetting flag for a number in line
	
	addiu $s5, $s5, 1		#next char address
	
	move $s3, $s5			#save address of a new line
	
	b save_line_length
	
found_dot:

	li $t9, 0
	b increment_number
	
increment_setup:
	
	move $t3, $t1			#save number length for later
	addu $s7, $s7, $t1
	
increment_number:

	beq $t9, 1, find_dot
	
	lb $t0, ($s2)			#loads byte from saved number
	subiu $s2, $s2, 1		#moves address of saved number buffer
	beq $t0, '9', nine_exc		#if the first digit is 9 go to special exception
	add $t0, $t0, 1			#increment the number
	sb $t0, ($s7)			#store byte in a newNumber buffer
	subiu $t1, $t1, 1		#this helps checking if the while number is done 
	
	beq $t1, 0, copy_line		#if the whole number is done start copying line
	subiu $s7, $s7, 1		#move buffer
	b copy_rest			#just copy the rest of the number
	
find_dot:

	lb $t0, ($s2)
	subiu $s2, $s2, 1
	sb $t0, ($s7)
	subiu $t1, $t1, 1
	subiu $s7, $s7, 1
	beq $t0, '.', found_dot
	b find_dot
	
	
nine_exc:
	
	subiu $t0, $t0, 9		#makes 0 from 9 (9 changes into 10)
	sb $t0, ($s7)			#saves byte to a buffer
	subiu $t1, $t1, 1		#help as previously
	#b copy_rest
	beq $t1, 0, finish_number	#if whole number is done finish the number (add 1 in front of it)
	lb $t0, ($s2)			#loads next byte
	subiu $s2, $s2, 1		##moving buffers
	subiu $s7, $s7, 1
	beq $t0, '9', nine_exc	#if it's a 9 again go back to the start
	#else
	
increment_next_number:

	addiu $t0, $t0, 1		#adds 1 to the next digit (eg. 79 -> 80, so 7 -> 8)
	sb $t0, ($s7)			#stores the byte in a buffer
	subiu $t1, $t1, 1		#help
	
	beq $t1, 0, copy_line		#if the number is finished doing copy the line
	subiu $s7, $s7,1		#move buffer
	b copy_rest			#just copy the rest of the number
	
finish_number:

	subiu $s7, $s7, 1		#moves buffer out of the number
	addiu $t0, $t0, 1		#make it a 1 (t0 is already a 0)
	sb $t0, ($s7)			#store the byte
	b copy_line			#go copy the line
	
copy_rest:

	lb $t0, 0($s2)			#just copies next bytes until the whole number is copied
	subiu $s2, $s2, 1
	sb $t0, 0($s7)
	subiu $t1, $t1, 1
	
	beq $t1, 0, copy_line
	subiu $s7, $s7, 1
	b copy_rest
	
correct_buffer:

	addu $s4, $s4, 1		#moves the buffer by the length of initial number, in case the new number is 1 digit longer (99 -> 100)
	subi $t3, $t3, 1
	bgtz $t3, correct_buffer
	subiu $t2, $t2, 1
	
	
copy_line:
	
	beqz $t2, copy_number		#when the buffer reaches the start of the last nuber found copy changed number instead of the initial one
	lb $t0, ($s4)			#loads byte from saved line
	
	beq $t0, '\n', write_to_file	#if its a end of line, write copied line to file
	sb $t0, ($s6)			#save byte to buffer
	
	li $v0, 4
	move $a0, $s6
	syscall
	
	addiu $s4, $s4, 1		#moving buffers
	addiu $s6, $s6, 1
	subiu $t2, $t2, 1		#one byte closer to the start of the saved number
	addiu $t8, $t8, 1		#num of characters in line counter
	
	b copy_line			#loop
	
copy_number:
	
	lb $t0, ($s7)			#loads byte from saved number
	beqz $t0, correct_buffer	#if it's the end of the saved number go to correct the buffer (we werent moving the saved line buffer)
	sb $t0, ($s6)			#save byte in a new line buffer
	
	addiu $s7, $s7, 1		#moving buffers
	addiu $s6, $s6, 1
	addiu $t8, $t8, 1		#num of characters in line counter
	
	b copy_number			#loop
	
write_to_file:
	
	subu $s6, $s6, $t8
	
	li $v0, 16
	move $a0, $s0
	syscall			
	
	li $v0, 13			
	la $a0, fileNameLin
	li $a1, 9
	la $a2, 0
	syscall
	
	move $s1, $v0
	
	li $v0, 15
	move $a0, $s1
	move $a1, $s6
	move $a2, $t8
	syscall
	
	b end
	
end:
	
	li $v0, 1
	move $a0, $t2
	syscall
	
	li $v0, 16
	move $a0, $s1
	syscall
	
	li $v0, 10
	syscall
