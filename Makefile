FUTHARK ?= futhark
PROGRAM := programs/main.fut
TEST_DIR := tests
BIN := bin/main

DOCKER_IMAGE := thuli:latest
DOCKER_CACHE_DIR ?= /lm/users/arul/docker-cache/thuli
DOCKER ?= /bin/docker

.PHONY: run test compile clean docker-build docker-run docker-test

compile: $(BIN)

$(BIN): $(PROGRAM) lib/github.com/arul/thuli/hello.fut
	mkdir -p bin
	$(FUTHARK) c -o $(BIN) $(PROGRAM)

run: $(BIN)
	./$(BIN) < /dev/null

test:
	$(FUTHARK) test $(TEST_DIR)

clean:
	find programs tests -type f \( -name '*.c' -o -name '*.h' -o -name '*.json' -o -name '*.py' \) -delete
	rm -f programs/main programs/tests/hello_test
	rm -rf bin

docker-build:
	mkdir -p $(DOCKER_CACHE_DIR)
	$(DOCKER) buildx build \
		--cache-from type=local,src=$(DOCKER_CACHE_DIR) \
		--cache-to type=local,dest=$(DOCKER_CACHE_DIR),mode=max \
		--load \
		-t $(DOCKER_IMAGE) \
		.

docker-run:
	$(DOCKER) compose run --rm -T thuli

docker-test:
	$(DOCKER) compose run --rm thuli make test
