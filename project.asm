########
# Simple singleplayer Blackjack game played with MARS Bitmap Display and Keyboard MMIO Simulator
# 
# Bitmap Display Requirements:
# Unit Width - 1
# Unit Height - 1
# Display Width - 512
# Display Height - 256
# Base address - 0x10040000 (heap)
#######

.data

####
# Constants
####

# Bitmap Display consts
.eqv WIDTH 512
.eqv HEIGHT 256
.eqv PIXEL_ROOT 0x10040000	# Memory address value for pixel (0,0)

# Card dimension consts
.eqv CARD_WIDTH 60
.eqv CARD_HEIGHT 90
.eqv CARD_SPRITE_SIZE 32

# Color consts
.eqv BACKGROUND_COLOR 0x008C2F39
.eqv RED 0x00FF0000
.eqv BLACK 0x00000000
.eqv WHITE 0x00FFFFFF

# Game/card values
.eqv SUIT_COUNT 4
.eqv CARDS_PER_SUIT 13
.eqv TOTAL_CARDS 52
.eqv FACE_CARD_VALUE 10
.eqv BLACKJACK_MAX 21
.eqv DEALER_MUST_DRAW 16
.eqv RESHUFFLE_COUNT 16

# Flags
.eqv HAS_ACE 1
.eqv BET_ENABLED 1

# Keyboard and Display MMIO Simulator addresses
.eqv INPUT_STATUS_ADDRESS 0xffff0000
.eqv INPUT_ADDRESS 0xffff0004

# Syscall consts
.eqv SYSCALL_DIALOG_CONFIRM 50
.eqv SYSCALL_DIALOG 55
.eqv SYSCALL_DIALOG_INT 56
.eqv SYSCALL_DIALOG_FLOAT 57
.eqv SYSCALL_DIALOG_STRING 59
.eqv SYSCALL_RANDOM_RANGE 42
.eqv SYSCALL_EXIT 10
.eqv SYSCALL_INPUT_FLOAT 52

# Input dialog response consts
.eqv INPUT_OK 0
.eqv INPUT_INVALID -1
.eqv INPUT_CANCEL -2
.eqv INPUT_NONE -3

#####
# Sprites
# Format: Width|Height|Bitstring as hex....
# Every 1 in the bitstring means that pixel will be drawn by render_sprite.
# A 32x32 sprite uses 34 words.
# These were created with GIMP and processed by a python script.
####
suit_root: 
suit_heat: .word 32,32,0x1fc003f8,0x3fe007fc,0x7ff00ffe,0xfff81fff,0xfff81fff,0xfffc3fff,0xfffc3fff,0xfffe7fff,0xffffffff,0xffffffff,0xffffffff,0x7ffffffe,0x7ffffffe,0x7ffffffe,0x3ffffffc,0x3ffffffc,0x1ffffff8,0x0ffffff0,0x0ffffff0,0x07ffffe0,0x03ffffc0,0x01ffff80,0x01ffff80,0x00ffff00,0x007ffe00,0x003ffc00,0x003ffc00,0x001ff800,0x000ff000,0x0007e000,0x0007e000,0x0003c000
suit_diamond: .word 32,32,0x00018000,0x0003c000,0x0003c000,0x0007e000,0x0007e000,0x000ff000,0x000ff000,0x001ff800,0x003ffc00,0x003ffc00,0x007ffe00,0x007ffe00,0x00ffff00,0x01ffff80,0x01ffff80,0x03ffffc0,0x03ffffc0,0x01ffff80,0x01ffff80,0x00ffff00,0x007ffe00,0x007ffe00,0x003ffc00,0x003ffc00,0x001ff800,0x000ff000,0x000ff000,0x0007e000,0x0007e000,0x0003c000,0x0003c000,0x00018000
suit_club: .word 32,32,0x000ff000,0x001ff800,0x003ffc00,0x003ffc00,0x003ffc00,0x003ffc00,0x003ffc00,0x003ffc00,0x003ffc00,0x001ff800,0x000ff000,0x0007e000,0x3f83c1fc,0x7fc3c3fe,0xffe3c7ff,0xfff3cfff,0xffffffff,0xffffffff,0xffffffff,0xfff3cfff,0xffe3c7ff,0x7fc3c3fe,0x3f83c1fc,0x0003c000,0x0003c000,0x0007e000,0x000ff000,0x007ffe00,0x00ffff00,0x03ffffc0,0x03ffffc0,0x01ffff80
suit_spade: .word 32,32,0x00018000,0x0003c000,0x0007e000,0x000ff000,0x001ff800,0x003ffc00,0x007ffe00,0x00ffff00,0x01ffff80,0x03ffffc0,0x07ffffe0,0x0ffffff0,0x1ffffff8,0x1ffffff8,0x3ffffffc,0x3ffffffc,0x3ffdbffc,0x3ffdbffc,0x1ff99ff8,0x1ff99ff8,0x0ff18ff0,0x07e187e0,0x00018000,0x0003c000,0x0003c000,0x0007e000,0x0007e000,0x000ff000,0x003ffc00,0x00ffff00,0x00ffff00,0x007ffe00

rank_root: 
rank_ace: .word 32,32,0x0003c000,0x0003c000,0x0007e000,0x0007e000,0x0007e000,0x0007e000,0x000ff000,0x000ff000,0x000e7000,0x000e7000,0x001e7800,0x001e7800,0x001c3800,0x001c3800,0x003c3c00,0x003c3c00,0x00ffff00,0x00ffff00,0x00ffff00,0x00700e00,0x00700e00,0x00f00f00,0x00f00f00,0x00e00700,0x00e00700,0x01e00780,0x01e00780,0x01c00380,0x03c003c0,0x03c003c0,0x038001c0,0x038001c0
rank_2: .word 32,32,0x003ffe00,0x00ffff00,0x03ffff80,0x07ffffc0,0x07e007c0,0x078003c0,0x070003c0,0x000003c0,0x000003c0,0x000007c0,0x00000fc0,0x00000fc0,0x00001f80,0x00003f00,0x00007e00,0x0000fc00,0x0000fc00,0x0001f800,0x0003f000,0x0007e000,0x000fc000,0x001f8000,0x001f0000,0x003e0000,0x007c0000,0x00f80000,0x01f80000,0x03f00000,0x07e00000,0x07ffff80,0x07ffffc0,0x07ffffc0
rank_3: .word 32,32,0x00fffc00,0x01fffe00,0x03ffff00,0x03c00f00,0x03800780,0x00000380,0x00000380,0x00000380,0x00000380,0x00000380,0x00000380,0x00000780,0x00000f80,0x00000f00,0x001ffe00,0x001ffc00,0x001ffe00,0x00000f00,0x00000f00,0x00000780,0x00000380,0x00000380,0x00000380,0x00000380,0x00000380,0x00000380,0x00000380,0x01c00780,0x01e00f00,0x01ffff00,0x00fffe00,0x007ffc00
rank_4: .word 32,32,0x00007800,0x0000f800,0x0001f800,0x0001f800,0x0003f800,0x0007f800,0x000fb800,0x000f3800,0x001e3800,0x003e3800,0x007c3800,0x00f83800,0x00f03800,0x01e03800,0x03ffff80,0x03ffff80,0x03ffff80,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800,0x00003800
rank_5: .word 32,32,0x01ffff00,0x01ffff00,0x01ffff00,0x01c00000,0x01c00000,0x01c00000,0x01c00000,0x01c00000,0x01c00000,0x01c00000,0x01c00000,0x01e00000,0x01fff000,0x00fffc00,0x007ffe00,0x00001e00,0x00000f00,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000700,0x00000f00,0x00001f00,0x01fffe00,0x01fffc00,0x01fff000
rank_6: .word 32,32,0x0003f800,0x0007f800,0x000ff800,0x001f0000,0x001e0000,0x003c0000,0x003c0000,0x00780000,0x00780000,0x00f00000,0x00f00000,0x00e00000,0x00e00000,0x00e00000,0x00e00000,0x00e00000,0x00e7f800,0x00fffe00,0x00ffff00,0x00f80f00,0x00e00780,0x00e00380,0x00e00380,0x00e00380,0x00e00380,0x00e00380,0x00e00380,0x00f00780,0x00780f00,0x007fff00,0x003ffe00,0x000ff800
rank_7: .word 32,32,0x07ffffc0,0x07ffffc0,0x07ffffc0,0x000007c0,0x000007c0,0x00000f80,0x00001f80,0x00001f00,0x00003f00,0x00003e00,0x00007e00,0x00007c00,0x0000f800,0x0001f800,0x0001f000,0x0003f000,0x0003e000,0x0007c000,0x000fc000,0x000f8000,0x001f8000,0x001f0000,0x003f0000,0x003e0000,0x007c0000,0x00fc0000,0x00f80000,0x01f80000,0x01f00000,0x03f00000,0x03e00000,0x03c00000
rank_8: .word 32,32,0x003ffc00,0x00ffff00,0x01ffff80,0x01e00780,0x03c003c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x03c003c0,0x01e00780,0x01fc3f80,0x00ffff00,0x003ffc00,0x003ffc00,0x00fc3f00,0x01f00f80,0x01e00780,0x03c003c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x038001c0,0x03c003c0,0x01e00780,0x01ffff80,0x00ffff00,0x003ffc00
rank_9: .word 32,32,0x007ff000,0x01fff800,0x03fffc00,0x03c07c00,0x07803c00,0x07003c00,0x07003c00,0x07003c00,0x07003c00,0x07003c00,0x03803c00,0x03803c00,0x03c03c00,0x01e03c00,0x01f83c00,0x00fffc00,0x003ffc00,0x0007fc00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00,0x00003c00
rank_10: .word 32,32,0x07c03ffc,0x1fc07ffe,0x7fc0ffff,0x7fc0ffff,0x3fc0f81f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f00f,0x07c0f81f,0x07c0ffff,0x3ff0ffff,0xfffcffff,0xfffe7ffe,0xfffe3ffc
rank_jack: .word 32,32,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x00000f00,0x01800f00,0x01c01f00,0x01f03f00,0x01fffe00,0x00fffe00,0x007ffc00,0x001ff000
rank_queen: .word 32,32,0x01fffe00,0x07ffff80,0x0fffffc0,0x0f0003c0,0x1e0001e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0000e0,0x1c0070e0,0x1c00f8e0,0x1c00fce0,0x1c00fee0,0x1c007fe0,0x1c003fe0,0x1c001fe0,0x1c000fe0,0x1e0007f0,0x0f0003f8,0x0ffffffc,0x07fffffe,0x01fffe7f,0x0000003f,0x0000001f
rank_king: .word 32,32,0x038001e0,0x038001e0,0x038007e0,0x03800fe0,0x03801fc0,0x03807f80,0x0380ff00,0x0381fc00,0x0383f800,0x038ff000,0x039fe000,0x03bfc000,0x03ff8000,0x03ff0000,0x03fc0000,0x03f80000,0x03f80000,0x03fc0000,0x03fe0000,0x03bf8000,0x039fc000,0x038fe000,0x0387f000,0x0381f800,0x0380fc00,0x03807e00,0x03801f80,0x03800fc0,0x038007e0,0x038003f0,0x038000f0,0x038000f0

####
# Game data
####
.eqv FULL_SUIT 0x1fff	# Each suit has 13-bit string where every 1 means that card is in the deck. The least significant bit is ace, and king is most significant
deck: .half FULL_SUIT, FULL_SUIT, FULL_SUIT, FULL_SUIT	# This array represents all 4 suits with 13 cards each for a total of all 52 cards

dealer_card_count: .byte 0
dealer_card_value: .byte 0
dealer_has_ace: .byte 0

player_card_count: .byte 0
player_card_value: .byte 0
player_has_ace: .byte 0
player_bet_enabled: .byte 0
player_bet: .float 0

bet_mult: .float 1
bet_mult_auto: .float 1.5
bet_mult_dealer_bust: .float 1

####
# Dialog Messages
####
msg_bet_prompt: .asciiz "Please enter your bet for this round (float): "
msg_bet_invalid: .asciiz "Pleae enter a valid bet, or press cancel to bet zero."
msg_bet_confirm: .asciiz "Do you want to play with betting?"

msg_dealer_win: .asciiz "Dealer wins! They won by "
msg_player_win: .asciiz "Congratulations, you won! You won by "
msg_player_win_bet: .asciiz "Congratulations, you won! You win $"
msg_tie: .asciiz "It's a tie! You both had "

msg_reshuffle: .asciiz "The deck has gotten low, so the dealer has reshuffled"

msg_card_value: .asciiz "Your current card value is "
msg_card_value_ace: .ascii 
"You have an ace, which can be either 1 or 11\n",
"Assuming it is 1, your current card value is \0"

msg_bust: .ascii 
"Bust! Your cards went over 21\n",
"Your total was \0"
msg_dealer_bust: .ascii 
"Congratulations, you win because the dealer busted\n",
"Their total was \0"
msg_dealer_bust_bet: .ascii 
"Congratulations, you win because the dealer busted\n",
"You win $\0"

msg_auto_win_bet: .ascii
"You have exactly 21, so you automatically win!\n",
"You win $\0"
msg_auto_win: .asciiz "You have exactly 21, so you automatically win!"

msg_info_title: .asciiz "Welcome to blackjack!\n"
msg_info_body: .ascii
"Your goal is to earn cards more valuable than the dealer without exceeding 21.\n",
"A virtual deck is being used, so card counting is possible and encouraged.\n\n",

"IMPORTANT:\n",
"The dealer's cards are at the top of the screen, and yours are at the bottom.\n\n",

"Cards 2-10 are worth their face value.\n",
"Jacks, Queens, and Kings are all worth 10.\n",
"Aces can be worth either 1 or 11, whichever is more advantageous.\n\n",

"Controls for Keyboard and Display MMIO Simulator:\n",
"h - Hit (draw a new card)\n",
"s - Stand (keep your current hand and let the dealer play)\n",
"v - View Value (view your current hand's value)\n",
"i - Info (show this dialog)\n",
"e - Exit (quit the game)\n",
"Tip: You can use space or enter to close pop-up dialogs.\n\n",

"Values for Bitmap Display:\n",
"Unit Width - 1\n"
"Unit Width - 1\n"
"Width - 512\n",
"Height - 256\n",
"Base Address - 0x10040000 (heap)\n\n"

"Remember to make sure both Bitmap Display and Keyboard and\n",
"Display MMIO Simulator are connected to MIPS.\0"


####
# Main
####
.text
main:
	jal show_info_dialog		# Display the how-to-play dialog
	
	jal bet_confirm_dialog		# Ask if the player wants to play with betting enabled
	lb $s0, player_bet_enabled	# Cache this response in a register
	
	li $a0, 0			# Draw background rectangle over entire bitmap window (zero offset, WIDTH and HEIGHT dimensions)
	li $a1, WIDTH
	li $a2, HEIGHT
	li $a3, BACKGROUND_COLOR
	jal render_rect

	j _start_game			# Skip resetting the game when it hasn't started yet

_reset_game:
	jal reset_game			# Remove all cards and reset player hand values

_start_game:
	bne $s0, BET_ENABLED, _skip_bet	# Skip betting if its not enabled, otherwise ask for the bet
	jal get_bet

_skip_bet:
	jal deal_player			# Deal 1 card to dealer, deal 2 to player
	jal deal_dealer
	jal deal_player
	
	lb $t0, player_card_value	# If the player has an ace and a 10 card (11 total), they win automatically
	lb $t1, player_has_ace		
	bne $t1, HAS_ACE, _await_input
	beq $t0, 11, _auto_win		# has_ace && value == 11

_await_input:
	lw $t0, INPUT_STATUS_ADDRESS	# Loop until input
	beqz $t0, _await_input

	lw $t0, INPUT_ADDRESS		# Process key input
	beq $t0, 'h', _hit
	beq $t0, 's', _stand
	beq $t0, 'v', _card_value
	beq $t0, 'i', _info
	beq $t0, 'e', exit
	beq $t0, 'q', exit
	j _await_input			# Repeat if invalid

_hit:
	jal deal_player			# Deal a new card to the player. If its over 21, they bust
	lb $t0, player_card_value
	bgt $t0, BLACKJACK_MAX, _bust
	j _await_input

_stand:
	jal deal_dealer			# The dealer gets 1 new card
	
	lb $t0, dealer_card_value	# If the dealer has 16 or under, they must draw another card
	bgt $t0, DEALER_MUST_DRAW, _decide_winner
	jal deal_dealer
	
	lb $t0, dealer_card_value	# If the dealer is at or below 21, decide the winner. Otherwise, they're bust
	ble $t0, BLACKJACK_MAX, _decide_winner

	beq $s0, BET_ENABLED, _dealer_bust_bet	# Go to betting version of dealer bust if it's enabled
	
	li $v0, SYSCALL_DIALOG_INT	# Send non bet dealer bust dialog including their total
	la $a0, msg_dealer_bust
	move $a1, $t0			# t0 is dealer's card value
	syscall
	j _reset_game

_dealer_bust_bet:
	li $v0, SYSCALL_DIALOG_FLOAT	# Prepare float dialog
	la $a0, msg_dealer_bust_bet
	l.s $f12, player_bet
	l.s $f1, bet_mult_dealer_bust
	mul.s $f12, $f12, $f1		# Calculate winnings (bet * dealer bust multiplier)
	syscall
	j _reset_game

_decide_winner:
	jal decide_winner		# Decide and announce the winner
	j _reset_game

_bust:
	li $v0, SYSCALL_DIALOG_INT	# Send bust dialog including the player's current card value
	la $a0, msg_bust
	lb $a1, player_card_value
	syscall
	j _reset_game

_auto_win:
	bne $s0, BET_ENABLED, _auto_win_no_bet	# Use no bet dialog if betting is disabled
	
	l.s $f12, player_bet
	l.s $f1, bet_mult_auto
	mul.s $f12, $f12, $f1		# Calculate win amount (bet * auto win multiplier)
	li $v0, SYSCALL_DIALOG_FLOAT	# Send float dialog telling the player they won automatically
	la $a0, msg_auto_win_bet
	syscall
	j _reset_game

_auto_win_no_bet:
	li $v0, SYSCALL_DIALOG		# Send no bet dialog
	la $a0, msg_auto_win
	li $a1, 1
	syscall
	j _reset_game

_card_value:
	lb $t0, player_has_ace		# Send ace dialog instead if they have an ace
	beq $t0, HAS_ACE, _card_value_ace
	li $v0, SYSCALL_DIALOG_INT	# Send dialog with the player's current card value
	la $a0, msg_card_value
	lb $a1, player_card_value
	syscall
	j _await_input

_card_value_ace:
	li $v0, SYSCALL_DIALOG_INT	# Send special ace card value dialog
	la $a0, msg_card_value_ace
	lb $a1, player_card_value
	syscall
	j _await_input

_info:
	jal show_info_dialog
	j _await_input

exit:
	li $v0, SYSCALL_EXIT
	syscall
	
####
# Macros and functions
####

# Push a register value on to the stack
.macro push_reg (%reg)
	addi $sp, $sp, -4
	sw %reg, ($sp)
	.end_macro
# Pop a register value from the stack	
.macro pop_reg (%reg)
	lw %reg, ($sp)
	addi $sp, $sp, 4
	.end_macro

# Push the value of ra on to the stack
.macro push_ra
	push_reg $ra
	.end_macro

# Pop the value of ra from the stack
.macro pop_ra
	pop_reg $ra
	.end_macro

####
# Draws a sprite from a sprite array (essentially a long bitstring). See info in .data section.
# It does so by iterating over each word in the bitstring, then every bit in each of those words, 
# drawing a pixel every time there is a 1.
# a0 - Pixel index of where the top-left corner of the sprite will be drawn
# a1 - Memory address of sprite array
# a2 - Color
####
render_sprite:
	lw $t0, 0($a1)			# Sprite width index (will be going down; i--)
	lw $t1, 4($a1)			# Sprite height index
	sll $t2, $a0, 2			# Pixel pointer = a0 * 4 + PIXEL_ROOT
	addi $t2, $t2, PIXEL_ROOT
	li $t3, 64			# Pixel bit index (start after first 2 words)

_rs_draw_pixel:
	rem $t7, $t3, 32		# Check if bit index is at the end of a word
	bnez $t7, _rs_skip_new_word	# If it's not, skip getting a new word

	srl $t7, $t3, 3			# Get the byte offset from the bit index by dividing it by 8
	add $t7, $t7, $a1		# Add offset to root address
	lw $t4, ($t7)			# Get new pixel word

_rs_skip_new_word:
	andi $t7, $t4, 0x80000000	# Is the most significant bit 1?
	sll $t4, $t4, 1			# Move the word left for next iteration
	addi $t3, $t3, 1		# Increment pixel bit index
	beqz $t7, _rs_skip_draw		# If the bit is not 1, skip drawing this pixel
	sw $a2, ($t2)			# Draw pixel
	
_rs_skip_draw:
	subi $t0, $t0, 1		# Decrement width
	addi $t2, $t2, 4		# Move pixel pointer
	beqz $t0, _rs_new_line		# Branch if this line is finished
	j _rs_draw_pixel
	
_rs_new_line:
	subi $t1, $t1, 1		# Decrement height
	beqz $t1, _rs_return		# Break if last line has been drawn

	lw $t0, ($a1)			# Reset width index
	li $t7, WIDTH			# Move pixel pointer by (WIDTH - sprite width) * 4
	sub $t7, $t7, $t0		# (t0 is still full sprite width)
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	j _rs_draw_pixel

_rs_return:
	jr $ra

####
# Draws a rectangle. It does so with a nested for loop.
# a0 - Pixel index of the top-left corner
# a1 - Width
# a2 - Height
# a3 - Color
####	
render_rect:
	li $t0, 0			# Width index
	li $t1, 0			# Height index
	sll $t2, $a0, 2			# Pixel index * 4
	addi $t2, $t2, PIXEL_ROOT	# Pixel pointer = root + index

_rr_draw_pixel:
	sw $a3, ($t2)			# Draw pixel
	addi $t0, $t0, 1		# Increment width index
	addi $t2, $t2, 4		# Move pixel pointer
	beq $t0, $a1, _rr_new_line	# Go to new line if at end
	j _rr_draw_pixel

_rr_new_line:
	addi $t1, $t1, 1		# Increment height index
	beq $t1, $a2, _rr_return	# Return if this is was the last line
	li $t0, 0			# Reset width index
	li $t7, WIDTH			# Move pixel pointer by (WIDTH - rect width) * 4
	sub $t7, $t7, $a1
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	j _rr_draw_pixel

_rr_return:
	jr $ra

####
# Draws a playing card. Suit/rank indexes are the same order as .data
# a0 - Pixel index of the top-left corner
# a1 - Suit
# a2 - Rank
####
render_card:
	push_ra				# Save all current values on stack
	push_reg $s0
	push_reg $s1
	push_reg $s2
	push_reg $a0
	push_reg $a1
	push_reg $a2
	push_reg $a3
	
	move $s0, $a0			# Save original argument values to s registers
	move $s1, $a1
	move $s2, $a2
	
	li $a1, CARD_WIDTH		# Render background
	li $a2, CARD_HEIGHT
	li $a3, WHITE
	jal render_rect
	
	li $t7, WIDTH			# Offset pixel sprite (width + 1) * 4
	addi $t7, $t7, 1
	sll $t7, $t7, 2
	add $a0, $s0, $t7
	
	la $a1, suit_root		# Get root suit address
	li $t7, 136			# Get address offset for this suit (Suit index * 34 * 4)
	mult $s1, $t7
	mflo $t7
	add $a1, $a1, $t7		# Add offset to root address
	
	bgt $s1, 1, _rc_black_suit	# If the suit is above 1 (not heart or diamond), draw it black
	li $a2, RED
	j _rc_after_suit_color

_rc_black_suit:
	li $a2, BLACK

_rc_after_suit_color:
	jal render_sprite
	
	li $t7, WIDTH			# Pixel index offset = (Width * (card height - sprite size - 4)) + card width - sprite size - 4
	li $t6, CARD_HEIGHT
	addi $t6, $t6, -CARD_SPRITE_SIZE
	addi $t6, $t6, -4
	mult $t7, $t6
	mflo $t7
	addi $t7, $t7, CARD_WIDTH
	addi $t7, $t7, -CARD_SPRITE_SIZE
	addi $t7, $t7, -4
	add $a0, $s0, $t7		# Add offset
	
	la $a1, rank_root		# Address offset = (index * 34 * 4)
	li $t7, 136
	mult $s2, $t7
	mflo $t7
	add $a1, $a1, $t7		# Add offset
	jal render_sprite		# Render sprite with same color as suit (a2 is still color)
	
	pop_reg $a3
	pop_reg $a2
	pop_reg $a1
	pop_reg $a0
	pop_reg $s2
	pop_reg $s1
	pop_reg $s0
	pop_ra
	jr $ra

####
# Searches through the deck for the Nth card (0 index), or returns the total card count.
# It does so by getting each suit bitstring, iterating through each bit, and keeping a running total of
# how many ones there have been. Once it reaches the Nth card or the end, it returns.
# a0 - Nth card or -1 to get total card count
# v0 - Either the suit of the Nth card, or the total card count
# v1 - Nth card rank, or nothing
####
search_deck:
	li $t0, 0			# Suit index
	li $t1, 0			# Card index
	la $t2, deck			# Suit halfword pointer
	li $t3, 0			# Running card count
	li $t5, -1			# Default value is -1 in case we aren't searching
	bltz $a0, _sd_new_hw		# Skip fixing search index if we're not searching
	addi $t5, $a0, 1		# Add 1 to the search number because we no longer want it 0 indexed

_sd_new_hw:
	lh $t4, ($t2)			# Get halfword value from pointer

_sd_sum_loop:				# This counts how many 1s are in the deck bitstring
	andi $t7, $t4, 0x1		# 1 if the last bit is 1, otherwise 0
	add $t3, $t3, $t7		# Add the result to the running total
	beq $t3, $t5, _sd_return_card	# This is the nth card, so return the information if we need to
	addi $t1, $t1, 1		# Increment card index
	beq $t1, CARDS_PER_SUIT, _sd_next_suit
	srl $t4, $t4, 1			# Move bitstring for next iteration
	j _sd_sum_loop

_sd_next_suit:
	addi $t0, $t0, 1		# Increment index, return if all suits have been counted
	beq $t0, SUIT_COUNT, _sd_return_count
	li $t1, 0			# Reset card index
	addi $t2, $t2, 2		# Move halfword pointer
	j _sd_new_hw

_sd_return_card:
	move $v0, $t0
	move $v1, $t1
	jr $ra

_sd_return_count:
	move $v0, $t3
	jr $ra

####
# Draws a random card from the deck, removing it from the deck. Uses MARS random int syscall
# v0 - Suit of card
# v1 - Rank of card
####
draw_random_card:
	push_ra
	push_reg $a0
	push_reg $a1
	
	li $a0, -1			# Get card count
	jal search_deck

	bnez $v0, _drc_skip_break	# Break if the deck is empty (there must be a bug)
	break

_drc_skip_break:
	li $a0, 0			# Get random number between 0 and the card count
	move $a1, $v0
	li $v0, SYSCALL_RANDOM_RANGE
	syscall
	
	jal search_deck			# Search for the Nth random card chosen (a0 is already the Nth card)
	
	la $t0, deck			# Get address of the suit the card is in
	sll $t1, $v0, 1			# Offset = suit * 2
	add $t0, $t0, $t1
	lh $t1, ($t0)			# Get value of suit bitsring
	li $t2, 1			# Create a value equal to 2^rank
	sllv $t2, $t2, $v1
	sub $t1, $t1, $t2		# Subtract that value to remove the card's bit (bitstring value - 2^rank)
	sh $t1, ($t0)			# Replace suit bitstring
	
	pop_reg $a1
	pop_reg $a0
	pop_ra
	jr $ra
	
####
# Returns the blackjack value of a card. Ace is counted as 1.
# a0 - Card rank
# v0 - Blackjack value
####
get_card_value:
	addi $v0, $a0, 1
	bgt $v0, FACE_CARD_VALUE, _gcv_face_card
	jr $ra

_gcv_face_card:
	li $v0, 10
	jr $ra

####
# Deals a new card for either the player or dealer by displaying it on the screen.
# Adds the card to the individual's total and marks if they have an ace.
# a0 - 0 for dealer, 1 for player
# a1 - Suit
# a2 - Rank
####
deal_card:
	push_ra
	push_reg $a0
	bnez $a0, _dc_player		# Branch if not the dealer
	
	li $a0, WIDTH			# Pixel index = (Width + 1) * 8
	addi $a0, $a0, 1
	sll $a0, $a0, 3
	
	lb $t0, dealer_card_count	# Pixel index += (card width + 8) * card count
	li $t1, CARD_WIDTH
	addi $t1, $t1, 8
	mult $t0, $t1
	mflo $t1
	add $a0, $a0, $t1
	
	addi $t0, $t0, 1		# Increment card count by 1
	sb $t0, dealer_card_count
	
	push_reg $v0
	push_reg $a0

	move $a0, $a2
	jal get_card_value		# Get the dealt card value and add it to the total
	lb $t0, dealer_card_value
	add $t0, $t0, $v0
	sb $t0, dealer_card_value
	bnez $a2, _dc_dealer_skip_ace	# Skip if not ace

	li $t0, HAS_ACE
	sb $t0, dealer_has_ace		# Mark that they were dealt an ace

_dc_dealer_skip_ace:
	pop_reg $a0
	pop_reg $v0
	
	j _dc_render
	
_dc_player:
	li $t0, HEIGHT			# Pixel index = Width * (height - card height - 8) + 8
	addi $t0, $t0, -CARD_HEIGHT
	addi $t0, $t0, -8
	li $t1, WIDTH
	mult $t0, $t1
	mflo $t0
	addi $a0, $t0, 8
	
	lb $t0, player_card_count	# Pixel index += (card width + 8) * card count
	li $t1, CARD_WIDTH
	addi $t1, $t1, 8
	mult $t0, $t1
	mflo $t1
	add $a0, $a0, $t1
	
	addi $t0, $t0, 1		# Increment card count by 1
	sb $t0, player_card_count
	
	push_reg $v0
	push_reg $a0

	move $a0, $a2
	jal get_card_value		# Get the dealt card value and add it to the total
	lb $t0, player_card_value
	add $t0, $t0, $v0
	sb $t0, player_card_value
	bnez $a2, _dc_player_skip_ace	# Skip if not ace

	li $t0, HAS_ACE
	sb $t0, player_has_ace		# Mark that they were dealt an ace

_dc_player_skip_ace:
	pop_reg $a0
	pop_reg $v0

_dc_render:
	jal render_card			# a1 and a2 are already suit and rank

	pop_reg $a0
	pop_ra
	jr $ra

####
# Removes the rightmost card for either the player or dealer
# a0 - 0 for dealer, 1 for player
####
pop_card:
	push_ra
	push_reg $a0
	push_reg $a1
	push_reg $a2
	push_reg $a3
	bnez $a0, _pc_player		# Branch if not the dealer
	
	li $a0, WIDTH			# Pixel index = (Width + 1) * 8
	addi $a0, $a0, 1
	sll $a0, $a0, 3
	
	lb $t0, dealer_card_count	
	addi $t0, $t0, -1		# Decrement card count by 1
	sb $t0, dealer_card_count
	li $t1, CARD_WIDTH		# Pixel index += (card width + 8) * card count
	addi $t1, $t1, 8
	mult $t0, $t1
	mflo $t1
	add $a0, $a0, $t1
	
	j _pc_render

_pc_player:
	li $t0, HEIGHT			# Pixel index = Width * (height - card height - 8) + 8
	addi $t0, $t0, -CARD_HEIGHT
	addi $t0, $t0, -8
	li $t1, WIDTH
	mult $t0, $t1
	mflo $t0
	addi $a0, $t0, 8
	
	lb $t0, player_card_count	
	addi $t0, $t0, -1		# Decrement card count by 1
	sb $t0, player_card_count
	li $t1, CARD_WIDTH		# Pixel index += (card width + 8) * card count
	addi $t1, $t1, 8
	mult $t0, $t1
	mflo $t1
	add $a0, $a0, $t1

_pc_render:
	li $a1, CARD_WIDTH
	li $a2, CARD_HEIGHT
	li $a3, BACKGROUND_COLOR
	jal render_rect
	
	pop_reg $a3
	pop_reg $a2
	pop_reg $a1
	pop_reg $a0
	pop_ra
	jr $ra

####
# Draws a random card and gives it to either the dealer or player
# a0 - 0 for dealer, 1 for player
####
draw_and_deal_card:
	push_ra
	push_reg $a1
	push_reg $a2
	jal draw_random_card
	move $a1, $v0
	move $a2, $v1
	jal deal_card
	pop_reg $a2
	pop_reg $a1
	pop_ra
	jr $ra

####
# Deal (draw and display) a random card to the dealer
####
deal_dealer:
	push_ra
	push_reg $a0
	li $a0, 0
	jal draw_and_deal_card
	pop_reg $a0
	pop_ra
	jr $ra

####
# Deal (draw and display) a random card to the player
####
deal_player:
	push_ra
	push_reg $a0
	li $a0, 1
	jal draw_and_deal_card
	pop_reg $a0
	pop_ra
	jr $ra

####
# Resets the game. Removes all cards and resets game data
###
reset_game:
	push_ra
	push_reg $a0
	push_reg $s0
	
	lb $s0, player_card_count	# Use card count as reverse index
	li $a0, 1			# Argument for pop_card

_rg_pop_player:
	beqz $s0, _rg_finish_player	# Pop cards until card count is zero
	jal pop_card
	addi $s0, $s0, -1
	j _rg_pop_player

_rg_finish_player:			# Switch to dealer, and do the same as player
	lb $s0, dealer_card_count
	li $a0, 0

_rg_pop_dealer:
	beqz $s0, _rg_finish_dealer
	jal pop_card
	addi $s0, $s0, -1
	j _rg_pop_dealer

_rg_finish_dealer:
	li $t0, 0			# Reset all game data values to zero
	sb $t0, player_card_count
	sb $t0, player_card_value
	sb $t0, player_has_ace
	sb $t0, dealer_card_count
	sb $t0, dealer_card_value
	sb $t0, dealer_has_ace
	
	push_reg $v0			# Save these values since they'll be overwritten
	push_reg $a1
	
	li $a0, -1
	jal search_deck			# Count the cards left, and if there are enough cards, don't reshuffle
	bgt $v0, RESHUFFLE_COUNT, _rg_return
	
	la $a0, msg_reshuffle
	li $a1, 1
	li $v0, SYSCALL_DIALOG
	syscall
	
	li $t0, FULL_SUIT		# Loop through each element of the deck array and replace it with the starting value
	la $t1, deck
	li $t2, 0
	
_rg_deck_reset:
	sb $t0, ($t1)
	addi $t2, $t2, 1
	beq $t2, SUIT_COUNT, _rg_return

	addi $t1, $t1, 2
	j _rg_deck_reset
	
_rg_return:
	pop_reg $a1
	pop_reg $v0
	pop_reg $s0
	pop_reg $a0
	pop_ra
	jr $ra

####
# Decides who the winner is and sends an appropriate dialog
####
decide_winner:
	push_reg $v0
	push_reg $a0
	push_reg $a1
	lb $t0, dealer_card_value			# t0 will be dealer value
	lb $t1, player_card_value			# t1 will be player value
	
	lb $t7, dealer_has_ace				# Add 10 value to the dealer/player if they have an ace unless it exceeds 21
	bne $t7, HAS_ACE, _dw_dealer_skip_ace
	addi $t7, $t0, 10

	bgt $t7, BLACKJACK_MAX, _dw_dealer_skip_ace	# If the ace would exceed 21, skip adding 10
	move $t0, $t7					# Use the +10 value if valid
	
_dw_dealer_skip_ace:
	lb $t7, player_has_ace				# Do the same for the player as the dealer
	bne $t7, HAS_ACE, _dw_player_skip_ace
	addi $t7, $t1, 10
	
	bgt $t7, BLACKJACK_MAX, _dw_player_skip_ace
	move $t1, $t7
	
_dw_player_skip_ace:
	li $v0, SYSCALL_DIALOG_INT			# Prepare int dialog syscall
	bgt $t0, $t1, _dw_dealer_wins			# Dealer > Player
	bgt $t1, $t0, _dw_player_wins			# Dealer < Player

	la $a0, msg_tie					# Tie
	move $a1, $t0
	syscall
	j _dw_return
	
_dw_dealer_wins:					# Dealer won
	la $a0, msg_dealer_win
	sub $a1, $t0, $t1
	syscall						# v0 is still for int dialog
	j _dw_return
	
_dw_player_wins:					# Player won
	lb $t7, player_bet_enabled
	beq $t7, BET_ENABLED, _dw_player_wins_bet	# Show bet-enabled version if it's enabled
	la $a0, msg_player_win
	sub $a1, $t1, $t0
	syscall						# v0 is still for int dialog
	j _dw_return
	
_dw_player_wins_bet:
	li $v0, SYSCALL_DIALOG_FLOAT			# Show float dialog instead of int
	la $a0, msg_player_win_bet
	l.s $f12, player_bet
	l.s $f1, bet_mult
	mul.s $f12, $f12, $f1				# Calculate winning amount (bet * regular win multiplier)
	syscall
	
_dw_return:
	pop_reg $a1
	pop_reg $a0
	pop_reg $v0
	jr $ra

####
# Shows the how-to-play dialog that appears at the start of the game
####
show_info_dialog:
	push_reg $v0
	push_reg $a0
	push_reg $a1
	li $v0, SYSCALL_DIALOG_STRING
	la $a0, msg_info_title
	la $a1, msg_info_body
	syscall
	pop_reg $a1
	pop_reg $a0
	pop_reg $v0
	jr $ra

####
# Prompts the user to input a bet and saves result in memory
####
get_bet:
	push_reg $a0
	push_reg $a1
	push_reg $v0
	li $v0, SYSCALL_INPUT_FLOAT		# Prepare float input dialog
	la $a0, msg_bet_prompt			# Default prompt
	
_gb_prompt_user:
	syscall
	beq $a1, INPUT_OK, _gb_answer		# Branch to answer parsing
	beq $a1, INPUT_CANCEL, _gb_cancel	# Branch to zero bet
	beq $a1, INPUT_NONE, _gb_cancel
	
_gv_reprompt:
	la $a0, msg_bet_invalid			# Change prompt message and reprompt
	j _gb_prompt_user
	
_gb_answer:
	mtc1 $zero, $f1				# Check if the bet isn't negative
	c.lt.s $f0, $f1
	bc1t _gv_reprompt			# Reprompt if it is negative
	j _gb_valid
	
_gb_cancel:
	mtc1 $zero, $f0				# Set bet to 0 if cancelled
	
_gb_valid:
	s.s $f0, player_bet			# Store bet in memory
	push_reg $v0
	pop_reg $a1
	pop_reg $a0
	jr $ra

####
# Ask the user if they want to play with betting enabled and save the response in memory
####
bet_confirm_dialog:
	push_reg $a0
	push_reg $v0

	li $v0, SYSCALL_DIALOG_CONFIRM		# Open yes/no dialog
	la $a0, msg_bet_confirm
	syscall
	
	beq $a0, 0, _bcd_enabled		# If the response is 0, that's yes so branch
	li $t0, 0				# If no/cancel, set flag value to 0
	j _bcd_return
	
_bcd_enabled:
	li $t0, BET_ENABLED			# Set flag value to BET_ENABLED
	
_bcd_return:
	sb $t0, player_bet_enabled		# Store flag value in memory
	pop_reg $v0
	pop_reg $a0
	jr $ra
