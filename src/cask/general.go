package cask

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

// getWorkingDir returns a current working directory. If it's not available for
// any reason returns an error.
func getWorkingDir() (string, error) {
	pwd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	return pwd, nil
}

// readFile reads the cask file content from provided directory and cask name
// into a string. The provided name should be without an extension.
//
// Returns an error if the resulting cask path is invalid.
func readCask(dirname string, caskname string) (string, error) {
	content, err := ioutil.ReadFile(filepath.Join(dirname, fmt.Sprintf("%s.rb", caskname)))
	if err != nil {
		return "", err
	}

	return string(content), nil
}
