package request

import (
	"strconv"

	"github.com/fatih/color"
)

type StatusCode struct {
	Int int
}

func (self StatusCode) String() string {
	return strconv.Itoa(self.Int)
}

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
