SHELL := /bin/bash

.PHONY: mac windows clean clean-mac clean-windows publish certs windows-env mac-env

default: mac windows
	@true

clean: clean-mac clean-windows
	@true

mac-env:
	if [[ ! $$(docker images nanobox/mac-env) =~ "nanobox/mac-env" ]]; then \
		docker build --no-cache -t nanobox/mac-env -f Dockerfile.mac-env .;\
	fi

windows-env:
	if [[ ! $$(docker images nanobox/windows-env) =~ "nanobox/windows-env" ]]; then \
		docker build --no-cache -t nanobox/windows-env -f Dockerfile.windows-env .; \
	fi

mac: clean-mac mac-env
	./script/build-mac

windows: clean-windows windows-env
	./script/build-windows

clean-mac:
	rm -f dist/mac/Nanobox*.pkg

clean-windows:
	rm -f dist/windows/Nanobox*.exe

certs:
	aws s3 sync \
		s3://private.nanobox.io/certs \
		certs/ \
		--region us-west-2

publish:
	aws s3 sync \
		dist/ \
		s3://tools.nanobox.io/installers/v1 \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
