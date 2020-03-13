
export GO111MODULE=on
export GOPROXY=https://proxy.golang.org
export SCOPE_LOG_ROOT_PATH=/dev/null

SHELL := /bin/bash -o pipefail
VERSION_PACKAGE = github.com/replicatedhq/kots/pkg/version
VERSION ?=`git describe --tags --dirty`
DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

GIT_TREE = $(shell git rev-parse --is-inside-work-tree 2>/dev/null)
ifneq "$(GIT_TREE)" ""
define GIT_UPDATE_INDEX_CMD
git update-index --assume-unchanged
endef
define GIT_SHA
`git rev-parse HEAD`
endef
else
define GIT_UPDATE_INDEX_CMD
echo "Not a git repo, skipping git update-index"
endef
define GIT_SHA
""
endef
endif

define LDFLAGS
-ldflags "\
	-X ${VERSION_PACKAGE}.version=${VERSION} \
	-X ${VERSION_PACKAGE}.gitSHA=${GIT_SHA} \
	-X ${VERSION_PACKAGE}.buildTime=${DATE} \
"
endef

BUILDTAGS = containers_image_ostree_stub exclude_graphdriver_devicemapper exclude_graphdriver_btrfs containers_image_openpgp

.PHONY: test
test:
	go test -tags "$(BUILDTAGS)" ./pkg/... ./cmd/... ./ffi/... -coverprofile cover.out

.PHONY: integration-cli
integration-cli:
	go build -o bin/kots-integration ./integration

.PHONY: ci-test
ci-test:
	go test -tags "$(BUILDTAGS)" ./pkg/... ./cmd/... ./ffi/... ./integration/... -coverprofile cover.out

.PHONY: kots
kots: fmt vet
	go build ${LDFLAGS} -o bin/kots -tags "$(BUILDTAGS)" github.com/replicatedhq/kots/cmd/kots

.PHONY: ffi
ffi: fmt vet
	go build ${LDFLAGS} -o bin/kots.so -tags "$(BUILDTAGS)" -buildmode=c-shared ./ffi/...

.PHONY: fmt
fmt:
	go fmt ./pkg/... ./cmd/... ./ffi/...

.PHONY: vet
vet:
	go vet -tags "$(BUILDTAGS)" ./pkg/... ./cmd/... ./ffi/...

.PHONY: gosec
gosec:
	go get github.com/securego/gosec/cmd/gosec
	$(GOPATH)/bin/gosec ./...

.PHONY: snapshot-release
snapshot-release:
	curl -sL https://git.io/goreleaser | VERSION=v0.118.2 bash -s -- --rm-dist --snapshot --config deploy/.goreleaser.snapshot.yml

.PHONY: release
release: export GITHUB_TOKEN = $(shell echo ${GITHUB_TOKEN_REPLICATEDBOT})
release:
	curl -sL https://git.io/goreleaser | VERSION=v0.118.2 bash -s -- --rm-dist --config deploy/.goreleaser.yml
