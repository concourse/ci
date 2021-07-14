package trivy

default ignore = false

ignore_cve_ids := {
  # doesn't affect us since the user doesn't get to control the mount locations
  "CVE-2019-16884",
  # doesn't affect us since the user doesn't get to control the mount locations
  "CVE-2019-19921"
}

ignore {
	input.VulnerabilityID == ignore_cve_ids[_]
}
