FUTHARK ?= futhark
PROGRAM := programs/main.fut
TEST_DIR := tests
BIN := bin/main
LIB := lib/github.com/ArulselvanMadhavan/thuli
LIB_SOURCES := $(wildcard $(LIB)/*.fut)

DOCKER_IMAGE := thuli:latest
DOCKER_CACHE_DIR ?= /lm/users/arul/docker-cache/thuli
DOCKER ?= /bin/docker

OPAMROOT ?= /lm/users/arul/.opam
OCAML_SWITCH ?= 5.5.0
OPAM_ENV = eval $$(OPAMROOT=$(OPAMROOT) opam env --switch=$(OCAML_SWITCH))

KRON_LIB := bin/libkron
KRON_FUT := programs/kron.fut
OCAML_KRON_C := ocaml/thuli/kron.c

.PHONY: run test compile check check-changed clean docker-build docker-run docker-test kron-lib ocaml ocaml-run perf-ocaml

compile: $(BIN)

kron-lib: $(KRON_LIB).c $(OCAML_KRON_C)

$(KRON_LIB).c: $(KRON_FUT) $(LIB_SOURCES)
	mkdir -p bin
	$(FUTHARK) c --library -o $(KRON_LIB) $(KRON_FUT)

$(OCAML_KRON_C): $(KRON_LIB).c
	cp $(KRON_LIB).c $(OCAML_KRON_C)

ocaml: kron-lib
	$(OPAM_ENV) && cd ocaml && dune build

ocaml-run: ocaml
	$(OPAM_ENV) && cd ocaml && dune exec ./bin/main.exe

perf-ocaml:
	./scripts/perf-ocaml.sh record --build

$(BIN): $(PROGRAM) $(LIB_SOURCES)
	mkdir -p bin
	$(FUTHARK) c -o $(BIN) $(PROGRAM)

run: $(BIN)
	./$(BIN) < /dev/null

test:
	$(FUTHARK) test $(TEST_DIR)

check:
	@test -n '$(FILE)' || { echo 'Usage: make check FILE=path/to/file.fut'; exit 1; }
	$(FUTHARK) check $(FILE)

check-changed:
	@files="$$( { git diff --name-only HEAD -- '*.fut'; git diff --cached --name-only -- '*.fut'; git ls-files --others --exclude-standard -- '*.fut'; } \
	  | sort -u \
	  | grep -v '/\.#' \
	  | while read -r f; do [ -f "$$f" ] && printf '%s\n' "$$f"; done )"; \
	if [ -z "$$files" ]; then \
	  echo 'No changed .fut files.'; \
	  exit 0; \
	fi; \
	for f in $$files; do \
	  echo "==> $$f"; \
	  $(MAKE) check FILE="$$f" || exit 1; \
	done

clean:
	find programs tests -type f \( -name '*.c' -o -name '*.h' -o -name '*.json' -o -name '*.py' \) -delete
	rm -f programs/main programs/tests/main_test
	rm -rf bin
	rm -f ocaml/thuli/kron.c
	cd ocaml && dune clean 2>/dev/null || true

docker-build:
	mkdir -p $(DOCKER_CACHE_DIR)
	$(DOCKER) buildx build \
		--cache-from type=local,src=$(DOCKER_CACHE_DIR) \
		--cache-to type=local,dest=$(DOCKER_CACHE_DIR),mode=max \
		--load \
		-t $(DOCKER_IMAGE) \
		.

docker-run:
	$(DOCKER) compose run --rm thuli

docker-test:
	$(DOCKER) compose run --rm thuli make test
