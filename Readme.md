# Odyssey Table Tennis core for MiSTer

## General description

Based on the Template Core for MiSTer. 

This core recreates the behavior of the Magnavox Odyssey's Table Tennis game. 

## Features

* Wall centering control
* Adjustable ball speed control
* Translated 3-handed controls to a PS4 controller 


## Control Scheme

Developed on a PS4 controller.

The following are the recommended controls for Joystick Inputs:

Name                     |   Button
-------------------------|---------------------------------
Horizontal Movement      | Left Joystick
Vertical Movement        | Right Joystick
English Up               | R
English Down             | L
Serve                    | Y
Player Position Reset    | A
Wall Left                | Select
Wall Right               | Start
Reset                    | X

### Original Odyssey Controller
![Original Odyssey Controller](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/OdysseyController.jpg)

### Translated Table Tennis Controls
![Translated Odyssey Controls](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/TableTennisControls.jpg)


## Installation

Copy the *.rbf file onto the FPGA board.

## Project History

This re-implementation was developed through a deconstruction of the original Magnavox Odyssey. While the original console's hybrid analog and digital circuity was considered, this re-implementation is based on the behavior of the gameplay. The modularity is loosely based on the actual circuitry, including Spot Generators for the paddles, ball, and center line using the same nominal clock as the original system (NTSC). 

This re-implementation was developed over a three year period from 2023-2026. 

## TO-DO

### Improve Core Accuracy

* Switch serve control to triggers instead of bumpers
* Imitate english dial behavior on triggers
* Refactor modules to be suitable for reuse in other Odyssey game card cores

### Quality of Life / Debug Features

* Mark where ball is when it travels offscreen
* Add total core reset 
* Reset english speed on serve

