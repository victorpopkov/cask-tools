package request

import (
	"crypto/tls"
	"io/ioutil"
	"net/http"
	"time"
)

type Request struct {
	Url        string
	Content    []byte
	StatusCode StatusCode
	Headers    []Header
}

type Header struct {
	Name  string
	Value string
}

// LoadContent create a new GET request to the URL specified in Request struct
// and loads content. The response content alongside with the code status is
// saved in the Request struct.
func (self *Request) LoadContent() (content []byte, err error) {
	// prepare request
	req, err := http.NewRequest("GET", self.Url, nil)
	for _, header := range self.Headers {
		req.Header.Set(header.Name, header.Value)
	}

	// prepare client
	client := http.DefaultClient
	client.Timeout = time.Duration(10 * time.Second)
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client.Transport = tr

	// make request
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// read response
	body, err := ioutil.ReadAll(resp.Body)

	self.Content = body
	self.StatusCode.Int = resp.StatusCode

	return self.Content, err
}

// AddHeader adds a new header with provided name and value to the Request
// struct which later will be used when making requests.
func (self *Request) AddHeader(name string, value string) {
	self.Headers = append(self.Headers, Header{name, value})
}
