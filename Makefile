SHELL := /bin/bash
VIRTUALBOX_VERSION := 5.1.10
VIRTUALBOX_REVISION := 112026

.PHONY: mac windows clean clean-mac clean-windows publish publish-beta certs windows-env mac-env

default: mac windows publish
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

mac: clean-mac mac-env mac/mpkg/nanobox.pkg/Scripts virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg certs
	./script/build-mac

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg"


mac/mpkg/nanobox.pkg/Scripts:
	cd mac; echo "scripts/postinstall" | cpio -o --format odc | gzip -c > mpkg/nanobox.pkg/Scripts

windows: clean-windows windows-env virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe certs
	./script/build-windows

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe"

clean-mac:
	rm -f dist/mac/Nanobox*.pkg
	rm -f mac/mpkg/nanobox.pkg/Scripts

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

publish-beta:
	aws s3 sync \
		dist/ \
		s3://tools.nanobox.io/installers/beta \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1