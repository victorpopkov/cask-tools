package appcast

import (
	"encoding/xml"

	"version"
)

type SourceForgeAppcast struct {
	BaseAppcast
}

type SourceForgeVersionGroup struct {
	Versions []SourceForgeVersion
}

type SourceForgeVersion struct {
	Version version.Version
	Urls    []string
	Weight  int
}

type SourceForgeXml struct {
	Items []SourceForgeXmlItem `xml:"channel>item"`
}

type SourceForgeXmlItem struct {
	Title   SourceForgeXmlTitle   `xml:"title"`
	Content SourceForgeXmlContent `xml:"content"`
}

type SourceForgeXmlTitle struct {
	Chardata string `xml:",chardata"`
}

type SourceForgeXmlContent struct {
	Url string `xml:"url,attr"`
}

// Parse() unmarshals modified content based on SourceForge XML and stores the
// used values in the BaseAppcast Item array.
func (self *SourceForgeAppcast) Parse() {
	var (
		x     SourceForgeXml
		items []Item
	)
	xml.Unmarshal([]byte(self.Content.Modified), &x)

	groups := version.NewGroups()

	for _, item := range x.Items {
		// create a version group with single or multiple versions
		g := version.NewGroup()
		g.ExtractAll(item.Title.Chardata)
		g.AddUrl(item.Content.Url)

		// add this group to collection
		if len(g.Versions) > 0 {
			groups.AddGroup(*g)
		}
	}

	groups.Weighten()
	groups.GroupVersions()
	groups.CleanByWeights()

	for _, group := range groups.Groups {
		items = append(items, Item{
			Version: group.PreferredVersion,
			Urls:    group.Urls,
		})
	}

	self.Items = items
}
