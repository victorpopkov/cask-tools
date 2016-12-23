package output

import (
	"io/ioutil"
	"testing"

	"appcast"
	"cask"

	"github.com/stretchr/testify/assert"
)

var testVersion = cask.Version{
	Current: "1.1.0",
	Latest: cask.Latest{
		Version: "2.0.0-beta",
		Build:   "200",
	},
	Appcast: *(appcast.New("https://example.com/")),
}

func TestNew(t *testing.T) {
	o := New()

	assert.IsType(t, &Output{}, o)
	assert.Empty(t, o.Outdated)
}

func TestAddOutdated(t *testing.T) {
	o := New()

	// before
	assert.Empty(t, o.Outdated)

	o.AddOutdated("example", "outdated", testVersion)

	// after
	assert.Len(t, o.Outdated, 1)
}

func TestSaveOutdatedAsCSVToFile(t *testing.T) {
	file, _ := ioutil.TempFile("", "")

	o := New()
	o.AddOutdated("example", "outdated", testVersion)

	// default
	err := o.SaveOutdatedAsCSVToFile(file.Name())
	assert.Nil(t, err)

	// invalid path
	err = o.SaveOutdatedAsCSVToFile("")
	assert.Regexp(t, "no such file or directory", err.Error())
}
