# Wookey SDK Dockerfile

## Introduction

this is the Dockerfile for the Wookey project SDK. This image contains a
fully functional development environment for the Wookey project, including
the overall requested software for building the Wookey firmware and the
Javacard applet.

The full Wookey project documentation can be found here:

https://wookey-project.github.io/index.html

In the following, commands starting with *host>* are made in the host computer, as
commands starting with *$* are made in the Wookey SDK Docker container.

## Building the Docker image

Just run:

   ```host> docker build Dockerfile-path```


## Running the Docker image


You can interactively open the Wookey SDK using:

   ```host> docker run -it wookey_sdk```

Once the SDK shell is open, the usual SDK commands can be used, as the overall configuration is already done:

   ```$ source setenv.sh```
   
   ```[...]```
   
   ```$ make defconfig_list```
   
   ```[...]```
   
   ```$ make boards/wookey/configs/wookey2_production_defconfig```
   
   ```$ make```
   
   ```$ make javacard_compile```


## Flashing boards and Javacard from Docker images

Wookey boards are connected through Discovery board ST-Link USB device, hosting as a CWD probe.
Javacard are connected through any USB CCID card reader.

These two devices are real hardware and require multiple USB devices to be accessed from the container.

This can be done at docker image start by specifying that USB devices should be mapped into the Docker container:

   ```host> docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb  wookey_sdk```

**CAUTION**: this mode make the docker container being executed in privilegied level, as the /dev/bus/usb subtree is
fully remapped in the docker container

It is possible to map explicitly each device using the --device option, avoiding a complete remap of the /dev/bus/usb
filesystem and a privilegied execution. Nonetheless, the --device arguments depend on your own hardware list (CCID reader,
Discovery board ST-Link reference, and so on).


### Flashing the board

This is done using OpenOCD:

   ```$ sudo /usr/bin/openocd -f tools/stm32f4disco1.cfg -f tools/ocd.cfg```

**HINT**: If the device is not detected, try to use stm32f4disco0.cfg. The Discovery board device ID may vary.

### Flashing the Javacard applets

**HINT**: You must have an USB Smartcard reader connected to the host which is supported by pcscd.

Javacards access requires PCSC daemon to be started. First, start it:

   ```$ sudo /usr/sbin/pcscd --auto-exit```

Considering you have three independent Javacard, you can enter successively a new one after each flashing process.
In the case of a debug firmware configuration, it is possible to use a single Javacard for testing purpose.

Enter the Authentication Javacard. Then run:

   ```$ make javacard_push_auth```

Enter the DFU upgrade Javacard. Then run:

   ```$ make javacard_push_dfu```

Enter the firmware signature Javacard. Then run:

   ```$ make javacard_push_sig```

## Booting the device in nominal mode

The device is now ready to be used with its first firmware, flashed using OpenOCD.

At boot time, it requires the AUTH Javacard to be inserted and ask successively for the pet pin (default 1234) and the
user pin (default 1337). Once the Authentication process is passed, the device is unlocked and usable as a usual
usb mass storage device.

## Signing a new firmware

Once you have compiled a new firmware (using make), and flashed the SIG applet to the Javacard, it is possible
to sign it using the Javacard applet as a secure token to encrypt and sign the firmware.

Check that pcscd is up, or start it:

   ```$ sudo /usr/sbin/pcscd --auto-exit```

To sign a new firmware, just run:

   ```$ make sign tosign=flip:flop version="1.0.0-0"```

This command create cyphered and signed version of both A and B (flip and flop) firmware images, with a
specific header including the given firmware version.

## Securely update the device

It is possible now to reboot the device in DFU mode (by pressing the DFU button bellow it (little black button).
The device boot in DFU mode, which can be distinguished by a violet color style.

The DFU Javacard must be used to authenticate. Default pet pin is 1234, Default user pin is also 1234.

Once the device has booted in DFU mode, it is possible to update it using the previously generated C+I firmware:

   ```$ sudo /usr/bin/dfu-util -v -D build/armv7-m/wookey/flop_fw.bin.signed -t 4096 -d dead:cafe```

The device ask the user to validate the new firmware version, and if it is okay, the firmware is uploaded, authenticated and the device reboots in nominal mode on the newly installed firmware.

