#!/usr/bin/env bash

#
#    Copyright (c) 2020 Project CHIP Authors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

set -e

# Build script for GN Bouffalolab examples GitHub workflow.

MATTER_ROOT=$(dirname "$(readlink -f "$0")")/../../
source "$MATTER_ROOT/scripts/activate.sh"

# export BL_IOT_SDK_PATH=$MATTER_ROOT/third_party/bouffalolab/repo

# if [[ "$OSTYPE" == "linux-gnu"* ]]; then
# export PATH="$BL_IOT_SDK_PATH/toolchain/riscv/Linux/bin:$PATH"
# elif [[ "$OSTYPE" == "darwin"* ]]; then
# export PATH="$BL_IOT_SDK_PATH/toolchain/riscv/Darwin/bin:$PATH"
# fi

bl702_boards=("BL706-IoT-DVK" "BL706-NIGHT-LIGHT")
bl702_modules=("BL702" "BL706C-22")
bl702_module_type="BL706C-22"

print_help() {
    bl702_boards_help=""
    for board in "${bl702_boards[@]}"; do
        bl702_boards_help=$bl702_boards_help$board"\n            "
    done

    bl702_modules_help=""
    for module in "${bl702_modules[@]}"; do
        bl702_modules_help=$bl702_modules_help$module"\n                "
    done

    echo -e "Build script for Bouffalolab Matter examples
    Format:
    ./scripts/examples/gn_bouffalolab_example.sh <Example folder> <Output folder> <Bouffalolab_board_name> [<Build options>]

    <Example folder>
        Folder of example application, e.g: lighting-app

    <Output folder>
        Desired location for the output files

    <Bouffalolab_board_name>
        Identifier of the board for which this app is built
        Currently Supported :
            $bl702_boards_help
    <Build options> - optional noteworthy build options for Bouffalolab IOT Matter examples
        chip_build_libshell
            Enable libshell support. (Default false)
        chip_openthread_ftd
            Use openthread Full Thread Device, else, use Minimal Thread Devic. (Default true)
        enable_heap_monitoring
            Monitor & log memory usage at runtime. (Default false)
        setupDiscriminator
            Discriminatoor value used for BLE connexion. (Default 3840)
        setupPinCode
            PIN code for PASE session establishment. (Default 20202021)
        'import("//with_pw_rpc.gni")'
            Use to build the example with pigweed RPC
        OTA_periodic_query_timeout
            Periodic query timeout variable for OTA in seconds
        enable_psram
            Enable PSRAM memory. (Default true for BL702/BL706)
        baudrate
            UART baudrate for log output and UART shell command, e.g, baudrate=2000000, by default.
        module_type
            Bouffalolab chip module, e.g, module_type=\"BL706C-22\". Currently Supported:
                $bl702_modules_help
    "
}

if [ "$#" -lt "3" ]; then
    print_help
else
    example_name=$1
    output_folder=$2
    board_name=$3
    bouffalo_chip=
    module_type=
    baudrate=2000000
    optArgs=""

    optArgs=custom_toolchain=\"$MATTER_ROOT/examples/platform/bouffalolab/common/toolchain:riscv_gcc\"

    shift
    shift
    shift

    while [ $# -gt 0 ]; do
        if [[ "$1" == "module_type"* ]]; then
            module_type=$(echo "$1" | awk -F'=' '{print $2}')

            shift
            continue
        fi
        if [[ "$1" == "baudrate"* ]]; then
            baudrate=$(echo "$1" | awk -F'=' '{print $2}')

            shift
            continue
        fi

        optArgs=$optArgs$1" "
        shift
    done

    if [[ "${bl702_boards[@]}" =~ "$board_name" ]]; then
        bouffalo_chip="bl702"

        optArgs=board=\"$board_name\"" "$optArgs

        if [[ "$module_type" != "" ]]; then
            if [[ ! "${bl702_modules[@]}" =~ "$module_type" ]]; then
                echo "Module $module_type is not supported."
                exit 1
            fi

            optArgs=module_type=\"$module_type\"" "$optArgs
        fi

        optArgs=baudrate=\"$baudrate\"" "$optArgs
    else
        echo "Board $board_name is not supported."
        exit 1
    fi

    example_dir=$MATTER_ROOT/examples/$example_name/bouffalolab/$bouffalo_chip
    output_dir=$MATTER_ROOT/$output_folder

    gn gen --check --fail-on-unused-args --export-compile-commands --root="$example_dir" "$output_dir" --args="${optArgs[*]}"

    ninja -C "$output_dir"
fi
