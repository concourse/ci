package main

import (
	"io/ioutil"
	"strconv"
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func TestScripts(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Validate Release Suite")
}

var _ = Describe("ValidateDockerDigests", func() {
	var tag, expectedDigest, testDigest string
	var err error

	BeforeEach(func() {
		tag = "6.0"
		expectedDigest = "sha256:39394e54bd712c942ce90b46c7ab36fefdeafb146ee5f88a6ccbdb5e1827939d"
	})

	JustBeforeEach(func() {
		err = ValidateDockerDigests([]string{tag}, map[string]string{
			testDigest: "test-digest"})
	})

	Context("when fetched docker image digest not match given digest", func() {

		BeforeEach(func() {
			testDigest = "sha256:blah"
		})

		It("returns error with mismatch digest", func() {
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("mismatch"))
		})
	})

	Context("when fetched docker image digest matches given digest", func() {

		BeforeEach(func() {
			testDigest = expectedDigest
		})

		It("returns no error", func() {
			Expect(err).ToNot(HaveOccurred())
		})
	})
})

var _ = Describe("ValidateSemverVerions", func() {
	var (
		err                 error
		filePaths, versions []string
		releaseVersion      string
	)

	JustBeforeEach(func() {
		for i, version := range versions {
			fileName := "file" + strconv.Itoa(i)
			versionFile, err := ioutil.TempFile("", fileName)
			Expect(err).NotTo(HaveOccurred())

			_, err = versionFile.Write([]byte(version))
			Expect(err).NotTo(HaveOccurred())

			err = versionFile.Close()
			Expect(err).NotTo(HaveOccurred())

			filePaths = append(filePaths, versionFile.Name())
		}

		releaseVersion, err = ValidateSemverVerions(filePaths)
	})

	Context("when all versions are the same", func() {
		BeforeEach(func() {
			versions = []string{"version1", "version1", "version1"}
		})

		It("returns the version with no error", func() {
			Expect(err).ToNot(HaveOccurred())
			Expect(releaseVersion).To(Equal("version1"))
		})

	})

	Context("when there is one version mismatch", func() {
		BeforeEach(func() {
			versions = []string{"version1", "version2", "version1"}
		})

		It("returns the version with no error", func() {
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).To(ContainSubstring("not unique"))
		})

	})
})
