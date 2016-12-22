package request

import (
	"errors"
	"testing"
	"time"

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

	// InsecureSkipVerify
	assert.False(t, r.InsecureSkipVerify)
	r.InsecureSkipVerify = true
	_, actualErr = r.LoadContent()
	assert.Equal(t, `Get invalid: unsupported protocol scheme ""`, actualErr.Error())

	// Timeout
	assert.Equal(t, time.Duration(0), r.Timeout)
	r.Timeout = 10
	r.LoadContent()
	assert.Equal(t, time.Duration(10), r.Timeout)
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

func TestGetErrorMsg(t *testing.T) {
	r := new(Request)

	// request timed out
	err := errors.New("Get http://example.com: net/http: request canceled (Client.Timeout exceeded while awaiting headers)")
	actualMsg, actualCode := r.getErrorMsgAndCode(err)
	assert.Equal(t, "Request timed out.", actualMsg)
	assert.Equal(t, 3, actualCode)

	// certificate signed by unknown authority"
	err = errors.New("Get https://example.com: x509: certificate signed by unknown authority")
	actualMsg, actualCode = r.getErrorMsgAndCode(err)
	assert.Equal(t, "Certificate signed by unknown authority.", actualMsg)
	assert.Equal(t, 4, actualCode)

	// unknown
	err = errors.New("Get https://example.com: this error in unknown")
	actualMsg, actualCode = r.getErrorMsgAndCode(err)
	assert.Equal(t, "Request error.", actualMsg)
	assert.Equal(t, 1, actualCode)
}

func TestAddGitHubAuth(t *testing.T) {
	r := new(Request)

	assert.Empty(t, r.Headers)

	// passed as argument
	user, token := r.AddGitHubAuth("user:token")

	assert.Len(t, r.Headers, 1)
	assert.Equal(t, "user", user)
	assert.Equal(t, "token", token)
}
