package cask

import (
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetWorkingDir(t *testing.T) {
	actual, err := getWorkingDir()
	assert.Regexp(t, "cask$", actual)
	assert.Nil(t, err)
}

func TestReadCask(t *testing.T) {
	pwd, _ := getWorkingDir()

	// default
	actual, err := readCask(filepath.Join(pwd, testdataDirname), testCaskname)
	assert.NotEmpty(t, actual)
	assert.Nil(t, err)

	// error
	actual, err = readCask("", "test")
	assert.Empty(t, actual)
	assert.Error(t, err)
	assert.Regexp(t, "no such file or directory$", err.Error())
}

func TestStringHasInterpolation(t *testing.T) {
	var testCases = map[string]bool{
		"#{version}":     true,
		"#{any}":         true,
		"#{any.chained}": true,

		"any":   false,
		"#{any": false,
		"#any":  false,
	}

	for testCase, expected := range testCases {
		assert.Equal(t, expected, StringHasInterpolation(testCase))
	}
}
