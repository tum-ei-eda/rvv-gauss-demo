/*
 * Copyright [2020] [Technical University of Munich]
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# gauss(void* mat)
# a0: address of first element of mat


    .text
    .align 2
    .global gauss

gauss:
# clear vector register v0 (masking register) with vector register length of VLEN=1024
    li a6, 1
    vsetvli t0,a6,e1024,m1  # set SEW=1024, LMUL=1, VL=1
    vand.vi v0,v0,0     # set all bits to 0
    vxor.vi v0,v0,-1    # set all bits to 1
    li a2 , 870         # set vector length
    vsetvli t0,a2,e8,m8 # set SEW=8, LMUL=8, VL=870
    
    
# gaussElim.c:22: 			for (i = 0; i < (GFBITS * SYS_T + 7) / 8; i++) // 194 (193*8+3=1547)
	sw	zero,-20(s0)	#, i
# gaussElim.c:22: 			for (i = 0; i < (GFBITS * SYS_T + 7) / 8; i++) // 194 (193*8+3=1547)
	j	.L2		        #
.L18:
# gaussElim.c:23: 			for (j = 0; j < 8; j++)
	sw	zero,-24(s0)	#, j
# gaussElim.c:23: 			for (j = 0; j < 8; j++)
	j	.L3		        #
.L17:
# gaussElim.c:25: 			row = i*8 + j;			
	lw	a5,-20(s0)		# tmp95, i (a5=i)
	slliw	a5,a5,3	    #, tmp94, tmp95 (a5=a5<<3 32 bit)
	sext.w	a5,a5	    # _1, tmp94  (a5= signextend a5)
# gaussElim.c:25: 			row = i*8 + j;			
	lw	a4,-24(s0)		# tmp97, j  (a4=j)
	addw	a5,a4,a5	# _1, tmp96, tmp97 (a5=a4+a5)
	sw	a5,-36(s0)	    # tmp96, row (row=a5)
# gaussElim.c:27: 			if (row >= GFBITS * SYS_T)
	lw	a5,-36(s0)		# tmp98, row
	sext.w	a4,a5	    # tmp99, tmp98
	li	a5,1546		    # tmp100,
	bgt	a4,a5,.L19	    # , tmp99, tmp100,  branch (if a4>a5) to break
	
	
	
# Load matrix row into vector register group
	lw	a2,-36(s0)	    #  read row number 
	li	a5,870		    #
	mul	a5,a2,a5	    # 
	add	a5,a5,a0	    # set address to current row of matrix
    vle8.v v8, (a5)     # Load into vector register group
    
    
 
# gaussElim.c:31: 		for (k = row + 1; k < GFBITS * SYS_T; k++) Execute: k=row+1
	lw	a5,-36(s0)		# tmp102, row
	addiw	a5,a5,1	    #, tmp101, tmp102
	sw	a5,-28(s0)	    # tmp101, k
# gaussElim.c:31: 		for (k = row + 1; k < GFBITS * SYS_T; k++)
	j	.L6		#
.L9:	
# Set mask (makes sure that pivot element is not zero)
# gaussElim.c:33: 			mask = mat[ row ][ i ] ^ mat[ k ][ i ]; Execute: Load mat[ row ][ i ]
	lw	a4,-20(s0)		# tmp105, i
	lw	a2,-36(s0)		# tmp106, row
	li	a5,870		    # tmp108,
	mul	a5,a2,a5	    # tmp107, tmp106, tmp108
	add	a5,a5,a0	    # set address to current row of matrix
	add	a5,a5,a4	    # set address to i-th element in current row
	lbu	a4,(a5)	        # load i-th element of current row of mat
# gaussElim.c:33: 			mask = mat[ row ][ i ] ^ mat[ k ][ i ]; Execute: Load mat[ k ][ i ]
	lw	a3,-20(s0)		# tmp111, i
	lw	a1,-28(s0)		# tmp112, k
	li	a5,870		    # tmp114,
	mul	a5,a1,a5	    # tmp113, tmp112, tmp114
	add	a5,a5,a0	    # set address to k-th row of matrix
	add	a5,a5,a3	    # set address to i-th element of k-th row
	lbu	a5,(a5)	        # _3, mat
# gaussElim.c:33: 			mask = mat[ row ][ i ] ^ mat[ k ][ i ]; Execute: XOR
	#.loc 1 33 9
	xor	a5,a4,a5	    # _3, tmp115, _2
	sb	a5,-37(s0)	    # tmp115, mask
# gaussElim.c:34: 			mask >>= j; //mask=mask>>j right shift
	lbu	a5,-37(s0)	    # tmp116, mask
	sext.w	a4,a5	    # _4, tmp116
	lw	a5,-24(s0)		# tmp117, j
	sraw	a5,a4,a5	# tmp117, tmp118, _4
	sext.w	a5,a5	    # _5, tmp118
	sb	a5,-37(s0)	    # _5, mask
# gaussElim.c:35: 			mask &= 1;  //mask=mask& 1 and
	lbu	a5,-37(s0)	    # tmp119, mask
	andi	a5,a5,1	    #, tmp120, tmp119
	sb	a5,-37(s0)	    # tmp120, mask
# gaussElim.c:36: 			mask = -mask; //unary minus 
	lbu	a5,-37(s0)	    # tmp121, mask
	negw	a5,a5	    # tmp122, tmp121
	sb	a5,-37(s0)	    # tmp122, mask
	
# Vector extension replaces loop: for (c = i; c < SYS_N/8; c++) mat[ row ][ c ] ^= mat[ k ][ c ] & mask; 
# Load k-th row into vector register group
	lw	a2,-28(s0)		# read k number
	li	a5,870		    # 
	mul	a5,a2,a5	    # 
	add	a5,a5,a0	    # set address to k-th row of matrix
	vle8.v v16, (a5)    # Load k-th row into vector register group starting at v16 
# Vector arithmetic - change current row (row of pivot)  mat[row]= mat[row]^(mat[k]&mask)
    lbu a5, -37(s0)
    vand.vx v24,v16,a5,v0.t     # v24 = v16 & mask
    vxor.vv v8,v8,v24,v0.t      # v8=v8^v24
# Store current row (row of pivot) from vector register group to memory
	lw	a2,-36(s0)		#  row
	li	a5,870		    # 
	mul	a5,a2,a5	    # 
	add	a5,a5,a0	    # set address to k-th row of matrix
    vse8.v v8, (a5)     # Store vector register group
  
    
# gaussElim.c:31: 			for (k = row + 1; k < GFBITS * SYS_T; k++) Execute: k++
	lw	a5,-28(s0)		# tmp151, k
	addiw	a5,a5,1	    #, tmp150, tmp151
	sw	a5,-28(s0)	    # tmp150, k
.L6:
# gaussElim.c:31: 			for (k = row + 1; k < GFBITS * SYS_T; k++) Execute: k< GFBITS*SYS_T
#	.loc 1 31 3 discriminator 1
	lw	a5,-28(s0)		# tmp152, k
	sext.w	a4,a5	    # tmp153, tmp152
	li	a5,1546		    # tmp154,
	ble	a4,a5,.L9	    #, tmp153, tmp154,
# gaussElim.c:43: 			if ( ((mat[ row ][ i ] >> j) & 1) == 0 ) // return if not systematic Execute: Load mat[ row ][ i ]
	lw	a4,-20(s0)		# tmp157, i
	lw	a2,-36(s0)		# tmp158, row
	li	a5,870		    # tmp160,
	mul	a5,a2,a5	    # tmp159, tmp158, tmp160
	add	a5,a5,a0	    # tmp159, tmp159, tmp156
	add	a5,a5,a4	    # tmp157, tmp159, tmp159
	lbu	a5,(a5)	        # _10, mat
	sext.w	a4,a5	    # _11, _10
# gaussElim.c:43: 			if ( ((mat[ row ][ i ] >> j) & 1) == 0 ) // return if not systematic Execute: Load j, ShiftRight
	lw	a5,-24(s0)		# tmp161, j
	sraw	a5,a4,a5	# tmp161, tmp162, _11
	sext.w	a5,a5	    # _12, tmp162
# gaussElim.c:43: 			if ( ((mat[ row ][ i ] >> j) & 1) == 0 ) // return if not systematic Execute: AND 1
	andi	a5,a5,1	    #, tmp163, _12
	sext.w	a5,a5	    # _13, tmp163
# gaussElim.c:43: 			if ( ((mat[ row ][ i ] >> j) & 1) == 0 ) // return if not systematic Execute: Comparison ==0
	bne	a5,zero,.L10	#, _13,,
# gaussElim.c:45: 			return -1;
	li	a5,-1		    # _27,
	j	.L11		    #
.L10:
# gaussElim.c:49: 			for (k = 0; k < GFBITS * SYS_T; k++)
	sw	zero,-28(s0)	#, k
# gaussElim.c:49: 			for (k = 0; k < GFBITS * SYS_T; k++)
	j	.L12		    #
.L16:
# gaussElim.c:51: 			if (k != row)
	lw	a4,-28(s0)		# tmp164, k
	lw	a5,-36(s0)		# tmp165, row
	sext.w	a4,a4	    # tmp166, tmp164
	sext.w	a5,a5	    # tmp167, tmp165
	beq	a4,a5,.L13	    #, tmp166, tmp167,
# gaussElim.c:53: 				mask = mat[ k ][ i ] >> j; Execute: Load mat[ k ][ i ]
	lw	a4,-20(s0)		# tmp170, i
	lw	a2,-28(s0)		# tmp171, k
	li	a5,870		    # tmp173,
	mul	a5,a2,a5	    # tmp172, tmp171, tmp173
	add	a5,a5,a0	    # tmp172, tmp172, tmp169
	add	a5,a5,a4	    # tmp170, tmp172, tmp172
	lbu	a5,(a5)	        # _14, mat
	sext.w	a4,a5	    # _15, _14
# gaussElim.c:53: 				mask = mat[ k ][ i ] >> j; Execute: Load j, ShiftRight
	lw	a5,-24(s0)		# tmp174, j
	sraw	a5,a4,a5	# tmp174, tmp175, _15
	sext.w	a5,a5	    # _16, tmp175
# gaussElim.c:53: 				mask = mat[ k ][ i ] >> j; Execute: Store
	sb	a5,-37(s0)	    # _16, mask
# gaussElim.c:54: 				mask &= 1;
	lbu	a5,-37(s0)	    # tmp176, mask
	andi	a5,a5,1	    #, tmp177, tmp176
	sb	a5,-37(s0)	    # tmp177, mask
# gaussElim.c:55: 				mask = -mask;
	lbu	a5,-37(s0)	    # tmp178, mask
	negw	a5,a5	    # tmp179, tmp178
	sb	a5,-37(s0)	    # tmp179, mask
	
# Vector Extension replaces loop: for (c = 0; c < SYS_N/8; c++) mat[ k ][ c ] ^= mat[ row ][ c ] & mask;
# Load k-th row of matrix into vector register group
	lw	a2,-28(s0)		#  k
	li	a5,870		    # 
	mul	a5,a2,a5	    # 
	add	a5,a5,a0	    # 
    vle8.v v16, (a5)    # Load into vector register group v16
# Vector arithmetic - change k-th row   mat[k]= mat[k]^(mat[row]&mask)
    lbu a6, -37(s0)     # Read mask
    vand.vx v24,v8,a6   # v24 = v8 & mask
    vxor.vv v16,v16,v24 # v16=v16^v24
# Store k-th row from vector register group v16 to memory
    vse8.v v16, (a5)    # 

.L13:
# gaussElim.c:49: 			for (k = 0; k < GFBITS * SYS_T; k++) Execute: k++
	#.loc 1 49 36 discriminator 2
	lw	a5,-28(s0)		# tmp207, k
	addiw	a5,a5,1	    #, tmp206, tmp207
	sw	a5,-28(s0)	    # tmp206, k
.L12:
# gaussElim.c:49: 			for (k = 0; k < GFBITS * SYS_T; k++) Execute: Comparison k < GFBITS*SYS_T
	#.loc 1 49 3 discriminator 1
	lw	a5,-28(s0)		# tmp208, k
	sext.w	a4,a5	    # tmp209, tmp208
	li	a5,1546		    # tmp210,
	ble	a4,a5,.L16	    #, tmp209, tmp210,
# gaussElim.c:23: 			for (j = 0; j < 8; j++) Execute: j++
	#.loc 1 23 22 discriminator 2
	lw	a5,-24(s0)		# tmp212, j
	addiw	a5,a5,1	    #, tmp211, tmp212
	sw	a5,-24(s0)	    # tmp211, j

.L3:
# gaussElim.c:23: 			for (j = 0; j < 8; j++) Execute: Comparison j<8
	#.loc 1 23 2 discriminator 1
	lw	a5,-24(s0)		# tmp213, j
	sext.w	a4,a5	    # tmp214, tmp213
	li	a5,7		    # tmp215,
	ble	a4,a5,.L17	    #, tmp214, tmp215,
	j	.L5		        #
.L19:
# gaussElim.c:28: 			break;
	nop	
.L5:
# gaussElim.c:22: 			for (i = 0; i < (GFBITS * SYS_T + 7) / 8; i++) // 194 (193*+3=1547) Executes: i++
	#.loc 1 22 45 discriminator 2
	lw	a5,-20(s0)		# tmp217, i
	addiw	a5,a5,1	    #, tmp216, tmp217
	sw	a5,-20(s0)	    # tmp216, i
	
	# Set Mask Register to replace loop: for (c = i; c < SYS_N/8; c++)
	li a6, 1
    vsetvli t0,a6,e1024,m1    # Switch to SEW=1024, LMUL=1, VL=1
    vsll.vi v0,v0,1     # Shift left for 1 bit position
    li a6, 870          # 
    vsetvli t0,a6,e8,m8 # Switch back to SEW=8, LMUL=8, VL=870
    
.L2:
# gaussElim.c:22: 			for (i = 0; i < (GFBITS * SYS_T + 7) / 8; i++) // 194 (193*+3=1547) Executes: Comparison i < (GFBITS * SYS_T + 7) / 8
	#.loc 1 22 2 discriminator 1
	lw	a5,-20(s0)		# tmp218, i #a5=i (32bit)
	sext.w	a4,a5	    # tmp219, tmp218 # a4=signextend a5 (32 bit)
	li	a5,193		    # tmp220,  #a5=193 
	ble	a4,a5,.L18	    #, tmp219, tmp220, (branch to .L18 if a4<=a5)
	li	a5,0		    # _27,
.L11:
    ret
