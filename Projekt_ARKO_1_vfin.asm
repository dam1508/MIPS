		.data

one:		.asciiz "1"
#fileName:	.asciiz "/home/dam1508/Pulpit/Arko/test1.txt"

fileName:	.space 128		# C:/Users/damia/OneDrive/Pulpit/Studia/Arko/MIPS/test.txt  |OR|  /home/dam1508/Pulpit/Arko/test1.txt
incNumber:	.space 64
newLine:	.space 512
buffer:		.space 512
currLine:	.space 128
savedLine:	.space 128

		.text
		
main:

	li 	$v0, 8
	la 	$a0, fileName
	li 	$a1, 128
	syscall
	
	la 	$s0, fileName
	jal 	correct_input

	li 	$v0, 13			#create file if it doesn't exist
	la 	$a0, fileName
	li 	$a1, 9
	li 	$a2, 0
	syscall
	
	move 	$s0, $v0
	
	bltz 	$v0, no_file		#instructions if it doesn't exist
	
	li 	$v0, 16			#if it does, close it and open to read
	move 	$a0, $s0
	syscall
	
	li 	$v0, 13			#opening file to read
	la 	$a0, fileName
	li 	$a1, 0
	li 	$a2, 0
	syscall
	
	move 	$s0, $v0
	
setup:

	la 	$s5, currLine
	la 	$s6, savedLine
	
	li 	$t1, 0			#checks if it's a number 0 - maybe, 1 - yes, 2 - number with a dot, 3 - not a number (nan), 4 - number with dot at the end
	li 	$t2, 0			#line length counter
	li 	$t3, 0			#number length counter
	li 	$t4, 0			#found number length
	li 	$t5, 0			#dot in the found number (0 - no dot, 1 - there is a dot)
	li 	$t6, 0			#number distance from the beggining of the line (to the end of the number)
	li 	$t7, 0			#lenth of the line with number
	li 	$t8, 0			#flag for a number in line
	b 	load_byte
	
check_byte:
	
	move 	$t0, $v1
	
	sb 	$t0, ($s5)
	
	beq 	$t0, '\n', new_line		#end of line
	
	addiu 	$t2, $t2, 1		#line length increase
	
	addu 	$s5, $s5, 1	
	
	beq 	$t0, '\r', load_byte
	beq 	$t0, ' ', new_word		#end of word
	beq 	$t0, '\t', new_word		#treat the same as space
	
	beq 	$t1, 3, load_byte		#it's already not a number, so go to next
	beq 	$t0, '.', next_dot		#it's a dot
	bltu 	$t0, '0', next_nan		#if it's less than 0 go to next step (not a number)
	bgtu 	$t0, '9', next_nan		#if it's greater than 9 go to next step (not a number)
	
	#if none of these happened, it's a number
	beq 	$t1, 0, next_new_num	#it's potentially a number
	beq 	$t1, 4, fix_dot_flag
	b 	next_num
	
fix_dot_flag:

	li 	$t1, 2
	b 	next_num
	
next_new_num:

	li 	$t1, 1
	
next_num:

	addiu 	$t3, $t3, 1
	
load_byte:

	move 	$a0, $s0
	jal 	getC
	
load_byte_check:
	
	bgtz 	$v0, check_byte
	beqz 	$v0, increment_setup
	b 	end
	
next_dot:
	
	beq 	$t1, 0, next_nan
	beq 	$t1, 2, next_nan
	li 	$t1, 4
	b 	next_num
	
next_nan:
	
	li 	$t1, 3
	b 	load_byte
	
new_word:

	beq 	$t1, 1, save_number_nd
	beq 	$t1, 2, save_number_d
	
new_word_cont:

	li 	$t1, 0
	li 	$t3, 0
	
	b 	load_byte
	
save_number_d:

	li 	$t5, 1
	b 	save_number
	
save_number_nd:

	li 	$t5, 0
	
save_number:

	li 	$t8, 1
	move 	$t4, $t3
	subiu 	$t6, $t2, 2
	beq 	$t0, '\n', fix
	
	b 	new_word_cont
	
fix:

	addiu 	$t6, $t6, 1
	b 	save_line
	
new_line:

	beq 	$t1, 1, save_number_nd
	beq 	$t1, 2, save_number_d
	bgtz 	$t8, save_line
	
new_line_cont:
	
	li 	$t1, 0
	li 	$t2, 0
	li 	$t3, 0
	li 	$t8, 0
	b 	load_byte
	
save_line:
	
	subu 	$s6, $s5, $t2
	move 	$t7, $t2			#saves line length
	move 	$s4, $s3			#saves address of the end of the line with number
	b 	new_line_cont
	
getC:

	bne 	$s1, $s2, return_byte	#checks if whole buffer was used
	
getC_load:
	
	li 	$v0, 14			#read from file
	la 	$a1, buffer			
	li 	$a2, 512			
	syscall
	li 	$s1, 0			# set number of readed bytes
	move 	$s2, $v0			# save number of loaded bytes
	
	bgtz 	$s2, return_byte
	jr 	$ra				# $v0 already contains info 0 - if end of file; negative - if error

return_byte:

	la 	$s3, buffer			# get address of first unreaded byte in inputBuffer
	addu 	$s3, $s3, $s1		#
	lbu 	$v1, ($s3)			# load byte for returning
	
	addu 	$s1, $s1, 1		# increase number of readed bytes from inputBuffer	
	li 	$v0, 1			# set flag as positive
	jr 	$ra
	
increment_setup:

	beqz 	$t4, no_number		#if the saved number length is 0 -> there is no number
	move 	$t1, $t4			#save number length 
	la 	$s1, incNumber		#here the incremented number will be stored
	addu 	$s1, $s1, $t4		#moving addresses to the correct position
	addu 	$s2, $s6, $t6
	beq 	$t5, 1, find_dot		#if there was a dot in the number, find it
	
increment_number:

	lb 	$t0, ($s2)
	subiu	$s2, $s2, 1		#moves address of saved number buffer
	beq	$t0, '9', nine_exc		#if the first digit is 9 go to special exception
	add 	$t0, $t0, 1			#increment the number
	sb 	$t0, ($s1)			#store byte in a newNumber buffer	
	subiu 	$t1, $t1, 1		#this helps checking if the while number is done 
	beq 	$t1, 0, copy_line_setup	#if the whole number is done start copying line
	subiu 	$s1, $s1, 1		#move buffer
	b 	copy_rest			#just copy the rest of the number
	
find_dot:

	lb 	$t0, ($s2)			#copying the number until we find the dot
	subiu 	$s2, $s2, 1
	sb 	$t0, ($s1)
	subiu 	$t1, $t1, 1
	subiu 	$s1, $s1, 1
	bne 	$t0, '.', find_dot
	b 	increment_number
	
nine_exc:
	
	subiu 	$t0, $t0, 9		#makes 0 from 9 (9 changes into 10)
	sb 	$t0, ($s1)			#saves byte to a buffer
	subiu 	$t1, $t1, 1		#help as previously
	beq 	$t1, 0, finish_number	#if whole number is done finish the number (add 1 in front of it)
	lb 	$t0, ($s2)			#loads next byte
	subiu 	$s2, $s2, 1		##moving buffers
	subiu 	$s1, $s1, 1
	beq 	$t0, '9', nine_exc		#if it's a 9 again go back to the start
	#else
	
increment_next_number:

	addiu 	$t0, $t0, 1		#adds 1 to the next digit (eg. 79 -> 80, so 7 -> 8)
	sb 	$t0, ($s1)			#stores the byte in a buffer
	subiu 	$t1, $t1, 1		#help
	beq 	$t1, 0, copy_line_setup		#if the number is finished doing copy the line
	subiu 	$s1, $s1 ,1		#move buffer
	b 	copy_rest
	
finish_number:

	subiu 	$s1, $s1, 1		#moves buffer out of the number
	addiu 	$t0, $t0, 1		#make it a 1 (t0 is already a 0)
	addiu 	$t7, $t7, 1
	sb 	$t0, ($s1)			#store the byte
	b 	copy_line_setup			#go copy the line
	
copy_rest:

	lb 	$t0, ($s2)			#just copies next bytes until the whole number is copied
	subiu 	$s2, $s2, 1
	sb 	$t0, ($s1)	
	subiu	$t1, $t1, 1
	
	beq 	$t1, 0, copy_line_setup
	subiu 	$s1, $s1, 1
	b 	copy_rest
	
copy_line_setup:

	subu 	$t1, $t6, $t4		#distance of the number from the beggining of the line
	addu 	$t1, $t1, 1
	li 	$t2, 0			#stores length of copied line
	move 	$t3, $t4
	move 	$s2, $s6
	la 	$s3, newLine
	
copy_line:
	
	beqz 	$t1, paste_number
	lbu 	$t0, ($s2)
	
	beq 	$t2, $t7, write_to_file
	sb 	$t0, ($s3)
	
	addiu 	$s2, $s2, 1
	addiu 	$s3, $s3, 1
	subiu 	$t1, $t1, 1
	addiu 	$t2, $t2, 1
	b 	copy_line
	
paste_number:

	lbu 	$t0, ($s1)			#loads byte from saved number
	beqz 	$t0, correct_buffer	#if it's the end of the saved number go to correct the buffer (we werent moving the saved line buffer)
	sb 	$t0, ($s3)			#save byte in a new line buffer
	
	addiu 	$s1, $s1, 1		#moving buffers
	addiu 	$s3, $s3, 1
	addiu 	$t2, $t2, 1		#num of characters in line counter
	
	b 	paste_number			#loop
	
correct_buffer:

	addu 	$s2, $s2, 1		#moves the buffer by the length of initial number, in case the new number is 1 digit longer (99 -> 100)
	subiu 	$t3, $t3, 1
	bgtz 	$t3, correct_buffer
	subiu 	$t1, $t1, 1
	b 	copy_line
	
write_to_file:

	subu 	$s3, $s3, $t2
	
	li 	$v0, 16			#close the file to read
	move 	$a0, $s0
	syscall			
	
	li 	$v0, 13			#open file to append to it
	la	$a0, fileName
	li 	$a1, 9
	la 	$a2, 0
	syscall
	
	move 	$s0, $v0
	
	li 	$v0, 15			#append to file
	move 	$a0, $s0
	move 	$a1, $s3
	move 	$a2, $t2
	syscall
	
	b 	end
	
no_number:

	li 	$v0, 16			#close the file to read
	move 	$a0, $s0
	syscall			
	
	li 	$v0, 13			#open file to append to it
	la 	$a0, fileName
	li 	$a1, 9
	la 	$a2, 0
	syscall
	
	move 	$s0, $v0
	
	li 	$v0, 15			#because there were no numbers inside the file, just write 1 at the end
	move 	$a0, $s0
	la 	$a1, one
	li 	$a2, 1
	syscall
	
	b end
	
no_file:
	
	li 	$v0, 15			#if there was no file create one with number 1 in it
	move 	$a0, $s0
	la 	$a1, one
	li 	$a2, 1
	syscall
	
	b 	end
	
correct_input:

	move	$t0, $s0		#load address of the name
	
correct_loop:

	lbu 	$t1, ($t0)			#loading bytes from name
	beqz 	$t1, exit_loop		#name is correct
	beq 	$t1, '\n', change
	addu 	$t0, $t0, 1		
	b 	correct_loop
	
change:

	li 	$t1, '\0'			#change $t1 to 0
	sb	 $t1, ($t0)			#save it in $t0
	
exit_loop:

	jr 	$ra
	
end:
	
	li 	$v0, 16			#close the file and end the programme
	move 	$a0, $s0
	syscall
	
	li 	$v0, 10
	syscall
