// Package output implements project specific output features.
package output

import (
	"cask"
	"os"

	"github.com/gocarina/gocsv"
)

type Output struct {
	Outdated []Outdated
}

// New creates a new Output instance and returns its pointer.
func New() *Output {
	return new(Output)
}

// AddOutdated adds a new Outdated instance to the Outdated slice.
func (self *Output) AddOutdated(name string, status string, v cask.Version) {
	self.Outdated = append(self.Outdated, *NewOutdated(name, status, v))
}

// SaveOutdatedAsCSVToFile marshals the Outdated slice as CSV and saves the
// result to file.
func (self Output) SaveOutdatedAsCSVToFile(path string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}

	gocsv.MarshalFile(self.Outdated, file)

	return nil
}
