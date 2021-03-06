ifdef VERSION_SRC

ifndef VERSION_FILES
$(error Need VERSION_FILES defined for version objects)
endif

ifndef VERSION_PREFIX
$(error Need VERSION_PREFIX defined for version objects)
endif

VERSION_OBJ = $(subst .c,.o,$(VERSION_SRC))

VERSION_NUM = $(VERSION_PREFIX)_BUILD_VERSION
VERSION_DATE = $(VERSION_PREFIX)_BUILD_DATE
VERSION_MD5 = $(VERSION_PREFIX)_BUILD_MD5

VERDEFS = -D$(VERSION_NUM)=\""$(VERSION)"\" \
	  -D$(VERSION_DATE)=\""$(shell LANG=C date)"\" \
	  -D$(VERSION_MD5)=\""$(shell cat stamp-md5)"\"

VERMAGIC = $(if $(filter $(VERSION_OBJ),$@),$(VERDEFS))

ifneq ($(MAKECMDGOALS),install)
VERSTAMP = stamp
endif

stamp: ;

stamp-md5: $(VERSION_FILES)
	@cat $(VERSION_FILES) Makefile | md5sum | sed -e 's/ .*//' > stamp-md5

$(VERSION_OBJ): stamp-md5 $(VERSTAMP)
endif


LOCAL_CFLAGS = $($(subst /,_,$(basename $@))_CFLAGS)
LOCAL_CPPFLAGS = $($(subst /,_,$(basename $@))_CPPFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) $(LOCAL_CFLAGS) $(CPPFLAGS) $(LOCAL_CPPFLAGS) $(INCLUDES) $(DEFINES) $(VERMAGIC) -o $@ -c $<

%.p: %.c
	$(CC) $(CFLAGS) $(LOCAL_CFLAGS) $(CPPFLAGS) $(LOCAL_CPPFLAGS) $(INCLUDES) $(DEFINES) $(VERMAGIC) -E -o $@ -c $<

%.s: %.c
	$(CC) $(CFLAGS) $(LOCAL_CFLAGS) $(CPPFLAGS) $(LOCAL_CPPFLAGS) $(INCLUDES) $(DEFINES) $(VERMAGIC) -S -o $@ -c $<



.PHONY: subdirs $(SUBDIRS)
subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all-rules
all-rules: subdirs $(LIBRARIES) $(BIN_PROGRAMS) $(SBIN_PROGRAMS) $(MODULES) $(MANS)


INSTALL_SUBDIRS = $(addsuffix -install,$(SUBDIRS))

.PHONY: install-rules install-subdirs $(INSTALL_RULES) install-bin-programs install-bin-extra install-sbin-programs install-sbin-extra install-shared-data

install-subdirs: $(INSTALL_SUBDIRS)

$(INSTALL_SUBDIRS):
	$(MAKE) -C $(subst -install,,$@) install

install-shared-data: $(SHARED_DATA)
ifdef SHARED_DATA
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(datadir)/gdb
	for prog in $(SHARED_DATA); do \
	  $(INSTALL_PROGRAM) -m 444 $$prog $(DESTDIR)$(datadir)/gdb/$$prog; \
	done
endif

install-bin-programs: $(BIN_PROGRAMS)
ifdef BIN_PROGRAMS
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(bindir)
	for prog in $(BIN_PROGRAMS); do \
	  $(INSTALL_PROGRAM) $$prog $(DESTDIR)$(bindir)/$$prog; \
	done
endif

install-bin-extra: $(BIN_EXTRA)
ifdef BIN_EXTRA
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(bindir)
	for prog in $(BIN_EXTRA); do \
	  $(INSTALL_PROGRAM) $$prog $(DESTDIR)$(bindir)/$$prog; \
	done
endif

install-sbin-programs: $(SBIN_PROGRAMS)
ifdef SBIN_PROGRAMS
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(sbindir)
	for prog in $(SBIN_PROGRAMS); do \
	  $(INSTALL_PROGRAM) $$prog $(DESTDIR)$(sbindir)/$$prog; \
	done
endif

install-sbin-extra: $(SBIN_EXTRA)
ifdef SBIN_EXTRA
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(sbindir)
	for prog in $(SBIN_EXTRA); do \
	  $(INSTALL_PROGRAM) $$prog $(DESTDIR)$(sbindir)/$$prog; \
	done
endif

install-mans: $(MANS)
ifdef MANS
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(mandir)
	for man in $(MANS); do \
	  dir=`echo $$man | sed -e 's/^.*\\./man/'`; \
	  $(SHELL) $(TOPDIR)/mkinstalldirs $(DESTDIR)$(mandir)/$$dir; \
	  $(INSTALL_DATA) $$man $(DESTDIR)$(mandir)/$$dir/$$man; \
	done
endif

install-rules: install-subdirs $(INSTALL_RULES) install-bin-programs install-bin-extra install-sbin-programs install-sbin-extra install-mans install-shared-data


CLEAN_SUBDIRS = $(addsuffix -clean,$(SUBDIRS))

.PHONY: clean clean-subdirs $(CLEAN_RULES) $(CLEAN_SUBDIRS)

clean-subdirs: $(CLEAN_SUBDIRS)

$(CLEAN_SUBDIRS):
	$(MAKE) -C $(subst -clean,,$@) clean

clean: clean-subdirs $(CLEAN_RULES)
	rm -f *.o *.p core $(BIN_PROGRAMS) $(SBIN_PROGRAMS) $(LIBRARIES) stamp-md5


DIST_SUBDIRS = $(addsuffix -dist,$(SUBDIRS))

.PHONY: dist-all dist-mkdir dist-copy dist-subdirs $(DIST_RULES) $(DIST_SUBDIRS)

dist-subdirs: $(DIST_SUBDIRS)

$(DIST_SUBDIRS):
	$(MAKE) -C $(subst -dist,,$@) dist-all \
	  DIST_CURDIR=$(DIST_CURDIR)/$(subst -dist,,$@)

dist-mkdir:
	$(SHELL) $(TOPDIR)/mkinstalldirs $(DIST_DIR)

DIST_ALL_FILES = Makefile $(BIN_EXTRA) $(SBIN_EXTRA) $(MANS) $(VERSION_FILES) $(DIST_FILES)

dist-copy: dist-mkdir $(DIST_ALL_FILES) $(DIST_RULES)
	@for file in $(DIST_ALL_FILES); do \
	  echo " cp -p $$file $(DIST_DIR)/$$file"; \
	  cp -p $$file $(DIST_DIR)/$$file; \
        done

dist-all: dist-copy dist-subdirs
	 

ifeq (Cscope.make,$(wildcard Cscope.make))
include Cscope.make
endif
