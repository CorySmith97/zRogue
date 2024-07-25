
           ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
           ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
             ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗  
            ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝  
           ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
           ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝
                                                     
                                                     
=== UPDATES ===
zRogue is currently undergoing updates to the master branch of zig. Not all 
features may work as intended. Any version newer than 0.12.0 should work fine,
(It does in my testing), but it is recommended to use the master branch.
If you need help maintaining the master branch, I recommend using the zig 
version manager zigup. (https://github.com/marler8997/zigup).


This is a library designed to help zig developers build a simple roguelike game in zig.
Wherever possible I am aiming to handle everything in zig. There is however one 
library that will be used is SDL2. The library construction is heavily inspired
by the sokol headers as well as bracket lib. 

=== Library structure ===

There are several modules within the library.

- Image
- Shader
- Window
- Sprite
- Geometry
- algorithms


=== How to use? ===

As of right now the build is only avaible for mac and linux(only tested on 
pop!_os but should run on more distros). 
In order to build you need to have zig 0.12.0 or newer. Along with the latest version 
of zig, you need to have SDL2 downloaded as a system library. Additionally 
you will need to have lib epoxy downloaded and in the system libraries. Please
feel free to have fun with this. It is still a work in progress and will be
changing rapidly (as rapid as I can get stuff out). It is a learning ground
for me, and hopefully it can help at least one other person.


=== Test Build ===

This is my main working branch. It is what runs by default with zig build run.


=== Examples ===

To run the examples run "zig build run-{name of example}"

