package trivy

default ignore = false

# TODO: remove once the version > 2.13.1-r1 is available on https://pkgs.alpinelinux.org/packages?name=git-lfs&branch=v3.14
ignore_cve_ids := {
  "CVE-2020-29652",
  "CVE-2020-9283",
}

ignore {
	input.VulnerabilityID == ignore_cve_ids[_]
}
