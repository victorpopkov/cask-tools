package appcast

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestStatusCodeString(t *testing.T) {
	// preparations
	c := new(StatusCode)
	c.Code = 200

	assert.Equal(t, "200", c.String())
	assert.Equal(t, "200", fmt.Sprint(c))
}

func TestStatusCodeColorized(t *testing.T) {
	// we only check values
	assert.Regexp(t, "200", StatusCode{200}.Colorized())
	assert.Regexp(t, "300", StatusCode{300}.Colorized())
	assert.Regexp(t, "400", StatusCode{400}.Colorized())
}
