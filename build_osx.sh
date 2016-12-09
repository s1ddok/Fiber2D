MACOSX_DEPLOYMENT_TARGET=10.11 swift build -Xlinker -lz \
-Xswiftc -Iexternal/SwiftBGFX/.build/debug \
-Xlinker -Lexternal/SwiftBGFX/.build/debug \
-Xlinker -lSwiftBGFX \
-Xlinker -framework -Xlinker Metal -Xlinker -framework -Xlinker Quartz \
-Xlinker -framework -Xlinker MetalKit \
-Xcc -DCP_USE_CGTYPES=0
