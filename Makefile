.PHONY: mac windows

default: mac windows
	@true

clean: clean-mac clean-windows
	@true

mac: clean-mac
	./script/build-mac

windows: clean-windows
	./script/build-windows

clean-mac:
	rm -f dist/Nanobox-*.pkg

clean-windows:
	rm -f dist/Nanobox-*.exe
