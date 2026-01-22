package policy

import rego.v1

default allow = false

allow := true if {
  # request is from csv
  input["submods"]["cpu0"]["ear.veraison.annotated-evidence"]["csv"]
  # must pass remote attestation
  input["submods"]["cpu0"]["ear.status"] == "affirming"
}
