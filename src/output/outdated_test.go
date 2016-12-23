package output

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewOutdated(t *testing.T) {
	o := NewOutdated("example", "outdated", testVersion)

	assert.IsType(t, &Outdated{}, o)
	assert.Equal(t, "example", o.Name)
	assert.Equal(t, testVersion.Appcast.Url, o.Appcast)
	assert.Equal(t, testVersion.Appcast.Request.StatusCode.String(), o.StatusCode)
	assert.Equal(t, testVersion.Current.Value, o.CurrentVersion)
	assert.Equal(t, "outdated", o.Status)
	assert.Equal(t, testVersion.Latest.Version.Value, o.LatestVersion)
	assert.Equal(t, testVersion.Latest.Version.Value, o.SuggestedLatestVersion)
}
