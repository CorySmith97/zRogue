
           ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
           ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
             ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗  
            ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝  
           ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
           ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝
                                                     
                                                     
=== UPDATES ===
zRogue is currently undergoing updates to the master branch of zig. Not all 
features may work as intended.


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
In order to build you need to have zig 0.12.1. Along with the latest version 
of zig, you need to have SDL2 downloaded as a system library. Additionally 
you will need to have lib epoxy downloaded and in the system libraries. 

