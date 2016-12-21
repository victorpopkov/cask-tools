package request

import "github.com/fatih/color"

type Error struct {
	Code    int
	Message string
}

// NewError returns a new Error instance with a message from provided value. By
// default, the code is "1".
func NewError(msg string, a ...interface{}) Error {
	code := 1
	if len(a) > 0 {
		code = a[0].(int)
	}

	e := new(Error)
	e.Code = code
	e.Message = msg

	return *e
}

// String returns the string representation of the Error.
func (self Error) String() string {
	return self.Message
}

// Colorized returns the colorized representation of the StatusCode. The color
// is red.
func (self Error) Colorized() string {
	return color.RedString(self.Message)
}
