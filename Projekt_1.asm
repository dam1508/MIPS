		.data
	
fileName:	.asciiz "C:/Users/damia/OneDrive/Pulpit/Studia/Arko/MIPS/test.txt"
fileName2:	.asciiz "C:/Users/damia/OneDrive/Pulpit/Studia/Arko/MIPS/tes.txt"
fileError:	.asciiz "file not found"
newLine:	.space 1024
buffer:		.space 1024

		.text
		
main:
		
	li $v0, 13			#opening file to read
	la $a0, fileName
	li $a1, 0
	li $a2, 0
	syscall
	
	#bltz $v0, no_file		#instructions if it doesn't exist
	
	move $s0, $v0			
	
	li $v0, 13			
	la $a0, fileName2
	li $a1, 9
	la $a2, 0
	syscall
	
	move $s1, $v0
	
read_file:

	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 1023
	syscall
	
	la $s5, buffer			#storing buffer in s5
	move $s3, $s5			#s3 will remember address of current line
	li $t3, 0			#is it a number? 0 - maybe, 1 - yes, 2 - no
	li $t4, 0			#number length
	li $t5, 0			#number of dots in a number sequence
	li $t6, 0			#line length counter
	li $t7, 0			#flag to check if line has a number
	
load_byte:

	lb $t0, 0($s5)	
	addiu $t6, $t6, 1		#line length increase		
	
	beq $t0, $0, end		#EOF
	beq $t0, ' ', new_word		#end of word
	beq $t0, '\t', new_word
	
	#seq $t9, $t0, '\n'
	beq $t0, '\n', new_line		#end of line
	
	beq $t3, 2, next_nan		#it's already not a number, so go to next
	beq $t0, '.', next_dot		#it's a dot
	bltu $t0, 48, next_nan		#if it's less than 0 go to next step (not a number)
	bgtu $t0, 57, next_nan		#if it's greater than 9 go to next step (not a number)
	
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
	
new_word:

	beq $t3, 1, save_num_address	#if current word was a number remember it
	
	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t5, 0			#resetting number of dots
	
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
	
save_line_length:

	move $t8, $t6			#saves line length
	li $t6, 0			#resetting line length
	
	b load_byte
	
next:

	addiu $s5, $s5, 1		#next char address
	
	b load_byte
	
save_num_address:
	
	subu $s2, $s5, $t4		#saves number address
	move $s4, $s3			#saves address of a line with a number
	
	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t5, 0			#resetting number of dots
	li $t7, 1			#line has a number 
	
	b next
	
save_num_address2:

	move $t8, $t6			#saves line length
	subu $s2, $s5, $t4		#saves number address
	move $s4, $s3			#saves address of a line with a number

	li $t3, 0			#resetting t3
	li $t4, 0			#resetting number length
	li $t5, 0			#resetting number of dots
	li $t6, 0			#resetting line length	
	li $t7, 0			#resetting flag for a number in line
	
	addiu $s5, $s5, 1		#next char address
	
	move $s3, $s5			#save address of a new line
	
	b load_byte
	
file_error:

	li $v0, 4
	la $a0, fileError
	syscall
	
end:
	lb $t0, 0($s4)
	lb $t1, 0($s2)
	
	li $v0, 11
	move $a0, $t0
	syscall
	
	li $v0, 11
	move $a0, $t1
	syscall
	
	li $v0, 1
	move $a0, $t8
	syscall
	
	li $v0, 16
	move $a0, $s1
	syscall
	
	li $v0, 16
	move $a0, $s0
	syscall
	
	li $v0, 10
	syscall
