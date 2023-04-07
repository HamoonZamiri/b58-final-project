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
	# initialize x and y coordinates
	# s4 -> x coordinate of main char
	# s5 -> y coordinate of main char
	li $s4, 0
	li $s5, 5
	
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
	la $s1, 2560($t0) 
	
	la $s2 80($t0)
	addi $s2, $s2, 10752 # move platform 2 34 units lower (256 * 34)
	
	la $s3 192($t0) # trying to touch corner with 16 length, 256 - 16 * 4
	addi $s3, $s3, 2560 # match height of platform 1
	
	li $t2, 0 # create loop to draw platforms
	la $t3, 0($s1)
	draw_p1: # loop to draw platform with length 60/4 = 15 + 1
		sw $t1, 0($t3)
		addi $t3, $t3, 4
		addi $t2, $t2, 4
		ble $t2, 60, draw_p1 # platform length is 16 right now
	
	li $t2, 0 # loop counter variable
	la $t3, 0($s2) # load base addr of platform 2
	draw_p2:
		sw $t1, 0($t3)
		addi $t3, $t3, 4
		addi $t2, $t2, 4
		ble $t2, 140, draw_p2 # platform length is 36 right now
	
	li $t2, 0 # loop counter variable
	la $t3, 0($s3) # load base addr of platform 2
	draw_p3:
		sw $t1, 0($t3)
		addi $t3, $t3, 4
		addi $t2, $t2, 4
		ble $t2, 60, draw_p3 # platform length is 16 right now
	
	# draw a spike 
    	la $a0, BASE_ADDRESS
    	jal draw_spike
    	la $a0, 24($t0)
    	jal draw_spike
    	

#####################################################################
# main game loop section
game_loop:
	li $v0, 32
	li $a0, 100 # Wait 500ms
	syscall
	j handle_move_down
	# check for keypress
post_gravity:	
	li $t8, 0
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	andi $t8, $t8, 0x01
	beqz $t8, game_loop 
	
	
#####################################################################
# handle key presses
key_pressed:
	li $t9, 0xffff0000
	lw, $t2, 4($t9) # t9 stores the address of the key press, the key that was pressed will be at addr + 4
	beq $t2, 113, END # can use ascii decimal values to check key presses (113 -> q)
	beq $t2, 112, main # currently when pressing p program does not wait for new key press and keeps looping on main
	beq $t2, 100, handle_move_right # when player presses d main character moves to the right
	beq $t2, 97, handle_move_left
	beq $t2, 119, handle_move_up
	j game_loop

draw_spike: # draws a spike at address thats found in a0
	la $t0, ($a0)
	li $t1, 0x0e706070 # grey colour
	sw $t1, 0($t0) # first pixel left corner
    	sw $t1, 8($t0) # top right corner
    	sw $t1, 260($t0) # centre
    	sw $t1, 512($t0) # bottom left
    	sw $t1, 520($t0) # bottom right
	jr $ra
	
handle_move_right:
	#####################################################################
	# check condition for if x ($s4) is at 61 do not move right
	bge $s4, 61, game_loop
	#####################################################################
	
	jal black_out_main_char
	
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, 4 # shift one pixel right
	addi $s4, $s4, 1 # shift x coordinate 1 unit to the right
	jal draw_main_char
	j game_loop

# very similar to handle move right except we go backwards by one unit	
handle_move_left:
	#####################################################################
	# check condition if x coordinate is at 0 cannot move left
	beq $s4, 0, game_loop
	#####################################################################
	
	jal black_out_main_char
	#####################################################################
	
	#####################################################################
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, -4 # shift one unit left
	addi $s4, $s4, -1 # shift x coordinate one unit left
	jal draw_main_char
	j game_loop
	#####################################################################


handle_move_up:
	#####################################################################
	# check condition if y coordinate is at 0 cannot move up
	ble $s5, 0, game_loop
	ble $s5, 1, game_loop
	#####################################################################
	jal black_out_main_char
	
	#####################################################################
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, -512 # shift base pixel two units up
	addi $s5, $s5, -2 # shift y coordinate two units up
	jal draw_main_char
	
	j game_loop
	#####################################################################
	
	
	#####################################################################
handle_move_down: # simulate gravity
	# check condition if y coordinate is at 64 cannot move down
	bge $s5, 60, end_down
	
	# check if there are platform collisions
	jal check_platform_collision
	beq $v0, 1, end_down
	#####################################################################
	
	jal black_out_main_char # call black_out function
	#####################################################################
	
	# swtich colour in t2 back to green and draw character 4 units to the down
	addi $s0, $s0, 256 # shift one unit down
	addi $s5, $s5, 1 # shift y coordinate one unit down
	jal draw_main_char # after shifting s0 redraw main character in function
	
	end_down:
		j post_gravity
	#####################################################################

check_platform_collision:
	la $t0, 768($s0) # addr of main character
	la $t1, -256($s1) # load address of first platform
	li $t2, 0
	collision_loop1: # loop for first platform to check collisions
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 15, collision_loop1
	
	la $t1, -256($s2)
	li $t2, 0
	
	collision_loop2: # loop for second platform to check collisions
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 35, collision_loop2 # platform 2 is currently 36 units large
	
	la $t1, -256($s3)
	li $t2, 0
	
	collision_loop3: # loop for third platform to check collisions
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 15, collision_loop3
	
	li $v0, 0
	jr $ra
	collided:
		li $v0, 1
		jr $ra
		
draw_main_char:
	la $t0, 0($s0)
	la $t2, main_char_col
	lw, $t2, 0($t2)
	
	# redraw character
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
	jr $ra
	
black_out_main_char:
	la $t0, 0($s0) # prev address of main character
	la $t2, clear_col # load colour black into t2
	lw $t2, 0($t2)
	
	#####################################################################
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
	
	jr $ra
END:	
	li $v0, 10
	syscall

