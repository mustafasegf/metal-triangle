APP_NAME = triangle

SRC = main.m
SHADERS = shader

FRAMEWORKS = -framework Cocoa -framework Metal -framework MetalKit

all: $(APP_NAME)

$(APP_NAME): $(SRC) $(SHADERS).metal
	xcrun -sdk macosx metal -c $(SHADERS).metal -o $(SHADERS).air
	xcrun -sdk macosx metallib $(SHADERS).air -o $(SHADERS).metallib
	clang $(SRC) -o $(APP_NAME) $(FRAMEWORKS) -fobjc-arc

clean:
	rm -f $(APP_NAME) $(SHADERS).air $(SHADERS).metallib

