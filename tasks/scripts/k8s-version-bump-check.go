package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/hashicorp/go-version"
	"sigs.k8s.io/yaml"
)

type ChartVersion struct {
	Version string `json:"version"`
}

func main() {
	prVersion, err := version.NewVersion(GetChartVersion("chart-pr/Chart.yaml"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	latestPublishedVersion, err := version.NewVersion(GetChartVersion("concourse-chart/Chart.yaml"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if prVersion.Metadata() != "" || prVersion.Prerelease() != "" {
		fmt.Println(prVersion.String(), "version cannot contain any metadata or prerelease data")
		os.Exit(1)
	}

	if prVersion.GreaterThan(latestPublishedVersion) {
		fmt.Println(prVersion.String(), "is greater than", latestPublishedVersion.String())
		os.Exit(0)
	}

	fmt.Println(prVersion.String(), "is not greater than", latestPublishedVersion.String())
	fmt.Println("Please bump the version in the Chart.yaml file")
	os.Exit(1)
}

func GetChartVersion(chartYaml string) string {
	data, err := ioutil.ReadFile(chartYaml)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var chart ChartVersion

	err = yaml.Unmarshal(data, &chart)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	return chart.Version
}
