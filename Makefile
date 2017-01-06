
SWIFT_FLAGS_COMMON = -Xcc -Iexternal/SwiftBGFX/3rdparty/bgfx/3rdparty/khronos \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bx/include \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bgfx/3rdparty \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bx/include/compat/osx \
-Xlinker -lc++ \
-Xlinker -lbgfxDebug -Xlinker -lz \
-Xlinker -framework -Xlinker Foundation \
-Xcc -DCP_USE_CGTYPES=0

IOS_FLAGS = -Xlinker -Lexternal/SwiftBGFX/3rdparty/bgfx/.build/ios-simulator/bin \
-Xlinker -framework -Xlinker OpenGLES -Xlinker -framework -Xlinker UIKit
MACOS_FLAGS = -Xlinker -framework -Xlinker AppKit -Xlinker -framework -Xlinker Quartz \
-Xlinker -Lexternal/SwiftBGFX/3rdparty/bgfx/.build/osx64_clang/bin
CC_FLAGS_METAL = -Xcc -DBGFX_CONFIG_RENDERER_METAL=1
SWIFT_FLAGS_METAL = -Xlinker -framework -Xlinker Metal -Xlinker -framework -Xlinker MetalKit

macos:
	swift build $(SWIFT_FLAGS_COMMON) $(MACOS_FLAGS) $(CC_FLAGS_METAL) $(SWIFT_FLAGS_METAL)

xcodeproj-ios:
	swift package generate-xcodeproj --xcconfig-overrides misc/ios-overrides.xcconfig \
	$(SWIFT_FLAGS_COMMON) $(SWIFT_FLAGS_METAL) $(CC_FLAGS_METAL) $(IOS_FLAGS)

clean:
	swift build --clean

.PHONY: clean xcodeproj-ios macos
