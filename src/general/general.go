// Package general implements different helper functions.
package general

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/fatih/color"
)

// getTerminalWidth return the terminal width, if it's available. Otherwise, the
// default width "25" will be returned.
//
// Supports different io.Writer and exit function for error printing.
func getTerminalWidth(a ...interface{}) int {
	cmd := exec.Command("stty", "size")
	cmd.Stdin = os.Stdin

	out, err := cmd.Output()
	exiter := DefaultExit()
	writer := bufio.NewWriter(os.Stdout)

	if len(a) > 0 {
		out = []byte(a[0].(string))
	}

	if len(a) > 1 {
		exiter = a[1].(*Exit)
	}

	if len(a) > 2 {
		writer = a[2].(*bufio.Writer)
	}

	if err == nil || len(out) > 0 {
		parts := strings.Split(string(out), " ")
		y, err := strconv.Atoi(strings.Replace(parts[1], "\n", "", 1))
		if err != nil {
			Error(err.Error(), exiter, writer)
		}

		return y
	}

	return 25
}

// TerminalPrintHr prints a separator that consists of provided character. By
// default it outputs to os.Stdout but different io.Writer can be used.
func TerminalPrintHr(char byte, a ...interface{}) {
	writer := bufio.NewWriter(os.Stdout)
	if len(a) > 0 {
		writer = a[0].(*bufio.Writer)
	}

	y := getTerminalWidth()
	for i := 0; i < y; i++ {
		fmt.Fprintf(writer, "%s", string(char))
	}
	fmt.Fprintf(writer, "\n")

	writer.Flush()
}

// Error prints a provided string as an error to os.Stdout by default and
// returns exit status 1.
//
// Supports different io.Writer and exit function for error printing.
func Error(e string, a ...interface{}) {
	exiter := DefaultExit()
	writer := bufio.NewWriter(os.Stdout)

	if len(a) > 0 {
		exiter = a[0].(*Exit)
	}

	if len(a) > 1 {
		writer = a[1].(*bufio.Writer)
	}

	fmt.Fprintln(writer, color.RedString(e))
	writer.Flush()
	exiter.Exit(1)
}

// GetWorkingDir return a current working directory. If it's not available
// outputs an error and exits program with error status 1.
func GetWorkingDir() string {
	pwd, err := os.Getwd()
	if err != nil {
		Error(err.Error())
	}

	return pwd
}

// IsCasksDir checks if current working directory matches "homebrew-.*/Casks".
func IsCasksDir(other ...interface{}) bool {
	dir := GetWorkingDir()
	if len(other) > 0 {
		dir = other[0].(string)
	}

	re := regexp.MustCompile("(?i)homebrew-.*/Casks")

	return re.MatchString(dir)
}

// GetFileContent get file content as a byte array from provided file path. If
// file not found, prints an error to os.Stdout by default with exit status 1.
//
// Supports different io.Writer and exit function for error printing.
func GetFileContent(relativePath string, a ...interface{}) []byte {
	exiter := DefaultExit()
	writer := bufio.NewWriter(os.Stdout)

	if len(a) > 0 {
		exiter = a[0].(*Exit)
	}

	if len(a) > 1 {
		writer = a[1].(*bufio.Writer)
	}

	content, err := ioutil.ReadFile(filepath.Join(GetWorkingDir(), relativePath))
	if err != nil {
		Error(err.Error(), exiter, writer)
	}

	return content
}

// ReadLine reads a provided line number from io.Reader and returns it.
func ReadLine(r io.Reader, lineNum int) (line string, lastLine int, err error) {
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		lastLine++
		if lastLine == lineNum {
			return sc.Text(), lastLine, sc.Err()
		}
	}

	return line, lastLine, io.EOF
}

// GetLineFromFile returns a line from provided file path and line number. By
// default uses os.Stdout for error printing.
//
// Supports different io.Writer and exit function for error printing.
func GetLineFromFile(lineNum int, relativePath string, a ...interface{}) (line string, lastLine int, err error) {
	exiter := DefaultExit()
	writer := bufio.NewWriter(os.Stdout)

	if len(a) > 0 {
		exiter = a[0].(*Exit)
	}

	if len(a) > 1 {
		writer = a[1].(*bufio.Writer)
	}

	r, err := os.Open(filepath.Join(GetWorkingDir(), relativePath))
	if err != nil {
		Error(err.Error(), exiter, writer)
	}

	return ReadLine(r, lineNum)
}

// GetLineFromString returns a line from string content based on provided line
// number.
func GetLineFromString(lineNum int, content string) (line string, lastLine int, err error) {
	r := bytes.NewReader([]byte(content))

	return ReadLine(r, lineNum)
}
