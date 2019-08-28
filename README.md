# Wookey SDK Dockerfile

## Introduction

this is the Dockerfile for the Wookey project SDK. This image contains a
fully functional development environment for the Wookey project, including
the overall requested software for building the Wookey firmware and the
Javacard applet.

## Building the Docker image

Just run:

   docker build Dockerfile-path

## Running the Docker image


You can interactively open the Wookey SDK using:

   docker run -it wookey_sdk

Once the SDK shell is open, the usual SDK commands can be used, as the overall configuration is already done:

   $ source setenv.sh
   [...]
   $ make defconfig_list
   [...]
   $ make boards/wookey/configs/wookey2_production_defconfig
   $ make
   $ make javacard_compile


