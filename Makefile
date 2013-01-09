# C Application Example for ARM Linux
#  
# Copyright (C) ARM Limited, 2007-2012. All rights reserved.

# This makefile is intended for use with GNU make

TARGET = default

CPU = -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard

CC_OPTS = -c -O0 -g  -marm

OBJS = $(TARGET).o
OBJS_ASM = $(TARGET)_asm.o

##########################################################################


CONFIG_FILE =
CPP = arm-none-linux-gnueabi-c++
CC  = arm-linux-gnueabihf-gcc
AR  = arm-none-linux-gnueabi-ar



# Select build rules based on Windows or Linux
ifdef WINDIR
#  Building on Windows
RPATH=$$ORIGIN
WINPATH=$(subst /,\,$(1))
DONE=@if exist $(call WINPATH,$(1)) echo Build completed.
define REAL_RM
if exist $(call WINPATH,$(1)) del /q $(call WINPATH,$(1))

endef
RM=$(foreach file,$(1),$(call REAL_RM,$(file)))
SHELL=$(windir)\system32\cmd.exe
MD=if not exist $(1) mkdir $(1)
CP=copy
else
ifdef windir
#  Building on Windows
RPATH=$$ORIGIN
WINPATH=$(subst /,\,$(1))
DONE=@if exist $(call WINPATH,$(1)) echo Build completed.
define REAL_RM
if exist $(call WINPATH,$(1)) del /q $(call WINPATH,$(1))

endef
RM=$(foreach file,$(1),$(call REAL_RM,$(file)))
SHELL=$(windir)\system32\cmd.exe
MD=if not exist $(1) mkdir $(1)
CP=copy

else
#  Building on Linux
RPATH='$$ORIGIN'
DONE=@if [ -f $(1) ]; then echo Build completed.; fi
RM=rm -f $(1)
MD=@if [ ! -d $(1) ]; then mkdir $(1); fi
CP=cp
endif
endif

##########################################################################

all: $(TARGET)
		$(call DONE,$(TARGET))

rebuild: clean all

clean:
		$(call RM,$(CONFIG_FILE))
		$(call RM,$(OBJS))
		$(call RM,$(OBJS_ASM))
		$(call RM,$(TARGET))




# Compile the sources
$(OBJS): %.o: %.c $(CONFIG_FILE)
	$(CC) $(CPU) $(CC_OPTS) $< -o $@
	
$(OBJS_ASM): %.o: %.s $(CONFIG_FILE)
	$(CC) $(CPU) $(CC_OPTS) $< -o $@


# Link the objects together to create an executable
# Strip the host/debug version to create a stripped/nodebug version for downloading to the target
$(TARGET): $(OBJS)  $(OBJS_ASM) $(CONFIG_FILE)
	$(CC) -static-libgcc $(OBJS) $(OBJS_ASM) -o $(TARGET)
