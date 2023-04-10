#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Hamoon Zamiri, 1007164710, zamiriha, hamoon.zamiri@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/score [2 marks]
# 2. Fail condition [1 mark]
# 3. Win condition [1 mark]
# 4. Moving objects [2 marks]
# 5. Disappearing platforms [1 mark]
# 6. Shoot enemies [2 marks]
# total 9 marks
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/watch/33a872d777b9b86a3302c6ac5ad8c15d
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - to shoot from your left side use the "j" key
# - to shoot from your right side use the "k" key
#####################################################################

.eqv	BASE_ADDRESS 0x10008000
.data
	platform_col: .word 0x991629
	clear_col: .word 0x00000000 # black
	red_col: .word 0xff0000
	brown_col: .word 0xeaddca
	main_char_col: .word 0x00ff00
	heart_pattern: .word 0x0e706070, 0x1f70f070, 0x3ff8f8f8 # heart pattern in 3x3 pixels
	stars: .space 12 # stores the addresses of the stars
	stars_collected: .word 0, 0, 0
	score: .word 0 # stores the current number of stars that have been collected
	star2_dir: .word 0 # 0 for left and 1 for right
	star2_indicator: .word 0
	left_bullet_addr: .word 0
	left_bullet_x: .word -1
	right_bullet_addr: .word 0
	right_bullet_x: .word -1
	spike_dead: .word 0
	platform_toggle: .word 0
	timer : .word 0 
.text

#####################################################################
# initialization section
main:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	# initialize x and y coordinates and reset .data section
	# s4 -> x coordinate of main char
	# s5 -> y coordinate of main char
	li $s4, 0
	li $s5, 5
	
	# reset score
	li $t0, 0
	la $t1, score
	sw $t0, ($t1)
	
	# reset star2 direction and indicator

	la $t1, star2_dir
	sw $t0, ($t1)
	
	la $t1, star2_indicator
	sw $t0, ($t1)
	
	# reset bullet info
	la $t1, left_bullet_addr
	sw $t0, ($t1)
	
	la $t1, right_bullet_addr
	sw $t0, ($t1)
	
	li $t0, -1
	la $t1, left_bullet_x
	sw $t0, ($t1)
	
	la $t1, right_bullet_x
	sw $t0, ($t1) 
	
	# reset spike dead
	li $t0, 0
	la $t1, spike_dead
	sw $t0, ($t1)
	
	# reset stars collected
	la $t1, stars_collected
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	
	# reset disappearing platform vars
	la $t1, platform_toggle
	sw $zero, platform_toggle
	
	la $t1, timer
	sw $zero, timer
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
	
    	# draw ropes that you can climb
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
    	
    	# draw the stars
    	jal draw_stars
#####################################################################
# main game loop section
game_loop:
	li $v0, 32
	li $a0, 80 # Wait 500ms
	syscall
	
	lw $t1, timer
	beq $t1, 8000, toggle_disappearing_platform
	
	after_toggle:
	lw $t1, timer
	la $t2, timer
	addi $t1, $t1, 100
	sw $t1, ($t2)
	
	lw $t1, score
	beq $t1, 3, END_WIN
	
	jal update_left_bullet # move any existing bullets
	jal update_right_bullet
	jal check_bullet_spike_collision # kill spike
	# draw the current score
	jal draw_score
	
	jal check_spike_collision
	beq $v0, 1, END_LOSS
	
	#####################################################################
	# handle spike movement
	# 16384 from base is last pixel
	jal blackout_spike # blackout spike first
	lw $t1, spike_dead
	beq $t1, 1, after_spike
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
after_spike:	
	#####################################################################
	# handle moving star 2
	# furthest right is 15352(base)
	
	# if indicator is 1 star has already been collected

	lw $t0, star2_indicator
	beq $t0, 1, after_star
	
	jal blackout_star2
	lw $t0, star2_dir
	beq $t0, 1, move_star_right
	
	# star needs to move left
	la $t1, stars
	
	lw $t2, 4($t1) # use t2 to change t1
	addi $t2, $t2, -4
	
	li $t0, BASE_ADDRESS
	addi $t3, $t0, 15100 # leftmost pixel 3 units above ground
	ble $t2, $t3, change_stardir_toright
	sw $t2, 4($t1)
	jal draw_star2
	j after_star
	
	change_stardir_toright:
		li $t0, 1
		addi $t2, $t2, 4		
		la $t4, star2_dir
		
		sw $t0, 0($t4) # change position of star to right
		sw $t2, 4($t1)
		
		jal draw_star2
		j after_star
	move_star_right:
		# star needs to move left
		li $t0, BASE_ADDRESS
		la $t1, stars
		
		lw $t2, 4($t1) # use t2 to change t1
		addi $t2, $t2, 4
		
		addi $t3, $t0, 15352
		bge $t2, $t3, change_stardir_toleft
		sw $t2, 4($t1)
		jal draw_star2
		j after_star
		
	change_stardir_toleft:
		li $t0, 0
		addi $t2, $t2, -4		
		la $t4, star2_dir
		sw $t0, 0($t4)
		
		sw $t2, 4($t1)
		jal draw_star2
after_star:
	# check collisions again as spike and bullet may move
	jal check_star_collision
	jal check_bullet_spike_collision
	jal check_spike_collision
		
	jal draw_ropes
	jal draw_platforms
	jal draw_main_char
	jal draw_static_stars
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
	beq $t2, 113, END_LOSS # can use ascii decimal values to check key presses (113 -> q)
	beq $t2, 112, main # currently when pressing p program does not wait for new key press and keeps looping on main
	beq $t2, 100, handle_move_right # when player presses d main character moves to the right
	beq $t2, 97, handle_move_left
	beq $t2, 119, handle_move_up
	beq $t2, 106, handle_shoot_left # when player presses j they want to shoot in the left direction
	beq $t2, 107, handle_shoot_right
	j game_loop

toggle_disappearing_platform:
	lw $t1, platform_toggle
	beq $t1, 1, make_visible
	# make invisible currently visible
	la $t1, platform_toggle
	li $t2, 1
	sw $t2, ($t1)
	
	la $t1, timer
	sw $zero, ($t1)
	j after_toggle
	
	make_visible:
	la $t1, platform_toggle
	li $t0, 0
	sw $t0, ($t1)
	
	la $t1, timer
	sw $zero, ($t1)
	j after_toggle
		
#####################################################################
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
#####################################################################	
	
#####################################################################
blackout_star2:
	la $t0, stars
	lw $t1, 4($t0)
	li $t2, 0
	
	sw $t2, 0($t1) # top left
	sw $t2, 4($t1) # top right
	sw $t2, 256($t1)
	sw $t2 260($t1)
	jr $ra
draw_star2:
	la $t0, stars
	lw $t1, 4($t0)
	li $t2, 0xffff00 # colour yellow
	
	sw $t2, 0($t1) # top left
	sw $t2, 4($t1) # top right
	sw $t2, 256($t1)
	sw $t2 260($t1)
	jr $ra
#####################################################################
# shooting section
handle_shoot_left:
	# shooting will occur from the second row of the main character
	ble $s4, 0, end_shoot_left
	
	# check if reset is necessary
	lw $t1, left_bullet_addr
	lw $t2, left_bullet_x
	
	beq $t2, -1, post_reset_left
	sw $zero, ($t1)
	la $t1, left_bullet_addr
	sw $zero, ($t1)
	
	la $t2, left_bullet_x
	li $t3, -1
	sw $t3, ($t2)
	
	post_reset_left:
	la $t1, left_bullet_addr
	la $t2, 256($s0) # load second row of main character left side
	addi $t2, $t2, -4 # addr of one to the left of main character
	
	sw $t2, 0($t1) # store addr into left bullet addr
	
	# store x coordinate
	addi $t3, $s4, 0
	addi $t3, $t3, -1
	
	la $t1, left_bullet_x
	sw $t3, 0($t1)
	end_shoot_left: 
		j game_loop
		 
handle_shoot_right:
	# shooting will occur from the second row of the main character
	bge $s4, 61, end_shoot_right
	lw $t1, right_bullet_addr
	lw $t2, right_bullet_x
	
	# reset bullet completely first
	beq $t2, -1, post_reset_right # no reset needed
	# if bullet is active blackout and reset
	sw $zero, ($t1)
	la $t1, right_bullet_addr
	sw $zero, ($t1)
	
	li $t3, -1
	la $t2, right_bullet_x
	sw $t3, ($t2)
	
	post_reset_right: 
	la $t2, 256($s0) # load second row of main character left side
	addi $t2, $t2, 12 # addr of one to the right of main character
	
	la $t1, right_bullet_addr
	sw $t2, 0($t1) # store addr into left bullet addr
	
	# store x coordinate
	addi $t3, $s4, 0
	addi $t3, $t3, 3
	
	la $t1, right_bullet_x
	sw $t3, 0($t1)
	end_shoot_right: 
		j game_loop

check_bullet_spike_collision:
	lw $t1, left_bullet_addr
	lw $t2, right_bullet_addr
	
	# check for collision from right bullet on left side of spike
	# spike is in a1
	la $t0, 0($a1)
	lw $t4, right_bullet_x
	beq $t4, -1, left_bullet_check
	beq $t0, $t2, right_bullet_spike_collided
	
	# check for collision on the right side of the spike
	left_bullet_check:
	la $t0, 0($a1) # load address of spike
	lw $t4, left_bullet_x
	beq $t4, -1, end_bullet_collision
	
	beq $t0, $t1, left_bullet_spike_collided
	addi $t0, $t0, 4
	beq $t0, $t1, left_bullet_spike_collided
	addi $t0, $t0, 4
	beq $t0, $t1, left_bullet_spike_collided
	addi $t0, $t0, 4
	beq $t0, $t1, left_bullet_spike_collided
	
	jr $ra
	
	right_bullet_spike_collided:
		# blackout spike
		la $t0, 0($a1)
		li $t3, 0 # grey colour
		sw $t3, 0($t0) # first pixel left corner
    		sw $t3, 8($t0) # top right corner
    		sw $t3, 260($t0) # centre
    		sw $t3, 512($t0) # bottom left
    		sw $t3, 520($t0) # bottom right
    		
    		sw $t3, 0($t2) # get rid of bullet
    		la $t2, right_bullet_x # load x coordinate set to -1 to indicate no bullet currently
    		li $t3, -1
    		sw $t3, 0($t2)
    		
    		la $t0, spike_dead # indicate the enemy is dead now 
    		li $t1, 1
    		sw $t1, 0($t0)
		jr $ra
	left_bullet_spike_collided:
		# blackout spike
		la $t0, 0($a1)
		li $t3, 0 # grey colour
		sw $t3, 0($t0) # first pixel left corner
    		sw $t3, 8($t0) # top right corner
    		sw $t3, 260($t0) # centre
    		sw $t3, 512($t0) # bottom left
    		sw $t3, 520($t0) # bottom right
    		
    		sw $t3, 0($t1) # get rid of bullet
    		la $t2, left_bullet_x # load x coordinate set to -1 to indicate no bullet currently
    		li $t3, -1
    		sw $t3, 0($t2)
    		
    		la $t0, spike_dead # indicate the enemy is dead now 
    		li $t1, 1
    		sw $t1, 0($t0)
		jr $ra
	end_bullet_collision:
		jr $ra
		
update_left_bullet:
	# left bullet
	lw $t0, left_bullet_addr # load the addr of the left bullet
	lw $t1, left_bullet_x
	
	# blackout both bullets right now
	
	# sanity checks for 0 and -1 x coordinate
	li $t2, 0
	beq $t1, $t2, reset_left_bullet
	addi $t2, $t2, -1
	beq $t2, $t1, end_left_bullet_update
	
	# now we know bullet needs to be updated
	sw $zero, 0($t0)
	li $t3, 0x0e706070 # grey colour
	addi $t0, $t0, -4 # move the address of new bullet
	sw $t3, 0($t0) # store grey colour in new bullet addr
	
	la $t2, left_bullet_addr
	sw $t0, 0($t2) # store new address of bullet in left_bullet addr
	
	addi $t1, $t1, -1
	la $t0, left_bullet_x
	sw $t1, 0($t0)
	
	end_left_bullet_update:
	jr $ra
	
	reset_left_bullet:
	sw $zero, 0($t0) # colour pixel black
	la $t0, left_bullet_addr
	sw $zero, 0($t0)
		
	la $t1, left_bullet_x
	li $t2, -1
	sw $t2, ($t1)
	jr $ra
	
update_right_bullet:
	# left bullet
	lw $t0, right_bullet_addr # load the addr of the left bullet
	lw $t1, right_bullet_x
	
	# blackout both bullets right now
	
	# sanity checks for 0 and -1 x coordinate
	li $t2, 63
	bge $t1, $t2, reset_right_bullet
	li $t2, -1
	beq $t2, $t1, end_right_bullet_update
	
	# now we know bullet needs to be updated
	sw $zero, 0($t0)
	li $t3, 0x0e706070 # grey colour
	addi $t0, $t0, 4 # move the address of new bullet
	sw $t3, 0($t0) # store grey colour in new bullet addr
	
	la $t2, right_bullet_addr
	sw $t0, 0($t2) # store new address of bullet in left_bullet addr
	
	addi $t1, $t1, 1
	la $t0, right_bullet_x
	sw $t1, 0($t0)
	
	end_right_bullet_update:
	jr $ra
	
	reset_right_bullet:
		sw $zero, 0($t0) # colour pixel black
		la $t0, right_bullet_addr
		sw $zero, 0($t0)
		
		la $t1, right_bullet_x
		li $t2, -1
		sw $t2, ($t1)
		jr $ra
#####################################################################
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
	jal check_star_collision
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END_LOSS
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
	jal check_star_collision
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END_LOSS
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
	jal check_star_collision
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END_LOSS
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
	jal check_star_collision
	# check if colliding with a spike now
	jal check_spike_collision
	beq $v0, 1, END_LOSS
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
	lw $t3, platform_toggle
	beq $t3, 1, after_p2 # platform is currently invisible
	
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
	
	after_p2:
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
	# no need to check if spike was shot
	lw $t0, spike_dead
	beq $t0, 1, no_collision
	la $t0, 0($a1) # load the top left pixel of the spike
	
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
		ble $t2, 3, mid_level_loop
	
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
		
	no_collision:
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
	
	li $t1, 0x991629
	lw $t4, platform_toggle
	beq $t4, 0, draw_p2
	li $t1, 0
	
	draw_p2:
		li $t4, 0x00ff00 # use green colour to check if we're on a character
		lw $t5, 0($t3)
		beq $t4, $t5, updates_p2
		
		sw $t1, 0($t3)
		updates_p2: 
			addi $t3, $t3, 4
			addi $t2, $t2, 4
			ble $t2, 140, draw_p2 # platform length is 36 right now
	
	li $t2, 0 # loop counter variable
	la $t3, 0($s3) # load base addr of platform 2
	li $t1, 0x991629 # reassign platform colour after disappearing platform
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

draw_static_stars:
	lw $t1, stars_collected
	beq $t1, 1, draw_static_star3
	
	la $t0, ($s1) # first start on platform 1
	addi $t0, $t0, -1024
	addi $t0, $t0, 56 # draw at the end of the platform
	
	li $t1, 0xffff00 # load yellow
	sw $t1, 0($t0) # top left
	sw $t1, 4($t0) # top right
	sw $t1, 256($t0)
	sw $t1 260($t0)
	
	draw_static_star3:
	la $t1, stars_collected
	lw $t1, 8($t1)
	
	beq $t1, 1, end_static_stars
	# draw star 3
	li $t1, 0xffff00
	la $t0, ($s3)
	addi $t0, $t0, -1024
	addi $t0, $t0, 56
	
	sw $t1, 0($t0) # top left
	sw $t1, 4($t0) # top right
	sw $t1, 256($t0)
	sw $t1 260($t0)
	
	end_static_stars:
	jr $ra
	
draw_stars:
	la $t0, ($s1) # first start on platform 1
	addi $t0, $t0, -1024
	addi $t0, $t0, 56 # draw at the end of the platform
	
	li $t1, 0xffff00 # load yellow
	sw $t1, 0($t0) # top left
	sw $t1, 4($t0) # top right
	sw $t1, 256($t0)
	sw $t1 260($t0)
	
	# store star in array called "stars"
	la $t2, stars # load the address of the first element in the array
	sw $t0, 0($t2) # store first pixel of star 1 into array stars
	
	# draw star on bottom level
    	la $t0, BASE_ADDRESS
    	addi $t0, $t0, 15352 # draw at main character height level above ground hard right
    	
	sw $t1, 0($t0) # top left
	sw $t1, 4($t0) # top right
	sw $t1, 256($t0)
	sw $t1 260($t0)

    	la $t2, stars
    	sw $t0, 4($t2) # store pixel as second star in stars array
    	
    	
	
	# draw star 3
	la $t0, ($s3)
	addi $t0, $t0, -1024
	addi $t0, $t0, 56
	
	sw $t1, 0($t0) # top left
	sw $t1, 4($t0) # top right
	sw $t1, 256($t0)
	sw $t1 260($t0)
	
	# store address of star 3 in stars
	sw $t0, 8($t2) # store into third slot in array
	
	jr $ra
	
check_star_collision:
	la $t0, stars # stars is an array of 3 addresses
	lw $t0, 0($t0) # load address of star 1
	
	li $t2, 0xffff00 # load yellow
	
	li $t3, 0 # loop counter
	star1_loop:
		la $t1, 0($s0) # load address of main character
		# check colour
		lw $t4, 0($t0)
		bne $t4, $t2, post_star1 # if pixel is not yellow
		beq $t1, $t0, collision_star1 
		
		addi $t1, $t1, 4
		beq $t1, $t0, collision_star1
		
		addi $t1, $t1, 4
		beq $t1, $t0, collision_star1
		
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		ble $t3, 1, star1_loop 
	
	post_star1: 
	
	# star 2
	la $t0, stars # stars is an array of 3 addresses
	lw $t0, 4($t0) # load address of star 3
	li $t3, 0 # loop counter
	star2_loop:
		# check colour
		lw $t4, 0($t0)
		la $t1, 0($s0) # load address of main character
		# add temp reg for bottom row
		addi $t5, $t1, 1024
		
		bne $t4, $t2, post_star2 # if pixel is not yellow
		beq $t1, $t0, collision_star2
		beq $t5, $t0, collision_star2
		
		addi $t1, $t1, 4
		addi $t5, $t5, 4
		beq $t1, $t0, collision_star2
		beq $t5, $t0, collision_star2
		
		
		addi $t1, $t1, 4
		addi $t5, $t5, 4
		beq $t1, $t0, collision_star2
		beq $t5, $t0, collision_star2
		
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		ble $t3, 1, star2_loop
	
	post_star2:
	la $t0, stars # stars is an array of 3 addresses
	lw $t0, 8($t0) # load address of star 3
	li $t3, 0 # loop counter

	star3_loop:
		la $t1, 0($s0) # load address of main character
		# check colour
		lw $t4, 0($t0)
		bne $t4, $t2, post_star3 # if pixel is not yellow
		beq $t1, $t0, collision_star3
		
		addi $t1, $t1, 4
		beq $t1, $t0, collision_star3
		
		addi $t1, $t1, 4
		beq $t1, $t0, collision_star3
		
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		ble $t3, 1, star3_loop 
	
	post_star3:	
	jr $ra
	collision_star1:
		# blackout star
		la $t0, stars # stars is an array of 3 addresses
		lw $t0, 0($t0) # load address of star 1
		li $t1, 0 # load black
		sw $t1, 0($t0) # top left
		sw $t1, 4($t0) # top right
		sw $t1, 256($t0)
		sw $t1 260($t0)
		
		# update score
		lw $t0, score
		la $t1, score
		addi $t0, $t0, 1
		sw $t0, 0($t1)
		
		# update collection array
		la $t0, stars_collected
		li $t1, 1
		sw $t1, 0($t0)
		jr $ra
		
	collision_star2:
		# blackout star
		la $t0, stars # stars is an array of 3 addresses
		lw $t0, 4($t0) # load address of star 2
		li $t1, 0 # load black
		sw $t1, 0($t0) # top left
		sw $t1, 4($t0) # top right
		sw $t1, 256($t0)
		sw $t1 260($t0)
		# update indicator so it doesnt get redrawn in main loop
		la $t0, star2_indicator
		li $t1, 1
		sw $t1, 0($t0)
		# update score
		lw $t0, score
		la $t1, score
		addi $t0, $t0, 1
		sw $t0, 0($t1)
		
		# update collection array
		la $t0, stars_collected
		li $t1, 1
		sw $t1, 4($t0)
		jr $ra
		
	collision_star3:
		# blackout star
		la $t0, stars # stars is an array of 3 addresses
		lw $t0, 8($t0) # load address of star 3
		li $t1, 0 # load black
		sw $t1, 0($t0) # top left
		sw $t1, 4($t0) # top right
		sw $t1, 256($t0)
		sw $t1 260($t0)
		
		# update score
		lw $t0, score
		la $t1, score
		addi $t0, $t0, 1
		sw $t0, 0($t1)
		
		# update collection array
		la $t0, stars_collected
		li $t1, 1
		sw $t1, 8($t0)
		jr $ra		

draw_score:
	# indicate the score of the player on the top row
	# for perfect middle alignment first pixel of second star should be at 128 (center)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 116
	li $t2, 0xffff00 # load colour yellow
	lw $t1, score # the current score either 1, 2, or 3
	beq $t1, 0, end_score
	beq $t1, 1, score_is_1
	beq $t1, 2, score_is_2
	
	# here score is 3 need to draw 3 stars
	# draw star 1 at 116 + t0 for best alignment 
	sw $t2, 0($t0) # top left
	sw $t2, 4($t0) # top right
	sw $t2, 256($t0)
	sw $t2 260($t0)
	
	addi $t0, $t0, 12
	sw $t2, 0($t0) # top left
	sw $t2, 4($t0) # top right
	sw $t2, 256($t0)
	sw $t2 260($t0)
	
	addi $t0, $t0, 12
	sw $t2, 0($t0) # top left
	sw $t2, 4($t0) # top right
	sw $t2, 256($t0)
	sw $t2 260($t0)
	jr $ra
	
	score_is_1:
		sw $t2, 0($t0) # top left
		sw $t2, 4($t0) # top right
		sw $t2, 256($t0)
		sw $t2 260($t0)
		jr $ra
	score_is_2:
		sw $t2, 0($t0) # top left
		sw $t2, 4($t0) # top right
		sw $t2, 256($t0)
		sw $t2 260($t0)
	
		addi $t0, $t0, 12
		sw $t2, 0($t0) # top left
		sw $t2, 4($t0) # top right
		sw $t2, 256($t0)
		sw $t2 260($t0)
	end_score:	
		jr $ra
draw_gameover:
	la $t0, BASE_ADDRESS
        li $t1, 0xf90d0d
        sw $t1, 1304($t0)
        sw $t1, 1308($t0)
        sw $t1, 1312($t0)
        sw $t1, 1316($t0)
        sw $t1, 1560($t0)
        sw $t1, 1624($t0)
        sw $t1, 1628($t0)
        sw $t1, 1632($t0)
        sw $t1, 1636($t0)
        sw $t1, 1816($t0)
        sw $t1, 1880($t0)
        sw $t1, 1892($t0)
        sw $t1, 2072($t0)
        sw $t1, 2080($t0)
        sw $t1, 2084($t0)
        sw $t1, 2088($t0)
        sw $t1, 2096($t0)
        sw $t1, 2100($t0)
        sw $t1, 2104($t0)
        sw $t1, 2112($t0)
        sw $t1, 2116($t0)
        sw $t1, 2120($t0)
        sw $t1, 2124($t0)
        sw $t1, 2128($t0)
        sw $t1, 2136($t0)
        sw $t1, 2140($t0)
        sw $t1, 2144($t0)
        sw $t1, 2148($t0)
        sw $t1, 2328($t0)
        sw $t1, 2344($t0)
        sw $t1, 2352($t0)
        sw $t1, 2360($t0)
        sw $t1, 2368($t0)
        sw $t1, 2376($t0)
        sw $t1, 2384($t0)
        sw $t1, 2392($t0)
        sw $t1, 2584($t0)
        sw $t1, 2588($t0)
        sw $t1, 2592($t0)
        sw $t1, 2596($t0)
        sw $t1, 2600($t0)
        sw $t1, 2608($t0)
        sw $t1, 2612($t0)
        sw $t1, 2616($t0)
        sw $t1, 2624($t0)
        sw $t1, 2632($t0)
        sw $t1, 2640($t0)
        sw $t1, 2648($t0)
        sw $t1, 2652($t0)
        sw $t1, 2656($t0)
        sw $t1, 2660($t0)
        sw $t1, 2876($t0)
        sw $t1, 3352($t0)
        sw $t1, 3356($t0)
        sw $t1, 3360($t0)
        sw $t1, 3364($t0)
        sw $t1, 3368($t0)
        sw $t1, 3376($t0)
        sw $t1, 3384($t0)
        sw $t1, 3392($t0)
        sw $t1, 3396($t0)
        sw $t1, 3400($t0)
        sw $t1, 3408($t0)
        sw $t1, 3412($t0)
        sw $t1, 3416($t0)
        sw $t1, 3420($t0)
        sw $t1, 3608($t0)
        sw $t1, 3624($t0)
        sw $t1, 3632($t0)
        sw $t1, 3640($t0)
        sw $t1, 3648($t0)
        sw $t1, 3664($t0)
        sw $t1, 3676($t0)
        sw $t1, 3864($t0)
        sw $t1, 3880($t0)
        sw $t1, 3888($t0)
        sw $t1, 3896($t0)
        sw $t1, 3904($t0)
        sw $t1, 3908($t0)
        sw $t1, 3912($t0)
        sw $t1, 3920($t0)
        sw $t1, 3924($t0)
        sw $t1, 3928($t0)
        sw $t1, 3932($t0)
        sw $t1, 4120($t0)
        sw $t1, 4136($t0)
        sw $t1, 4144($t0)
        sw $t1, 4152($t0)
        sw $t1, 4160($t0)
        sw $t1, 4176($t0)
        sw $t1, 4180($t0)
        sw $t1, 4376($t0)
        sw $t1, 4380($t0)
        sw $t1, 4384($t0)
        sw $t1, 4388($t0)
        sw $t1, 4392($t0)
        sw $t1, 4400($t0)
        sw $t1, 4408($t0)
        sw $t1, 4416($t0)
        sw $t1, 4420($t0)
        sw $t1, 4424($t0)
        sw $t1, 4432($t0)
        sw $t1, 4440($t0)
        sw $t1, 4660($t0)
        sw $t1, 4700($t0)
        jr $ra
        
draw_win_screen:
	la $t0, BASE_ADDRESS
        li $t1, 0xebd500
        sw $t1, 2384($t0)
        sw $t1, 2400($t0)
        sw $t1, 2408($t0)
        sw $t1, 2448($t0)
        sw $t1, 2452($t0)
        sw $t1, 2456($t0)
        sw $t1, 2464($t0)
        sw $t1, 2468($t0)
        sw $t1, 2472($t0)
        sw $t1, 2488($t0)
        sw $t1, 2496($t0)
        sw $t1, 2640($t0)
        sw $t1, 2656($t0)
        sw $t1, 2672($t0)
        sw $t1, 2676($t0)
        sw $t1, 2680($t0)
        sw $t1, 2688($t0)
        sw $t1, 2692($t0)
        sw $t1, 2696($t0)
        sw $t1, 2704($t0)
        sw $t1, 2720($t0)
        sw $t1, 2728($t0)
        sw $t1, 2896($t0)
        sw $t1, 2904($t0)
        sw $t1, 2912($t0)
        sw $t1, 2920($t0)
        sw $t1, 2928($t0)
        sw $t1, 2936($t0)
        sw $t1, 2944($t0)
        sw $t1, 2952($t0)
        sw $t1, 2960($t0)
        sw $t1, 2964($t0)
        sw $t1, 2968($t0)
        sw $t1, 2976($t0)
        sw $t1, 2996($t0)
        sw $t1, 3012($t0)
        sw $t1, 3152($t0)
        sw $t1, 3156($t0)
        sw $t1, 3160($t0)
        sw $t1, 3164($t0)
        sw $t1, 3168($t0)
        sw $t1, 3176($t0)
        sw $t1, 3184($t0)
        sw $t1, 3192($t0)
        sw $t1, 3200($t0)
        sw $t1, 3208($t0)
        sw $t1, 3216($t0)
        sw $t1, 3232($t0)
        sw $t1, 3252($t0)
        sw $t1, 3256($t0)
        sw $t1, 3260($t0)
        sw $t1, 3264($t0)
        sw $t1, 3268($t0)
        sw $t1, 3472($t0)
        sw $t1, 3476($t0)
        sw $t1, 3480($t0)
	jr $ra
END_LOSS:	
	jal clear_screen
	jal draw_gameover
	
	li $v0, 10
	syscall
END_WIN:
	jal clear_screen
	jal draw_win_screen
	
	li $v0, 10
	syscall
