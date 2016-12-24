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
