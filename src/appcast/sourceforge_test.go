package appcast

import (
	"fmt"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

var testCases = map[string]map[string][]string{
	"sourceforge_empty.xml": map[string][]string{},
	"sourceforge_single.xml": map[string][]string{
		"2.0.0": []string{"https://sourceforge.net/projects/example/files/app/2.0.0.dmg/download", "10.10"},
	},
	"sourceforge.xml": map[string][]string{
		"2.0.0": []string{"https://sourceforge.net/projects/example/files/app/2.0.0.dmg/download", "10.10"},
		"1.1.0": []string{"https://sourceforge.net/projects/example/files/app/1.1.0.dmg/download", "10.9"},
		"1.0.1": []string{"https://sourceforge.net/projects/example/files/app/1.0.1.dmg/download", "10.9"},
		"1.0.0": []string{"https://sourceforge.net/projects/example/files/app/1.0.0.dmg/download", "10.9"},
	},
}

func TestSourceForgeParse(t *testing.T) {
	for filename, values := range testCases {
		a := new(SourceForgeAppcast)
		a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
		a.Provider = SourceForge
		a.PrepareContent()

		// before
		assert.Empty(t, a.Items)

		a.Parse()

		// after
		assert.Len(t, a.Items, len(values))
		for _, item := range a.Items {
			v := item.Version.Value
			assert.Equal(t, v, item.Version.Value)
			assert.Empty(t, "", item.Build.Value)
			assert.Equal(t, values[v][0], item.Urls[0])
			assert.Equal(t, "", item.MinimumSystemVersion)
		}
	}
}
