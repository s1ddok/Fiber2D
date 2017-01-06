
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
ANDROID_FLAGS = -Xswiftc -I$ANDROID_NDK_HOME/sources/android/native_app_glue/ \
-Xcc     -I$ANDROID_NDK_HOME/platforms/android-21/arch-arm/usr/include \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation/closure \
-Xswiftc -target -Xswiftc armv7-none-linux-androideabi \
-Xswiftc -sdk -Xswiftc $ANDROID_NDK_HOME/platforms/android-21/arch-arm \
-Xcc -target -Xcc armv7-none-linux-androideabi \
-Xcc -B -Xcc $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin/ \
-Xcc --sysroot=$ANDROID_NDK_HOME/platforms/android-21/arch-arm/ \
-Xlinker -L/usr/local/lib/swift/android/ \
-Xlinker -L$ANDROID_SWIFT_SOURCE/build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation/ \
-Xlinker -L$ANDROID_NDK_HOME/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/lib/gcc/arm-linux-androideabi/4.9.x/ \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/lib/armv7-a/ \
-Xlinker -L$ANDROID_LIBICONV/armeabi-v7a \
-Xlinker -lgcc        -Xlinker -lc++    -Xlinker -ldispatch \
-Xlinker -lFoundation -Xlinker -latomic -Xlinker -licui18n  \
-Xlinker -licuuc \
-Xlinker --sysroot=$ANDROID_NDK_HOME/platforms/android-21/arch-arm/

CC_FLAGS_METAL = -Xcc -DBGFX_CONFIG_RENDERER_METAL=1
SWIFT_FLAGS_METAL = -Xlinker -framework -Xlinker Metal -Xlinker -framework -Xlinker MetalKit

macos:
	swift build $(SWIFT_FLAGS_COMMON) $(MACOS_FLAGS) $(CC_FLAGS_METAL) $(SWIFT_FLAGS_METAL)

android:
	swift build $(SWIFT_FLAGS_COMMON) $(ANDROID_FLAGS)

xcodeproj-ios:
	swift package generate-xcodeproj --xcconfig-overrides misc/ios-overrides.xcconfig \
	$(SWIFT_FLAGS_COMMON) $(SWIFT_FLAGS_METAL) $(CC_FLAGS_METAL) $(IOS_FLAGS)

clean:
	swift build --clean

.PHONY: clean xcodeproj-ios macos android
