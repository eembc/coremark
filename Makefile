#Author : Shay Gal-On, EEMBC
#
#This file is part of  EEMBC(R) and CoreMark(TM), which are Copyright (C) 2009 
#All rights reserved.                            
#
#EEMBC CoreMark Software is a product of EEMBC and is provided under the terms of the
#CoreMark License that is distributed with the official EEMBC COREMARK Software release. 
#If you received this EEMBC CoreMark Software without the accompanying CoreMark License, 
#you must discontinue use and download the official release from www.coremark.org.  
#
#Also, if you are publicly displaying scores generated from the EEMBC CoreMark software, 
#make sure that you are in compliance with Run and Reporting rules specified in the accompanying readme.txt file.
#
#EEMBC 
#4354 Town Center Blvd. Suite 114-200
#El Dorado Hills, CA, 95762 


# Make sure the default target is to simply build and run the benchmark.
RSTAMP = v1.0

.PHONY: run score
run: $(OUTFILE) rerun score

score:
	@echo "Check run1.log and run2.log for results."
	@echo "See readme.txt for run and reporting rules." 
	
ifndef PORT_DIR
# Ports for a couple of common self hosted platforms
UNAME=$(shell if [[ `uname 2> /dev/null` ]] ; then uname ; fi)
ifneq (,$(findstring CYGWIN,$(UNAME)))
PORT_DIR=cygwin
endif
ifneq (,$(findstring Linux,$(UNAME)))
MACHINE=$(shell uname -m)
ifneq (,$(findstring 64,$(MACHINE)))
PORT_DIR=linux64
else
PORT_DIR=linux
endif
endif
endif
ifndef PORT_DIR
$(error PLEASE define PORT_DIR! (e.g. make PORT_DIR=simple)) 
endif
vpath %.c $(PORT_DIR)
vpath %.h $(PORT_DIR)
vpath %.mak $(PORT_DIR)
include $(PORT_DIR)/core_portme.mak

ifndef $(ITERATIONS)
ITERATIONS=0
endif
ifdef REBUILD
FORCE_REBUILD=force_rebuild
endif

CFLAGS += -DITERATIONS=$(ITERATIONS)

CORE_FILES = core_list_join core_main core_matrix core_state core_util
ORIG_SRCS = $(addsuffix .c,$(CORE_FILES))
SRCS = $(ORIG_SRCS) $(PORT_SRCS)
OBJS = $(addprefix $(OPATH),$(addsuffix $(OEXT),$(CORE_FILES)) $(PORT_OBJS))
OUTNAME = coremark$(EXE)
OUTFILE = $(OPATH)$(OUTNAME)
LOUTCMD = $(OFLAG) $(OUTFILE) $(LFLAGS_END)
OUTCMD = $(OUTFLAG) $(OUTFILE) $(LFLAGS_END)

HEADERS = coremark.h 
CHECK_FILES = $(ORIG_SRCS) $(HEADERS)

$(OPATH):
	$(MKDIR) $(OPATH)

.PHONY: compile link
ifdef SEPARATE_COMPILE
$(OPATH)$(PORT_DIR):
	$(MKDIR) $(OPATH)$(PORT_DIR)

compile: $(OPATH) $(OPATH)$(PORT_DIR) $(OBJS) $(HEADERS) 
link: compile 
	$(LD) $(LFLAGS) $(XLFLAGS) $(OBJS) $(LOUTCMD)
	
else

compile: $(OPATH) $(SRCS) $(HEADERS) 
	$(CC) $(CFLAGS) $(XCFLAGS) $(SRCS) $(OUTCMD)
link: compile 
	@echo "Link performed along with compile"

endif

$(OUTFILE): $(SRCS) $(HEADERS) Makefile core_portme.mak $(FORCE_REBUILD)
	$(MAKE) port_prebuild
	$(MAKE) link
	$(MAKE) port_postbuild

.PHONY: rerun
rerun: 
	$(MAKE) XCFLAGS="$(XCFLAGS) -DPERFORMANCE_RUN=1" load run1.log
	$(MAKE) XCFLAGS="$(XCFLAGS) -DVALIDATION_RUN=1" load run2.log

PARAM1=$(PORT_PARAMS) 0x0 0x0 0x66 $(ITERATIONS)
PARAM2=$(PORT_PARAMS) 0x3415 0x3415 0x66 $(ITERATIONS)
PARAM3=$(PORT_PARAMS) 8 8 8 $(ITERATIONS)

run1.log-PARAM=$(PARAM1) 7 1 2000
run2.log-PARAM=$(PARAM2) 7 1 2000 
run3.log-PARAM=$(PARAM3) 7 1 1200

run1.log run2.log run3.log: load
	$(MAKE) port_prerun
	$(RUN) $(OUTFILE) $($(@)-PARAM) > $(OPATH)$@
	$(MAKE) port_postrun
	
.PHONY: gen_pgo_data
gen_pgo_data: run3.log

.PHONY: load
load: $(OUTFILE)
	$(MAKE) port_preload
	$(LOAD) $(OUTFILE)
	$(MAKE) port_postload

.PHONY: clean
clean:
	rm -f $(OUTFILE) $(OPATH)*.log *.info $(OPATH)index.html $(PORT_CLEAN)

.PHONY: force_rebuild
force_rebuild:
	echo "Forcing Rebuild"
	
.PHONY: check
check:
	md5sum -c coremark.md5 

ifdef ETC
# Targets related to testing and releasing CoreMark. Not part of the general release!
include Makefile.internal
endif	
