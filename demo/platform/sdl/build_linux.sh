swift build \
-Xswiftc -I../../../.build/debug \
-Xswiftc -I../../../Packages/Cpng-1.0.0/Cpng/include \
-Xswiftc -I../../../Packages/CChipmunk2D-1.0.0/CChipmunk2D/include \
-Xswiftc -I../../../external/SwiftBGFX/.build/debug \
-Xlinker -L../../../.build/debug \
-Xlinker -L../../../external/SwiftBGFX/.build/debug \
-Xlinker -lSwiftMath -Xlinker -lSwiftBGFX -Xlinker -lFiber2D -Xlinker -lGL -Xlinker -lX11

cp ../../../.build/debug/libFiber2D.so .build/debug/libFiber2D.so
cp ../../../.build/debug/libCpng.so .build/debug/libCpng.so
cp ../../../.build/debug/libCChipmunk2D.so .build/debug/libCChipmunk2D.so
cp ../../../external/SwiftBGFX/.build/debug/libCbgfx.so .build/debug/libCbgfx.so
cp ../../../external/SwiftBGFX/.build/debug/libSwiftBGFX.so .build/debug/libSwiftBGFX.so
cp ../../../external/SwiftBGFX/3rdparty/bgfx/.build/linux64_gcc/bin/libbgfxDebug.a \
.build/debug/libbgfxDebug.a
