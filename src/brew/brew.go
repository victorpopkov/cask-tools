package brew

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"os/exec"
	"path"
	"strings"
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

// Update updates the Homebrew by running the `brew update` command.
func Update() error {
	var out bytes.Buffer

	_, err := LookForExecutable()
	if err != nil {
		return err
	}

	fmt.Print("Running Homebrew update... ")
	cmd := exec.Command("brew", "update")
	cmd.Stdout = &out

	err = cmd.Run()
	if err != nil {
		fmt.Println("Error")
		return err
	}

	scanner := bufio.NewScanner(&out)
	scanner.Scan()
	fmt.Printf("%s\n", scanner.Text())

	return nil
}
