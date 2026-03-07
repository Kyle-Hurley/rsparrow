# rsparrow package Makefile
# Run from repo root: /home/kp/Documents/projects/rsparrow-master/

R_LIBS_USER  = /home/kp/R/libs
CHECK_ENV    = R_LIBS=$(R_LIBS_USER) _R_CHECK_FORCE_SUGGESTS_=false
PKG_DIR      = RSPARROW_master
PKG_NAME     = rsparrow
PKG_VERSION  = 2.1.0
TARBALL      = $(PKG_NAME)_$(PKG_VERSION).tar.gz

.PHONY: check test build document install clean help

help:
	@echo "rsparrow build targets:"
	@echo "  make check     — R CMD check (CRAN compliance + tests)"
	@echo "  make test      — Run testthat tests (installs first)"
	@echo "  make build     — Build package tarball"
	@echo "  make document  — Rebuild roxygen2 docs and NAMESPACE"
	@echo "  make install   — Build and install to R_LIBS"
	@echo "  make clean     — Remove build artifacts"

## Run R CMD check with correct environment and flags
check:
	$(CHECK_ENV) R CMD check --no-build-vignettes $(PKG_DIR)/

## Run testthat tests (installs package first)
test: install
	R_LIBS=$(R_LIBS_USER) Rscript -e "testthat::test_package('$(PKG_NAME)')"

## Build package tarball (--no-build-vignettes: some Suggests may be absent)
build:
	R CMD build --no-build-vignettes $(PKG_DIR)/

## Rebuild roxygen2 documentation and NAMESPACE
document:
	R_LIBS=$(R_LIBS_USER) Rscript -e "roxygen2::roxygenise('$(PKG_DIR)/')"

## Install package to R_LIBS_USER
install: build
	R_LIBS=$(R_LIBS_USER) R CMD INSTALL $(TARBALL)

## Remove build artifacts
clean:
	rm -f $(TARBALL)
	rm -rf $(PKG_NAME).Rcheck/
