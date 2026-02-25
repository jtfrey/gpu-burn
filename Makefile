CUDA_HOME   ?= /usr/local/cuda
IS_JETSON   ?= $(shell if grep -Fwq "Jetson" /proc/device-tree/model 2>/dev/null; then echo true; else echo false; fi)
NVCC        :=  ${CUDA_HOME}/bin/nvcc
CCPATH      ?=

override CFLAGS   ?=
override CFLAGS   += -O3
override CFLAGS   += -Wno-unused-result
override CFLAGS   += -I${CUDA_HOME}/include
override CFLAGS   += -std=c++11
override CFLAGS   += -DIS_JETSON=${IS_JETSON}

override LDFLAGS  ?=
override LDFLAGS  += -lcuda
override LDFLAGS  += -L${CUDA_HOME}/lib64
override LDFLAGS  += -L${CUDA_HOME}/lib64/stubs
override LDFLAGS  += -L${CUDA_HOME}/lib
override LDFLAGS  += -L${CUDA_HOME}/lib/stubs
override LDFLAGS  += -Wl,-rpath=${CUDA_HOME}/lib64
override LDFLAGS  += -Wl,-rpath=${CUDA_HOME}/lib
override LDFLAGS  += -lcublas
override LDFLAGS  += -lcublasLt
override LDFLAGS  += -lcudart

COMPUTE      ?= 50
CUDA_VERSION ?= 11.8.0
IMAGE_DISTRO ?= ubi8

override NVCCFLAGS ?=
override NVCCFLAGS += -I${CUDA_HOME}/include
override NVCCFLAGS += -arch=compute_$(subst .,,${COMPUTE})

IMAGE_NAME ?= gpu-burn

.PHONY: clean

gpu_burn: gpu_burn-drv.o compare.ptx
	g++ -o $@ $< -O3 ${LDFLAGS}

%.o: %.cpp
	g++ ${CFLAGS} -c $<

%.ptx: %.cu
	PATH="${PATH}:${CCPATH}:." ${NVCC} ${NVCCFLAGS} -ptx $< -o $@

clean:
	$(RM) *.ptx *.o gpu_burn

image:
	docker build --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg IMAGE_DISTRO=${IMAGE_DISTRO} -t ${IMAGE_NAME} .
