.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
#.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
#.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 100	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16		# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

# define various constants you need in your .data segment here
oneF: .float 1.0
newline: .asciiz "\n"
plus: .asciiz " + "
i:.asciiz " i"
xstring: .asciiz "x"
ystring: .asciiz "y"
eqstring: .asciiz " = "

########################################################################################
.text
	
	# TODO: Write your function testing code here
	
	#uncomment to draw julia
	#la $t0, JuliaC1
	#lwc1 $f12,0($t0)
	#lwc1 $f13,4($t0)
	#jal drawJulia
	
	#uncomment to draw mandelbrot
	jal drawMandelbrot
	
	#uncomment to test pixel2ComplexInWindow
	#li $a0,256
	#li $a1,128
	#jal pixel2ComplexInWindow
	
	mov.s $f12,$f0 # move $f13 to $f12 in order to print it
	li $v0,2 # print the imaginary part
	syscall
	
	mov.s $f12,$f1 # move $f13 to $f12 in order to print it
	li $v0,2 # print the imaginary part
	syscall
	
	li $v0 10 # exit
	syscall


# TODO: Write your functions to implement various assignment objectives here

########################################################################################
#prints two float arguments in $f12 $f13
printComplex:
	addi $sp,$sp,-4 # we need to save the return address
	sw $ra,0($sp) # push the return address to the stack
	
	li $v0,2 # print the real part
	syscall

	la $a0, plus # print the plus sign
	li $v0, 4
	syscall
	
	mov.s $f4,$f12 # temporarily hold the value of $f12
	
	mov.s $f12,$f13 # move $f13 to $f12 in order to print it
	li $v0,2 # print the imaginary part
	syscall
	
	mov.s $f12,$f4 # restore $f12
	
	la $a0,i # print the i in the end 
	li $v0, 4
	syscall
	
	jal printNewline
	
	lw $ra,0($sp)# restore return address
	addi $sp,$sp,4
	 
	jr $ra #return 
	
########################################################################################	
#prints a single newline character
printNewline:
	la $a0,newline # print new line character 
	li $v0, 4 # 4 in $v0 to print a string
	syscall
	
	jr $ra #return 
	
########################################################################################	
# compute the expression ( $f12 + $f13 i ) +( $f14 + $f15 i )
# return the result in ( $f0 + $f1 i )
addComplex:
	add.s $f0,$f12,$f14 # compute the real part
	add.s $f1,$f13,$f15 # compute the imginary part

	jr $ra
	
########################################################################################	
# mult the product ( a=$f12 + b=$f13 i ) * ( c=$f14 + d=$f15 i )
# return the result in ( $f0 + $f1 i )
multComplex:
	mul.s $f0,$f12,$f14 # compute the real part 
	mul.s $f4,$f13,$f15
	sub.s $f0,$f0,$f4
	
	mul.s $f1,$f12,$f15 #compute the imaginary part
	mul.s $f4,$f13,$f14
	add.s $f1,$f1,$f4
	
	jr $ra
	
########################################################################################
# take the following parameters ( n=$a0 , a=$f12, b=$f13, x=$f14, y=$f15)	
# print the result of f(x,y)=(x^2-y^2+a,2xy+b) n times or until (x^2+y^2)>bound
# if (z=x+yi) and (c=a+bi) then f(z)=z^2+c
iterateVerbose:
	addi $sp,$sp,-20 # we need space to store the return address and to store 4 save registers
	sw $ra,0($sp) # push the return address on the stack
	swc1 $f20,4($sp) # push $f20 on the stack
	swc1 $f21,8($sp) # push $f21 on the stack
	swc1 $f22,12($sp) # push $f22 on the stack
	sw $s0,16($sp) # push $s0 on the stack
	
	la $t0,bound # get the address for bound variable
	l.s $f20,0($t0) # fetch bound from memory into $f20
	sub $t0,$t0,$t0 # reset the counter
	
	move $s0,$a0 # save the argument, because we will use $a0 later
	
	verboseLoop:
		mul.s $f4, $f14,$f14 # compute x^2
		mul.s $f5, $f15,$f15 # compute y^2
		add.s $f4,$f4,$f5 # compute x^2+y^2
	
		c.lt.s $f20,$f4 # check bound<x^2+y^2
		
		bc1t verboseExitCondition1 # finish execution if the condition is broken
		
		beq $s0,$t0,verboseExitCondition2 # check if we reached the limit of our iterations
	
		# print the formated string "x%d + y%d i = %d + %d i"
		
		la $a0,xstring # print "x"
		li $v0, 4
		syscall
		
		move $a0,$t0 # print iteration counter
		li $v0, 1
		syscall
		
		la $a0,plus # print " + "
		li $v0, 4
		syscall
		
		la $a0,ystring # print "y"
		li $v0, 4
		syscall
		
		move $a0,$t0 # print iteration counter
		li $v0, 1
		syscall
		
		la $a0,i # print " i"
		li $v0, 4
		syscall
		
		la $a0,eqstring # print " = "
		li $v0, 4
		syscall
		
		# save $f12,$f13 because we need to overwrite them
		mov.s $f21,$f12 # a
		mov.s $f22,$f13 # b
		
		mov.s $f12,$f14 # prepare $f14 to be printed
		mov.s $f13,$f15 # prepare $f15 to be printed
		
		jal printComplex # print the complex number in this iteration
		
		# compute Z^2 and put the results in ( $f0 + $f1 i)
		jal multComplex # we already have $f12 $f13 containing Z so this will compute Z^2
		
		
		#prepare to add Z^2+c
		mov.s $f12,$f0 # put Re(z) in $f12
		mov.s $f13,$f1 # put Im(z) in $f13
		mov.s $f14,$f21 # put a in $f14
		mov.s $f15,$f22 # put b in $f15
		
		# compute Z^2 + C
		jal addComplex 
		
		# prepare the next input z=(x+yi)
		mov.s $f14,$f0	# put x in place
		mov.s $f15,$f1 # put y in place
		
		# restore the constants
		mov.s $f12,$f21	# restore a
		mov.s $f13,$f22 # restore b
		
		addi $t0,$t0,1 # increase the iteration counter by 1
		j verboseLoop # loop again
		
	verboseExitCondition1:  #terminate the function and fix the result
		# we subtract 1 becasue in this case the last iteration 
		# IS greater than bound and we don't want to count it
		addi $t0,$t0,-1 
		 
	verboseExitCondition2: # terminate the function
	
	lw $s0,16($sp) # restore $s0
	lwc1 $f22,12($sp) # restore $f22 
	lwc1 $f21,8($sp) # restore $f21 
	lwc1 $f20,4($sp) # restore $f20 
	lw $ra,0($sp) # restore return address
	addi $sp,$sp,20 # restore stack pointer
	
	move $v0,$t0 # return  the counter
	
	move $a0,$v0 # print the return value
	li $v0, 1
	syscall
	
	jr $ra # return
	
########################################################################################
# take the following parameters ( n=$a0 , a=$f12, b=$f13, x=$f14, y=$f15)	
# compute the result of f(x,y)=(x^2-y^2+a,2xy+b) n times or until (x^2+y^2)>bound
# if (z=x+yi) and (c=a+bi) then f(z)=z^2+c
# return the number of iterations with x^2+y^2 <= bound in $v0 
iterate:
	addi $sp,$sp,-20 # we need space to store the return address and to store 4 save registers
	sw $ra,0($sp) # push the return address on the stack
	swc1 $f20,4($sp) # push $f20 on the stack
	swc1 $f21,8($sp) # push $f21 on the stack
	swc1 $f22,12($sp) # push $f22 on the stack
	sw $s0,16($sp) # push $s0 on the stack
	
	la $t0,bound # get the address for bound variable
	l.s $f20,0($t0) # fetch bound from memory into $f20
	sub $t0,$t0,$t0 # reset the counter
	
	move $s0,$a0 # save the argument, because we will use $a0 later
	
	iterateLoop:
		mul.s $f4, $f14,$f14 # compute x^2
		mul.s $f5, $f15,$f15 # compute y^2
		add.s $f4,$f4,$f5 # compute x^2+y^2
	
		c.lt.s $f20,$f4 # check bound<x^2+y^2
		
		bc1t iterateExitCondition1 # finish execution if the condition is broken
		
		beq $s0,$t0,iterateExitCondition2 # check if we reached the limit of our iterations
	
		
		# save $f12,$f13 because we need to overwrite them
		mov.s $f21,$f12 # a
		mov.s $f22,$f13 # b
		
		mov.s $f12,$f14 # prepare $f14 to be used in multComplex
		mov.s $f13,$f15 # prepare $f15 to be used in multComplex
		
		# compute Z^2 and put the results in ( $f0 + $f1 i)
		jal multComplex # we already have $f12 $f13 containing Z so this will compute Z^2
		
		
		#prepare to add Z^2+c
		mov.s $f12,$f0 # put Re(z) in $f12
		mov.s $f13,$f1 # put Im(z) in $f13
		mov.s $f14,$f21 # put a in $f14
		mov.s $f15,$f22 # put b in $f15
		
		# compute Z^2 + C
		jal addComplex 
		
		# prepare the next input z=(x+yi)
		mov.s $f14,$f0	# put x in place
		mov.s $f15,$f1 # put y in place
		
		# restore the constants
		mov.s $f12,$f21	# restore a
		mov.s $f13,$f22 # restore b
		
		addi $t0,$t0,1 # increase the iteration counter by 1
		j iterateLoop # loop again
		
	iterateExitCondition1:  #terminate the function and fix the result
		# we subtract 1 becasue in this case the last iteration 
		# IS greater than bound and we don't want to count it
		addi $t0,$t0,-1 
		 
	iterateExitCondition2: # terminate the function
	
	lw $s0,16($sp) # restore $s0
	lwc1 $f22,12($sp) # restore $f22 
	lwc1 $f21,8($sp) # restore $f21 
	lwc1 $f20,4($sp) # restore $f20 
	lw $ra,0($sp) # restore return address
	addi $sp,$sp,20 # restore stack pointer
	
	move $v0,$t0 # return  the counter

	jr $ra # return

########################################################################################
# takes (col=$a0 , row=$a1)  and computes 
# $f0=x=((col/w)(r-l))+l
# $f1=y=((row/h)(t-b))+b 
pixel2ComplexInWindow:
	la $t0,windowlrbt # store the address of windowlrbt
	la $t1,resolution # store the address of resolution
	
	# we start by calculating x
	mtc1 $a0,$f0 # store col into $f0
	lwc1 $f4,0($t1) # load the width
	div.s $f0,$f0,$f4 # calculate col/w
	
	lwc1 $f4,0($t0) # load l into $f4
	lwc1 $f5,4($t0) # load r into $f5
	sub.s $f5,$f5,$f4 # calculate $f5=(r-l)
	
	mul.s $f0,$f0,$f5 # calculate $f0=(col/w)(r-l)
	add.s $f0,$f0,$f4 # calculate $f0=(col/w)(r-l)+l
	
	# now we calculate y
	mtc1 $a1,$f1 # store row into $f1
	lwc1 $f4,4($t1) # load the height
	div.s $f1,$f1,$f4 # calculate row/h
	
	lwc1 $f4,8($t0) # load b into $f4
	lwc1 $f5,12($t0) # load t into $f5
	sub.s $f5,$f5,$f4 # calculate $f5=(t-b)
	
	mul.s $f1,$f1,$f5 # calculate $f1=(row/h)(t-b)
	add.s $f1,$f1,$f4 # calculate $f1=(row/h)(t-b)+b
	
	jr $ra #return
	
########################################################################################
# takes (a=$f12 , b=$f12)  and draws a julia fractal 
drawJulia:
	addi $sp,$sp,-24 # we need to save return address and 5 saved registers
	sw $ra,0($sp) # save return address
	sw $s0,4($sp) # push s0
	sw $s1,8($sp) # push s1
	sw $s2,12($sp) # push s2
	sw $s3,16($sp) # push s3
	sw $s4,20($sp) # push s4
	
	la $t0,resolution # load image resolution address
	lw $s0,0($t0) # load w into $s0
	lw $s1,4($t0) # load h into $s1
	
	mult $s0,$s1 # set $s2 to the number of pixels in the image
	mflo $s2
	# we need to multiply the size by 4
	li $t0,4
	mult $s2,$t0
	mflo $s2
	
	sub $s3,$s3,$s3 # reset current pixel $s3=0
	
	#get the maximum number of iterations
	la $t0,maxIter
	lw $s4,0($t0) # $s4 =maxIter
	
	drawJuliaLoop:
		bge $s3,$s2,exitdrawJuliaLoop # check if we have finished drawing
		
		# we need to calculate (col,row)
		move $t0,$s3 # $t0=currentPixel
		li $t1,4 # just a temporary for division
		div $t0,$t1 # currentPixel/=4
		mflo $t0
		div $t0,$s0 # currentPixel/=w
		
		# get parameters for pixel2ComplexInWindow
		mfhi $a0 # col=$a0
		mflo $a1 # row=$a1
		
		# calculate the starting point
		jal pixel2ComplexInWindow
		
		# prepare parameters for iterate
		mov.s $f14,$f0 # pass the resulting starting x to iterate
		mov.s $f15,$f1 # pass the resulting starting y to iterate
		
		# put n=maxIter
		move $a0,$s4
		
		# check if the current point is in julia set
		jal iterate
		
		# if the point is not bounded set we don't color it
		blt $v0,$s4,ColorJulia
			sub $v0,$v0,$v0
			j endColoringJulia
		ColorJulia:
			move $a0,$v0
			jal computeColour
		endColoringJulia:
		
		# store the color for the current pixel
		la $t0,bitmapDisplay
		add $t0,$t0,$s3
		sw $v0,0($t0)
		
		addi $s3,$s3,4 #move to the next pixel
		j drawJuliaLoop
	exitdrawJuliaLoop:
	
	lw $s4,20($sp) # push s4
	lw $s3,16($sp) # push s3
	lw $s2,12($sp) # push s2
	lw $s1,8($sp) # push s1
	lw $s0,4($sp) # push s0
	lw $ra,0($sp) # restore return address
	addi $sp,$sp,24 # restore stack pointer
	
	jr $ra #return
	
########################################################################################
# draws a Mandelbrot fractal 
drawMandelbrot:
	addi $sp,$sp,-24 # we need to save return address and 5 saved registers
	sw $ra,0($sp) # save return address
	sw $s0,4($sp) # push s0
	sw $s1,8($sp) # push s1
	sw $s2,12($sp) # push s2
	sw $s3,16($sp) # push s3
	sw $s4,20($sp) # push s4
	
	la $t0,resolution # load image resolution address
	lw $s0,0($t0) # load w into $s0
	lw $s1,4($t0) # load h into $s1
	
	mult $s0,$s1 # set $s2 to the number of pixels in the image
	mflo $s2
	# we need to multiply the size by 4
	li $t0,4
	mult $s2,$t0
	mflo $s2
	
	sub $s3,$s3,$s3 # reset current pixel $s3=0
	
	#get the maximum number of iterations
	la $t0,maxIter
	lw $s4,0($t0) # $s4 =maxIter
	
	drawMandelbrotLoop:
		bge $s3,$s2,exitdrawMandelbrotLoop # check if we have finished drawing
		
		# we need to calculate (col,row)
		move $t0,$s3 # $t0=currentPixel
		li $t1,4 # just a temporary for division
		div $t0,$t1 # currentPixel/=4
		mflo $t0
		div $t0,$s0 # currentPixel/=w
		
		# get parameters for pixel2ComplexInWindow
		mfhi $a0 # col=$a0
		mflo $a1 # row=$a1
		
		# calculate the starting point
		jal pixel2ComplexInWindow
		
		# prepare parameters for iterate
		mov.s $f12,$f0 # pass the resulting starting x to iterate
		mov.s $f13,$f1 # pass the resulting starting y to iterate
		
		sub.s $f14,$f14,$f14 # set x=0
		sub.s $f15,$f15,$f15 # set y=0
		
		# put n=maxIter
		move $a0,$s4
		
		# check if the current point is in julia set
		jal iterate
		
		# if the point is not bounded set we don't color it
		blt $v0,$s4,ColorMandelbrot
			sub $v0,$v0,$v0
			j endColoringMandelbrot
		ColorMandelbrot:
			move $a0,$v0
			jal computeColour
		endColoringMandelbrot:
		
		#DEBUG 
		#move $a0,$v0
		#li $v0,1
		#syscall
		
		#jal printNewline
		
		# store the color for the current pixel
		la $t0,bitmapDisplay
		add $t0,$t0,$s3
		sw $v0,0($t0)
		
		addi $s3,$s3,4 #move to the next pixel
		j drawMandelbrotLoop
	exitdrawMandelbrotLoop:
	
	lw $s4,20($sp) # restore s4
	lw $s3,16($sp) # restore s3
	lw $s2,12($sp) # restore s2
	lw $s1,8($sp) # restore s1
	lw $s0,4($sp) # restore s0
	lw $ra,0($sp) # restore return address
	addi $sp,$sp,24 # restore stack pointer
	
	jr $ra #return
	
########################################################################################
# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parametre defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop
