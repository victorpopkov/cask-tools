package appcast

import (
	"encoding/json"
	"regexp"
	"time"

	"version"
)

type GitHubAppcast struct {
	BaseAppcast
}

type GitHubJson []struct {
	URL         string        `json:"url"`
	TagName     string        `json:"tag_name"`
	Name        string        `json:"name"`
	Draft       bool          `json:"draft"`
	Prerelease  bool          `json:"prerelease"`
	CreatedAt   time.Time     `json:"created_at"`
	PublishedAt time.Time     `json:"published_at"`
	Assets      []GitHubAsset `json:"assets"`
}

type GitHubAsset struct {
	URL                string    `json:"url"`
	ID                 int       `json:"id"`
	Name               string    `json:"name"`
	Label              string    `json:"label"`
	ContentType        string    `json:"content_type"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
	BrowserDownloadURL string    `json:"browser_download_url"`
}

// Parse() unmarshals modified content based on JSON provided by GitHub API and
// stores the used values in the BaseAppcast Item array.
func (self *GitHubAppcast) Parse() {
	var (
		j     GitHubJson
		items []Item
	)
	json.Unmarshal([]byte(self.Content.Modified), &j)

	groups := version.NewGroups()

	for _, item := range j {
		for _, asset := range item.Assets {
			// if filter is set, skip all the releases that don't match the tag name
			if self.Filter != nil && !self.Filter.MatchString(item.TagName) {
				continue
			}

			// remove the first "v" from string
			re := regexp.MustCompile(`^v`)
			v := re.ReplaceAllString(item.TagName, "")

			// create a version group with single version
			g := version.NewGroup()
			g.AddVersion(v, 0, item.Prerelease)
			g.AddUrl(asset.BrowserDownloadURL)

			// add this group to collection
			if len(g.Versions) > 0 {
				groups.AddGroup(*g)
			}
		}
	}

	groups.GroupVersions()

	for _, group := range groups.Groups {
		items = append(items, Item{
			Version: group.Versions[0],
			Urls:    group.Urls,
		})
	}

	self.Items = items
}
