./shaderc -f f2d_builtin_postexture.sc --platform osx \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_postex_mtl.bin --bin2c --type fragment -p metal

./shaderc -f f2d_builtin_postexture.sc --platform linux \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_postex_gl.bin --bin2c --type fragment

./shaderc -f f2d_builtin_poscolor.sc --platform osx \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_poscolor_mtl.bin --bin2c --type fragment -p metal

./shaderc -f f2d_builtin_poscolor.sc --platform linux \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_poscolor_gl.bin --bin2c --type fragment

./shaderc -f f2d_builtin_vertex.sc --platform osx \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_vertex_mtl.bin --bin2c --type vertex -p metal

./shaderc -f f2d_builtin_vertex.sc --platform linux \
--varyingdef varying.def.sc -i ../external/SwiftBGFX/3rdparty/bgfx/src \
-o f2d_vertex_gl.bin --bin2c --type vertex
