package appcast

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewError(t *testing.T) {
	// default
	e := NewError("Error")
	assert.IsType(t, Error{}, e)
	assert.Equal(t, "Error", e.Message)
	assert.Equal(t, 1, e.Code)

	// with error code
	e = NewError("Error", 2)
	assert.IsType(t, Error{}, e)
	assert.Equal(t, "Error", e.Message)
	assert.Equal(t, 2, e.Code)
}

func TestErrorString(t *testing.T) {
	// preparations
	e := new(Error)
	e.Message = "Error"

	assert.Equal(t, "Error", e.String())
}

func TestErrorColorized(t *testing.T) {
	// preparations
	e := new(Error)
	e.Message = "Error"

	// we only check values
	assert.Regexp(t, "Error", e.Colorized())
}
