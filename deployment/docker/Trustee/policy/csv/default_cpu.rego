package policy

import rego.v1

# This policy validates multiple TEE platforms
# The policy is meant to capture the TCB requirements
# for confidential containers.

# This policy is used to generate an EAR Appraisal.
# Specifically it generates an AR4SI result.
# More informatino on AR4SI can be found at
# <https://datatracker.ietf.org/doc/draft-ietf-rats-ar4si/>

# For the  trust claim, the value 33 stands for
# "Runtime memory includes executables, scripts, files, and/or
#  objects which are not recognized."
default executables := 33

# For the  trust claim, the value 97 stands for
# "A Verifier does not recognize an Attester's hardware or
#  firmware, but it should be recognized."
default hardware := 97

# For the  trust claim the value 36 stands for
# "Elements of the configuration relevant to security are
#  unavailable to the Verifier."
default configuration := 36

# For the  trust claim, the value 35 stands for
# "File system integrity cannot be verified or is compromised."
default file_system := 35

##### Common Helper Functions

# Generic function to validate measurements for any platform and algorithm
validate_boot_measurements(measurements_data) if {
    some algorithm in {"SHA1", "SHA256", "SHA384"}
    components := ["grub", "shim", "initrd", "kernel"]
    every component in components {
        measurement_key := sprintf("measurement.%s.%s", [component, algorithm])
        measurements_data[measurement_key] in data.reference[measurement_key]
    }
}

# Generic function to validate kernel cmdline for any platform and algorithm
validate_kernel_cmdline(measurements_data, cmdline_data) if {
    cmdline_data in data.reference.kernel_cmdline

    some algorithm in {"SHA1", "SHA256", "SHA384"}
    measurement_key := sprintf("measurement.kernel_cmdline.%s", [algorithm])
    measurements_data[measurement_key] in data.reference[measurement_key]
}

# Generic funtion to validate all file measurements in AA Eventlog
file_measurements_valid(measurements_data) if {
    every file_key, file_value in measurements_data {
        startswith(file_key, "AA.eventlog.file")
        file_path := substring(file_key, 16, -1)
        file_value in data.reference[sprintf("measurement.file%s", [file_path])]
    }
}

### The following functions are for parsing UEFI event logs
### These functions are chosen when the related verifier is using
### crate

# Parse grub algorithm and digest
parse_grub(uefi_event_logs) := grub if {
    some i, j
    uefi_event_logs[i].type_name == "EV_EFI_BOOT_SERVICES_APPLICATION"
    contains(uefi_event_logs[i].details.device_paths[j], "grub")
    grub := {
        "alg": uefi_event_logs[i].digests[0].alg,
        "value": uefi_event_logs[i].digests[0].digest,
    }
}

# Parse shim algorithm and digest
parse_shim(uefi_event_logs) := shim if {
    some i, j
    uefi_event_logs[i].type_name == "EV_EFI_BOOT_SERVICES_APPLICATION"
    contains(uefi_event_logs[i].details.device_paths[j], "shim")
    shim := {
        "alg": uefi_event_logs[i].digests[0].alg,
        "value": uefi_event_logs[i].digests[0].digest,
    }
}

# Parse kernel algorithm and digest
parse_kernel(uefi_event_logs) := kernel if {
    some i
    uefi_event_logs[i].type_name == "EV_IPL"
    contains(uefi_event_logs[i].details.string, "Kernel")
    kernel := {
        "alg": uefi_event_logs[i].digests[0].alg,
        "value": uefi_event_logs[i].digests[0].digest,
    }
}

# Parse initrd algorithm and digest
parse_initrd(uefi_event_logs) := initrd if {
    some i
    uefi_event_logs[i].type_name == "EV_IPL"
    contains(uefi_event_logs[i].details.string, "Initrd")
    initrd := {
        "alg": uefi_event_logs[i].digests[0].alg,
        "value": uefi_event_logs[i].digests[0].digest,
    }
}

# Generic function to validate measurements for any platform and algorithm
# that recorded via uefi eventlog format
validate_boot_measurements_uefi_event_log(uefi_event_logs) if {
    grub := parse_grub(uefi_event_logs)
    shim := parse_shim(uefi_event_logs)
    initrd := parse_initrd(uefi_event_logs)
    kernel := parse_kernel(uefi_event_logs)
    components := [
        {"name": "grub", "value": grub.value, "alg": grub.alg},
        {"name": "shim", "value": shim.value, "alg": shim.alg},
        {"name": "initrd", "value": initrd.value, "alg": initrd.alg},
        {"name": "kernel", "value": kernel.value, "alg": kernel.alg},
    ]
    every component in components {
        measurement_key := sprintf("measurement.%s.%s", [component.name, component.alg])
        component.value in data.reference[measurement_key]
    }
}

# Generic function to validate kernel cmdline for any platform and algorithm
validate_kernel_cmdline_uefi(uefi_event_logs) if {
    some prefix in ["grub_cmd linux", "kernel_cmdline", "grub_kernel_cmdline"]
    some i
    uefi_event_logs[i].type_name == "EV_IPL"
    startswith(uefi_event_logs[i].details.string, prefix)
    measurement_key := sprintf("measurement.kernel_cmdline.%s", [uefi_event_logs[i].digests[0].alg])
    uefi_event_logs[i].digests[0].digest in data.reference[measurement_key]
}

# Function to check the cryptpilot load config
validate_cryptpilot_config(uefi_event_logs) if {
    some i
    uefi_event_logs[i].type_name == "EV_EVENT_TAG"
    uefi_event_logs[i].details.unicode_name == "AAEL"
    uefi_event_logs[i].details.data.domain == "cryptpilot.alibabacloud.com"
    uefi_event_logs[i].details.data.operation == "load_config"
    uefi_event_logs[i].details.data.content in data.reference["AA.eventlog.cryptpilot.alibabacloud.com.load_config"]
}

# Function to check the cryptpilot fde rootfs integrity
validate_cryptpilot_fde(uefi_event_logs) if {
    some i
    uefi_event_logs[i].type_name == "EV_EVENT_TAG"
    uefi_event_logs[i].details.unicode_name == "AAEL"
    uefi_event_logs[i].details.data.domain == "cryptpilot.alibabacloud.com"
    uefi_event_logs[i].details.data.operation == "fde_rootfs_hash"
    uefi_event_logs[i].details.data.content in data.reference["AA.eventlog.cryptpilot.alibabacloud.com.fde_rootfs_hash"]
}

##### Hygon CSV

executables := 3 if {
    # Check the kernel, initrd, shim and grub measurements
    #validate_boot_measurements_uefi_event_log(input.csv.uefi_event_logs)

    # Check rootfs integrity
    #validate_cryptpilot_fde(input.csv.uefi_event_logs)
}

# Check cryptpilot config. Uncomment this due to your need
hardware := 2 if {
    input.csv.version in ["2", "1"]
    # input.csv.vm_id in data.reference["csv.vm_id"]
    # input.csv.vm_version in data.reference["csv.vm_version"]
    # input.csv.serial_number in data.reference["csv.serial_number"]
    # input.csv.measure in data.reference["csv.measurement"]
}

# Check cryptpilot config. Uncomment this due to your need
configuration := 2 if {
    # input.csv.policy.nodbg in data.reference["csv.policy.nodbg"]
    # input.csv.policy.noks in data.reference["csv.policy.noks"]
    # input.csv.policy.es in data.reference["csv.policy.es"]
    # input.csv.policy.nosend in data.reference["csv.policy.nosend"]
    # input.csv.policy.domain in data.reference["csv.policy.domain"]
    # input.csv.policy.csv in data.reference["csv.policy.csv"]
    # input.csv.policy.csv3 in data.reference["csv.policy.csv3"]
    # input.csv.policy.asid_reuse in data.reference["csv.policy.asid_reuse"]
    # input.csv.policy.hsk_version in data.reference["csv.policy.hsk_version"]
    # input.csv.policy.cek_version in data.reference["csv.policy.cek_version"]
    # input.csv.policy.api_major in data.reference["csv.policy.api_major"]
    # input.csv.policy.api_minor in data.reference["csv.policy.api_minor"]
    # input.csv.user_pubkey_digest in data.reference["csv.user_pubkey_digest"]

    # Check kernel command line parameters have the expected value for any supported algorithm
    #validate_kernel_cmdline_uefi(input.csv.uefi_event_logs)

    # Check cryptpilot config. Uncomment this due to your need
    #validate_cryptpilot_config(input.csv.uefi_event_logs)
}
