
# ------------------ Compilation options ------------------------

ifndef TARGET	
	#TARGET := $(shell basename `pwd`)
	TARGET = nn
endif
# ------------------ Compilation options ------------------------

include Makefile.d_rebuild
