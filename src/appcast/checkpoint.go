package appcast

import (
	"crypto/sha256"
	"fmt"
	"regexp"
)

type Checkpoint struct {
	Current string
	Latest  string
}

// GetLatest generates a sha256 checksum from the provided content.
func (self *Checkpoint) GetLatest(content string) string {
	// remove <pubDate></pubDate>
	re := regexp.MustCompile(`<pubDate>[^<]*<\/pubDate>`)
	content = re.ReplaceAllString(content, "")

	// generate checkpoint
	checksum := sha256.Sum256([]byte(content))
	self.Latest = fmt.Sprintf("%x", checksum)

	if self.Current == "" {
		self.Current = self.Latest
	}

	return self.Latest
}
