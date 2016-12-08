# Change the value N and filenames to test different given matrix problems
.data
N: .word 64
Afname: .asciiz "A64.bin"
Bfname: .asciiz "B64.bin"
Cfname: .asciiz "C64.bin"
Dfname: .asciiz "D64.bin"       # Use D to check your code: D = AB - C 

#################################################################
# Main function for testing assignment objectives.
# Modify this function as needed to complete your assignment.
# Note that the TA will ultimately use a different testing program.
# Finally note we will use save registers in the main function without
# saving them, but you must respect register conventions for all
# of the functions you implement!  Recall that $f20-$f31 are save 
# registers on the floating point coprocessor
.text
main:	la   $t0, N
	lw   $s7, ($t0)		# Let $s7 be the matrix size n

	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix A
	move $s0 $v0		# $s0 is a pointer to matrix A
	la $a0 Afname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s0
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix B
	move $s1 $v0		# $s1 is a pointer to matrix B
	la $a0 Bfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s1
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix C
	move $s2 $v0		# $s2 is a pointer to matrix C
	la $a0 Cfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s2
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix A
	move $s3 $v0		# $s3 is a pointer to matrix D
	la $a0 Dfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s3
	jal loadMatrix		# D is the answer, i.e., D = AB+C 
	
	
	
	
			
	# TODO: add your testing code here
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix A
	move $s4 $v0		# $s4 is a pointer to matrix temp

	move $a0,$s4
	move $a1,$s7
	jal reset
	
	
	# calculate D-C
	move $a0,$s3
	move $a1,$s2
	move $a2,$s2
	move $a3,$s7
	
	jal subtract
	
	#print D-C
	move $a0,$s2
	move $a1,$s7
	
	jal printMat
	
	# calc A*B
	move $a0,$s0
	move $a1,$s1
	move $a2,$s4
	move $a3,$s7
	
	jal multiplyAndAddV2
	
	#print A*B
	move $a0,$s4
	move $a1,$s7
	
	jal printMat
	
	
	#print check A*B == D-C
	move $a0,$s4
	move $a1,$s2
	move $a2,$s7
	
	jal check
	
	
	li $v0, 10      # load exit call code 10 into $v0
        syscall         # call operating system to exit	

		
###############################################################
# mallocMatrix( int N )
# Allocates memory for an N by N matrix of floats
# The pointer to the memory is returned in $v0	
mallocMatrix: 	mul  $a0, $a0, $a0	# Let $s5 be n squared
		sll  $a0, $a0, 2	# Let $s4 be 4 n^2 bytes
		li   $v0, 9		
		syscall			# malloc A
		jr $ra
	
###############################################################
# loadMatrix( char* filename, int width, int height, float* buffer )
.data
errorMessage: .asciiz "FILE NOT FOUND" 
.text
loadMatrix:	mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		slti $t1 $v0 0
		beq $t1 $0 fileFound
		la $a0 errorMessage
		li $v0 4
		syscall		  # print error message
		li $v0 10         # and then exit
		syscall		
fileFound:	move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer in which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
		# $v0 contains number of characters read (0 if end-of-file, negative if error).
                # We'll assume that we do not need to be checking for errors!
		
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra	
###############################################################
# FOR DEBUGGING ONLY (this is not required for the assignment).
# printMat( float* A=$a0, int n=$a1 )
# this function prints a matrix of size n referenced by A
# we need two loops, because we need to know when to print a newline
.data
newline: .asciiz "\n"
space: .asciiz " "
.text
printMat:
	
	#set limit in $t5
	li $t0,4
	mul $t5,$a1,$t0
	
	#set the first counter to 0
	add $t0,$0,$0
	
	#save the array address in $t4
	add $t4,$0,$a0
	
	printLoopOuter:
		# we have scanned all rows
		beq $t0,$t5,printExitOuter
		
		#set the second counter to 0
		sub $t1,$t1,$t1
		
		printLoopInner:
			# we have scanned all columns
			beq $t1,$t5,printExitInner
		
			#calculate the offset in $t2
			sub $t2,$t2,$t2
			
			#offset is (i*n+j)+A
			mul $t2,$t0,$a1
			add $t2,$t2,$t1
			add $t2,$t2,$t4
			
			#get A_ij then print it
			lwc1 $f12,0($t2)
			li $v0,2
			syscall
	
			#print space
			li $v0,4
			la $a0,space
			syscall
		
			#increment the inner counter
			addi $t1,$t1,4
			
			#loop inner
			j printLoopInner
			
		printExitInner:
		
		#print newline
		li $v0,4
		la $a0,newline
		syscall
		
		#increment the outer counter
		addi $t0,$t0,4
		
		#loop outer
		j printLoopOuter
		
	printExitOuter:
	
	#print newline
	li $v0,4
	la $a0,newline
	syscall
	
	#return
	jr $ra
	
###############################################################
# FOR DEBUGGING ONLY (this is not required for the assignment).
# reset( float* A=$a0, int n=$a1 )
# this function will reset all values for a matrix to zero
.data
zero: .float 0.0 
.text
reset:
	#calculate the limit in $a3
	mul $a1,$a1,$a1
	
	resetLoop:
		
		#set A_ij=0
		la $t0,zero
		lwc1 $f4,0($t0)
		swc1 $f4,0($a0)
		
		addi $a0,$a0,4
		sub $a1,$a1,1
		
		#while we didn't pass over all entries
		bne $a1,$0,resetLoop
	
	#return 
	jr $ra
	
###############################################################
# subtract( float* A=$a0, float* B=$a1, float* C=$a2, int n=$a3 )
# this function compute the matrix subtraction C = A - B,with all A,B,C of size n
subtract:
	#calculate the limit in $a3
	mul $a3,$a3,$a3
	
	subtractLoop:
		
		#get A_ij
		lwc1 $f4,0($a0)
		
		#get B_ij
		lwc1 $f5,0($a1)
		
		
		#calculate the result of A_ij-B_ij in $t4
		sub.s $f4,$f4,$f5
		
		#store the result in C_ij
		swc1 $f4,0($a2)
	
		#increment the addresses of A,B,C and decrement $a3
		addi $a0,$a0,4
		addi $a1,$a1,4
		addi $a2,$a2,4
		sub $a3,$a3,1
		
		#while we didn't do the subtraction for all entries
		bne $a3,$0,subtractLoop
	
	#return 
	jr $ra
	
###############################################################
# frobeneousNorm( float* A=$a0, int n=$a1 )
# this function compute the Frobeneous norm of the matrix A of size n
frobeneousNorm:
	#calculate the limit in $a1
	mul $a1,$a1,$a1
	
	# $f5 will hold the sum of all entries, reset it 
	sub.s $f6,$f6,$f6
	
	frobeneousLoop:
		
		#get A_ij
		lwc1 $f4,0($a0)
		
		#calculate the result of A_ij ^ 2
		mul.s $f4,$f4,$f4
	
		#sum the current entry
		add.s $f6,$f6,$f4
		
		#increment the addresses of A and decrement $a1
		add $a0,$a0,4
		sub $a1,$a1,1
		
		#while we didn't pass over all entries
		bne $a1,$0,frobeneousLoop
	
	#return the root of the sum
	sqrt.s $f0,$f6
	
	#return 
	jr $ra
	
###############################################################
# check( float* A=$a0, float* B=$a1, int n=$a2 )
# this function prints the frobeneousNorm of A-B
check:
	#push return address and two saved registers 
	addi $sp,$sp,-12
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	
	
	#save n in $s0
	add $s0,$0,$a2
	
	#save address to A in $s1
	add $s1,$0,$a0
	
	#prepare parameters for subtract(A,B,A,n)
	#put A as the third parameter
	add $a2,$0,$s1
	
	#put n as the fourth parameter
	add $a3,$0,$s0
	
	#call subtract 
	jal subtract
	
	#prepare the parameters for frobeneousNorm(subtract(A,B,A),n)
	#put A as the first parameter 
	add $a0,$0,$s1
	
	#put n as the second parameter
	add $a1,$0,$s0
	
	#call frobeneousNorm 
	jal frobeneousNorm
	
	
	#print the result
	mov.s $f12,$f0
	li $v0,2
	syscall
	
	#restore the return address and the saved registers from the stack
	lw $s1,8($sp)
	lw $s0,4($sp)
	lw $ra,0($sp)
	addi $sp,$sp,12
	
	#return 
	jr $ra
	

###############################################################
# multiplyAndAddV1( float* A=$a0, float* B=$a1, float* C=$a2, int n=$a3 )
# this function computes C=A*B in the naive way
multiplyAndAddV1:

	#calculate the limit for the for loops in $t7
	li $t0,4
	mul $t7,$a3,$t0
	
	# naive loop for i=$t0
	sub $t0,$t0,$t0
	multiplyAndAddV1LoopI:
	
		
		# naive loop for j=$t1
		sub $t1,$t1,$t1
		
		multiplyAndAddV1LoopJ:
		
			# $f6 will hold the sum
			sub.s $f6,$f6,$f6
			
			# naive loop for k=$t2
			sub $t2,$t2,$t2
			multiplyAndAddV1LoopK:
			
			#calculate address of A[i][k]=$t3
			#$t3=i*n
			mul $t3,$t0,$a3
			#$t3=i*n+k
			add $t3,$t3,$t2
			#$t3=A+(i*n+k)
			add $t3,$t3,$a0
			#get A[i][k]=$f4
			lwc1 $f4,0($t3)
			
			#calculate address of B[k][j]=$t4
			#$t4=k*n
			mul $t4,$t2,$a3
			#$t4=k*n+j
			add $t4,$t4,$t1
			#$t4=B+(k*n+j)
			add $t4,$t4,$a1
			#get B[k][j]=$f5
			lwc1 $f5,0($t4)
			
			#calculate A[i][k] * B[k][j] 
			mul.s $f4,$f4,$f5
			#sum the values in $f6
			add.s $f6,$f6,$f4
			
			#increment k
			addi $t2,$t2,4
			#loop k
			bne $t2,$t7,multiplyAndAddV1LoopK
			
			multiplyAndAddV1EndK:
			
			#calculate the "address" of C[i][j] in $t5
			#$t5=i*n
			mul $t5,$t0,$a3
			#$t5=i*n+j
			add $t5,$t5,$t1
			#$t5=C+(i*n+j)
			add $t5,$t5,$a2
			
			#store the sum in C[i][j]=$f6
			swc1 $f6,0($t5)
			
		#increment j
		addi $t1,$t1,4
		#loop j
		bne $t1,$t7,multiplyAndAddV1LoopJ
		multiplyAndAddV1EndJ:
	
	#increment i
	addi $t0,$t0,4
	#loop i
	bne $t0,$t7,multiplyAndAddV1LoopI
	multiplyAndAddV1EndI:
	
	#return 
	jr $ra
	
###############################################################
# multiplyAndAddV2( float* A=$a0, float* B=$a1, float* C=$a2, int n=$a3 )
# this function computes C=A*B in the cache friendly way
multiplyAndAddV2:

	#calculate the limit for the for loops in $t9
	li $t0,4
	mul $t9,$t0,$a3
	
	# loop for jj=$t0
	sub $t0,$t0,$t0
	multiplyAndAddV2_LoopJJ:
	
		# loop for kk=$t1
		sub $t1,$t1,$t1
		multiplyAndAddV2_LoopKK:
		
			# loop for i=$t2
			sub $t2,$t2,$t2
			multiplyAndAddV2_LoopI:

				# loop for j=$t3 (j=jj in the start of the loop)
				add $t3,$0,$t0
				
				#calculate min(jj+bsize,n)=$t5
				#$t5=jj+bsize
				addi $t5,$t0,16
				#check if (jj+bsize<n)
				slt $t5,$t5,$t9
				#else statment (limit=n)
				bne $t5,$0, trueMin1
				add $t5,$0,$t9
				j exitMin1
				#if statment (limit=jj+bsize)
				trueMin1:
				addi $t5,$t0,16
				exitMin1:
				
				multiplyAndAddV2_LoopJ:
					
					
					# $f6=0 will hold the local sum
					sub.s $f6,$f6,$f6
					
					#calculate min(kk+bsize,n)=$t6
					#$t7=kk+bsize
					addi $t6,$t1,16
					#check if (kk+bsize<n)
					slt $t6,$t6,$t9
					#else statment (limit=n)
					bne $t6,$0, trueMin2
					add $t6,$0,$t9
					j exitMin2
					#if statment (limit=kk+bsize)
					trueMin2:
					addi $t6,$t1,16
					exitMin2:
					#multiply limit by 4
					#addi $t7,$0,4
					#mul $t6,$t6,$t7
					
					# loop for k=$t4 (k=kk in the start of the loop)
					add $t4,$0,$t1
					multiplyAndAddV2_LoopK:
					
						#calculate address of A[i][k]=$t7
						#$t7=i*n
						mul $t7,$t2,$a3
						#$t7=i*n+k
						add $t7,$t7,$t4
						#$t7=A+(i*n+k)
						add $t7,$t7,$a0
						#get A[i][k]=$f4
						lwc1 $f4,0($t7)
			
						#calculate address of B[k][j]=$t7
						#$t7=k*n
						mul $t7,$t4,$a3
						#$t7=k*n+j
						add $t7,$t7,$t3
						#$t7=B+(k*n+j)
						add $t7,$t7,$a1
						#get B[k][j]=$f5
						lwc1 $f5,0($t7)
			
						#calculate A[i][k] * B[k][j] 
						mul.s $f4,$f4,$f5
						#sum the values in $f6
						add.s $f6,$f6,$f4
					

					#increment k
					addi $t4,$t4,4
					
					#check if k<min(kk+bsize,n)
					slt $t7,$t4,$t6
					bne $t7,$0,multiplyAndAddV2_LoopK
					
					#calculate the "address" of C[i][j] in $t7
					#$t7=i*n
					mul $t7,$t2,$a3
					#$t7=i*n+j
					add $t7,$t7,$t3
					#$t7=C+(i*n+j)
					add $t7,$t7,$a2
			
					#add to the stored the sum in C[i][j]+=$f6
					lwc1 $f7,0($t7)
					add.s $f6,$f6,$f7
					swc1 $f6,0($t7)
				
				#increment j
				addi $t3,$t3,4
				
				#check if j<min(jj+bsize,n)
				slt $t7,$t3,$t5
				bne $t7,$0,multiplyAndAddV2_LoopJ

			#increment i
			addi $t2,$t2,4
			
			#check if (i<n)
			bne $t2,$t9,multiplyAndAddV2_LoopI
			multiplyAndAddV2_EndI:
		
		
		#increment kk by psize=4
		addi $t1,$t1,16
		
		#we need to check if kk<n
		slt $t7,$t1,$t9
		bne $t7,$0,multiplyAndAddV2_LoopKK
			
	#increment jj by psize=4
	addi $t0,$t0,16
	
	#we need to check if jj<n
	slt $t7,$t0,$t9
	bne $t7,$0,multiplyAndAddV2_LoopJJ

	#return 
	jr $ra
	
