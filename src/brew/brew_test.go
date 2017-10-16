package brew

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLookForExecutable(t *testing.T) {
	// test (successful)
	path, err := LookForExecutable("ls")
	assert.Nil(t, err)
	assert.NotEmpty(t, path)

	// test (error)
	path, err = LookForExecutable("invalid")
	assert.Error(t, err)
	assert.Empty(t, path)
}
