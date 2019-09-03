# WooKey SDK Dockerfile

## Introduction

this is the Dockerfile for the WooKey project SDK. This image contains a
fully functional development environment for the WooKey project, including
the overall requested software for building the WooKey firmware and the
Javacard applet.

The full WooKey project documentation can be found here:

https://wookey-project.github.io/index.html

In the following, commands starting with *host>* are made in the host computer, as
commands starting with *$* are made in the WooKey SDK Docker container.

## Building the Docker image

Just run:

   ```host> docker build --tag wookey_sdk --compress <Dockerfile-path>```


## Running the Docker image


### Introduction

A basic start to interactively access the container would be to use: *docker run -it wookey_sdk*

Although, the SDK is made to build an embedded firmware **and** to interact with the
WooKey boards and Javacard in order to flash them properly. WooKey boards are connected through Discovery
board ST-Link USB device, hosting as a CWD probe. Javacard are connected through any USB CCID card reader.

These two devices are real hardware and require multiple USB devices to be accessed from the container.
In order to build **and** flash a WooKey devices in the container require to map them at container start.

This can be done by specifying that USB devices should be mapped into the Docker container:

   ```host> docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb  wookey_sdk```

**CAUTION**: this mode make the docker container being executed in privilegied level, as the /dev/bus/usb subtree is
fully remapped in the docker container

It is possible to map explicitly each device using the --device option, avoiding a complete remap of the /dev/bus/usb
filesystem and a privilegied execution. Nonetheless, the --device arguments depend on your own hardware list (CCID reader,
Discovery board ST-Link reference, and so on).

### Saving the docker container useful content in the host

You may whish to keep the SDK content (sources, keys, and generated binary files) in the host PC in order to destroy and
reinstanciate another container without loosing the useful Wookey files, mostly the crypographic keypairs generated
during the first build and used to (un)cypher the Wookey device.

This can be easily done by bind-mounting a given host directory into the container and use it as a storage backend:

   ```
   host> mkdir /home/john/wookey
   host> docker run -it --privileged -v /home/john/wookey:/mnt/backup -v /dev/bus/usb:/dev/bus/usb  wookey_sdk
   ```

Here, when entering the container, the /mnt/backup directory exists and can be used by the 'build' user directly.
It is then possible to save the private keys after the first build:

   ```$ cp -r private /mnt/backup/private```

When restarting another container, it is also possible, **before** building a new firmware, to get back the previously saved private
directory from the backup storage:

   ```$ cp -r /mnt/backup/private private```

Knowing that, it is possible to keep the cryptographic content independently of the container lifecycle and to generate
new firmwares using the same keypairs. A previously flashed device with a formated SDCard storage can be flashed again without
loosing the storage content as there is no key substitution.

**CAUTION**: In a real, production, mode, the cryptographic elements should be stored securely (software or hardware vault, etc.)

### Using the Wookey SDK

Now that the container is up and running and the SDK shell is open, the usual SDK commands can be used, as the overall configuration is already done:

   ```$ source setenv.sh```
   
   ```[...]```
   
   ```$ make defconfig_list```
   
   ```[...]```
   
   ```$ make boards/wookey/configs/wookey2_production_defconfig```

**INFO** It is possible to update configuration items using:

   ```$ make menuconfig```

Typical items are the Javacard PIN values that can be upgraded, in the *Secure Token Configuration* menu.

Once the configuration is done, it is possible to compile the overall project:
   
   ```$ make```
   
   ```$ make javacard_compile```

All generated files are hosted in the build/armv7-m/wookey subdirectory.

## Flashing boards and Javacard from the Docker container

### Flashing the board

This is done using OpenOCD:

   ```$ sudo /usr/bin/openocd -f tools/stm32f4disco1.cfg -f tools/ocd.cfg```

**HINT**: If the device is not detected, try to use stm32f4disco0.cfg. The Discovery board device ID may vary.

### Flashing the Javacard applets

**HINT**: You must have an USB Smartcard reader connected to the host which is supported by pcscd.

Javacards access requires PCSC daemon to be started. First, start it:

   ```$ sudo /usr/sbin/pcscd```

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

These PIN can be set in the *Secure Token Configuration/AUTH Token* configuration menu before building the Javacard applet.

They can also be updated at runtime on the WooKey device directly, once it is fully unlocked.

**INFO**: When booting the device, it may not appear *inside* the container, as newly hotplugged devices may not
have the corresponding /dev/sdX file being created automatically. This does not impact the DFU mode, which can
nevertheless be used in the container.
In nominal mode although, the device should appear in the host list and be visible in the *dmesg* messages:

   ```host> dmesg
   [...]
   [ 7404.745045] usb 3-1.4.2.4: new high-speed USB device number 14 using xhci_hcd
   [ 7404.846368] usb 3-1.4.2.4: New USB device found, idVendor=dead, idProduct=cafe, bcdDevice= 0.00
   [ 7404.846370] usb 3-1.4.2.4: New USB device strings: Mfr=2, Product=1, SerialNumber=3
   [ 7404.846371] usb 3-1.4.2.4: Product: wookey
   [ 7404.846372] usb 3-1.4.2.4: Manufacturer: ANSSI
   [ 7404.846373] usb 3-1.4.2.4: SerialNumber: 123456789012345678901234
   [ 7404.849150] usb-storage 3-1.4.2.4:1.0: USB Mass Storage device detected
   [ 7404.849315] scsi host3: usb-storage 3-1.4.2.4:1.0
   [ 7405.869731] scsi 3:0:0:0: Direct-Access     ANSSI    wookey           0001 PQ: 0 ANSI: 0
   [ 7405.870234] sd 3:0:0:0: Attached scsi generic sg2 type 0
   [ 7405.871469] sd 3:0:0:0: [sdd] 31217152 4096-byte logical blocks: (128 GB/119 GiB)
   [ 7405.871778] sd 3:0:0:0: [sdd] Write Protect is off
   [ 7405.871779] sd 3:0:0:0: [sdd] Mode Sense: 03 00 00 00
   [ 7405.872031] sd 3:0:0:0: [sdd] No Caching mode page found
   [ 7405.872035] sd 3:0:0:0: [sdd] Assuming drive cache: write through
   [ 7405.881815] sd 3:0:0:0: [sdd] Attached SCSI disk
   ```

## Signing a new firmware

Once you have compiled a new firmware (using make), and flashed the SIG applet to the Javacard, it is possible
to sign it using the Javacard applet as a secure token to encrypt and sign the firmware.

Check that you already started pcscd, or start it:

   ```$ sudo /usr/sbin/pcscd```

To sign a new firmware, just run:

   ```$ make sign_interactive tosign=flip:flop version="1.0.0-0"```

This command create ciphered and signed version of both A and B (flip and flop) firmware images, with a
specific header including the given firmware version.

**INFO**: This command request the SIG applet Pet PIN and User PIN that have been used at applet compile time.
These PIN are the one you set in the *Secure Token Configuration/SIG Token* configuration menu, or 1234/1234 by default.

## Securely update the device

It is possible now to reboot the device in DFU mode (by pressing the DFU button bellow it (little black button).
The device boot in DFU mode, which can be distinguished by a violet color style.

The DFU Javacard must be used to authenticate. Again Pet PIN, name and user PIN are the one set in the corresponding
configuration menu. Default are 1234/1234.

Once the device has booted in DFU mode, it is possible to update it using the previously generated C+I firmware:

   ```$ sudo /usr/bin/dfu-util -v -D build/armv7-m/wookey/flop_fw.bin.signed -t 4096 -d dead:cafe```

The device ask the user to validate the new firmware version, and if it is okay, the firmware is uploaded, authenticated and the device reboots in nominal mode on the newly installed firmware.

