package cask

import (
	"appcast"
	"version"
)

type Version struct {
	Current version.Version
	Latest  Latest
	Appcast appcast.BaseAppcast
}

type Latest struct {
	Version version.Version
	Build   version.Version
}

// NewVersion returns a new Version instance with provided current value and
// returns its pointer. By default the appcast is not specified.
func NewVersion(current string, a ...interface{}) *Version {
	v := new(Version)
	v.Current.Value = current

	if len(a) > 0 {
		v.Appcast = *(a[0]).(*appcast.BaseAppcast)
		v.interpolateVersionIntoAppcast()
	}

	return v
}

// interpolateVersionIntoAppcast interpolates an existing current version value
// into the appcast and then tries to guess the provider by URL again.
func (self *Version) interpolateVersionIntoAppcast() {
	url := version.NewVersion(self.Current.Value).InterpolateIntoString(self.Appcast.Url)
	self.Appcast.Url = url
	self.Appcast.GuessProviderByUrl()
}

// LoadAppcast loads appcast content and extracts releases into its Items array.
func (self *Version) LoadAppcast() {
	self.Appcast = *self.Appcast.LoadContent()

	if len(self.Appcast.Items) > 0 {
		self.Latest.Version.Value = self.Appcast.Items[0].Version.Value
		self.Latest.Build.Value = self.Appcast.Items[0].Build.Value
	}
}
