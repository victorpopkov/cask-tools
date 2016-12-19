package request

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestString(t *testing.T) {
	// preparations
	c := new(StatusCode)
	c.Int = 200

	assert.Equal(t, "200", c.String())
	assert.Equal(t, "200", fmt.Sprint(c))
}

func TestColorized(t *testing.T) {
	// we only check values
	assert.Regexp(t, "200", StatusCode{200}.Colorized())
	assert.Regexp(t, "300", StatusCode{300}.Colorized())
	assert.Regexp(t, "400", StatusCode{400}.Colorized())
}
