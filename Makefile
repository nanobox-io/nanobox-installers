SHELL := /bin/bash
VIRTUALBOX_VERSION := 5.1.12
VIRTUALBOX_REVISION := 112440

.PHONY: mac windows mac-bundle windows-bundle clean clean-mac clean-mac-bundle clean-windows clean-windows-bundle publish publish-beta certs windows-env mac-env

default: mac windows mac-bundle windows-bundle
	@true

clean: clean-mac clean-mac-bundle clean-windows-bundle clean-windows
	@true

mac-env:
	if [[ ! $$(docker images nanobox/mac-env) =~ "nanobox/mac-env" ]]; then \
		docker build --no-cache -t nanobox/mac-env -f Dockerfile.mac-env .;\
	fi

windows-env:
	if [[ ! $$(docker images nanobox/windows-env) =~ "nanobox/windows-env" ]]; then \
		docker build --no-cache -t nanobox/windows-env -f Dockerfile.windows-env .; \
	fi

mac: clean-mac mac-env certs
	./script/build-mac

mac-bundle: clean-mac-bundle mac-env virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg certs
	./script/build-mac-bundle

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg"

windows: clean-windows windows-env certs
	./script/build-windows

windows-bundle: clean-windows-bundle windows-env virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe certs
	./script/build-windows-bundle

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe"

clean-mac:
	if [[ -f dist/mac/Nanobox.pkg ]]; then rm -f dist/mac/Nanobox.pkg; fi

clean-mac-bundle:
	if [[ -f dist/mac/NanoboxBundle.pkg ]]; then rm -f dist/mac/NanoboxBundle.pkg; fi

clean-windows:
	if [[ -f dist/windows/NanoboxSetup.exe ]]; then rm -f dist/windows/NanoboxSetup.exe; fi

clean-windows-bundle:
	if [[ -f dist/windows/NanoboxBundleSetup.exe ]]; then rm -f dist/windows/NanoboxBundleSetup.exe; fi

certs:
	mkdir -p certs
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