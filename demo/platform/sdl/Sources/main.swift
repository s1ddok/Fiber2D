import CSDL2
import SwiftMath

let window = Window(title: "Fiber2D-SDL", origin: .zero, size: Size(1024, 768), flags: [.shown])

var event = SDL_Event()
while true {
    SDL_WaitEvent(&event)
}
