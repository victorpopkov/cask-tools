package version

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

var extractAllTestCases = map[string][]string{
	// single
	"2":             nil,
	"12":            []string{"12"},
	"102":           []string{"102"},
	"1.0.2":         []string{"1.0.2"},
	"10.2":          []string{"10.2"},
	"1.02":          []string{"1.02"},
	"v1.0.2":        []string{"1.0.2"},
	"Version 1.0.2": []string{"1.0.2"},
	"Version-1.0.2": []string{"1.0.2"},
	"1.0b2":         []string{"1.0b2"},
	"1.0RC2":        []string{"1.0RC2"},
	"1.0-2_i386":    []string{"1.0-2_i386"},

	// multiples
	"First is v1.0.1, second is v.1.0.2, third is v1.0.3": []string{"1.0.1", "1.0.2", "1.0.3"},

	// ignored
	"86_64": nil,
	"386":   nil,
	"64":    nil,
	"32":    nil,
}

func GroupsTestCases() *Groups {
	testCases := [][]string{
		[]string{"2.0.9", "2016"},
		[]string{"2.0.9"},
		[]string{"2.0.9", "100"},
		[]string{"1.0.0", "86_64"},
		[]string{"200", "1.0.0", "64"},
		[]string{"0.9.8"},
	}

	groups := new(Groups)
	for i, group := range testCases {
		g := new(Group)

		for _, version := range group {
			g.Versions = append(g.Versions, Version{
				Value:      version,
				Weight:     0,
				Prerelease: false,
			})
		}

		// add URL only to first version
		g.Urls = append(g.Urls, fmt.Sprintf("http://example.com/%s/%d/download", group[0], i))

		groups.Groups = append(groups.Groups, *g)
	}

	return groups
}

func TestNewGroups(t *testing.T) {
	g := NewGroups()
	assert.IsType(t, Groups{}, *g)
	assert.Empty(t, g.Groups)
}

func TestNewGroup(t *testing.T) {
	// without versions as argument
	g := NewGroup()
	assert.IsType(t, Group{}, *g)
	assert.Empty(t, g.Versions)
	assert.Empty(t, g.PreferredVersion.Value)
	assert.Empty(t, g.Urls)
	assert.Len(t, g.Urls, 0)

	// when versions are provided in argument
	versions := []Version{
		Version{"1.0.0", 0, false},
		Version{"1.0.1", 0, false},
	}
	g = NewGroup(versions)
	assert.IsType(t, Group{}, *g)
	assert.NotEmpty(t, g.Versions)
}

func TestNewVersion(t *testing.T) {
	version := "1.0.0"

	// without weight
	v := NewVersion(version)
	assert.IsType(t, Version{}, *v)
	assert.Equal(t, v.Value, version)
	assert.Equal(t, v.Weight, 0)

	// with weight
	weight := 10
	v = NewVersion(version, weight)
	assert.IsType(t, Version{}, *v)
	assert.Equal(t, v.Value, version)
	assert.Equal(t, v.Weight, weight)
}

//
func TestExtractAll(t *testing.T) {
	for content, versions := range extractAllTestCases {
		actual := ExtractAll(content)
		expected := versions

		assert.Equal(t, expected, actual)
	}
}

func TestGroupsAddGroup(t *testing.T) {
	groups := NewGroups()
	assert.Empty(t, groups.Groups)
	assert.Len(t, groups.Groups, 0)

	// without weight
	g := NewGroup()
	groups.AddGroup(*g)
	assert.NotEmpty(t, groups.Groups)
	assert.Len(t, groups.Groups, 1)
}

func TestGroupsWeighten(t *testing.T) {
	testCases := map[string]int{
		"2.0.9": 3,
		"1.0.0": 2,
		"0.9.8": 1,
		"2016":  1,
		"200":   1,
		"100":   1,
		"64":    1,
		"86_64": 1,
	}

	groups := GroupsTestCases()

	// weights should be zero by default
	for _, group := range groups.Groups {
		for _, version := range group.Versions {
			assert.Equal(t, 0, version.Weight)
		}
	}

	groups.Weighten()

	// weights should be calculated and changed
	for _, group := range groups.Groups {
		for _, version := range group.Versions {
			assert.Equal(t, testCases[version.Value], version.Weight)
		}
	}
}

func TestGroupsGroupVersionsAndCleanByWeights(t *testing.T) {
	testCases := map[string][]string{
		"2.0.9": []string{
			"http://example.com/2.0.9/0/download",
			"http://example.com/2.0.9/1/download",
			"http://example.com/2.0.9/2/download",
		},
		"1.0.0": []string{
			"http://example.com/1.0.0/3/download",
			"http://example.com/200/4/download",
		},
		"0.9.8": []string{
			"http://example.com/0.9.8/5/download",
		},
	}

	groups := GroupsTestCases()

	groups.Weighten()
	groups.GroupVersions()
	groups.CleanByWeights()

	for _, group := range groups.Groups {
		assert.EqualValues(t, testCases[group.PreferredVersion.Value], group.Urls)
	}
}

func TestGroupAddVersion(t *testing.T) {
	version := "1.0.0"

	g := NewGroup()
	assert.Empty(t, g.Versions)
	assert.Len(t, g.Versions, 0)

	// with required parameters only
	g.AddVersion(version)
	assert.NotEmpty(t, g.Versions)
	assert.Len(t, g.Versions, 1)
	assert.Equal(t, version, g.Versions[0].Value)
	assert.Equal(t, 0, g.Versions[0].Weight)

	// with all parameters
	weight := 10
	prerelease := true
	g = NewGroup()
	g.AddVersion(version, weight, prerelease)
	assert.NotEmpty(t, g.Versions)
	assert.Len(t, g.Versions, 1)
	assert.Equal(t, version, g.Versions[0].Value)
	assert.Equal(t, weight, g.Versions[0].Weight)
	assert.Equal(t, prerelease, g.Versions[0].Prerelease)
}

func TestGroupAddUrl(t *testing.T) {
	g := NewGroup()
	assert.Empty(t, g.Urls)

	g.AddUrl("https://example.com/")
	assert.Len(t, g.Urls, 1)
}

func TestGroupExtractAll(t *testing.T) {
	for content, versions := range extractAllTestCases {
		g := NewGroup()
		g.ExtractAll(content)

		var expected []Version
		for _, version := range versions {
			expected = append(expected, Version{version, 0, false})
		}
		actual := g.Versions

		assert.EqualValues(t, expected, actual)
	}
}

func TestVersionLessThan(t *testing.T) {
	v1 := NewVersion("1.0.0")
	v2 := NewVersion("1.0.1")
	v3 := NewVersion("0.9.0")

	assert.True(t, v1.LessThan(v2))
	assert.True(t, v3.LessThan(v1))
	assert.True(t, v3.LessThan(v2))
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
