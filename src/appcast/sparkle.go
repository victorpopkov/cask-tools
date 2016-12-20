package appcast

import (
	"encoding/xml"
	"regexp"

	"version"
)

type SparkleAppcast struct {
	BaseAppcast
}

type SparkleXml struct {
	Items []SparkleXmlItem `xml:"channel>item"`
}

type SparkleXmlItem struct {
	Title                string              `xml:"title"`
	MinimumSystemVersion string              `xml:"minimumSystemVersion"`
	Enclosure            SparkleXmlEnclosure `xml:"enclosure"`
}

type SparkleXmlEnclosure struct {
	Version            string `xml:"version,attr"`
	ShortVersionString string `xml:"shortVersionString,attr"`
	Url                string `xml:"url,attr"`
}

// PrepareContent modifies original content by uncommenting existing lines in
// Sparkle XML and stores it as modified value.
func (self *SparkleAppcast) PrepareContent() {
	if self.Content.Original == "" {
		return
	}

	// uncomment XML tags
	regex := regexp.MustCompile(`(<!--([[:space:]]*)?)|(([[:space:]]*)?-->)`)
	if regex.MatchString(self.Content.Original) {
		self.Content.Modified = regex.ReplaceAllString(self.Content.Original, "")
		return
	}

	self.Content.Modified = self.Content.Original
}

// Parse() unmarshals modified content based on Sparkle XML and stores the used
// values in the BaseAppcast Item array.
func (self *SparkleAppcast) Parse() {
	var x SparkleXml
	xml.Unmarshal([]byte(self.Content.Modified), &x)

	items := make([]Item, len(x.Items))
	for i, item := range x.Items {
		items[i] = Item{
			Version: version.Version{
				Value:      item.Enclosure.ShortVersionString,
				Weight:     0,
				Prerelease: false,
			},
			Build: version.Version{
				Value:      item.Enclosure.Version,
				Weight:     0,
				Prerelease: false,
			},
			Urls:                 []string{item.Enclosure.Url},
			MinimumSystemVersion: item.MinimumSystemVersion,
		}
	}

	if len(items) > 1 {
		self.Items = self.SortItemsByVersions(items)
	} else {
		self.Items = items
	}
}
