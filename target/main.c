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

/*
 * 
 * Gaussian Elimination Algorithm with Inline Assembly RVV0.9 
 * for Classical McEliece with parameters 6960,119 | 8192,128 | 6688,128
 * 
 */

#include <stdlib.h>
#include <stdio.h>

#define GFBITS 13
#ifdef MCELIECE_8192128
	#define  SYS_T 128
	#define  SYS_N 8192
#else
	#ifdef MCELIECE_6960119
		#define  SYS_T 119
		#define  SYS_N 6960
	#else //MCELIECE_6688128
		#define  SYS_T 128
		#define  SYS_N 6688
	#endif
#endif

typedef uint8_t mat_t[GFBITS * SYS_T][SYS_N/8];

int gaussian_elim(mat_t mat){
	unsigned char mask=0;
	unsigned char * pt=0;
	unsigned char ret=0;
	int arg1=1;
    // clear vector register v0 (masking register) with vector register length of VLEN=1024
	asm volatile("vsetvli %[ret], %[arg1], e1024, m1 \n" // set SEW=1024, LMUL=1, VL=1
		    :[ret] "=r" (ret)
		    :[arg1] "r"(arg1));
	asm volatile("vand.vi v0, v0, 0\n" //set all bits to 0
                "vxor.vi v0, v0, -1 \n"); //set all bits to 1
	arg1=SYS_N/8;
	asm volatile("vsetvli %[ret], %[arg1], e8, m8 \n" // set SEW=8, LMUL=8, VL=870
 		    :[ret] "=r" (ret)
 		    :[arg1] "r"(arg1));

	printf("Gauss Elimination Algorithm for %d%d: \n", SYS_N, SYS_T);
	// Gaussian elimination algorithm from Classical McEliece NIST submission Round 2, see: https://classic.mceliece.org/
	for (int i = 0; i < (GFBITS * SYS_T + 7) / 8; ++i){
		for (int j = 0; j < 8; ++j){
			int row = i*8 + j;

			if (row >= GFBITS * SYS_T)
				break;
			
			//Load matrix row into vector register group
			pt=&(mat[row][0]); // set address to current row of matrix
			asm volatile("vle8.v v8, (%[pt]) \n" // Load into vector register group v8
				:[pt] "+r"(pt));

			for (int k = row + 1; k < GFBITS * SYS_T; ++k)
			{
				mask = mat[ row ][ i ] ^ mat[ k ][ i ];
				mask >>= j;
				mask &= 1;
				mask = -mask;
				
				//Vector extension replaces loop: for (c = i; c < SYS_N/8; c++) mat[ row ][ c ] ^= mat[ k ][ c ] & mask; 
				pt=&(mat[k][0]);
				asm volatile("vle8.v v16, (%[pt]) \n" // Load k-th row into vector register group v16
					:[pt] "+r"(pt));
				
				asm volatile("vand.vx v24,v16,%[mask],v0.t\n" // v24 = v16 & mask
							:[mask] "+r"(mask));
				asm volatile("vxor.vv v8,v8,v24,v0.t \n"); // v8=v8^v24
		
				pt=&(mat[row][0]);
				asm volatile("vse8.v v8, (%[pt]) \n" // Store current row (row of pivot) from vector register group to memory
					:[pt] "+r"(pt));
				
			}

			if ( ((mat[ row ][ i ] >> j) & 1) == 0 ) // return if not systematic
			{
				return -1;
			}

			for (int k = 0; k < GFBITS * SYS_T; ++k)
			{
				if (k != row)
				{
					mask = mat[ k ][ i ] >> j;
					mask &= 1;
					mask = -mask;

					// Vector Extension replaces loop: for (c = 0; c < SYS_N/8; c++) mat[ k ][ c ] ^= mat[ row ][ c ] & mask;
					pt=&(mat[k][0]);
					asm volatile("vle8.v v16, (%[pt]) \n" // Load k-th row of matrix into vector register group v16
						:[pt] "+r"(pt));
				
					asm volatile("vand.vx v24,v8,%[mask]\n" // v24 = v8 & mask
						"vxor.vv v16,v16,v24 \n" // v16=v16^v24
						:[mask] "+r"(mask));
					
					asm volatile("vse8.v v16, (%[pt]) \n" // Store k-th row from vector register group v16 to memory
						:[pt] "+r"(pt));
				}
			}
		}
		
		// Set Mask Register to replace loop: for (c = i; c < SYS_N/8; c++)
		arg1=1;
		asm volatile("vsetvli %[ret], %[arg1], e1024, m1 \n" // Switch to SEW=1024, LMUL=1, VL=1
			:[ret] "=r" (ret)
			:[arg1] "r"(arg1));
		asm volatile("vsll.vi v0, v0, 1 \n"); // Shift left for 1 bit position
		arg1=SYS_N/8;
		asm volatile("vsetvli %[ret], %[arg1], e8, m8 \n" // Switch back to SEW=8, LMUL=8, VL=870
			:[ret] "=r" (ret)
			:[arg1] "r"(arg1));
	}
}

int main()
{
	mat_t mat = {		
#ifdef MCELIECE_8192128
		#include "matrix_begin8192128.data"
#else
	#ifdef MCELIECE_6960119
		#include "matrix_begin6960119.data"
	#else //MCELIECE_6688128
		#include "matrix_begin6688128.data"
	#endif
#endif		
	};
    
	gaussian_elim(mat);
    
	for (int i=0; i<GFBITS * SYS_T; ++i){
		for(int j=0; j<(SYS_N/8); ++j){
			printf("%02X\t",mat[i][j]);
		}
		printf("\n");
	}
}
