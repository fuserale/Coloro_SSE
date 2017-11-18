CC=g++
FLAGS=-std=c++11 -O3

SRC=satcol.cpp
OBJS=$(subst .cc,.o,$(SRC))

all : satcol

satcol : $(OBJS)
	$(CC) $(FLAGS) -o satcol $(OBJS) 

satcol.o : satcol.cpp

clean:
	rm -f *.o
