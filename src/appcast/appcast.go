// Package appcast implements project specific appcast features.
package appcast

import (
	"bufio"
	"fmt"
	"general"
	"io"
	"os"
	"regexp"

	"request"
	"version"
)

type Appcast interface {
	GetUrl() string
	GetRequest() request.Request
	GetContent() string
	GetCheckpoint() Checkpoint
	GetProvider() Provider
	GetItems() []Item
	PrepareContent()
	LoadContent() *BaseAppcast
	Parse()
	AddItem()
	SortItemsByVersions() []Item
}

type BaseAppcast struct {
	Url        string
	Request    request.Request
	Content    Content
	Checkpoint Checkpoint
	Provider   Provider
	Items      []Item
	Filter     *regexp.Regexp
}

type Content struct {
	Original string
	Modified string
}

type Item struct {
	Version              version.Version
	Build                version.Version
	Urls                 []string
	MinimumSystemVersion string
}

// New returns a new BaseAppcast instance with provided URL and User-Agent. By
// default the content loading is enabled.
func New(url string) *BaseAppcast {
	a := new(BaseAppcast)
	a.Url = url
	a.GuessProviderByUrl()

	return a
}

// GetUrl gets appcast URL.
func (self BaseAppcast) GetUrl() string {
	return self.Url
}

// GetRequest gets Request struct.
func (self BaseAppcast) GetRequest() request.Request {
	return self.Request
}

// GetContent gets appcast Content struct.
func (self BaseAppcast) GetContent() Content {
	return self.Content
}

// GetCheckpoint gets appcast Checkpoint struct.
func (self BaseAppcast) GetCheckpoint() Checkpoint {
	return self.Checkpoint
}

// GetProvider gets appcast Provider const.
func (self BaseAppcast) GetProvider() Provider {
	return self.Provider
}

// GetItems gets appcast array of items as Item structs.
func (self BaseAppcast) GetItems() []Item {
	return self.Items
}

// GuessProviderByUrl guesses the provider by URL and replaces current URL with
// new one if needed.
func (self *BaseAppcast) GuessProviderByUrl() {
	p := new(Provider)
	self.Provider, self.Request.Url = p.GuessByUrl(self.Url)
}

// LoadContent loads content in the Request, generates checkpoints, sets the
// guessed provider and return the new BaseAppcast instance.
func (self *BaseAppcast) LoadContent() *BaseAppcast {
	self.Request.LoadContent()
	self.Content.Original = string(self.Request.Content)

	// guess provider by content if guessing by URL failed
	provider := new(Provider)
	if self.Provider == Unknown {
		self.Provider = provider.GuessByContent(self.Content.Original)
	}

	// checkpoint
	self.Checkpoint.GetLatest(self.Content.Original)

	switch self.Provider {
	case GitHubAtom:
		g := GitHubAppcast{BaseAppcast: *self}
		g.PrepareContent()
		g.Parse()
		self = &g.BaseAppcast
		break
	case Sparkle:
		s := SparkleAppcast{BaseAppcast: *self}
		s.PrepareContent()
		s.Parse()
		self = &s.BaseAppcast
		break
	case SourceForge:
		s := SourceForgeAppcast{BaseAppcast: *self}
		s.PrepareContent()
		s.Parse()
		self = &s.BaseAppcast
		break
	}

	return self
}

// PrepareContent basically just copies Original content to Modified.
// Implemented in provider specific appcasts this functions can have different
// purposes for content preparations.
func (self *BaseAppcast) PrepareContent() {
	if self.Content.Original == "" {
		return
	}

	self.Content.Modified = self.Content.Original
}

// Parse should be implemented by provider specific appcasts in order to parse
// loaded content to retrieve the versions.
func (self *BaseAppcast) Parse(a ...interface{}) {
	exiter := general.DefaultExit()
	writer := bufio.NewWriter(os.Stdout)

	if len(a) > 0 {
		exiter = a[0].(*general.Exit)
	}

	if len(a) > 1 {
		writer = a[1].(*bufio.Writer)
	}

	general.Error("Parse() not implemented", exiter, writer)
}

// AddItem adds a new Item to the appcast items array based on provided version
// and build. The Urls and MinimumSystemVersion are optional.
func (self *BaseAppcast) AddItem(version version.Version, build version.Version, a ...interface{}) {
	urls := []string{}
	if len(a) > 0 {
		urls = a[0].([]string)
	}

	minimumSystemVersion := ""
	if len(a) > 1 {
		minimumSystemVersion = a[1].(string)
	}

	item := Item{
		Version:              version,
		Build:                build,
		Urls:                 urls,
		MinimumSystemVersion: minimumSystemVersion,
	}

	self.Items = append(self.Items, item)
}

// SortItemsByVersions sorts Item array by versions. Can be useful if the
// versions order in the content is inconsistent.
func (self *BaseAppcast) SortItemsByVersions() {
	var v1 *version.Version
	var v2 *version.Version

	items := self.Items

	// comparison priorities
	priorities := [][]string{
		{items[0].Version.Value, items[1].Version.Value},
		{items[0].Build.Value, items[1].Build.Value},
		{items[len(items)-2].Version.Value, items[len(items)-1].Version.Value},
	}

	// create versions for comparison
	for _, priority := range priorities {
		if priority[0] != "" && priority[1] != "" {
			v1 = version.NewVersion(priority[0])
			v2 = version.NewVersion(priority[1])

			// compare
			firstLess, err := v1.LessThan(v2)
			if err == nil && firstLess {
				// reverse items, if the first version is less than second one
				newItems := make([]Item, len(items))
				for i, j := 0, len(items)-1; i < j; i, j = i+1, j-1 {
					newItems[i], newItems[j] = items[j], items[i]
				}

				self.Items = newItems
			}
		}
	}
}

// FprintSingleVersionAndBuild prints only the version and/or build of the first
// item. By default it only uses first Item from the Items array, but it can be
// changed.
func (self BaseAppcast) FprintSingleVersionAndBuild(w io.Writer, a ...interface{}) {
	i := 0
	if len(a) > 0 {
		i = a[0].(int)
	}

	if len(self.Items) > 0 {
		fmt.Fprint(w, self.Items[i].Version.Value)
		if self.Items[i].Build.Value != "" {
			fmt.Fprintf(w, " %s", self.Items[i].Build.Value)
		}
		fmt.Fprint(w, "\n")
		return
	}

	fmt.Fprintln(w, "-")
}

// FprintSingleDownloads prints only the download URLs of the first item. By
// default only uses first Item from the Items array, but it can be changed.
func (self BaseAppcast) FprintSingleDownloads(w io.Writer, a ...interface{}) {
	i := 0
	if len(a) > 0 {
		i = a[0].(int)
	}

	if len(self.Items) > 0 {
		for _, url := range self.Items[i].Urls {
			fmt.Fprintln(w, url)
		}
		return
	}

	fmt.Fprintln(w, "-")
}
