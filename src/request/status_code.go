package request

import (
	"strconv"

	"github.com/fatih/color"
)

type StatusCode struct {
	Int int
}

// String returns the string representation of the StatusCode.
func (self StatusCode) String() string {
	return strconv.Itoa(self.Int)
}

// Colorized returns the colorized representation of the StatusCode. The color
// is based on the status code: green (200), yellow (>= 300 < 400) and red
// (>= 400).
func (self StatusCode) Colorized() string {
	result := self.String()
	if self.Int == 200 {
		result = color.GreenString(result)
	} else if self.Int >= 300 && self.Int < 400 {
		result = color.YellowString(result)
	} else if self.Int >= 400 {
		result = color.RedString(result)
	}

	return result
}
