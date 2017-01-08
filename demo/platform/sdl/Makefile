SHARED_FLAGS = -Xlinker -lFiber2D \
-Xswiftc -I../../../.build/debug \
-Xswiftc -I../../../external/Cpng/Cpng/include \
-Xswiftc -I../../../external/CChipmunk2D/CChipmunk2D/include \
-Xlinker -L../../../.build/debug \
-Xcc -DCP_USE_CGTYPES=0

MACOS_SDL_FLAGS = -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib
LINUX_SDL_FLAGS = -Xswiftc -I/usr/include \
-Xlinker -L/usr/lib -Xlinker -lGL -Xlinker -lX11

macos:
	swift build $(SHARED_FLAGS) $(MACOS_SDL_FLAGS)
	cp ../../../.build/debug/*.dylib .build/debug

xcodeproj-macos:
	swift package $(SHARED_FLAGS) $(MACOS_SDL_FLAGS) \
	generate-xcodeproj

.PHONY: macos
