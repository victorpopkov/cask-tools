package appcast

import (
	"fmt"
	"regexp"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

func TestSparklePrepareContent(t *testing.T) {
	testCases := map[string][]int{
		"sparkle_attributes_as_elements.xml": []int{15, 24},
		"sparkle_default_asc.xml":            []int{27, 34},
		"sparkle_default.xml":                []int{13, 20},
		"sparkle_incorrect_namespace.xml":    []int{13, 20},
		"sparkle_multiple_enclosure.xml":     []int{13, 14, 15, 22, 23, 24},
		"sparkle_single.xml":                 []int{13},
		"sparkle_without_comments.xml":       nil,
		"sparkle_without_namespaces.xml":     []int{13, 20},
	}

	regexCommentStart := regexp.MustCompile(`<!--([[:space:]]*)?<`)
	regexCommentEnd := regexp.MustCompile(`>([[:space:]]*)?-->`)

	// without original content
	a := new(SparkleAppcast)

	// before
	assert.Empty(t, a.Content.Original)
	assert.Empty(t, a.Content.Modified)

	a.PrepareContent()

	// after
	assert.Empty(t, a.Content.Original)
	assert.Empty(t, a.Content.Modified)

	for filename, commentLines := range testCases {
		a = new(SparkleAppcast)
		a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))

		// before PrepareContent()
		for _, commentLine := range commentLines {
			line, _, _ := general.GetLineFromFile(commentLine, fmt.Sprintf(testdataPath, filename))
			check := (regexCommentStart.MatchString(line) && regexCommentEnd.MatchString(line))
			assert.True(t, check, fmt.Sprintf("PrepareContent() test case \"%s\" doesn't have a commented out line", filename))
		}

		a.PrepareContent()

		// after PrepareContent()
		for _, commentLine := range commentLines {
			line, _, _ := general.GetLineFromString(commentLine, a.Content.Modified)
			check := (regexCommentStart.MatchString(line) && regexCommentEnd.MatchString(line))
			assert.False(t, check, fmt.Sprintf("PrepareContent() test case \"%s\" didn't uncomment a commented out line", filename))
		}
	}
}

func TestSparkleParseMultiple(t *testing.T) {
	// multiple items
	filenameMultiple := "sparkle_default.xml"
	testCasesMultiple := map[string][]string{
		"2.0.0": []string{"200", "https://example.com/app_2.0.0.dmg", "10.10"},
		"1.1.0": []string{"110", "https://example.com/app_1.1.0.dmg", "10.9"},
		"1.0.1": []string{"101", "https://example.com/app_1.0.1.dmg", "10.9"},
		"1.0.0": []string{"100", "https://example.com/app_1.0.0.dmg", "10.9"},
	}

	a := new(SparkleAppcast)
	a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filenameMultiple)))
	a.Provider = Sparkle
	a.PrepareContent()

	// before
	assert.Empty(t, a.Items)

	a.Parse()

	// after
	assert.Len(t, a.Items, 4)
	for _, item := range a.Items {
		v := item.Version.Value
		assert.Equal(t, v, item.Version.Value)
		assert.Equal(t, testCasesMultiple[v][0], item.Build.Value)
		assert.Equal(t, testCasesMultiple[v][1], item.Urls[0])
		assert.Equal(t, testCasesMultiple[v][2], item.MinimumSystemVersion)
	}
}

func TestSparkleParseSingle(t *testing.T) {
	filenameSingle := "sparkle_single.xml"
	testCasesSingle := map[string][]string{
		"2.0.0": []string{"200", "https://example.com/app_2.0.0.dmg", "10.10"},
	}

	a := new(SparkleAppcast)
	a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filenameSingle)))
	a.Provider = Sparkle
	a.PrepareContent()

	// before
	assert.Empty(t, a.Items)

	a.Parse()

	// after
	assert.Len(t, a.Items, 1)
	for _, item := range a.Items {
		v := item.Version.Value
		assert.Equal(t, v, item.Version.Value)
		assert.Equal(t, testCasesSingle[v][0], item.Build.Value)
		assert.Equal(t, testCasesSingle[v][1], item.Urls[0])
		assert.Equal(t, testCasesSingle[v][2], item.MinimumSystemVersion)
	}
}
