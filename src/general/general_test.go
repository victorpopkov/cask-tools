package general

import (
	"bufio"
	"bytes"
	"os"
	"path"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

var testdataFile = "../appcast/testdata/unknown.xml"

func TestGetTerminalWidth(t *testing.T) {
	var (
		buffer   bytes.Buffer
		expected int
		actual   int
	)

	exiter := NewExit(func(int) {})

	// default
	expected = 25
	actual = getTerminalWidth()
	assert.Equal(t, expected, actual)

	// when no cmd
	expected = 40
	actual = getTerminalWidth("160 40")
	assert.Equal(t, expected, actual)

	// when error converting to integer
	expected = 40
	actual = getTerminalWidth("160 error", exiter, bufio.NewWriter(&buffer))
	assert.Regexp(t, `strconv.ParseInt: parsing "error": invalid syntax`, buffer.String())
}

func TestTerminalPrintHr(t *testing.T) {
	var buffer bytes.Buffer

	TerminalPrintHr('-', bufio.NewWriter(&buffer))

	assert.Equal(t, "-------------------------\n", buffer.String())
}

func TestError(t *testing.T) {
	var buffer bytes.Buffer

	exiter := NewExit(func(int) {})

	Error("Error", exiter, bufio.NewWriter(&buffer))

	assert.Equal(t, 1, exiter.Status())
	assert.Regexp(t, "Error", buffer.String())
}

func TestGetWorkingDir(t *testing.T) {
	actual := path.Base(GetWorkingDir())
	expected := "general"

	assert.Equal(t, expected, actual)
}

func TestIsCasksDir(t *testing.T) {
	assert.False(t, IsCasksDir())

	assert.True(t, IsCasksDir("homebrew-cask/casks"))
	assert.True(t, IsCasksDir("homebrew-Cask/Casks"))
}

func TestGetFileContent(t *testing.T) {
	var buffer bytes.Buffer

	exiter := NewExit(func(int) {})

	// default
	actual := string(GetFileContent(testdataFile))
	expected := `<?xml version="1.0"?>
<rss xmlns:dc="http://purl.org/dc/elements/1.1/">
  <updates>
  </updates>
</rss>
`
	assert.Equal(t, expected, actual)

	// file not found
	actual = string(GetFileContent("error.txt", exiter, bufio.NewWriter(&buffer)))
	assert.Empty(t, actual)
	assert.Regexp(t, `open .*\: no such file or directory`, buffer.String())
}

func TestReadLine(t *testing.T) {
	lineNum := 4

	fullPath := filepath.Join(GetWorkingDir(), testdataFile)
	r, err := os.Open(fullPath)
	if err != nil {
		t.Fatalf("File \"%s\" doesn't exist", fullPath)
	}

	actual, lastLine, err := ReadLine(r, lineNum)
	expected := "  </updates>"

	assert.Equal(t, expected, actual)
	assert.Equal(t, lineNum, lastLine)
	assert.Nil(t, err)
}

func TestGetLineFromFile(t *testing.T) {
	var buffer bytes.Buffer

	exiter := NewExit(func(int) {})
	lineNum := 4

	// default
	actual, _, _ := GetLineFromFile(lineNum, testdataFile)
	expected := "  </updates>"
	assert.Equal(t, expected, actual)

	// file not found
	actual, _, _ = GetLineFromFile(lineNum, "error.txt", exiter, bufio.NewWriter(&buffer))
	assert.Empty(t, actual)
	assert.Regexp(t, `open .*\: no such file or directory`, buffer.String())
}

func TestGetLineFromString(t *testing.T) {
	lineNum := 2
	content := `line 1
line 2
line 3
`

	actual, _, _ := GetLineFromString(lineNum, content)
	expected := "line 2"

	assert.Equal(t, expected, actual)
}

func TestGetLinesFromBuffer(t *testing.T) {
	var buffer bytes.Buffer

	buffer.Write([]byte("first line\nsecond line\nthird line"))

	lines := GetLinesFromBuffer(buffer)

	assert.Len(t, lines, 3)
	assert.Equal(t, "first line", lines[0])
	assert.Equal(t, "second line", lines[1])
	assert.Equal(t, "third line", lines[2])
}
