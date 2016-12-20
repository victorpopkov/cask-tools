package appcast

import (
	"fmt"
	"regexp"
	"strconv"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

func TestGitHubParse(t *testing.T) {
	filename := "github_api_compact.json"
	testCases := map[string][]string{
		"2.0.0": []string{"https://github.com/app/app/releases/download/v2.0.0/app_2.0.0.dmg", "true"},
		"1.1.0": []string{"https://github.com/app/app/releases/download/v1.1.0/app_1.1.0.dmg", "false"},
		"1.0.1": []string{"https://github.com/app/app/releases/download/v1.0.1/app_1.0.1.dmg", "false"},
		"1.0.0": []string{"https://github.com/app/app/releases/download/v1.0.0/app_1.0.0.dmg", "false"},
	}

	a := new(GitHubAppcast)
	a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
	a.Provider = GitHubAtom
	a.PrepareContent()

	// before
	assert.Empty(t, a.Items)

	a.Parse()

	// after
	assert.Len(t, a.Items, 4)
	for _, item := range a.Items {
		v := item.Version.Value
		prerelease, _ := strconv.ParseBool(testCases[v][1])
		assert.Equal(t, v, item.Version.Value)
		assert.Equal(t, prerelease, item.Version.Prerelease)
		assert.Empty(t, "", item.Build.Value)
		assert.Equal(t, testCases[v][0], item.Urls[0])
		assert.Equal(t, "", item.MinimumSystemVersion)
	}
}

func TestGitHubParseFilter(t *testing.T) {
	filename := "github_api_compact.json"
	testCases := map[string][]string{
		"1.1.0": []string{"https://github.com/app/app/releases/download/v1.1.0/app_1.1.0.dmg", "false"},
		"1.0.1": []string{"https://github.com/app/app/releases/download/v1.0.1/app_1.0.1.dmg", "false"},
		"1.0.0": []string{"https://github.com/app/app/releases/download/v1.0.0/app_1.0.0.dmg", "false"},
	}

	a := new(GitHubAppcast)
	a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
	a.Provider = GitHubAtom
	a.PrepareContent()
	a.Filter, _ = regexp.Compile("^v1.*")

	// before
	assert.Empty(t, a.Items)

	a.Parse()

	// after
	assert.Len(t, a.Items, 3)
	for _, item := range a.Items {
		v := item.Version.Value
		prerelease, _ := strconv.ParseBool(testCases[v][1])
		assert.Equal(t, v, item.Version.Value)
		assert.Equal(t, prerelease, item.Version.Prerelease)
		assert.Empty(t, "", item.Build.Value)
		assert.Equal(t, testCases[v][0], item.Urls[0])
		assert.Equal(t, "", item.MinimumSystemVersion)
	}
}
