package cask

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	httpmock "gopkg.in/jarcoal/httpmock.v1"
)

var (
	testCaskname    = "default"
	testdataDirname = "testdata"
)

var testCases = map[string]map[string][]string{
	"default.rb": map[string][]string{
		"1.1.0": []string{
			"https://example.com/sparkle/1/appcast.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
	},
	"global-version-two-sha256.rb": map[string][]string{
		"1.1.0": []string{
			"https://example.com/sparkle/1/appcast.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
	},
	"no-appcast.rb": map[string][]string{
		"1.1.0": []string{
			"",
			"",
		},
	},
	"six-versions-six-appcasts.rb": map[string][]string{
		"0.1.0": []string{
			"https://example.com/sparkle/0/snowleopard.xml",
			"3fb0fdcd252f0d0898076a66c3ad3ef045590a82abc9c9789bc1d7fdd0dc21f0",
		},
		"0.2.0": []string{
			"https://example.com/sparkle/0/lion.xml",
			"81397ad4229e65572fb5386f445e7ecfdfc2161c51ce85747d2b4768b419984e",
		},
		"0.3.0": []string{
			"https://example.com/sparkle/0/mountainlion.xml",
			"916ed186f168a0ce5072beccb6e17f6f1771417ef3769aabff46d348f79b4c66",
		},
		"0.4.0": []string{
			"https://example.com/sparkle/0/mavericks.xml",
			"9a81f957ef6be7894a7ee7bd68ce37c4b5c6062560c9ef6c708c1cb3270793cc",
		},
		"0.5.0": []string{
			"https://example.com/sparkle/0/yosemite.xml",
			"3618d6152a3a32bc2793e876f1b89a485b2160cc43ba44e17141497fe7e04301",
		},
		"1.1.0": []string{
			"https://example.com/sparkle/1/elcapitan.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
	},
	"three-versions-one-appcast.rb": map[string][]string{
		"0.9.0": []string{
			"",
			"",
		},
		"1.1.0": []string{
			"",
			"",
		},
		"1.9.0": []string{
			"https://example.com/sparkle/1/appcast.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
	},
	"two-versions-one-global-appcast.rb": map[string][]string{
		"0.9.0": []string{
			"https://example.com/sparkle/0/appcast.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
		"1.1.0": []string{
			"https://example.com/sparkle/1/appcast.xml",
			"95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7",
		},
	},
}

func createTestCask() *Cask {
	pwd, _ := getWorkingDir()

	c := new(Cask)
	c.Name = testCaskname
	c.Content, _ = readCask(filepath.Join(pwd, testdataDirname), c.Name)

	// mock the request
	content, _ := readTestdata("appcast.xml")
	httpmock.Activate()
	httpmock.RegisterResponder(
		"GET",
		"https://example.com/sparkle/1/appcast.xml",
		httpmock.NewStringResponder(200, content),
	)

	return c
}

func readTestdata(filename string) (string, error) {
	pwd, _ := getWorkingDir()
	content, err := ioutil.ReadFile(filepath.Join(pwd, testdataDirname, filename))
	if err != nil {
		return "", nil
	}

	return string(content), nil
}

func TestNew(t *testing.T) {
	for cask, versions := range testCases {
		c := New(cask, testdataDirname)

		assert.IsType(t, Cask{}, *c)
		if len(c.Versions) > 0 {
			assert.Len(t, c.Versions, len(versions))
		}
	}
}

func TestString(t *testing.T) {
	name := "example"
	c := new(Cask)
	c.Name = name
	assert.Equal(t, name, c.String())
}

func TestIsOutdated(t *testing.T) {
	c := createTestCask()
	defer httpmock.DeactivateAndReset()
	c.ExtractVersionsWithAppcasts()

	// before
	assert.False(t, c.IsOutdated())

	c.LoadAppcasts()

	// after
	assert.True(t, c.IsOutdated())
}

func TestStanzaValues(t *testing.T) {
	for cask, versions := range testCases {
		// preparations
		c := new(Cask)
		c.Name = strings.TrimSuffix(cask, filepath.Ext(cask))
		c.Content, _ = readCask(testdataDirname, c.Name)

		// check
		actual, _ := c.StanzaValues("version")
		assert.Len(t, actual, len(versions))
	}
}

func TestExtractVersionsWithAppcasts(t *testing.T) {
	for cask, versions := range testCases {
		// preparations
		c := new(Cask)
		c.Name = strings.TrimSuffix(cask, filepath.Ext(cask))
		c.Content, _ = readCask(testdataDirname, c.Name)

		c.ExtractVersionsWithAppcasts() // extract

		if len(c.Versions) > 0 {
			assert.Len(t, c.Versions, len(versions))
		}

		// check each cask version
		for _, version := range c.Versions {
			// latest should have empty values
			assert.Empty(t, version.Latest.Version)
			assert.Empty(t, version.Latest.Build)

			// verify that the version match the one mentioned in test cases
			assert.NotEmpty(t, versions[version.Current])

			// compare appcast and current checkpoint with values in test cases
			expected := versions[version.Current][0]
			actual := version.Appcast.Url
			assert.Equal(t, expected, actual, fmt.Sprintf("Cask %s versions mismatch", c.Name))

			expected = versions[version.Current][1]
			actual = version.Appcast.Checkpoint.Current
			assert.Equal(t, expected, actual, fmt.Sprintf("Cask %s version %s checkpoints mismatch", c.Name, version.Current))
		}
	}
}

func TestLoadAppcasts(t *testing.T) {
	c := createTestCask()
	defer httpmock.DeactivateAndReset()
	c.ExtractVersionsWithAppcasts()

	// before
	for _, version := range c.Versions {
		assert.Empty(t, version.Latest.Version)
		assert.Empty(t, version.Latest.Build)
	}

	c.LoadAppcasts()

	// after
	for _, version := range c.Versions {
		assert.NotEmpty(t, version.Latest.Version)
		assert.NotEmpty(t, version.Latest.Build)
	}
}
