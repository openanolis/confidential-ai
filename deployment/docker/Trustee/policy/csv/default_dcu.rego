package policy

import rego.v1

# This policy validates multiple TEE platforms
# The policy is meant to capture the TCB requirements
# for confidential containers.

# This policy is used to generate an EAR Appraisal.
# Specifically it generates an AR4SI result.
# More informatino on AR4SI can be found at
# <https://datatracker.ietf.org/doc/draft-ietf-rats-ar4si/>

# For the `executables` trust claim, the value 33 stands for
# "Runtime memory includes executables, scripts, files, and/or
#  objects which are not recognized."
default executables := 33

# For the `hardware` trust claim, the value 97 stands for
# "A Verifier does not recognize an Attester's hardware or
#  firmware, but it should be recognized."
default hardware := 97

# For the `configuration` trust claim the value 36 stands for
# "Elements of the configuration relevant to security are
#  unavailable to the Verifier."
default configuration := 36

# Uncomment this due to your need
executables := 3 if {
    # input.hygondcu.0.body.measure in data.reference["hygondcu.body.measure"]
}

# Uncomment this due to your need
hardware := 2 if {
    # input.hygondcu.0.body.version in data.reference["hygondcu.body.version"]
    # input.hygondcu.0.body.chip_id in data.reference["hygondcu.body.chip_id"]
    # input.hygondcu.0.body.reserved in data.reference["hygondcu.body.reserved"]
}

# Uncomment this due to your need
configuration := 2 if {
    # input.hygondcu.0.body.user_data in data.reference["hygondcu.body.user_data"]
    # input.hygondcu.0.body.sig_usage in data.reference["hygondcu.body.sig_usage"]
    # input.hygondcu.0.body.sig_algo in data.reference["hygondcu.body.sig_algo"]
}
