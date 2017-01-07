# Fiber2D

[![Join the chat at https://gitter.im/Fiber2D/Lobby](https://badges.gitter.im/Fiber2D/Lobby.svg)](https://gitter.im/Fiber2D/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

![Swift Version](https://img.shields.io/badge/swift-3.0.2-green.svg?style=flat)
![Build State](https://img.shields.io/wercker/ci/wercker/docs.svg)
![Target Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20linux%20%7C%20Android%20-lightgrey.svg)

This project originated as [cocos2d-objc](https://github.com/cocos2d/cocos2d-objc) rewrite to Swift. As I stopped commiting to the repo since June, because Obj-C is dead for me. 

This is still in a very **alpha state**, but you already can build some games with it, even though it may be unpleasant process as I change API almost every day. The project served as `.dylib` (`.so` on `Linux`/`Android`) that builds by Swift Package Manager. It requires some project config in order to use it, but you can experiment with the demo provided in the repo.
*Generally the project should be considered unstable and most of the API is likely to be changed.*

## Basement 
We worked hard before starting this project and it relies on several self-made libs we made:
* [SwiftMath](https://github.com/SwiftGFX/SwiftMath) ([@s1ddok](https://github.com/s1ddok), [@stuartcarnie](https://github.com/stuartcarnie))
* [SwiftBGFX](https://github.com/SwiftGFX/SwiftBGFX) ([@stuartcarnie](https://github.com/stuartcarnie))

Thanks to them we currently have:
* Ultra fast cross-platform math lib, that works with `SIMD` on `Darwin` platforms and has self-implemnted algorithms to run on `Glibc` based environment. Not speaking of **zero ARC** impact and modern swifty syntax features.
* Modern agnostic renderer, which works with following list of backends **out of the box**:
  * Direct3D 9, 11, 12
  * Metal
  * OpenGL 2.1, 3.1+, ES 2, ES 3.1
  * WebGL 1.0, 2.0

### What it looks like?
Currently this repo only contains demos for `Linux`, `Android` and `macOS`. `macOS demo` can use both `MetalKit` and `SDL`, it also can seamlessly be ported to `iOS` and `tvOS`, but developing is easier with desktop executables. `Linux` and `Android` demos can only be compiled with `SDL`, hence only `GL` rendering backend is available.

You can get the idea from this GIF: 
![Fiber2D Demo Gif](http://imgur.com/CP6d9kT.gif)

# Goals (updated 29 DEC 2016)
My goals for the near future are (order means nothing):

* **Port to `Windows`**
* Introduce basic `UI components` (Button, Slider, Label)
* Introduce GPU computed `Particle systems` 
* **Drop the concept of `contentScale` and use `one set of assets` for all screen resolutions**
* Add support for more asset format loading from `.jpg` to `.pvr`
* **Add easy post-processing mechanism**

We have a [trello](https://trello.com/b/eUe8CkrW/fiber2d) which I will try to maintain soon.

# Build
## macOS
1. Clone

   ```$ git clone --recursive https://github.com/s1ddok/Fiber2D.git```

2. Call helper script, that will do all the preparation stuff for you. (You have to have `ninja build` installed)

   ```
   cd external/SwiftBGFX
   sh prepare_bgfx_macos.sh
   ```

3. Open demo XCode project, compile and run. You should see the demo yourself.

## iOS

1. Clone, build `bgfx` for `iOS`
2. ``` make xcodeproj-ios ```
3. Open demo XCode project, compile and run. 

# Contributors 

* [@stuartcarnie](https://github.com/stuartcarnie) did initial setup of the bgfx renderer along with general support on how to use it
* [@gonzalolarralde](https://github.com/gonzalolarralde) helped with Android port of libDispatch/libFoundation and Fiber2D itself.

# Questions

You can reach me on twitter ([@s1ddok](https://twitter.com/s1ddok)) or by e-mail in my profile.

# LICENSE (BSD 2-clause)

All parts in this package (Fiber2D, SwiftMath, SwiftBGFX and bgfx itself) use the same license. 

Copyright 2016 Andrey Volodin. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
