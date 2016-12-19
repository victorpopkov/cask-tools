package request

import (
	"testing"

	"github.com/stretchr/testify/assert"
	httpmock "gopkg.in/jarcoal/httpmock.v1"
)

func TestLoadContent(t *testing.T) {
	// mock the request
	httpmock.Activate()
	defer httpmock.DeactivateAndReset()

	httpmock.RegisterResponder("GET", "https://example.com/", httpmock.NewStringResponder(200, `Test`))

	// prepare request
	r := new(Request)
	r.Url = "https://example.com/"
	r.Headers = append(r.Headers, Header{
		Name:  "User-Agent",
		Value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36",
	})

	// before
	assert.Empty(t, r.StatusCode.Int)
	assert.Empty(t, r.Content)

	// default
	r.LoadContent()
	assert.Equal(t, 200, r.StatusCode.Int)
	assert.Equal(t, "Test", string(r.Content))

	// invalid Url
	r.Url = "invalid"
	_, actualErr := r.LoadContent()
	assert.Equal(t, `Get invalid: no responder found`, actualErr.Error())
}

func TestAddHeader(t *testing.T) {
	r := new(Request)

	// before
	assert.Len(t, r.Headers, 0)

	r.AddHeader("User-Agent", "Example")

	// after
	assert.Len(t, r.Headers, 1)
	assert.Equal(t, "User-Agent", r.Headers[0].Name)
	assert.Equal(t, "Example", r.Headers[0].Value)
}
