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
	brown_col: .word 0xeaddca
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
	jal clear_screen
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
	
	jal draw_platforms
	
	# draw a spike 
    	la $a0, BASE_ADDRESS
    	addi $a0, $a0, 15360 # draw spike 3 levels higher than floor
    	jal draw_spike
    	li $a2, 1 # tell spike to move right first
    	
    	jal draw_ropes
    	
    	# draw the floor
    	li $t1, 0x0e706070
    	li $t0, BASE_ADDRESS
    	la $t2, 16128($t0)
    	la $t3, 16384($t0)
    	draw_floor_loop:
    		sw $t1, 0($t2) # store grey into pixel on bottom row
    		addi $t2, $t2, 4 # move one unit right
    		ble $t2, $t3, draw_floor_loop
#####################################################################
# main game loop section
game_loop:
	li $v0, 32
	li $a0, 100 # Wait 500ms
	syscall
	
	# handle spike movement
	# 16384 from base is last pixel
	jal blackout_spike # blackout spike first
	
	# use $a2 as an indicator for what DIR to move in R - 1, L - 0
	beq $a2, 1, move_spike_right
	
	# move spike left
	
	addi $a1, $a1, -4
	li $t0, BASE_ADDRESS
	la $t0, 15360($t0) # leftmost pixel 3 units above ground
	ble $a1, $t0, change_dir_toright
	la $a0, ($a1)
	jal draw_spike
	j after_spike
	
	change_dir_toright:
		addi $a1, $a1, 4
		li $a2, 1
		la $a0, ($a1)
		jal draw_spike
		j after_spike
	move_spike_right:
	 	addi $a1, $a1, 4
	 	li $t0, BASE_ADDRESS
	 	la $t0, 15608($t0) # store address of last pixel
	 	bge $a1, $t0, change_dir_toleft
	 	# not at the edge yet
	 	la $a0, ($a1)
	 	jal draw_spike
	 	j after_spike
	 	
	 	change_dir_toleft:
	 		addi $a1, $a1, -4
	 		li $a2, 0
	 		la $a0, ($a1) # load arg for draw_spike
	 		jal draw_spike
	#####################################################################
	
after_spike:	
	jal draw_ropes
	jal draw_platforms
	j handle_move_down
	# check for keypress
post_gravity:	
	li $t1, 0
	li $t2, 0xffff0000
	lw $t1, 0($t2)
	andi $t1, $t1, 0x01
	beqz $t1, game_loop 
	
	
#####################################################################
# handle key presses
key_pressed:
	li $t1, 0xffff0000
	lw, $t2, 4($t1) # t1 stores the address of the key press, the key that was pressed will be at addr + 4
	beq $t2, 113, END # can use ascii decimal values to check key presses (113 -> q)
	beq $t2, 112, main # currently when pressing p program does not wait for new key press and keeps looping on main
	beq $t2, 100, handle_move_right # when player presses d main character moves to the right
	beq $t2, 97, handle_move_left
	beq $t2, 119, handle_move_up
	j game_loop

draw_spike: # draws a spike at address thats found in a0
	la $t0, ($a0)
	la $a1, ($a0)
	li $t1, 0x0e706070 # grey colour
	sw $t1, 0($t0) # first pixel left corner
    	sw $t1, 8($t0) # top right corner
    	sw $t1, 260($t0) # centre
    	sw $t1, 512($t0) # bottom left
    	sw $t1, 520($t0) # bottom right
	jr $ra
	 	
blackout_spike:
	la $t0, ($a1)
	li $t1, 0 # grey colour
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
	
	#####################################################################
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END
	#####################################################################
	
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
	
	#####################################################################
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END
	#####################################################################
	
	jal draw_main_char
	j game_loop
	#####################################################################


handle_move_up:
	#####################################################################
	# check condition if y coordinate is at 0 cannot move up
	ble $s5, 0, game_loop
	ble $s5, 1, game_loop
	jal check_rope_collision
	beqz $v0, game_loop # when collision function returns 0 we cant move up
	# can only move up when we are touching a rope
	#####################################################################
	jal black_out_main_char
	
	#####################################################################
	# swtich colour in t2 back to green and draw character 4 units to the right
	addi $s0, $s0, -512 # shift base pixel two units up
	addi $s5, $s5, -2 # shift y coordinate two units up
	
	#####################################################################
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END
	#####################################################################
	
	jal draw_main_char
	
	j game_loop
	#####################################################################
	
	
	#####################################################################
handle_move_down: # simulate gravity
	# check condition if y coordinate is at 64 cannot move down
	bge $s5, 59, end_down
	
	# check if there are platform collisions
	jal check_platform_collision
	beq $v0, 1, end_down
	
	jal check_rope_collision
	beq $v0, 1, end_down
	#####################################################################
	
	jal black_out_main_char # call black_out function
	#####################################################################
	
	# swtich colour in t2 back to green and draw character 4 units to the down
	addi $s0, $s0, 256 # shift one unit down
	addi $s5, $s5, 1 # shift y coordinate one unit down
	
	#####################################################################
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END
	#####################################################################
	
	jal draw_main_char # after shifting s0 redraw main character in function
	
	end_down:
		j post_gravity
	#####################################################################

check_rope_collision:
	# ropes found at $s6 $s7 and $s8
	
	la $t1, 0($s7) # first pixel of rope 2
	li $t2, 0
	
	collision_rope2:
		la $t0, 768($s0) # first pixel of bottom main character (bottom left)
		beq $t0, $t1, collided_rope
		
		addi $t0, $t0, 4 # middle pixel of bottom row
		beq $t0, $t1, collided_rope
		
		addi $t0, $t0, 4 # last pixel of bottom row
		beq $t0, $t1, collided_rope
		
		addi $t2, $t2, 1 # increment loop counter
		addi $t1, $t1, 256 # one pixel down on the rope
		ble $t2, 20, collision_rope2
		
	la $t1, 0($t8)
	li $t2, 0
	
	collision_rope3:
		la $t0, 768($s0) # first pixel of bottom main character (bottom left)
		beq $t0, $t1, collided_rope
		
		addi $t0, $t0, 4 # middle pixel of bottom row
		beq $t0, $t1, collided_rope
		
		addi $t0, $t0, 4 # last pixel of bottom row
		beq $t0, $t1, collided_rope
		
		addi $t2, $t2, 1 # increment loop counter
		addi $t1, $t1, 256 # one pixel down on the rope
		ble $t2, 30, collision_rope3
	
	li $v0, 0 # no collision
	jr $ra
	collided_rope:
		li $v0, 1
		jr $ra
		
check_platform_collision:
	la $t1, -256($s1) # load address of first platform
	li $t2, 0
	collision_loop1: # loop for first platform to check collisions
		la $t0, 768($s0) # addr of main character
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 15, collision_loop1
	
	la $t1, -256($s2)
	li $t2, 0
	
	collision_loop2: # loop for second platform to check collisions
		la $t0, 768($s0) # addr of main character
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 35, collision_loop2 # platform 2 is currently 36 units large
	
	la $t1, -256($s3)
	li $t2, 0
	
	collision_loop3: # loop for third platform to check collisions
		la $t0, 768($s0) # addr of main character
		beq $t0, $t1, collided # if leftmost main character pixel is on top of platform pixel collision detected
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t0, $t0, 4 # check if middle pixel collides 
		beq $t0, $t1, collided
		
		addi $t1, $t1, 4 # move platform pixel one unit right
		addi, $t2, $t2, 1 # increment loop counter by 1
		ble $t2, 15, collision_loop3
	
	li $v0, 0
	jr $ra
	collided:
		li $v0, 1
		jr $ra

check_spike_collision:
	la $t0, ($a1) # load the top left pixel of the spike
	
	li $t2, 0 # loop counter
	
	mid_level_loop:
		la $t1, 256($s0) # second level of main character intersecting with top of spike
		beq $t0, $t1, collided_spike
		
		addi $t1, $t1, 4
		beq $t0, $t1, collided_spike
		
		addi $t1, $t1, 4
		beq $t0, $t1, collided_spike
		
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		ble $t2, 2, mid_level_loop
	
	la $t0, ($a1) # load the top left pixel of the spike
	bottom_level_loop:
		la $t1, 768($s0) # bottom level on main character
		beq $t0, $t1, collided_spike
		
		addi $t1, $t1, 4
		beq $t0, $t1, collided_spike
		
		addi $t1, $t1, 4
		beq $t0, $t1, collided_spike
		
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		ble $t2, 2, bottom_level_loop
		
	li $v0, 0
	jr $ra
	collided_spike:
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
	
draw_ropes:
	# drawing ropes
    	li $t1, 0x0000ff # blue colour code
    	li $t2, 0
    	la $t3, 256($s2) # directly under platform is first pixel of ladder
    	la $s7, 0($t3) 
	draw_rope2:
		li $t4, 0x00ff00 # $t4 stores the green colour code
		lw $t5, 0($t3)
		beq $t4, $t5, updates_rope2 # skip colouring if main character is on this pixel

		sw $t1, 0($t3) # colour pixel blue
		updates_rope2:
			addi $t3, $t3, 256 # move address one pixel down
			addi $t2, $t2, 1
			ble $t2, 20, draw_rope2 # 21 units large rope
	
	li $t2, 0
	la $t3, 256($s3) # underneath 3rd platform
	addi $t3, $t3, 16
	
	la $t8, 0($t3) # t8 represents rope on third platform
	
	draw_rope3:
		li $t4, 0x00ff00
		lw $t5, 0($t3)
		beq $t4, $t5, updates_rope3
		
		sw $t1, 0($t3)
		updates_rope3:
			addi $t3, $t3, 256 # move address one pixel down
			addi $t2, $t2, 1
			ble $t2, 30, draw_rope3 # 21 units large rope
	jr $ra
	
draw_platforms:
	li $t1, 0x991629 # platform colour
	li $t2, 0 # create loop to draw platforms
	la $t3, 0($s1)
	draw_p1: # loop to draw platform with length 60/4 = 15 + 1
		li $t4, 0x00ff00 # $t4 stores the green colour code
		lw $t5, 0($t3)
		beq $t4, $t5, updates_p1
		
		sw $t1, 0($t3)
		updates_p1:
			addi $t3, $t3, 4
			addi $t2, $t2, 4
			ble $t2, 60, draw_p1 # platform length is 16 right now
	
	li $t2, 0 # loop counter variable
	la $t3, 0($s2) # load base addr of platform 2
	draw_p2:
		li $t4, 0x00ff00 # $t4 stores the green colour code
		lw $t5, 0($t3)
		beq $t4, $t5, updates_p2
		
		sw $t1, 0($t3)
		updates_p2: 
			addi $t3, $t3, 4
			addi $t2, $t2, 4
			ble $t2, 140, draw_p2 # platform length is 36 right now
	
	li $t2, 0 # loop counter variable
	la $t3, 0($s3) # load base addr of platform 2
	draw_p3:
		li $t4, 0x00ff00 # $t4 stores the green colour code
		lw $t5, 0($t3)
		beq $t4, $t5, updates_p3
		
		sw $t1, 0($t3)
		
		updates_p3: 
			addi $t3, $t3, 4
			addi $t2, $t2, 4
			ble $t2, 60, draw_p3 # platform length is 16 right now
	jr $ra

clear_screen:
	li $t1, BASE_ADDRESS
	la $t2, 16380($t1)
	clear_screen_loop:	
		sw $zero, 0($t1)
		addi $t1, $t1, 4
		ble $t1, $t2 clear_screen_loop
	jr $ra
	
END:	
	li $v0, 10
	syscall

