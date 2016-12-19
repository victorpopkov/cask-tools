package request

import (
	"io/ioutil"
	"net/http"
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

	// make request
	resp, err := http.DefaultClient.Do(req)
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
