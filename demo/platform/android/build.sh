cd f2dc
swift build \
-Xcc -I../../../external/SwiftBGFX/3rdparty/bgfx/3rdparty/khronos \
-Xcc -I../../../external/SwiftBGFX/3rdparty/bx/include \
-Xcc -I../../../external/SwiftBGFX/3rdparty/bgfx/3rdparty \
-Xcc -DCP_USE_CGTYPES=0 \
-Xcc     -I$ANDROID_NDK_HOME/platforms/android-21/arch-arm/usr/include \
-Xswiftc -I$ANDROID_NDK_HOME/sources/android/native_app_glue/ \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation/closure \
-Xswiftc -I../android/android-project/jni/SDL2-2.0.5/include \
-Xswiftc -target -Xswiftc armv7-none-linux-androideabi \
-Xswiftc -sdk -Xswiftc $ANDROID_NDK_HOME/platforms/android-21/arch-arm \
-Xswiftc -DNOSIMD \
-Xlinker -L/usr/local/lib/swift/android/ \
-Xlinker -L$ANDROID_SWIFT_SOURCE/build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation/ \
-Xlinker -L$ANDROID_NDK_HOME/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/lib/gcc/arm-linux-androideabi/4.9.x/ \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/lib/armv7-a/ \
-Xlinker -L$ANDROID_LIBICONV/armeabi-v7a \
-Xlinker -L../android/android-project/libs/armeabi-v7a/ \
-Xlinker -L../../../external/SwiftBGFX/3rdparty/bgfx/.build/android-arm/bin \
-Xlinker -lgcc    -Xlinker -ldispatch  -Xlinker -lFoundation \
-Xlinker -latomic -Xlinker -licui18n   -Xlinker -licuuc \
-Xlinker -lc++_shared -Xlinker -lbgfxDebug -Xlinker -lz \
-Xlinker --sysroot=$ANDROID_NDK_HOME/platforms/android-21/arch-arm/

cp -f .build/debug/libFiber2D.so ../android/android-project/libs/armeabi-v7a/libFiber2D.so
cp -f .build/debug/libf2dc.so ../android/android-project/libs/armeabi-v7a/libf2dc.so
cp -f .build/debug/libCbgfx.so ../android/android-project/libs/armeabi-v7a/libCbgfx.so
cp -f .build/debug/libCpng.so ../android/android-project/libs/armeabi-v7a/libCpng.so
cp -f .build/debug/libCChipmunk2D.so ../android/android-project/libs/armeabi-v7a/libCChipmunk2D.so
