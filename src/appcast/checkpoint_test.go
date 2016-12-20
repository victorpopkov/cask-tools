package appcast

import (
	"fmt"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

func TestGetLatest(t *testing.T) {
	testCases := map[string]string{
		"github_default.xml":                 "1e92c6187485bdafa39716f824ddf8c1233e776fd23f9a0d42032bedc92edfb8",
		"sourceforge.xml":                    "1eed329e29aa768b242d23361adf225a654e7df74d58293a44d14862ef7ef975",
		"sparkle_attributes_as_elements.xml": "06a16fc0d5c7f8e18ca04dbc52138159b5438cdb929e033dae6ddebca7e710fc",
		"sparkle_default_asc.xml":            "8ad0cd8d67f12ed75fdfbf74e904ef8b82084875c959bec00abd5a166c512b5d",
		"sparkle_default.xml":                "583743f5e8662cb223baa5e718224fa11317b0983dbf8b3c9c8d412600b6936c",
		"sparkle_incorrect_namespace.xml":    "f7ced8023765dc7f37c3597da7a1f8d33b3c22cc764e329babd3df16effdd245",
		"sparkle_multiple_enclosure.xml":     "6ba0ab0e37d4280803ff2f197aaf362a3553849fb296a64bc946eda1bdb759c7",
		"sparkle_no_releases.xml":            "65911706576dab873c2b30b2d6505581d17f8e2c763da7320cfb06bbc2d4eaca",
		"sparkle_single.xml":                 "98c94ba87d4eb1d99b56652b537a26d3c68efa7efa5f497839a3832a31147a7a",
		"sparkle_without_comments.xml":       "88ceb464f652d7bf43f351f41637facd671f8f04e9a32b4b077886d24251e472",
		"sparkle_without_namespaces.xml":     "d4cdd55c6dbf944d03c5267f3f7be4a9f7c2f1b94929359ce7e21aeef3b0747b",
		"unknown.xml":                        "a4161a72df970e6fca434e2b9e256b850f12d2934cdde057985b77ea892f35d8",
	}

	for filename, checkpoint := range testCases {
		// preparations
		content := string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
		c := new(Checkpoint)

		// before
		assert.Empty(t, c.Latest, "Latest checkpoint should be empty before calling GetLatestCheckpoint()")

		c.GetLatest(content)

		// after
		expected := checkpoint
		actual := c.Latest
		assert.Equal(t, expected, actual, "Latest checkpoints doesn't match.")
	}
}
