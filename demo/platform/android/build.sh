cd f2dc
swift build \
\ # INCLUDE SECTION
-Xswiftc -I$ANDROID_NDK_HOME/sources/android/native_app_glue/ \
-Xcc     -I$ANDROID_NDK_HOME/platforms/android-21/arch-arm/usr/include \
-Xswiftc -I../../../../.build/debug \
-Xswiftc -I../../../../.build/checkouts/Cpng--1187074719251419583/Cpng/include \ # Sorry for this, there is no better way for now
-Xswiftc -I../../../../.build/checkouts/CChipmunk2D-5254365140957283169/CChipmunk2D/include \
-Xswiftc -I../../../../external/SwiftBGFX/.build/debug \
-Xswiftc -I../android-project/jni/SDL2-2.0.5/include \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation \
-Xswiftc -I$ANDROID_SWIFT_SOURCE/swift-corelibs-foundation/closure \
\ # SWIFTC SECTION
-Xswiftc -target -Xswiftc armv7-none-linux-androideabi \
-Xswiftc -sdk -Xswiftc $ANDROID_NDK_HOME/platforms/android-21/arch-arm \
-Xswiftc -DNOSIMD \
\ # CC SECTION
-Xcc -target -Xcc armv7-none-linux-androideabi \
-Xcc -B -Xcc $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin/ \
-Xcc --sysroot=$ANDROID_NDK_HOME/platforms/android-21/arch-arm/ \
\ # LINKER SECTION
-Xlinker -L/usr/local/lib/swift/android/ \ # Path to libDispatch
-Xlinker -L$ANDROID_SWIFT_SOURCE/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation/ \ # Path to libFoundation
-Xlinker -L$ANDROID_NDK_HOME/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/lib/gcc/arm-linux-androideabi/4.9.x/ \
-Xlinker -L$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/lib/armv7-a/ \
-Xlinker -L$ANDROID_LIBICONV/armeabi-v7a \
-Xlinker -L../../../../.build/debug \
-Xlinker -L../../../../external/SwiftBGFX/.build/debug \
-Xlinker -L../android-project/libs/armeabi-v7a \
-Xlinker -lgcc        -Xlinker -lc++     -Xlinker -ldispatch  \
-Xlinker -lFoundation -Xlinker -latomic  -Xlinker -lSwiftMath \
-Xlinker -lSwiftBGFX  -Xlinker -lFiber2D -Xlinker -licui18n   \
-Xlinker -licuuc \
-Xlinker --sysroot=$ANDROID_NDK_HOME/platforms/android-21/arch-arm/ # This does not work for now and requires a hack for clang


