package output

import (
	"cask"
	"general"
)

type Outdated struct {
	Name                   string `csv:"Name"`
	Appcast                string `csv:"Appcast"`
	StatusCode             string `csv:"Status code"`
	CurrentVersion         string `csv:"Current version"`
	Status                 string `csv:"Status"`
	LatestVersion          string `csv:"Latest version"`
	SuggestedLatestVersion string `csv:"Suggested latest version"`
}

// NewOutdated creates a new Outdated instance based on provided parameters and
// returns its pointer.
func NewOutdated(name string, status string, v cask.Version) *Outdated {
	o := new(Outdated)

	o.Name = name
	o.Appcast = general.Dashify(v.Appcast.Url)
	o.StatusCode = v.Appcast.Request.StatusCode.String()
	o.CurrentVersion = v.Current
	o.Status = status
	o.LatestVersion = general.Dashify(v.Latest.Version)
	o.SuggestedLatestVersion = general.Dashify(v.Latest.Version)

	return o
}
