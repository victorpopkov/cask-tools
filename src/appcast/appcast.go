// Package appcast implements project specific appcast features.
package appcast

import (
	"log"

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
	SortItemsByVersions() []Item
}

type BaseAppcast struct {
	Url        string
	Request    request.Request
	Content    Content
	Checkpoint Checkpoint
	Provider   Provider
	Items      []Item
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
func New(url string, userAgent string, a ...interface{}) *BaseAppcast {
	urlOriginal := url
	appcast := new(BaseAppcast)
	provider := new(Provider)

	// content loading is enabled by default
	load := true
	if len(a) > 0 {
		load = a[0].(bool)
	}

	// guess provider by URL and replace current URL with new one if needed
	appcast.Provider, url = provider.GuessByUrl(url)

	// request
	appcast.Url = urlOriginal
	appcast.Request.Url = url
	appcast.Request.AddHeader("User-Agent", userAgent)

	// load content and guess provider
	if load {
		appcast = appcast.LoadContent()
	}

	return appcast
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

// PrepareContent basically just copies Original content to Modified.
// Implemented in provider specific appcasts this functions can have different
// purposes for content preparations.
func (self *BaseAppcast) PrepareContent() {
	if self.Content.Original == "" {
		return
	}

	self.Content.Modified = self.Content.Original
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

// Parse should be implemented by provider specific appcasts in order to parse
// loaded content to retrieve the versions.
func (self *BaseAppcast) Parse() {
	log.Fatal("Parse() not implemented")
}

// SortItemsByVersions sorts Item array by versions. Can be useful if the
// versions order in the content is inconsistent.
func (self *BaseAppcast) SortItemsByVersions(items []Item) []Item {
	var v1 *version.Version
	var v2 *version.Version

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
			break
		}
	}

	// compare
	if v1.LessThan(v2) {
		// reverse items, if the first version is less than second one
		newItems := make([]Item, len(items))
		for i, j := 0, len(items)-1; i < j; i, j = i+1, j-1 {
			newItems[i], newItems[j] = items[j], items[i]
		}

		return newItems
	}

	return items
}
