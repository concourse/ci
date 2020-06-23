package main

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestScripts(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Validate Release Suite")
}

var _ = Describe("ValidateDockerDigests", func() {
	It("includes the version being shipped", func() {
		err := ValidateDockerDigests([]string{"blah"}, nil)
		Expect(err).To(HaveOccurred())
	})
})
