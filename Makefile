PREFIX = /usr/local

install: ma.sh
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f ma.sh $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/ma.sh

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ma.sh

.PHONY: test clean install uninstall
