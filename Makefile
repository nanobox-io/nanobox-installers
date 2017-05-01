SHELL := /bin/bash
INSTALLER_VERSION := 2
NANOBOX_VERSION := 2
VIRTUALBOX_VERSION := 5.1.14
VIRTUALBOX_REVISION := 112924
DOCKER_MACHINE_VERSION := 0.8.2

.PHONY: mac windows mac-bundle windows-bundle clean clean-mac clean-mac-bundle clean-windows clean-windows-bundle publish publish-beta certs urls

default: mac windows mac-bundle windows-bundle arch centos debian generic-linux
	@true

.PHONY: from/arch from/centos from/debian from/generic-linux from/mac from/windows

from/arch:
	docker pull base/archlinux

from/centos:
	docker pull centos:7

from/debian:
	docker pull debian:jessie

from/generic-linux: from/debian

from/mac: from/debian

from/windows: from/debian

.PHONY: env/arch env/centos env/debian env/generic-linux env/mac env/windows

env/arch: Dockerfile.arch-env from/arch
	docker build -t nanobox/arch-env -f Dockerfile.arch-env .

env/centos: Dockerfile.centos-env from/centos
	docker build -t nanobox/centos-env -f Dockerfile.centos-env .

env/debian: Dockerfile.debian-env from/debian
	docker build -t nanobox/debian-env -f Dockerfile.debian-env .

env/generic-linux: Dockerfile.generic-linux-env from/generic-linux
	docker build -t nanobox/generic-linux-env -f Dockerfile.generic-linux-env .

env/mac: Dockerfile.mac-env from/mac
	docker build -t nanobox/mac-env -f Dockerfile.mac-env .

env/windows: Dockerfile.windows-env from/windows
	docker build -t nanobox/windows-env -f Dockerfile.windows-env .

.PHONY: clean-images clean-nanobox-arch-env clean-nanobox-centos-env clean-nanobox-debian-env clean-nanobox-generic-linux-env clean-nanobox-mac-env clean-nanobox-windows-env clean-nanobox-arch-installer clean-nanobox-centos-installer clean-nanobox-debian-installer clean-nanobox-generic-linux-installer clean-nanobox-mac-installer clean-nanobox-mac-bundle-installer clean-nanobox-windows-installer clean-nanobox-windows-bundle-installer

clean-images: clean-nanobox-arch-env clean-nanobox-centos-env clean-nanobox-debian-env clean-nanobox-generic-linux-env clean-nanobox-mac-env clean-nanobox-windows-env

clean-nanobox-arch-installer:
	docker rmi nanobox/arch-installer || true

clean-nanobox-centos-installer:
	docker rmi nanobox/centos-installer || true

clean-nanobox-debian-installer:
	docker rmi nanobox/debian-installer || true

clean-nanobox-generic-linux-installer:
	docker rmi nanobox/generic-linux-installer || true

clean-nanobox-mac-installer:
	docker rmi nanobox/mac-installer || true

clean-nanobox-mac-bundle-installer:
	docker rmi nanobox/mac-bundle-installer || true

clean-nanobox-windows-installer:
	docker rmi nanobox/windows-installer || true

clean-nanobox-windows-bundle-installer:
	docker rmi nanobox/windows-bundle-installer || true

clean-nanobox-arch-env: clean-nanobox-arch-installer
	docker rmi nanobox/arch-env || true

clean-nanobox-centos-env: clean-nanobox-centos-installer
	docker rmi nanobox/centos-env || true

clean-nanobox-debian-env: clean-nanobox-debian-installer
	docker rmi nanobox/debian-env || true

clean-nanobox-generic-linux-env: clean-nanobox-generic-linux-installer
	docker rmi nanobox/generic-linux-env || true

clean-nanobox-mac-env: clean-nanobox-mac-installer clean-nanobox-mac-bundle-installer
	docker rmi nanobox/mac-env || true

clean-nanobox-windows-env: clean-nanobox-windows-installer clean-nanobox-windows-bundle-installer
	docker rmi nanobox/windows-env || true

clean: clean-mac clean-mac-bundle clean-windows-bundle clean-windows clean-arch clean-centos clean-debian clean-generic-linux
	for i in $$(docker images -f "dangling=true" --format {{.ID}}); do docker rmi $$i || true; done

mac: clean-mac env/mac certs
	./script/build-mac ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

mac-bundle: clean-mac-bundle env/mac virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg certs
	./script/build-mac-bundle ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg"

windows: clean-windows env/windows certs
	./script/build-windows ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

windows-bundle: clean-windows-bundle env/windows virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe certs
	./script/build-windows-bundle ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe"

centos: clean-centos env/centos
	./script/build-centos ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

debian: clean-debian env/debian
	./script/build-debian ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

arch: clean-arch env/arch
	./script/build-arch ${INSTALLER_VERSION} ${NANOBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

generic-linux: clean-generic-linux env/generic-linux
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

.PHONY: publish-arch publish-centos publish-debian publish-generic-linux publish-mac publish-mac-bundle publish-windows publish-windows-bundle

publish-arch:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz

publish-centos:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm

publish-debian:
	aws s3 cp \
		dist/linux/nanobox_${INSTALLER_VERSION}_amd64.deb \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox_${INSTALLER_VERSION}_amd64.deb \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/linux/nanobox_${INSTALLER_VERSION}_amd64.deb

publish-generic-linux:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}.tar.gz \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}.tar.gz \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/linux/nanobox-${INSTALLER_VERSION}.tar.gz

publish-mac:
	aws s3 cp \
		dist/mac/Nanobox.pkg \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/mac/Nanobox.pkg \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/mac/Nanobox.pkg

publish-mac-bundle:
	aws s3 cp \
		dist/mac/NanoboxBundle.pkg \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/mac/NanoboxBundle.pkg \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/mac/NanoboxBundle.pkg

publish-windows:
	aws s3 cp \
		dist/windows/NanoboxSetup.exe \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/windows/NanoboxSetup.exe \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/windows/NanoboxSetup.exe

publish-windows-bundle:
	aws s3 cp \
		dist/windows/NanoboxBundleSetup.exe \
		s3://tools.nanobox.io/installers/v${INSTALLER_VERSION}/windows/NanoboxBundleSetup.exe \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation \
		--distribution-id E1O0D0A2DTYRY8 \
		--paths /installers/v${INSTALLER_VERSION}/windows/NanoboxBundleSetup.exe

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

publish-beta-arch:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz \
		s3://tools.nanobox.io/installers/beta/linux/nanobox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-centos:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm \
		s3://tools.nanobox.io/installers/beta/linux/nanobox-${INSTALLER_VERSION}-1.x86_64.rpm \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-debian:
	aws s3 cp \
		dist/linux/nanobox_${INSTALLER_VERSION}_amd64.deb \
		s3://tools.nanobox.io/installers/beta/linux/nanobox_${INSTALLER_VERSION}_amd64.deb \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-generic-linux:
	aws s3 cp \
		dist/linux/nanobox-${INSTALLER_VERSION}.tar.gz \
		s3://tools.nanobox.io/installers/beta/linux/nanobox-${INSTALLER_VERSION}.tar.gz \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-mac:
	aws s3 cp \
		dist/mac/Nanobox.pkg \
		s3://tools.nanobox.io/installers/beta/mac/Nanobox.pkg \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-mac-bundle:
	aws s3 cp \
		dist/mac/NanoboxBundle.pkg \
		s3://tools.nanobox.io/installers/beta/mac/NanoboxBundle.pkg \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-windows:
	aws s3 cp \
		dist/windows/NanoboxSetup.exe \
		s3://tools.nanobox.io/installers/beta/windows/NanoboxSetup.exe \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

publish-beta-windows-bundle:
	aws s3 cp \
		dist/windows/NanoboxBundleSetup.exe \
		s3://tools.nanobox.io/installers/beta/windows/NanoboxBundleSetup.exe \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1


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
