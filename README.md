# ElocNG-Firmware

This repository contains a PlatformIO project implementing the ULP stage of the Eloc-NG detector.

Functionality:
- The device boots to the main CPU code (main.c) where it sets the ADC threshold variables. Then it starts the ULP code.

- The ULP code (main.S) samples the ADC and whenever the value falls outside the lower or upper thresholds, it awakes the main CPU code.

- As long as the ADC does not go off the threshold values, the ULP code keeps running.


