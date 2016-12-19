package appcast

import (
	"testing"

	"request"

	"github.com/stretchr/testify/assert"
)

var (
	// paths
	testdataPath = "./testdata/%s"

	// other
	testUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
)

var testAppcast = BaseAppcast{
	Url: "https://example.com/",
	Request: request.Request{
		Url: "https://example.com/request/",
	},
	Content: Content{
		Original: "example content",
	},
	Checkpoint: Checkpoint{
		Current: "current checkpoint example",
		Latest:  "3587cb776ce0e4e8237f215800b7dffba0f25865cb84550e87ea8bbac838c423",
	},
	Provider: Unknown,
}

func TestGetUrl(t *testing.T) {
	expected := testAppcast.Url
	actual := testAppcast.GetUrl()

	assert.Equal(t, expected, actual)
}

func TestGetRequest(t *testing.T) {
	expected := testAppcast.Request
	actual := testAppcast.GetRequest()

	assert.Equal(t, expected, actual)
}

func TestGetContent(t *testing.T) {
	expected := testAppcast.Content
	actual := testAppcast.GetContent()

	assert.Equal(t, expected, actual)
}

func TestGetCheckpoint(t *testing.T) {
	expected := testAppcast.Checkpoint
	actual := testAppcast.GetCheckpoint()

	assert.Equal(t, expected, actual)
}

func TestGetProvider(t *testing.T) {
	expected := testAppcast.Provider
	actual := testAppcast.GetProvider()

	assert.Equal(t, expected, actual)
}

func TestGetItems(t *testing.T) {
	expected := testAppcast.Items
	actual := testAppcast.GetItems()

	assert.Equal(t, expected, actual)
}

func TestPrepareContent(t *testing.T) {
	// before
	assert.NotEmpty(t, testAppcast.GetContent().Original)
	assert.Empty(t, testAppcast.GetContent().Modified)

	testAppcast.PrepareContent()

	// after
	assert.NotEmpty(t, testAppcast.GetContent().Original)
	assert.NotEmpty(t, testAppcast.GetContent().Modified)

	// when original content is empty
	a := testAppcast
	a.Content.Original = ""
	a.PrepareContent()

	assert.NotEmpty(t, testAppcast.GetContent().Modified)
}
