#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Name, Student Number, UTorID, official email
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.eqv	BASE_ADDRESS 0x10008000
.data
	platform_col: .word 0x991629
	clear_col: .word 0x00000000 # black
	red_col: .word 0xff0000
	main_char_col: .word 0x00ff00
	heart_pattern: .word 0x0e706070, 0x1f70f070, 0x3ff8f8f8 # heart pattern in 3x3 pixels
.text

#####################################################################
# initialization section
main:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	
	
#####################################################################
	# clear the screen before beginning
	la $t1, clear_col
	li $t2, 0x2000 # size of bitmap display
	
	clear_screen:
		sw $t1, ($t0)
		addiu $t0, $t0, 4
		addiu $t2, $t2, -4
		bgtz $t2, clear_screen

#####################################################################

	# sleep for two seconds
	li $v0, 32
	li $a0, 2000
	syscall
	
	li $t0, BASE_ADDRESS
	la $t1, platform_col # load platform color from .data
	lw $t1, 0($t1) # set value of t1 to value at addr t1
	
	li $t2, 0x00ff00 # $t2 stores the green colour code
	li $t3, 0x0000ff # $t3 stores the blue colour code

	# test screen width
	sw $t1, 252($t0) # 256 - 4 is top corner
	
	# represents a 4x3 pixel main character
	la $t4, 1280($t0)
	la $s0, 0($t4)
	
	sw $t2, 0($t4)
	sw $t2, 256($t4) # colour vertically
	sw $t2, 512($t4)
	sw $t2, 768($t4)
	
	addi $t4, $t4, 4 # do the same one pixel to the right
	sw $t2, 0($t4)
	sw $t2, 256($t4) # colour vertically
	sw $t2, 512($t4)
	sw $t2, 768($t4)
	
	addi $t4, $t4, 4 # do the same one pixel to the right
	sw $t2, 0($t4)
	sw $t2, 256($t4) # colour vertically
	sw $t2, 512($t4)
	sw $t2, 768($t4)
	
	
	# draw three platforms
	# store the base addresses in $s1 $s2 and $s3
	la $s1, 1536($s0)
	la $s2 128($s1)
	la $s3 240($s1)
	
	
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	
	# colour second platform (5 pixels wide)
	sw $t1, 0($s2)
	sw $t1, 4($s2)
	sw $t1, 8($s2)
	sw $t1, 12($s2)
	
	# colour second platform (5 pixels wide)
	sw $t1, 0($s3)
	sw $t1, 4($s3)
	sw $t1, 8($s3)
	sw $t1, 12($s3)
	
	# draw a spike 
    	la $a0, BASE_ADDRESS
    	jal draw_spike
    	la $a0, 24($t0)
    	jal draw_spike
    	

#####################################################################
# main game loop section
game_loop:
	# check for keypress
	li $t8, 0
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	andi $t8, $t8, 0x01
	beqz $t8, game_loop # if t8 has a 1 a key was pressed
	
	
#####################################################################
# handle key presses
key_pressed:
	li $t9, 0xffff0000
	lw, $t2, 4($t9) # t9 stores the address of the key press, the key that was pressed will be at addr + 4
	beq $t2, 113, END # can use ascii decimal values to check key presses (113 -> q)
	beq $t2, 112, main # currently when pressing p program does not wait for new key press and keeps looping on main
	beq $t2, 100, handle_move_right # when player presses d main character moves to the right
	beq $t2, 97, handle_move_left
	j game_loop

draw_spike: # draws a spike at address thats found in a0
	la $t0, ($a0)
	li $t1, 0x0e706070
	sw $t1, 0($t0) # first pixel left corner
    	sw $t1, 8($t0) # top right corner
    	sw $t1, 260($t0) # centre
    	sw $t1, 512($t0) # bottom left
    	sw $t1, 520($t0) # bottom right
	jr $ra
	
handle_move_right:
	la $t0, 0($s0) # prev address of main character
	la $t2, clear_col # load colour black into t1
	lw $t2, 0($t2)
	
	# draw black over previous location
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, 4 # shift one pixel right
	la $t0, 0($s0)
	la $t2, main_char_col
	lw, $t2, 0($t2)
	
	# redraw character 1 unit to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	j game_loop

# very similar to handle move right except we go backwards by one unit	
handle_move_left:
	la $t0, 0($s0) # prev address of main character
	la $t2, clear_col # load colour black into t1
	lw $t2, 0($t2)
	
	# draw black over previous location
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, -4 # shift one pixel left
	la $t0, 0($s0)
	la $t2, main_char_col
	lw, $t2, 0($t2)
	
	# redraw character 1 unit to the left
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	
	addi $t0, $t0, 4 # do the same one pixel to the right
	sw $t2, 0($t0)
	sw $t2, 256($t0) # colour vertically
	sw $t2, 512($t0)
	sw $t2, 768($t0)
	j game_loop
END:	
	li $v0, 10
	syscall

