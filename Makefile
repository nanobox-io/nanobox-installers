SHELL := /bin/bash
INSTALLER_VERSION := 2
NANOBOX_VERSION := 2
VIRTUALBOX_VERSION := 5.1.14
VIRTUALBOX_REVISION := 112924
DOCKER_MACHINE_VERSION := 0.11.0

.PHONY: mac windows mac-bundle windows-bundle clean clean-mac clean-mac-bundle clean-windows clean-windows-bundle publish publish-beta certs windows-env mac-env urls

default: mac windows mac-bundle windows-bundle arch centos debian generic-linux
	@true

clean: clean-mac clean-mac-bundle clean-windows-bundle clean-windows clean-arch clean-centos clean-debian clean-generic-linux
	for i in $$(docker ps --format {{.Names}}); do docker stop $$i; done
	for i in $$(docker ps -a --format {{.Names}}); do docker rm $$i; done
	for i in $$(docker images -f "dangling=true" --format {{.ID}}); do docker rmi $$i; done

clean-all: clean
	for i in $$(docker images --format {{.ID}}); do docker rmi $$i; done

mac-env:
	if [[ ! $$(docker images nanobox/mac-env) =~ "nanobox/mac-env" ]]; then \
		docker build --no-cache -t nanobox/mac-env -f Dockerfile.mac-env .;\
	fi

windows-env:
	if [[ ! $$(docker images nanobox/windows-env) =~ "nanobox/windows-env" ]]; then \
		docker build --no-cache -t nanobox/windows-env -f Dockerfile.windows-env .; \
	fi

centos-env:
	if [[ ! $$(docker images nanobox/centos-env) =~ "nanobox/centos-env" ]]; then \
		docker build --no-cache -t nanobox/centos-env -f Dockerfile.centos-env .; \
	fi

debian-env:
	if [[ ! $$(docker images nanobox/debian-env) =~ "nanobox/debian-env" ]]; then \
		docker build --no-cache -t nanobox/debian-env -f Dockerfile.debian-env .; \
	fi

arch-env:
	if [[ ! $$(docker images nanobox/arch-env) =~ "nanobox/arch-env" ]]; then \
		docker build --no-cache -t nanobox/arch-env -f Dockerfile.arch-env .; \
	fi

generic-linux-env:
	if [[ ! $$(docker images nanobox/generic-linux-env) =~ "nanobox/generic-linux-env" ]]; then \
		docker build --no-cache -t nanobox/generic-linux-env -f Dockerfile.generic-linux-env .; \
	fi

mac: clean-mac mac-env certs
	./script/build-mac ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

mac-bundle: clean-mac-bundle mac-env virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg certs
	./script/build-mac-bundle ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg"

windows: clean-windows windows-env certs
	./script/build-windows ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

windows-bundle: clean-windows-bundle windows-env virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe certs
	./script/build-windows-bundle ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe"

centos: clean-centos centos-env
	./script/build-centos ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

debian: clean-debian debian-env
	./script/build-debian ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

arch: clean-arch arch-env
	./script/build-arch ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

generic-linux: clean-generic-linux generic-linux-env
	./script/build-generic-linux ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

clean-mac:
	if [[ -f dist/mac/Nanobox.pkg ]]; then rm -f dist/mac/Nanobox.pkg; fi

clean-mac-bundle:
	if [[ -f dist/mac/NanoboxBundle.pkg ]]; then rm -f dist/mac/NanoboxBundle.pkg; fi

clean-windows:
	if [[ -f dist/windows/NanoboxSetup.exe ]]; then rm -f dist/windows/NanoboxSetup.exe; fi

clean-windows-bundle:
	if [[ -f dist/windows/NanoboxBundleSetup.exe ]]; then rm -f dist/windows/NanoboxBundleSetup.exe; fi

clean-centos:
	if [[ -f dist/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm ]]; then rm -f dist/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm; fi

clean-debian:
	if [[ -f dist/linux/nanobox_${INSTALLER_VERSION}_amd64.deb ]]; then rm -f dist/linux/nanobox_${INSTALLER_VERSION}_amd64.deb; fi

clean-arch:
	if [[ -f dist/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz ]]; then rm -f dist/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz; fi

clean-generic-linux:
	if [[ -f dist/linux/nanobox-${INSTALLER_VERSION}.tar.gz ]]; then rm -f dist/linux/nanobox-${INSTALLER_VERSION}.tar.gz; fi

certs:
	mkdir -p certs
	aws s3 sync \
		s3://private.nanobox.io/certs \
		certs/ \
		--region us-west-2

publish:
	aws s3 sync \
		dist/ \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION} \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/mac/Nanobox.pkg /installers/v${INSTALLER_VERSION}/mac/NanoboxBundle.pkg \
		/installers/v${INSTALLER_VERSION}/windows/NanoboxSetup.exe /installers/v${INSTALLER_VERSION}/windows/NanoboxBundleSetup.exe \
		/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm /installers/v${INSTALLER_VERSION}/linux/nanobox_${INSTALLER_VERSION}_amd64.deb \
		/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz /installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}.tar.gz \

publish-beta:
	aws s3 sync \
		dist/ \
		s3://tools.nanobox.io/installers/beta \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

urls:
	@echo S3:
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/mac/Nanobox.pkg
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/mac/NanoboxBundle.pkg
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/windows/NanoboxSetup.exe
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/windows/NanoboxBundleSetup.exe
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox_${INSTALLER_VERSION}_amd64.deb
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz
	@echo https://s3.amazonaws.com/tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}.tar.gz
	@echo CloudFront:
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/mac/Nanobox.pkg
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/mac/NanoboxBundle.pkg
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/windows/NanoboxSetup.exe
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/windows/NanoboxBundleSetup.exe
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/nanobox_${INSTALLER_VERSION}_amd64.deb
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz
	@echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}.tar.gz
