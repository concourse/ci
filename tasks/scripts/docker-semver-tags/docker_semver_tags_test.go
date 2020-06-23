package main

import (
	"testing"

	"github.com/hashicorp/go-version"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestScripts(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Docker Semver Tags Suite")
}

var _ = Describe("TagsToPush", func() {
	It("includes the version being shipped", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "")
		Expect(tags).To(ContainElement("6.2.0"))
	})

	It("appends metadata to version being shipped", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "ubuntu")
		Expect(tags).To(ContainElement("6.2.0-ubuntu"))
	})

	It("includes the minor line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"), "")
		Expect(tags).To(ContainElement("5.8"))
	})

	It("appends metadata to minor line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"), "ubuntu")
		Expect(tags).To(ContainElement("5.8-ubuntu"))
	})

	It("includes the major line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"), "")
		Expect(tags).To(ContainElement("5"))
	})

	It("appends metadata to major line", func() {
		tags := TagsToPush(v("5.8.1"), v("6.1.0"), v("5.8.0"), "ubuntu")
		Expect(tags).To(ContainElement("5-ubuntu"))
	})

	It("excludes the major if shipit is not newest within its major", func() {
		tags := TagsToPush(v("5.5.11"), v("6.1.0"), v("5.8.1"), "")
		Expect(tags).NotTo(ContainElement("5"))
	})

	It("includes 'latest'", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "")
		Expect(tags).To(ContainElement("latest"))
	})

	It("includes the metadata if supplied", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "ubuntu")
		Expect(tags).To(ContainElement("ubuntu"))
	})

	It("excludes 'latest' if meatadata supplied", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "ubuntu")
		Expect(tags).NotTo(ContainElement("latest"))
	})

	It("excludes metadata if not supplied", func() {
		tags := TagsToPush(v("6.2.0"), v("6.1.0"), v("6.1.0"), "")
		Expect(tags).NotTo(ContainElement(""))
	})

	It("excludes 'latest' if shipit is not the newest", func() {
		tags := TagsToPush(v("5.5.11"), v("6.1.0"), v("5.8.0"), "")
		Expect(tags).NotTo(ContainElement("latest"))
	})
})

func v(rawVersion string) *version.Version {
	version, _ := version.NewVersion(rawVersion)
	return version
}
