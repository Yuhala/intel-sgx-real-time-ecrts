
CXX = g++ 
CC = occlum-gcc #gcc
# Set CC as occlum-gcc for Occlum
OCCLUM_GCC = occlum-gcc

CXXFlags = -std=c++17 -Wall 
CCFlags = -Wall

LIB_RT = -lrt -pthread

SOURCES = error.c rt-utils.c cyclictest.c

HEADERS = error.h rt-tests.h rt-utils.h 

OBJS = $(SOURCES:.c=.o)

all: cyclictest

.PHONY: all clean

%.o: %.c $(HEADERS)
	$(CC) $(CC_FLAGS) -c $< -o $@	

cyclictest: $(OBJS)
	$(CC) $^ $(LIB_RT) -o $@


clean: 
	rm -f $(OBJS) cyclictest