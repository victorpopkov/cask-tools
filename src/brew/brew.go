// Package brew is a simple Homebrew wrapper for running supported Homebrew
// commands.
package brew

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"os/exec"
	"path"
	"sort"
	"strings"

	"gopkg.in/AlecAivazis/survey.v1"
)

// LookForExecutable searches for a Homebrew executable binary in the
// directories named by the PATH environment variable. Returns its full path or
// an "Homebrew executable not found" error. The default executable binary name
// is "brew". It can be changed by passing the new name as an argument.
func LookForExecutable(a ...interface{}) (string, error) {
	e := "brew"
	if len(a) > 0 {
		e = a[0].(string)
	}

	path, err := exec.LookPath(e)
	if err == nil {
		return path, nil
	}

	return "", errors.New("Homebrew executable not found")
}

// LookForCaskroomTaps searches for the Caskroom taps in the Homebrew directory
// and returns a map with a tap name as a key and a full tap path as a value.
func LookForCaskroomTaps() (map[string]string, error) {
	var out bytes.Buffer

	_, err := LookForExecutable()
	if err != nil {
		return nil, err
	}

	cmd := exec.Command("brew", "--repository")
	cmd.Stdout = &out

	err = cmd.Run()
	if err != nil {
		return nil, errors.New("`brew --repository` has returned an error")
	}

	tapsDir := path.Join(strings.TrimSpace(out.String()), "Library/Taps/caskroom")
	files, err := ioutil.ReadDir(tapsDir)
	if err != nil {
		return nil, errors.New("No Caskroom taps found")
	}

	taps := map[string]string{}
	for _, file := range files {
		if file.IsDir() {
			taps[file.Name()] = path.Join(tapsDir, file.Name())
		}
	}

	return taps, nil
}

// ChooseCaskroomTaps searches for the Caskroom taps in the Homebrew directory
// and asks the user to select single or multiple taps. The selected taps will
// be returned as a map with a tap name as a key and a full tap path as a value.
func ChooseCaskroomTaps(msg string) (map[string]string, error) {
	fmt.Print("Searching for Caskroom taps... ")
	taps, err := LookForCaskroomTaps()

	if err != nil {
		fmt.Println("Not found")
		return nil, err
	}

	tapsLen := len(taps)
	if tapsLen > 0 {
		fmt.Printf("Found %d tap", tapsLen)
		if tapsLen != 1 {
			fmt.Print("s")
		}
		fmt.Print("\n\n")

		keys := []string{}
		for k := range taps {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		chosen := []string{}
		prompt := &survey.MultiSelect{
			Message: msg,
			Options: keys,
			Default: []string{"homebrew-cask", "homebrew-versions"},
		}
		survey.AskOne(prompt, &chosen, nil)

		result := map[string]string{}
		for _, choice := range chosen {
			result[choice] = taps[choice]
		}

		fmt.Print("\n")

		return result, nil
	}

	fmt.Println("Not found")
	return nil, errors.New("No Caskroom taps found")
}

// Update updates the Homebrew by running the `brew update` command. Returns
// Stdout as a successful result. Otherwise returns an error.
func Update() (*bytes.Buffer, error) {
	var out bytes.Buffer

	_, err := LookForExecutable()
	if err != nil {
		return nil, err
	}

	cmd := exec.Command("brew", "update")
	cmd.Stdout = &out

	err = cmd.Run()
	if err != nil {
		return nil, errors.New("`brew update` has returned an error")
	}

	return &out, nil
}
