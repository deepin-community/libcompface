prefix          = /usr/local
exec_prefix     = ${prefix}
srcdir          = .
BINDIR		= ${exec_prefix}/bin
LIBDIR		= ${exec_prefix}/lib
MANDIR		= ${prefix}/man
INCLUDEDIR	= ${prefix}/include



RM              = rm -f
LN_S            = ln -s
RANLIB          = ranlib
INSTALL         = /usr/bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA    = ${INSTALL} -m 644
SHELL           = /bin/sh

NAME		= compface
UNNAME		= uncompface
EXEEXT		= 
NAMEEXE		= $(NAME)$(EXEEXT)
UNNAMEEXE	= $(UNNAME)$(EXEEXT)
EXECUTABLE	= $(BINDIR)/$(NAMEEXE)
UNEXECUTABLE	= $(BINDIR)/$(UNNAMEEXE)
LIBNAME		= lib$(NAME).a
SOLIBNAME	= lib$(NAME).so
LIBRARY		= $(LIBDIR)/$(LIBNAME)
MAN1DIR		= $(MANDIR)/man1
MAN3DIR		= $(MANDIR)/man3
OBJECTS		= arith.o file.o compress.o gen.o uncompface.o compface.o
SOURCES		= compface.c uncompface.c arith.c file.c compress.c gen.c \
		  cmain.c uncmain.c version.c
INSTALLHEADERS  = compface.h
HDRS		= $(INSTALLHEADERS) data.h compface_private.h
OTHERS		= README $(NAME).1 $(NAME).3 Makefile.in Makefile.Ashton \
		  configure configure.in install-sh mkinstalldirs ChangeLog

DISTFILES       =  $(OTHERS) $(HDRS) $(SOURCES)

CC		= gcc
CFLAGS		= -g -O2
#CFLAGS		= -g 
DEFS		= -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DHAVE_ERRNO_H=1 -DHAVE_FCNTL_H=1 -DHAVE_STRINGS_H=1 -DHAVE_STRERROR=1  -DHAVE_CONFIG_H
LDFLAGS		= 
LIBS		= 

all:		$(NAMEEXE) $(UNNAMEEXE)

$(NAMEEXE) :	cmain.o $(LIBNAME)
		$(CC) $(LDFLAGS) -o $@ cmain.o -lcompface

$(UNNAMEEXE) :	uncmain.o $(LIBNAME)
		$(CC) $(LDFLAGS) -o $@ uncmain.o -lcompface

$(LIBNAME) :	$(OBJECTS)
		ar rc $(LIBNAME) $(OBJECTS)
		-$(RANLIB) $(LIBNAME)

lint :
		lint -abchx $(SOURCES)

clean :
		-rm -f *.o *.a *.sh core a.out $(NAMEEXE) $(UNNAMEEXE)

distclean: clean
		-rm -rf *~
		-rm -f config.log config.status config.cache Makefile

dist: $(DISTFILES)
		echo compface-`sed -e '/version/!d' -e 's/[^0-9.]*\([0-9.]*\).*/\1/' -e q version.c` > .fname
		$(RM) -rf `cat .fname`
		mkdir `cat .fname`
		ln $(DISTFILES) `cat .fname`
		tar chzf `cat .fname`.tar.gz `cat .fname`
		$(RM) -rf `cat .fname` .fname

install: 	$(NAMEEXE) $(UNNAMEEXE) $(LIBNAME)
		$(INSTALL_PROGRAM) -d $(BINDIR) $(LIBDIR) $(MAN1DIR) $(MAN3DIR) $(INCLUDEDIR)
		$(INSTALL_PROGRAM) $(srcdir)/$(NAMEEXE) $(EXECUTABLE) 
		-chmod 0755 $(EXECUTABLE)
		-strip $(EXECUTABLE)
		$(INSTALL_PROGRAM) $(srcdir)/$(UNNAMEEXE) $(UNEXECUTABLE)
		-chmod 0755 $(UNEXECUTABLE)
		-strip $(UNEXECUTABLE)
		$(INSTALL_DATA) $(srcdir)/$(NAME).1 $(MAN1DIR)/$(NAME).1
		cd $(MAN1DIR) && $(RM) ./$(UNNAME).1 && $(LN_S) $(NAME).1 $(UNNAME).1
		$(INSTALL_DATA) $(srcdir)/$(NAME).3 $(MAN3DIR)/$(NAME).3
		cd $(MAN3DIR) && $(RM) ./$(UNNAME).3 && $(LN_S) $(NAME).3 $(UNNAME).3
		for hdr in $(INSTALLHEADERS); do $(INSTALL_DATA) $(srcdir)/$${hdr} $(INCLUDEDIR)/$${hdr}; done
		$(INSTALL_DATA) $(srcdir)/$(LIBNAME) $(LIBRARY)

shar :
		shar.script $(OTHERS) $(HDRS) $(SOURCES) > $(NAME).sh
		compress $(NAME).sh

static:		$(OBJECTS)
		ar rc $(LIBNAME) $(OBJECTS)
		-ranlib $(LIBNAME)

shared:		$(OBJECTS)
		$(CC) -shared -Wl,-soname,$(SOLIBNAME).1 $(LDFLAGS) -o $(SOLIBNAME).1.0.0 $(OBJECTS)

.c.o:
	$(CC) -c $(CPPFLAGS) $(DEFS) $(CFLAGS) $<

arith.o:	arith.c compface.h data.h
cmain.o:	cmain.c compface.h data.h
compface.o:	compface.c compface.h data.h
compress.o:	compress.c compface.h data.h
file.o:		file.c compface.h data.h
gen.o:		gen.c compface.h data.h
uncmain.o:	uncmain.c compface.h data.h
uncompface.o:	uncompface.c compface.h data.h

.PHONY: clean mostlyclean distclean realclean dist all shared static

# Prevent GNU make v3 from overflowing arg limit on SysV.
.NOEXPORT:

