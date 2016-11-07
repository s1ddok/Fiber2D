# Fiber2D

[![Join the chat at https://gitter.im/Fiber2D/Lobby](https://badges.gitter.im/Fiber2D/Lobby.svg)](https://gitter.im/Fiber2D/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

![Swift Version](https://img.shields.io/badge/swift-3.0.1-green.svg?style=flat)
![Build State](https://img.shields.io/wercker/ci/wercker/docs.svg)
![Target Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20linux%20%7C%20Android%20-lightgrey.svg)

This project originated as [cocos2d-objc](https://github.com/cocos2d/cocos2d-objc) rewrite to Swift. As I stopped commiting to the repo since June, because Obj-C is dead for me. 

This is still in a very **proof-of-a-concept** state, where you can't really make any use of it yet. Currently it is served as a barely working demo, which compiles only with XCode and has some tricky prepartions to be done before running (more on this later). Some code parts still smell like Objective-C (some does not, though). *Generally the project is in transition from cocos2d-objc to Swifty style and most of (**all**? :) ) API will change.*

# Name
Why is this not called `cocos2d-swift`. How dare you?!
There are couple of reasons:

1. There already was the `cocos2d-swift`. Apportable used this name for cocos2d-objc v3.0+ and most of the google results are related to that. I don't want to create any confusion.
2. While I have a commit-access to `cocos2d-objc` repo, I dont think Ricardo and the whole cocos2d team will appreciate it if I remove cocos2d-objc and replace it with barely working Swifty prototype. 

*cocos2d-objc is still very good for Apple only development, I use it everyday and provide support on forum, it is not dead, we just don't work on the new features anymore*

## Basement 
We worked hard before starting this project and it relies on several self-made libs we made:
* [SwiftMath](https://github.com/SwiftGFX/SwiftMath) ([@s1ddok](https://github.com/s1ddok), [@stuartcarnie](https://github.com/stuartcarnie))
* [SwiftBGFX](https://github.com/SwiftGFX/SwiftBGFX) ([@stuartcarnie](https://github.com/stuartcarnie))

Thanks to them we currently have:
* Ultra fast cross-platform math lib, that works with `SIMD` on `Darwin` platforms and has self-implemnted algorithms to run on `Glibc` based environment. Not speaking of **zero ARC** impact and modern swifty syntax features.
* Modern agnostic renderer, which works with following list of backends **out of the box**:
  * Direct3D 9, 11, 12 (WIP)
  * Metal (WIP)
  * OpenGL 2.1, 3.1+, ES 2, ES 3.1
  * WebGL 1.0, 2.0
 
# Current state of implementation
Alright, cool. But what do we have now?

What is done so far:
* Converted cocos2d core:
   * `Responder`, `Node`, `Scene graph`, `Director`, `SpriteFrame`/`Texture` (+ Caches), `ColorNode`, `Sprite` (+ 9 slice), `File handling` (only `.png`), `Layout`
*  `libpng` Swift bindings to load and scale `png`s on the fly
*  Implemented Swift bindings to `Chipmunk2D` physics engine (Not finished)
*  Implemented *hello-world* `bgfx renderer`
   * Render texture (done)
   * Viewport node (WIP)
* Scheduling, including **new Action API**, that has *zero ARC* impact and modern syntax as well.
* Prototype of a feature component system.
  * Physics already work as a pluggable component, adding custom scripting behaviour is possible already too, but the whole API must be reconsidered.

### What it looks like?
Currently we have only `macOS` demo for the ease of development, but it will seamlessly port to `iOS` and `tvOS` as it uses `MetalKit` for now (GL support will land later). `Linux` and `Android` are a bit more complicated, but 85% of existing code base is x-platform, what is more important: other 15% is **possible to convert today** (more on this later).

You can get the idea from this GIF: 
![Fiber2D Demo Gif](http://imgur.com/CP6d9kT.gif)


# Goals
My goals for the near future are (order means nothing):

* Migrate to **SwiftPM project structure completely**, drop XCode as a heart of the project
  * Introduce `CChipmunk`, `Clibpng`, etc
* Fully drop inheriting based structure by finishing `Component/System` code
* **Port to `Linux` using `SDL` for Windowing and Input handle (first step on the way to `Android`)** (remember those 15%?)
* Remove code parts that has `Obj-C smell` (this includes making the whole API more Swifty, moving forward to `protocol-obsessed` world)
* **Add `FreeType 2` support for cross-platform text rendering**
* Add `imgui` support for cross-platform debug UI rendering
* Introduce basic `UI components` (Button, Slider)
* **Introduce event system**
* Cover code with `tests`
* **`Abstract input layer`**
* **Introduce `Responder Component` and drop the need of overriding `touch***/mouse***` methods**
* Add `compute shader` support
* Introduce GPU computed `Particle systems`
* Add support of cross-platform shader loading from `shaderc` 
* **Add support of `custom shader uniforms`**
* **Introduce `data-driven Material/Technique/Pass render model` with multi-pass rendering for post-processing effects**
* **Drop `RenderableNode` concept and use `Geometry Component` instead**
* **Drop the concept of `contentScale` and use `one set of assets` for all screen resolutions**
* Add support for more asset format loading from `.jpg` to `.pvr`

We have a [trello](https://trello.com/b/eUe8CkrW/fiber2d) which I will try to maintain soon.

# Build
Okay, so how we build this monster? I tried to simplify the whole process for you, so the steps are:

1. Clone

   ```$ git clone --recursive https://github.com/s1ddok/Fiber2D.git```
   
2. Go to `/external/SwiftBGFX/3rdparty/bgfx/src`

3. In `bgfx.cpp` change:

```
-#    define BGFX_CHECK_RENDER_THREAD() BX_CHECK(BGFX_MAIN_THREAD_MAGIC != s_threadIndex, "Must be called from render thread.")
+#    define BGFX_CHECK_RENDER_THREAD() BX_CHECK(s_ctx->m_singleThreaded || BGFX_MAIN_THREAD_MAGIC != s_threadIndex, "Must be called from render thread.")
```
   - **Question:** OMG! WHY??? 
   - **Answer:** We are not sure if this is a correct fix yet, but it is required to work for now.
   
4\. Return to root repository and call helper script, that will do all the stuff for you. (You have to have `ninja build` installed)
```
sh prepare_bgfx_macos.sh
```

5\. Open XCode project, compile and run. You should see the demo yourself.

# Contributors 

* [@stuartcarnie](https://github.com/stuartcarnie) did initial setup of the bgfx renderer along with general support on how to use it

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
