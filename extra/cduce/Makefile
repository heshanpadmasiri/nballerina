CDUCE_SRC=$(wildcard *.bal)
CDUCE_JAR=../../build/compiler/extra/bin/nballerina.cduce.jar
COMPILER_PACK=../../build/pack/bala/wso2-nballerina-any-0.1.0.bala
COMPILER_SRC=$(wildcard ../../compiler/*.bal) $(wildcard ../../compiler/modules/*/*.bal)
TARGETS=all clean test

all: $(CDUCE_JAR)

clean:
	rm -f $(CDUCE_JAR)

test: $(COMPILER_PACK)
	bal test

$(CDUCE_JAR): $(CDUCE_SRC) $(COMPILER_PACK)
	bal build --target-dir ../../build/extra $(BAL_BUILD_FLAGS)

$(COMPILER_PACK): $(COMPILER_SRC)
	$(MAKE) -C ../.. target=pack compiler.d

.PHONY: $(TARGETS)
