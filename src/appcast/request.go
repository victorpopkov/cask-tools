package appcast

import (
	"crypto/tls"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type Request struct {
	Url                string
	Content            []byte
	StatusCode         StatusCode
	Headers            []Header
	Error              Error
	InsecureSkipVerify bool
	Timeout            time.Duration
}

type Header struct {
	Name  string
	Value string
}

// LoadContent creates a new GET request to the URL in a Request struct and
// loads content. The loaded response content alongside with the status code is
// saved in the Request struct.
func (self *Request) LoadContent() (content []byte, err error) {
	// prepare request
	req, err := http.NewRequest("GET", self.Url, nil)
	for _, header := range self.Headers {
		req.Header.Set(header.Name, header.Value)
	}

	// prepare client
	client := http.DefaultClient
	if self.Timeout > 0 {
		client.Timeout = self.Timeout
	} else {
		client.Timeout = time.Duration(10 * time.Second)
	}

	if self.InsecureSkipVerify {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}

	// make request
	resp, err := client.Do(req)
	if err != nil {
		errMsg, errCode := self.getErrorMsgAndCode(err)
		self.Error = NewError(errMsg, errCode)
		return nil, err
	}
	defer resp.Body.Close()

	// read response
	body, err := ioutil.ReadAll(resp.Body)

	self.Content = body
	self.StatusCode.Code = resp.StatusCode

	return self.Content, err
}

// AddHeader adds a new header with provided name and value to the Request
// struct which later will be used when making requests.
func (self *Request) AddHeader(name string, value string) {
	self.Headers = append(self.Headers, Header{name, value})
}

// getErrorMsgAndCode returns a custom error message alongside with the custom
// code based on the provided request error.
func (self Request) getErrorMsgAndCode(err error) (msg string, code int) {
	regexTimeout := regexp.MustCompile(`Client.Timeout`)
	regexUnknownAuthority := regexp.MustCompile(`certificate signed by unknown authority`)

	if regexTimeout.MatchString(err.Error()) {
		return "Request timed out.", 3
	} else if regexUnknownAuthority.MatchString(err.Error()) {
		return "Certificate signed by unknown authority.", 4
	}

	return "Request error.", 1
}

// AddGitHubAuth adds an authorization header for GitHub API. The githubAuth
// parameter needs to have both username and token separated by semicolon:
// AddGitHubAuth("<username>:<token>").
//
// Returns the provided username and token.
func (self *Request) AddGitHubAuth(githubAuth string) (githubUser string, githubToken string) {
	auth := strings.Split(githubAuth, ":")
	if len(auth) == 2 {
		githubUser = auth[0]
		githubToken = auth[1]
		encoded := base64.URLEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", auth[0], auth[1])))
		self.AddHeader("Authorization", fmt.Sprintf("Basic %s", encoded))
	}

	return githubUser, githubToken
}
