// Author: Dimitrios Kechagias, dkechag at cpan.org
// Copyright (C) 2019, SpareRoom.com
// This program is free software; you can redistribute
// it and/or modify it under the same terms as Perl itself.
// Significant code adapted from:

/*
 * Fast discrete cosine transform algorithms (C)
 *
 * Copyright (c) 2017 Project Nayuki. (MIT License)
 * https://www.nayuki.io/page/fast-discrete-cosine-transform-algorithms
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - The Software is provided "as is", without warranty of any kind, express or
 *   implied, including but not limited to the warranties of merchantability,
 *   fitness for a particular purpose and noninfringement. In no event shall the
 *   authors or copyright holders be liable for any claim, damages or other
 *   liability, whether in an action of contract, tort or otherwise, arising from,
 *   out of or in connection with the Software or the use or other dealings in the
 *   Software.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif

void transform_recursive(double input[], double temp[], int size, double coef[]);

void fct8_1d(char *inbuf) {
    double *vector = (double *) inbuf;

    const double v0 = vector[0] + vector[7];
    const double v1 = vector[1] + vector[6];
    const double v2 = vector[2] + vector[5];
    const double v3 = vector[3] + vector[4];
    const double v4 = vector[3] - vector[4];
    const double v5 = vector[2] - vector[5];
    const double v6 = vector[1] - vector[6];
    const double v7 = vector[0] - vector[7];

    const double v8 = v0 + v3;
    const double v9 = v1 + v2;
    const double v10 = v1 - v2;
    const double v11 = v0 - v3;
    const double v12 = -v4 - v5;
    const double v13 = (v5 + v6) * 0.707106781186547524400844;
    const double v14 = v6 + v7;

    const double v15 = v8 + v9;
    const double v16 = v8 - v9;
    const double v17 = (v10 + v11) * 0.707106781186547524400844;
    const double v18 = (v12 + v14) * 0.382683432365089771728460;

    const double v19 = -v12 * 0.541196100146196984399723 - v18;
    const double v20 = v14 * 1.306562964876376527856643 - v18;

    const double v21 = v17 + v11;
    const double v22 = v11 - v17;
    const double v23 = v13 + v7;
    const double v24 = v7 - v13;

    const double v25 = v19 + v24;
    const double v26 = v23 + v20;
    const double v27 = v23 - v20;
    const double v28 = v24 - v19;

    vector[0] = v15;
    vector[1] = 0.509795579104157595 * v26;
    vector[2] = 0.54119610014619577 * v21;
    vector[3] = 0.60134488693504412 * v28;
    vector[4] = 0.707106781186547 * v16;
    vector[5] = 0.8999762231364133 * v25;
    vector[6] = 1.30656296487637502 * v22;
    vector[7] = 2.5629154477415022505 * v27;
}

void fct8_2d(
    char *inbuf)
{
    double *input = (double *) inbuf;
    double  temp[64];
    int x,y;

    for (x = 0; x < 64; x+=8) {
        fct8_1d((char *)&input[x]);
    }

    for (x = 0; x < 8; x++) {
        for (y = 0; y < 8; y++) {
            temp[y*8+x]=input[x*8+y];
        }
    }

    for (y = 0; y < 64; y+=8) {
        fct8_1d((char *)&temp[y]);
    }

    for (x = 0; x < 8; x++) {
        for (y = 0; y < 8; y++) {
            input[y*8+x]=temp[x*8+y];
        }
    }
}

void dct_1d(
    char *inbuf,
    int   size)
{
    double *input  = (double *) inbuf;
    double  temp[size];
    double  factor = M_PI/size;

    int i,j;
    for(i = 0; i < size; ++i) {
        double sum = 0;
        double mult = i*factor;
        for(j = 0; j < size; ++j) {
            sum += input[j] * cos((j+0.5)*mult);
        }
        temp[i]=sum;
    }

    for(i = 0; i < size; ++i) {
        input[i]=temp[i];
    }
}

void idct_1d(
    char *inbuf,
    int   size)
{
    double *input  = (double *) inbuf;
    double  temp[size];
    double  factor = M_PI/size;
    float   scale = 2.0 / size;

    int i,j;
    for (i = 0; i < size; i++) {
        double sum = input[0] / 2.0;
        double mult = (i+0.5)*factor;
        for (j = 1; j < size; j++) {
            sum += input[j] * cos(j*mult);
        }
        temp[i] = sum;
    }

    for(i = 0; i < size; ++i) {
        input[i]=temp[i] * scale;
    }
}

void dct_coef(int size, double coef[size][size]) {
    double factor = M_PI/size;

    int i, j;
    for (i = 0; i < size; i++) {
        double mult = i*factor;
        for (j = 0; j < size; j++) {
            coef[j][i] = cos((j+0.5)*mult);
        }
    }
}

void idct_coef(int size, double coef[size][size]) {
    double factor = M_PI/size;

    int i, j;
    for (i = 0; i < size; i++) {
        double mult = (i+0.5)*factor;
        for (j = 0; j < size; j++) {
            coef[j][i] = cos(j*mult);
        }
    }
}

void dct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size][size];
    double  temp[size*size];
    int x, y, i, j;

    dct_coef(size, coef);

    for (x = 0; x < size; x++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            y = x * size;
            for (j = 0; j < size; j++) {
                sum += input[y+j] * coef[j][i];
            }
            temp[y+i] = sum;
        }
    }

    for (y = 0; y < size; y++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            for (j = 0; j < size; j++) {
                sum += temp[j*size+y] * coef[j][i];
            }
            input[i*size+y] = sum;
        }
    }
}

void idct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size][size];
    double  temp[size*size];
    float   scale = 2.0 / size;
    int x, y, i, j;

    idct_coef(size, coef);

    for (x = 0; x < size; x++) {
        for (i = 0; i < size; i++) {
            double sum = input[x*size] / 2.0;
            y = x * size;
            for (j = 1; j < size; j++) {
                sum += input[y+j] * coef[j][i];
            }
            temp[y+i] = sum * scale;
        }
    }

    for (y = 0; y < size; y++) {
        for (i = 0; i < size; i++) {
            double sum = temp[y] / 2.0;
            for (j = 1; j < size; j++) {
                sum += temp[j*size+y] * coef[j][i];
            }
            input[i*size+y] = sum * scale;
        }
    }
}

void fast_dct_1d_precalc(
    char *inbuf,
    int   size,
    double coef[])
{
    double *input = (double *) inbuf;
    double  temp[size];

    transform_recursive(input, temp, size, coef);
}

void fast_dct_coef(int size, double coef[size]) {

    int i, j;
    for (i = 1; i <= size/2; i*=2) {
        double factor = M_PI/(i*2);
        for (j = 0; j < i; j++) {
            coef[i+j] = cos((j+0.5)*factor)*2;
        }
    }
}

void fast_dct_1d(
    char *inbuf,
    int   size)
{
    double  coef[size];

    fast_dct_coef(size, coef);

    fast_dct_1d_precalc(inbuf, size, coef);
}

void fast_dct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size];
    double  temp[size*size];
    int x,y,k;

    fast_dct_coef(size, coef);

    for (x = 0; x < size*size; x+=size) {
        fast_dct_1d_precalc((char *)&input[x], size, coef);
    }

    for (x = 0; x < size; x++) {
        k = x * size;
        for (y = 0; y < size; y++) {
            temp[y*size+x]=input[k++];
        }
    }

    for (y = 0; y < size*size; y+=size) {
        fast_dct_1d_precalc((char *)&temp[y], size, coef);
    }

    for (x = 0; x < size; x++) {
        k = x * size;
        for (y = 0; y < size; y++) {
            input[y*size+x]=temp[k++];
        }
    }
}

void transform_recursive(double input[], double temp[], int size, double coef[]) {
    if (size == 1)
        return;

    int i,j;
    int half = size / 2;

    for (i = 0; i < half; i++) {
        double x = input[i];
        double y = input[size-1-i];
        temp[i] = x+y;
        temp[i+half] = (x-y)/coef[half+i];
    }

    transform_recursive(temp, input, half, coef);
    transform_recursive(&temp[half], input, half, coef);

    j = 0;
    for (i = 0; i < half-1; i++) {
        input[j++] = temp[i];
        input[j++] = temp[i+half] + temp[i+half+1];
    }
    input[size-2] = temp[half-1];
    input[size-1] = temp[size-1];
}


MODULE = Math::DCT  PACKAGE = Math::DCT  

PROTOTYPES: DISABLE


void
fct8_1d (inbuf)
    char *  inbuf
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fct8_1d(inbuf);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fct8_2d (inbuf)
    char *  inbuf
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fct8_2d(inbuf);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dct_1d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dct_1d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
idct_1d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        idct_1d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dct_2d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dct_2d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
idct_2d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        idct_2d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fast_dct_1d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fast_dct_1d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fast_dct_2d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fast_dct_2d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

