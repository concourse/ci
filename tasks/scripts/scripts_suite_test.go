package main

import (
	"testing"

	"github.com/hashicorp/go-version"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestScripts(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Scripts Suite")
}

var _ = Describe("TagsToPush", func() {
	It("includes the version being shipped", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"))
		Expect(tags).To(ContainElement("6.2.0"))
	})

	It("includes the minor line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"))
		Expect(tags).To(ContainElement("5.8"))
	})

	It("includes the major line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"))
		Expect(tags).To(ContainElement("5"))
	})

	It("excludes the major if shipit is not newest within its major", func() {
		tags := TagsToPush(v("5.5.11"), v("6.1.0"), v("5.8.1"))
		Expect(tags).NotTo(ContainElement("5"))
	})

	It("includes 'latest'", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"))
		Expect(tags).To(ContainElement("latest"))
	})

	It("excludes 'latest' if shipit is not the newest", func() {
		tags := TagsToPush(v("5.5.11"), v("6.1.0"), v("5.8.0"))
		Expect(tags).NotTo(ContainElement("latest"))
	})
})

func v(rawVersion string) *version.Version {
	version, _ := version.NewVersion(rawVersion)
	return version
}
