package appcast

import (
	"fmt"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

func TestSourceForgeParse(t *testing.T) {
	filename := "sourceforge.xml"
	testCases := map[string][]string{
		"2.0.0": []string{"https://sourceforge.net/projects/example/files/app/2.0.0.dmg/download", "10.10"},
		"1.1.0": []string{"https://sourceforge.net/projects/example/files/app/1.1.0.dmg/download", "10.9"},
		"1.0.1": []string{"https://sourceforge.net/projects/example/files/app/1.0.1.dmg/download", "10.9"},
		"1.0.0": []string{"https://sourceforge.net/projects/example/files/app/1.0.0.dmg/download", "10.9"},
	}

	a := new(SourceForgeAppcast)
	a.Content.Original = string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
	a.Provider = SourceForge
	a.PrepareContent()

	// before
	assert.Empty(t, a.Items)

	a.Parse()

	// after
	assert.Len(t, a.Items, 4)
	for _, item := range a.Items {
		v := item.Version.Value
		assert.Equal(t, v, item.Version.Value)
		assert.Empty(t, "", item.Build.Value)
		assert.Equal(t, testCases[v][0], item.Urls[0])
		assert.Equal(t, "", item.MinimumSystemVersion)
	}
}
