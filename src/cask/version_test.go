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
	assert.Equal(t, version, v.Current)
	assert.Empty(t, v.Latest.Build)
	assert.Empty(t, v.Latest.Version)
	assert.Empty(t, v.Appcast.Url)

	// with appcast
	a := appcast.New(url)
	v = NewVersion(version, a)

	assert.IsType(t, Version{}, *v)
	assert.Equal(t, version, v.Current)
	assert.Empty(t, v.Latest.Build)
	assert.Empty(t, v.Latest.Version)
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
		v.Current = version
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
	assert.Empty(t, v.Latest.Build)
	assert.Empty(t, v.Latest.Version)

	v.LoadAppcast()

	// after
	assert.NotEmpty(t, v.Appcast.Content.Original)
	assert.NotEmpty(t, v.Appcast.Content.Modified)
	assert.NotEmpty(t, "2.0.0", v.Latest.Version)
	assert.NotEmpty(t, "200", v.Latest.Build)
}

func TestInterpolateIntoString(t *testing.T) {
	v := NewVersion("1.2.3,1000:400")

	testCases := map[string]string{
		"#{version}": "1.2.3,1000:400",

		// semantic
		"#{version.major}":             "1",
		"#{version.minor}":             "2",
		"#{version.patch}":             "3",
		"#{version.major_minor}":       "1.2",
		"#{version.major_minor_patch}": "1.2.3",

		// before & after
		"#{version.before_comma}": "1.2.3",
		"#{version.after_comma}":  "1000:400",
		"#{version.before_colon}": "1.2.3,1000",
		"#{version.after_colon}":  "400",

		// dots
		"#{version.no_dots}":             "123,1000:400",
		"#{version.dots_to_underscores}": "1_2_3,1000:400",
		"#{version.dots_to_hyphens}":     "1-2-3,1000:400",

		// multiple
		"#{version.major} #{version.minor} #{version.patch}": "1 2 3",

		// chained
		"#{version.before_colon.before_comma.no_dots}": "123",

		// when unknown method (shouldn't change at all)
		"#{version.unknown}":                      "#{version.unknown}",
		"#{version.before_colon.unknown.no_dots}": "#{version.before_colon.unknown.no_dots}",
	}

	for content, interpolated := range testCases {
		actual := v.InterpolateIntoString(content)
		assert.Equal(t, interpolated, actual)
	}
}
