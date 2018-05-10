# Project 7: Deferred Renderer

Name: Alexis Ward

PennKey: aleward

Demo Link: [here](https://aleward.github.io/deferred-renderer-aleward/)

**Goal:** Learn an advanced rendering technique using the OpenGL pipeline and apply it to make artistic procedural post-processing effects.

## Post passing data to G-Buffers, basic scene shading, and HDR Tone Mapping
![](base.gif)

## Post-process effects (75 points)
* __Bloom:__

![](bloom.gif)

* __Approximated depth of field:__

![](original.gif)
![](distance.gif)
![](mid-depth.gif)

* __Motion blur:__

There is a very small blur based on changing camera properties:
![](GOOD-camera-motion.gif)

... and a large blur for object motion:
![](GOOD-blur-loop.gif)


## Extra credit (30 points max)
* Dat.GUI

![](gui.png)
