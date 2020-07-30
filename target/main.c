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


#include <stdlib.h>
#include <stdio.h>
#define GFBITS 13
#define SYS_T 119
#define SYS_N 6960

void gauss(void* mat);

int main()
{
    int i=0;
    int j=0;
    int k=0;
    int c=0;
    int row=0;
    unsigned char mask=0;
    unsigned char mat[ GFBITS * SYS_T ][ SYS_N/8 ]={
        #include "matrix_begin.data"
    };
    
    printf("Gauss Elimination Algorithm: \n");
    gauss(mat);
    
    for (i=0;i<GFBITS * SYS_T;i++){
        for(j=0;j<(SYS_N/8);j++){
            printf("%02X\t",mat[i][j]);
        }
        printf("\n");
    }
}
