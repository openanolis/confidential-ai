package policy

import rego.v1

default allow = false

allow := true if {
  # request is from tdx
  input["submods"]["cpu0"]["ear.veraison.annotated-evidence"]["tdx"]
}
