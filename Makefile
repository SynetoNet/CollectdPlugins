DESTDIR=
PREFIX=/usr/local
BUILD_DIR:=$(shell readlink -f _build)
INSTALL_DIR:=$(shell readlink -f _install)
PARBUILD=-j 5

.PHONY: all install unit-test ui-test doc clean distclean

# This GNU Make function is used to optimize nightly build by not recompiling and re-installing software if build instructions have not changed.
ALL_DEPS=Makefile iostat_illumos.rb zfs_iostat.d zfs_iostat.sh
md5_make=@md5sum $(ALL_DEPS) > $(1).build-new; if diff $(1).build-new $(1).build >/dev/null 2>&1; then rm -f $(1).build-new; else $(MAKE) $(1); mv $(1).build-new $(1).build; fi

all:
	$(call md5_make,install)

install:
	$(call md5_make,install-collectd-plugins)
	cp -a $(INSTALL_DIR)/* $(DESTDIR)/

install-collectd-plugins:
	rm -rf $(INSTALL_DIR)
	mkdir -p $(INSTALL_DIR)
	ginstall -d -m 777 -o admin -g staff $(INSTALL_DIR)/$(PREFIX)/collectd-plugins
	ginstall -m 755 -o root -g root *.rb $(INSTALL_DIR)/$(PREFIX)/collectd-plugins/
	ginstall -m 755 -o root -g root *.d $(INSTALL_DIR)/$(PREFIX)/collectd-plugins/
	ginstall -m 755 -o root -g root *.sh $(INSTALL_DIR)/$(PREFIX)/collectd-plugins/

clean:
	rm -rf $(BUILD_DIR)
	rm -f *.build
	rm -f *.build-new

distclean: clean
	rm -rf $(INSTALL_DIR)
	rm -f *.log
