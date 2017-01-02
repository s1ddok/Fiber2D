MACOSX_DEPLOYMENT_TARGET=10.11 swift build \
-Xcc -DCP_USE_CGTYPES=0 -Xcc -DBGFX_CONFIG_RENDERER_METAL=1 \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bgfx/3rdparty/khronos \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bx/include \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bgfx/3rdparty \
-Xcc -Iexternal/SwiftBGFX/3rdparty/bx/include/compat/osx \
-Xcc -fno-objc-arc -Xlinker -lc++ \
-Xlinker -lbgfxDebug -Xlinker -lz \
-Xlinker -framework -Xlinker Foundation \
-Xlinker -framework -Xlinker AppKit \
-Xlinker -Lexternal/SwiftBGFX/3rdparty/bgfx/.build/osx64_clang/bin #\
#-Xlinker -framework -Xlinker Metal -Xlinker -framework -Xlinker Quartz \
#-Xlinker -framework -Xlinker MetalKit

