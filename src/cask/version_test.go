package cask

import (
	"fmt"
	"general"
	"testing"

	"appcast"

	"github.com/stretchr/testify/assert"
	httpmock "gopkg.in/jarcoal/httpmock.v1"
)

func TestNewVersion(t *testing.T) {
	version := "1.0.0"
	url := "https://example.com/sparkle/#{version}/appcast.xml"
	urlMod := "https://example.com/sparkle/1.0.0/appcast.xml"

	// default
	v := NewVersion(version)

	assert.IsType(t, Version{}, *v)
	assert.Equal(t, version, v.Current.Value)
	assert.Empty(t, v.Latest.Build.Value)
	assert.Empty(t, v.Latest.Version.Value)
	assert.Empty(t, v.Appcast.Url)

	// with appcast
	a := appcast.New(url)
	v = NewVersion(version, a)

	assert.IsType(t, Version{}, *v)
	assert.Equal(t, version, v.Current.Value)
	assert.Empty(t, v.Latest.Build.Value)
	assert.Empty(t, v.Latest.Version.Value)
	assert.Equal(t, urlMod, v.Appcast.Url) // version should be interpolated in constructor
}

func TestInterpolateVersionIntoAppcast(t *testing.T) {
	var testCases = map[string][]string{
		"2.0.0": []string{
			"https://example.com/sparkle/#{version}/appcast.xml",
			"https://example.com/sparkle/2.0.0/appcast.xml",
		},
		"1.2.3,1000:400": []string{
			"https://example.com/sparkle/#{version.before_comma}/#{version.after_colon}/appcast.xml",
			"https://example.com/sparkle/1.2.3/400/appcast.xml",
		},
	}

	for version, url := range testCases {
		// when New, should be interpolated automatically
		v := new(Version)
		v.Current.Value = version
		v.Appcast = *appcast.New(url[0])

		// before
		assert.Equal(t, url[0], v.Appcast.Url)

		v.interpolateVersionIntoAppcast()

		// after
		assert.Equal(t, url[1], v.Appcast.Url)
	}
}

func TestLoadAppcast(t *testing.T) {
	version := "1.0.0"
	url := "https://example.com/sparkle/appcast.xml"

	// mock the request
	httpmock.Activate()
	defer httpmock.DeactivateAndReset()

	httpmock.RegisterResponder(
		"GET",
		url,
		httpmock.NewStringResponder(200, string(general.GetFileContent(fmt.Sprintf(appcastsTestdataPath, "sparkle_default.xml")))),
	)

	a := appcast.New(url)
	v := NewVersion(version, a)

	// before
	assert.Equal(t, url, v.Appcast.Url)
	assert.Empty(t, v.Appcast.Content.Original)
	assert.Empty(t, v.Appcast.Content.Modified)
	assert.Empty(t, v.Latest.Build.Value)
	assert.Empty(t, v.Latest.Version.Value)

	v.LoadAppcast()

	// after
	assert.NotEmpty(t, v.Appcast.Content.Original)
	assert.NotEmpty(t, v.Appcast.Content.Modified)
	assert.NotEmpty(t, "2.0.0", v.Latest.Version.Value)
	assert.NotEmpty(t, "200", v.Latest.Build.Value)
}
