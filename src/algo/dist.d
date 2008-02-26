module algo.dist;

/* Return the squared distance between two vectors. 
	This is highly optimized, with loop unrolling, as it is one
	of the most expensive inner loops of recognition.
*/
public float squaredDist(T,U)(T[] a, U[] b) 
{
	float distsq = 0.0;
	float diff0, diff1, diff2, diff3;
	T* v1 = a.ptr;
	U* v2 = b.ptr;
	
	T* final_ = v1 + a.length;
	T* finalgroup = final_ - 3;

	/* Process 4 pixels with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0] - v2[0];	
		diff1 = v1[1] - v2[1];
		diff2 = v1[2] - v2[2];
		diff3 = v1[3] - v2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
		v2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff0 = *v1++ - *v2++;
		distsq += diff0 * diff0;
	}
	return distsq;
}


public float squaredDist(T)(T[] a) 
{
	
	float distsq = 0.0;
	float diff0, diff1, diff2, diff3;
	T* v1 = a.ptr;
	
	T* final_ = v1 + a.length;
	T* finalgroup = final_ - 3;

	/* Process 4 pixels with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0];
		diff1 = v1[1];
		diff2 = v1[2];
		diff3 = v1[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff0 = *v1++;
		distsq += diff0 * diff0;
	}
	return distsq;
}




/**
 * Computes the squared L2 distance between two uc vectors using SSE2 instructions.
 * Gives an ~2.5x speed improvement over standard.
 *
 * Preconditions:
 *  a.length = b.length = multiple of 32 and less than 216!
 */
version (SSE2)  public float squaredDistSSE2(ubyte[] a, ubyte[] b)
{
   uint mask[4] = [ 0x00ff00ffu, 0x00ff00ffu, 0x00ff00ffu, 0x00ff00ffu];

   uint sum_sqr;
   int veclen = a.length;
   ubyte* va = a.ptr;
   ubyte* vb = b.ptr;

   asm {   
      mov int ptr EAX, veclen ;
      pxor     XMM6, XMM6 ;
      pxor     XMM7, XMM7 ;

      mov      EBX, va;
      mov      ECX, vb;
      loop_begin:
    
      movdqu   XMM0, [EBX] ;     // 0 = 2 = a[0:16]
      movdqa   XMM2, XMM0 ;
      movdqu   XMM1, [ECX] ;     // 1 = b[0:16]

      movdqu   XMM3, [EBX+16] ;    // 3 = 5 = a[16:32]
      movdqa   XMM5, XMM3 ;
      movdqu   XMM4, [ECX+16] ;

      psubusb  XMM0, XMM1 ;    // 0 = max(a-b,[0])[0:16]
      psubusb  XMM1, XMM2 ;   // 1 = max(b-a,[0])[0:16]
      paddusb  XMM0, XMM1 ;

      psubusb  XMM3, XMM4 ;    // For 16:32
      psubusb  XMM4, XMM5 ;
      paddusb  XMM3, XMM4 ;

      movdqa   XMM1, XMM0 ;   // 0 = 1 = |a-b|[0:16]
      movdqa   XMM4, XMM3 ;  // 3 = 4 = |a-b|[16:32]

      pand     XMM0, mask ;    // 0 = lower nums
      pmaddwd  XMM0, XMM0 ;  // 0 = sum(|a-b|^2)
      paddd    XMM6, XMM0 ;

      pand     XMM3, mask ;
      pmaddwd  XMM3, XMM3 ;
      paddd    XMM7, XMM3 ;

      psrldq   XMM1, 1 ;
      pand     XMM1, mask ;    // 1 = higher nums
      pmaddwd  XMM1, XMM1 ;  // 1 = sum(|a-b|^2)
      paddd    XMM6, XMM1 ;

      psrldq   XMM4, 1 ;
      pand     XMM4, mask ;
      pmaddwd  XMM4, XMM4 ;
      paddd    XMM7, XMM4 ;

      add      EBX, 32 ;
      add      ECX, 32 ;
      sub      EAX, 32 ;
      test     EAX, EAX ;
      jnz loop_begin ;

      paddd    XMM7, XMM6 ;
      pshufd   XMM6, XMM7, 14 ;
      paddd    XMM7, XMM6 ;
      pshufd   XMM6, XMM7, 1 ;
      paddd    XMM7, XMM6 ;
      movd sum_sqr, XMM7 ;
    }

  	return sum_sqr;
}
