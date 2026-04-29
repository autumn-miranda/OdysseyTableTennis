# Odyssey Table Tennis Core for MiSTer

## General Description

Based on the Template Core for MiSTer. 

This core recreates the behavior of the Magnavox Odyssey's Table Tennis game. You can learn more about the original game here: https://www.odysseynow.org/Games/TableTennis.html

## Features

* Wall centering control
* Adjustable ball speed control
* Translated 3-handed controls to a PS4 controller 


## Control Scheme

Developed on a PS4 controller.

The following are the recommended controls for Joystick Inputs:

Name                            |   Button
--------------------------------|---------------------------------
Horizontal Movement             | Left Joystick
Vertical Movement               | Right Joystick
English (Vertical Blocking)     | R
English (Horizontal Blocking)   | L
Serve                           | Y
Player Position Reset           | A
Wall Left                       | Select
Wall Right                      | Start

### About the Controls

The movement of the player spots is split between the left and right joysticks to emulate the two movement dials on the original controller. The vertical movement is controlled by moving the right joystick vertically, and the horizontal movement is controlled by moving the left joystick horizontally. Holding down the english control will switch the corresponding joystick from the player movement to the ball's vertical movement.

### Original Odyssey Controller
![Original Odyssey Controller](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/OdysseyController.jpg)

### Translated Table Tennis Controls
![Translated Odyssey Controls](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/TableTennisControls.jpg)


## Installation

Copy the *.rbf file onto the FPGA board. Suggested path: /media/fat/_Other/.

## Project History

This re-implementation was developed through a deconstruction of the original Magnavox Odyssey. While the original console's hybrid analog and digital circuity was considered, this re-implementation is based on the behavior of the gameplay. The modularity is loosely based on the actual circuitry, including Spot Generators for the paddles, ball, and center line using the same nominal clock as the original system (NTSC). 

This re-implementation was developed over a three year period from 2023-2026. 

## TO-DO

### Improve Core Accuracy

* Smooth english speed and movement
* Adjust english to be position based instead of speed based
* Refactor modules to be suitable for reuse in other Odyssey game card cores

### Quality of Life / Debug Features

* Mark where ball is when it travels offscreen
* Add total core reset (reset ball and player position)
