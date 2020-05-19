package main

import (
	"flag"
	"io/ioutil"
	"strconv"
	"strings"

	"github.com/hashicorp/go-version"
)

// 3 required flag args pointing to the files described below
// --shipit
// --latest
// --latest-of-same-major
// --output
// optionally the SUFFIX env var can be set
// populates the file indicated by the `--output` flag with the tags that
// should be pushed when `version/version` is being shipped

func main() {
	var shipitPath, latestPath, latestOfSameMajorPath, outputPath string
	flag.StringVar(&shipitPath, "shipit", "", "path to file containing version to ship")
	flag.StringVar(&latestPath, "latest", "", "path to file containing latest version shipped")
	flag.StringVar(&latestOfSameMajorPath, "latest-of-same-major", "", "path to file containing latest version in the same major line as 'shipit'")
	flag.StringVar(&outputPath, "output", "", "path to output file")
	flag.Parse()
	shipit, err := readSemver(shipitPath)
	if err != nil {
		panic(err)
	}
	latest, err := readSemver(latestPath)
	if err != nil {
		panic(err)
	}
	latestOfSameMajor, err := readSemver(latestOfSameMajorPath)
	if err != nil {
		panic(err)
	}
	tags := TagsToPush(shipit, latest, latestOfSameMajor)
	ioutil.WriteFile(outputPath, []byte(strings.Join(tags, "\n")), 0666)
}

func readSemver(filePath string) (*version.Version, error) {
	fileContents, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	return version.NewVersion(strings.TrimSpace(string(fileContents)))
}

func TagsToPush(shipit, latest, latestOfSameMajor *version.Version) []string {
	tags := []string{shipit.String(), minorTag(shipit)}
	if shipit.GreaterThanOrEqual(latestOfSameMajor) {
		tags = append(tags, majorTag(shipit))
	}
	if shipit.GreaterThanOrEqual(latest) {
		tags = append(tags, "latest")
	}
	return tags
}

func minorTag(semver *version.Version) string {
	segments := semver.Segments()
	ret := []string{}
	for _, segment := range segments[:len(segments)-1] {
		ret = append(ret, strconv.Itoa(segment))
	}
	return strings.Join(ret, ".")
}

func majorTag(semver *version.Version) string {
	segments := semver.Segments()
	return strconv.Itoa(segments[0])
}
