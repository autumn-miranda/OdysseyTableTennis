# Odyssey Table Tennis core for MiSTer

## General description

Based on the Template Core for MiSTer. 

This core recreates the behavior of the Magnavox Odyssey's Table Tennis game. 

## Features

* Wall centering control
* Adjustable Ball Speed Control
* Translated 3-handed controls to PS 4 

## TO-DO

### Improve Core Accuracy

* Switch serve control to triggers instead of bumpers
* Imitate english dial behavior on triggers
* Refactor modules to be suitable for reuse in other Odyssey game card cores

### Add Quality of Life / Debug Features

* Mark where ball is when it travels offscreen
* Add total core reset 
* Reset English speed on serve


### Control Scheme

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

![Original Odyssey Controller](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/OdysseyController.jpg)

![Translated Odyssey Controls](https://github.com/autumn-miranda/OdysseyTableTennis/blob/master/Images/TableTennisControls.jpg)


## Installation

Copy the *.rbf file onto the FPGA board.

## Notes

Developed through a deconstruction of the behavior of the original system. The original console's combinaton of anolog and digital cicuits was considered through this core's use of modules to emulate circuit functionality.

