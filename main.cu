#include <stdio.h>
#include <sys/time.h>
#include <cmath>
#include "cuda_runtime.h"

#include "toolbox.hpp"


template<class T>
void sinus_cpu(const T* input, T* output, const size_t size) {
    for(int i=0;i<size;++i) {
        output[i] = sin(input[i]);
    }
}

template<class T>
void sinus_par(const T* input, T* output, const size_t size) {
#pragma omp parallel for
    for(int i=0;i<size;++i) {
        output[i] = sin(input[i]);
    }
}

template<class T>
__global__ void sinus(const T* input, T* output, const uint size) {
    const int tidx = threadIdx.x + blockDim.x * blockIdx.x;
    if(tidx<size)
        output[tidx] = sin(input[tidx]);
}
template<class T>
__global__ void sinus(const T* input, T* output, const uint size, const uint iterations) {
    /*
    const int tidx = threadIdx.x + blockDim.x * blockIdx.x;
    for(int i = 0;i<iterations;++i)
        output[idx + blockDim.x * blockIdx.x] = sin();
    */
}

struct sin_time {
    double cpu;
    double gpu;
    double par_gpu;
};

template<class T>
void test_sinus(const size_t input_size, const uint wg_size, timestruct& tms) {
    double t1,t2;
    T *dev_a, *dev_b;
    T *h_a,*h_b;

    /**init**/

    h_a = (T*)malloc(input_size*sizeof(T));
    h_b = (T*)malloc(input_size*sizeof(T));

    cudaMalloc( (void**)&dev_a, input_size*sizeof(T));
    cudaMalloc( (void**)&dev_b, input_size*sizeof(T));

#pragma omp parallel for
    for(int i = 0;i<input_size;++i) {
        h_a[i]=i;
    }
    cudaMemcpy(dev_a,h_a,input_size*sizeof(T),cudaMemcpyHostToDevice);

    //GPU
    {
        const int nblocks = input_size / wg_size +1;

        t1 = time_in_seconds();
        sinus<<<nblocks,wg_size>>>(dev_a,dev_b,input_size);
        cudaThreadSynchronize();
        t2 = time_in_seconds();
        printf("Time Sinus GPU: %.3fs\n", t2-t1);
        tms.add(t2-t1,0,"Sinus GPU");
    }
    //CPU
    {
        t1 = time_in_seconds();
        sinus_cpu(h_a,h_b,input_size);
        t2 = time_in_seconds();
        printf("Time Sinus CPU: %.3fs\n", t2-t1);
        tms.add(t2-t1,1,"Sinus CPU");
    }
    //CPU
    {
        t1 = time_in_seconds();
        sinus_par(h_a,h_b,input_size);
        t2 = time_in_seconds();
        printf("Time Sinus Par: %.3fs\n", t2-t1);
        tms.add(t2-t1,2,"Sinus Parallel CPU");
    }

    /***copy dev_b to h_a for checking, which is not needed anymore***/
    cudaMemcpy(h_a,dev_b,input_size*sizeof(T),cudaMemcpyDeviceToHost);
    for(int i = 0;i<input_size;++i) {
        if(!compare_float(h_b[i],h_a[i])) {
            fprintf(stderr,"Error at Position %d: %.3f (GPU) <> %.3f (CPU)\n",i,h_a[i],h_b[i]);
            break;
        }
    }
    free(h_a);
    free(h_b);
    cudaFree(dev_a);
    cudaFree(dev_b);
}

int main(int argc, char** argv) {
    uint s = 1000*1000*10;
    uint wg_size = 256;

    if(argc>1) {
        s = atoi(argv[1]);
    }
    printf("Size: %d\n",s);
    if(argc>2) {
        wg_size = atoi(argv[2]);
        printf("Workgroup Size: %d\n", wg_size);
    }

    timestruct tms_double;
    timestruct tms_float;

    for(int i=0;i<5;++i) {
        printf("=== Double ===\n");
        test_sinus<double>(s, wg_size,tms_double);

        printf("=== Float ===\n");
        test_sinus<float>(s, wg_size,tms_float);
    }
    printf("#double;%d;",s);
    tms_double.print();
    printf("#float;%d;",s);
    tms_float.print();
}
