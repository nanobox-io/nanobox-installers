.PHONY: mac windows clean clean-mac clean-windows publish certs

default: mac windows
	@true

clean: clean-mac clean-windows
	@true

mac: clean-mac
	./script/build-mac

windows: clean-windows
	./script/build-windows

clean-mac:
	rm -f dist/Nanobox*.pkg

clean-windows:
	rm -f dist/Nanobox*.exe

certs:
	aws s3 sync \
		s3://private.nanobox.io/certs \
		certs/ \
		--region us-west-2

publish:
	aws s3 sync \
		dist/ \
		s3://tools.nanobox.io/installers/beta \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
