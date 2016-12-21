package appcast

import (
	"bufio"
	"bytes"
	"fmt"
	"testing"

	"general"
	"request"
	"version"

	"github.com/stretchr/testify/assert"
	httpmock "gopkg.in/jarcoal/httpmock.v1"
)

var (
	// paths
	testdataPath = "./testdata/%s"

	// URLs
	urlUnknown     = "https://example.com/"
	urlGitHubAtom  = "https://github.com/user/repo/releases.atom"
	urlGitHubAPI   = "https://api.github.com/repos/user/repo/releases"
	urlSparkle     = "https://example.com/sparkle/appcast.xml"
	urlSourceForge = "https://sourceforge.net/projects/example/rss"

	// other
	testUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
)

func createTestAppcast() BaseAppcast {
	a := BaseAppcast{
		Url: urlUnknown,
		Request: request.Request{
			Url: urlUnknown,
		},
		Content: Content{
			Original: "example content",
		},
		Checkpoint: Checkpoint{
			Current: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
			Latest:  "3587cb776ce0e4e8237f215800b7dffba0f25865cb84550e87ea8bbac838c423",
		},
		Provider: Unknown,
	}

	return a
}

func TestNew(t *testing.T) {
	url := "https://example.com/sparkle/appcast.xml"
	a := New(url)

	// both appcast and request URLs should be set
	assert.Equal(t, url, a.Url)
	assert.Equal(t, url, a.Request.Url)

	// checkpoints should be empty
	assert.Empty(t, a.Checkpoint.Current)
	assert.Empty(t, a.Checkpoint.Latest)

	// provider is empty without loading content for Sparkle
	assert.Equal(t, Unknown, a.Provider)

	// request should have default values only
	assert.Empty(t, a.Request.Content)
	assert.Empty(t, a.Request.Headers)
	assert.False(t, a.Request.InsecureSkipVerify)
	assert.Equal(t, 0, a.Request.StatusCode.Int)
}

func TestGetUrl(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Url, a.GetUrl())
}

func TestGetRequest(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Request, a.GetRequest())
}

func TestGetContent(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Request, a.GetRequest())
}

func TestGetCheckpoint(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Checkpoint, a.GetCheckpoint())
}

func TestGetProvider(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Provider, a.GetProvider())
}

func TestGetItems(t *testing.T) {
	a := createTestAppcast()
	assert.Equal(t, a.Items, a.GetItems())
}

func TestGuessProviderByUrl(t *testing.T) {
	// Unknown
	a := new(BaseAppcast)
	a.Url = urlUnknown
	assert.Equal(t, Unknown, a.Provider)
	a.GuessProviderByUrl()
	assert.Equal(t, Unknown, a.Provider)

	// GitHub Atom
	a = new(BaseAppcast)
	a.Url = urlGitHubAtom
	assert.Equal(t, Unknown, a.Provider)
	a.GuessProviderByUrl()
	assert.Equal(t, GitHubAtom, a.Provider)

	// SourceForge
	a = new(BaseAppcast)
	a.Url = urlSourceForge
	assert.Equal(t, Unknown, a.Provider)
	a.GuessProviderByUrl()
	assert.Equal(t, Unknown, a.Provider)

	// Sparkle
	a = new(BaseAppcast)
	a.Url = urlSourceForge
	assert.Equal(t, Unknown, a.Provider)
	a.GuessProviderByUrl()
	assert.Equal(t, Unknown, a.Provider)
}

func TestGitHubAtomLoadContent(t *testing.T) {
	url := urlGitHubAtom
	urlRequest := urlGitHubAPI

	// mock the requests
	httpmock.Activate()
	defer httpmock.DeactivateAndReset()

	httpmock.RegisterResponder(
		"GET",
		url,
		httpmock.NewStringResponder(200, string(general.GetFileContent(fmt.Sprintf(testdataPath, "github_default.xml")))),
	)

	httpmock.RegisterResponder(
		"GET",
		urlRequest,
		httpmock.NewStringResponder(200, string(general.GetFileContent(fmt.Sprintf(testdataPath, "github_api_compact.json")))),
	)

	// load content
	a := New(url)

	// appcast URL are request URLs should be set but different
	assert.Equal(t, GitHubAtom, a.Provider)
	assert.Equal(t, url, a.Url)
	assert.Equal(t, urlRequest, a.Request.Url)

	a.LoadContent()

	// checkpoints both should be the same
	checkpoint := "f405570baf720d8cc490a300ae42d3189ae9ec0c2c8f9a32badd679a92c27aeb"
	assert.Equal(t, checkpoint, a.Checkpoint.Current)
	assert.Equal(t, checkpoint, a.Checkpoint.Current)

	// provider is empty without loading content for Sparkle
	assert.Equal(t, GitHubAtom, a.Provider)

	// request content and status should be set
	assert.NotEmpty(t, a.Request.Content)
	assert.Equal(t, 200, a.Request.StatusCode.Int)
}

func TestSourceForgeLoadContent(t *testing.T) {
	url := urlSourceForge

	// mock the request
	httpmock.Activate()
	defer httpmock.DeactivateAndReset()

	httpmock.RegisterResponder(
		"GET",
		url,
		httpmock.NewStringResponder(200, string(general.GetFileContent(fmt.Sprintf(testdataPath, "sourceforge_default.xml")))),
	)

	// load content
	a := New(url)

	// both appcast and request URLs should be the same
	assert.Equal(t, Unknown, a.Provider)
	assert.Equal(t, url, a.Url)
	assert.Equal(t, url, a.Request.Url)

	a.LoadContent()

	// checkpoints both should be the same
	checkpoint := "1eed329e29aa768b242d23361adf225a654e7df74d58293a44d14862ef7ef975"
	assert.Equal(t, checkpoint, a.Checkpoint.Current)
	assert.Equal(t, checkpoint, a.Checkpoint.Current)

	// provider is empty without loading content for Sparkle
	assert.Equal(t, SourceForge, a.Provider)

	// request content and status should be set
	assert.NotEmpty(t, a.Request.Content)
	assert.Equal(t, 200, a.Request.StatusCode.Int)
}

func TestSparkleLoadContent(t *testing.T) {
	url := urlSparkle

	// mock the request
	httpmock.Activate()
	defer httpmock.DeactivateAndReset()

	httpmock.RegisterResponder(
		"GET",
		url,
		httpmock.NewStringResponder(200, string(general.GetFileContent(fmt.Sprintf(testdataPath, "sparkle_default.xml")))),
	)

	// load content
	a := New(url)

	// both appcast and request URLs should be the same
	assert.Equal(t, Unknown, a.Provider)
	assert.Equal(t, url, a.Url)
	assert.Equal(t, url, a.Request.Url)

	a.LoadContent()

	// checkpoints both should be the same
	checkpoint := "583743f5e8662cb223baa5e718224fa11317b0983dbf8b3c9c8d412600b6936c"
	assert.Equal(t, checkpoint, a.Checkpoint.Current)
	assert.Equal(t, checkpoint, a.Checkpoint.Current)

	// provider is empty without loading content for Sparkle
	assert.Equal(t, Sparkle, a.Provider)

	// request content and status should be set
	assert.NotEmpty(t, a.Request.Content)
	assert.Equal(t, 200, a.Request.StatusCode.Int)
}

func TestPrepareContent(t *testing.T) {
	a := createTestAppcast()

	// before
	assert.NotEmpty(t, a.GetContent().Original)
	assert.Empty(t, a.GetContent().Modified)

	a.PrepareContent()

	// after
	assert.NotEmpty(t, a.GetContent().Original)
	assert.NotEmpty(t, a.GetContent().Modified)

	// when original content is empty
	a.Content.Original = ""
	a.PrepareContent()

	assert.NotEmpty(t, a.GetContent().Modified)
}

func TestParse(t *testing.T) {
	var buffer bytes.Buffer

	exiter := general.NewExit(func(int) {})

	a := new(BaseAppcast)
	a.Parse(exiter, bufio.NewWriter(&buffer))

	assert.Equal(t, 1, exiter.Status())
	assert.Regexp(t, `Parse\(\) not implemented`, buffer.String())
}

func TestAddItem(t *testing.T) {
	var testCases = [][]string{
		[]string{"2.0.0", "200", "https://example.com/", "10.12"},
		[]string{"1.1.0", "110", "https://example.com/"},
		[]string{"1.0.1", "101"},
	}
	a := new(BaseAppcast)

	// before
	assert.Len(t, a.Items, 0)

	// add versions
	a.AddItem(*version.NewVersion(testCases[0][0]), *version.NewVersion(testCases[0][1]), []string{testCases[0][2]}, testCases[0][3])
	a.AddItem(*version.NewVersion(testCases[1][0]), *version.NewVersion(testCases[1][1]), []string{testCases[1][2]})
	a.AddItem(*version.NewVersion(testCases[2][0]), *version.NewVersion(testCases[2][1]))

	// after
	assert.Len(t, a.Items, len(testCases))
	for i, item := range a.Items {
		assert.Equal(t, testCases[i][0], item.Version.Value)
		assert.Equal(t, testCases[i][1], item.Build.Value)

		if len(testCases[i]) > 2 {
			assert.Equal(t, testCases[i][2], item.Urls[0])
		}

		if len(testCases[i]) > 3 {
			assert.Equal(t, testCases[i][3], item.MinimumSystemVersion)
		}
	}
}

func TestSortItemsByVersions(t *testing.T) {
	// this will be the result of reordering (if needed)
	var itemsCorrect = []Item{
		Item{
			Version: version.Version{Value: "2.0.0", Weight: 0},
			Build:   version.Version{Value: "200", Weight: 0},
		},
		Item{
			Version: version.Version{Value: "1.1.0", Weight: 0},
			Build:   version.Version{Value: "110", Weight: 0},
		},
		Item{
			Version: version.Version{Value: "1.0.1", Weight: 0},
			Build:   version.Version{Value: "101", Weight: 0},
		},
		Item{
			Version: version.Version{Value: "1.0.0", Weight: 0},
			Build:   version.Version{Value: "101", Weight: 0},
		},
	}

	var itemsAsc = []Item{
		Item{
			Version: version.Version{Value: "1.0.0", Weight: 0, Prerelease: false},
			Build:   version.Version{Value: "101", Weight: 0, Prerelease: false},
		},
		Item{
			Version: version.Version{Value: "1.0.1", Weight: 0, Prerelease: false},
			Build:   version.Version{Value: "101", Weight: 0, Prerelease: false},
		},
		Item{
			Version: version.Version{Value: "1.1.0", Weight: 0, Prerelease: false},
			Build:   version.Version{Value: "110", Weight: 0, Prerelease: false},
		},
		Item{
			Version: version.Version{Value: "2.0.0", Weight: 0, Prerelease: false},
			Build:   version.Version{Value: "200", Weight: 0, Prerelease: false},
		},
	}

	// descending order (order shouldn't be changed)
	a := new(BaseAppcast)
	a.Items = itemsCorrect
	a.SortItemsByVersions()
	assert.EqualValues(t, a.Items, itemsCorrect)

	// ascending order (should be reordered)
	a = new(BaseAppcast)
	a.Items = itemsAsc
	a.SortItemsByVersions()
	assert.EqualValues(t, a.Items, itemsCorrect)
}
