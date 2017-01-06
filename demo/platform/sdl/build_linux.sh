swift build \
-Xswiftc -I../../../.build/debug \
-Xswiftc -I../../../Packages/Cpng-1.0.0/Cpng/include \
-Xswiftc -I../../../Packages/CChipmunk2D-1.0.0/CChipmunk2D/include \
-Xlinker -L../../../.build/debug \
-Xlinker -lSwiftMath -Xlinker -lSwiftBGFX -Xlinker -lFiber2D -Xlinker -lGL -Xlinker -lX11

cp ../../../.build/debug/libFiber2D.so .build/debug/libFiber2D.so
cp ../../../.build/debug/libCpng.so .build/debug/libCpng.so
cp ../../../.build/debug/libCChipmunk2D.so .build/debug/libCChipmunk2D.so
cp ../../../.build/debug/libCbgfx.so .build/debug/libCbgfx.so
cp ../../../.build/debug/libSwiftBGFX.so .build/debug/libSwiftBGFX.so
