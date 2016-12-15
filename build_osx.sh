MACOSX_DEPLOYMENT_TARGET=10.11 swift build -Xlinker -lz \
-Xswiftc -Iexternal/SwiftBGFX/.build/debug \
-Xlinker -Lexternal/SwiftBGFX/.build/debug \
-Xlinker -lSwiftBGFX \
-Xcc -DCP_USE_CGTYPES=0 \
-Xswiftc -DF2D_PLATFORM_MTK
