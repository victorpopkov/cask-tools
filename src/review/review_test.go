package review

import (
	"bytes"
	"general"
	"testing"

	"github.com/stretchr/testify/assert"
)

var itemsTestCasesKeys = []string{"First", "Second", "Third value", "Fourth value"}
var itemsTestCases = map[string][]string{
	"First":        []string{"value one"},
	"Second":       []string{""},
	"Third value":  []string{"", "value two"},
	"Fourth value": []string{"value one", "", "value three"},
}

func createTestCaseReview() *Review {
	r := new(Review)
	for _, key := range itemsTestCasesKeys {
		suffix := ""
		if len(itemsTestCases[key]) > 1 {
			suffix = "s"
		}

		r.Items = append(r.Items, Item{
			Name: Name{
				Value:        key,
				PluralSuffix: suffix,
			},
			Values: itemsTestCases[key],
		})
	}

	return r
}

func TestNew(t *testing.T) {
	r := New()
	assert.IsType(t, Review{}, *r)
	assert.Empty(t, r.Items)
	assert.Equal(t, 0, r.Spacing)

	r = New(20)
	assert.IsType(t, Review{}, *r)
	assert.Empty(t, r.Items)
	assert.Equal(t, 20, r.Spacing)
}

func TestGetValuesMaxLength(t *testing.T) {
	testCases := []string{"one", "two", "three", "four"}

	expected := 5
	actual := getValuesMaxLength(testCases)

	assert.Equal(t, expected, actual)
}

func TestGetNameSpacing(t *testing.T) {
	r := createTestCaseReview()

	// when spacing taken from name values
	expected := 16
	actual := r.getNameSpacing()
	assert.Equal(t, expected, actual)

	// when spacing taken from the review itself
	expected = 20

	r = new(Review)
	r.Spacing = expected
	actual = r.getNameSpacing()
	assert.Equal(t, expected, actual)
}

func TestAddItem(t *testing.T) {
	r := new(Review)
	for _, key := range itemsTestCasesKeys {
		r.AddItem(key, itemsTestCases[key][0])
	}

	assert.NotEmpty(t, r.Items)
	assert.Len(t, r.Items, len(itemsTestCases))

	for _, item := range r.Items {
		assert.Equal(t, itemsTestCases[item.Name.Value][0], item.Values[0])
	}
}

func TestAddItems(t *testing.T) {
	r := new(Review)
	for _, key := range itemsTestCasesKeys {
		r.AddItems(key, itemsTestCases[key], "s")
	}

	assert.NotEmpty(t, r.Items)
	assert.Len(t, r.Items, len(itemsTestCases))

	for _, item := range r.Items {
		assert.EqualValues(t, itemsTestCases[item.Name.Value], item.Values)
	}
}

func TestAddPipeItems(t *testing.T) {
	r := new(Review)
	r.AddPipeItems(
		"Example",
		"s",
		[]string{"one", "two", "three"},
		[]string{"four", "five", "six"},
		[]string{"seven", "eight", "nine"},
	)

	assert.NotEmpty(t, r.Items)
	assert.Equal(t, "one   | four | seven", r.Items[0].Values[0])
	assert.Equal(t, "two   | five | eight", r.Items[0].Values[1])
	assert.Equal(t, "three | six  | nine", r.Items[0].Values[2])
}

func TestFprint(t *testing.T) {
	var buffer bytes.Buffer

	r := createTestCaseReview()
	r.Fprint(&buffer)
	lines := general.GetLinesFromBuffer(buffer)

	assert.Equal(t, 7, len(lines))
	assert.Equal(t, "First:           value one", lines[0])
	assert.Equal(t, "Second:          -", lines[1])
	assert.Equal(t, "Third values:    -", lines[2])
	assert.Equal(t, "                 value two", lines[3])
	assert.Equal(t, "Fourth values:   value one", lines[4])
	assert.Equal(t, "                 -", lines[5])
	assert.Equal(t, "                 value three", lines[6])

	// test when no value (should be also dashed)
	r = new(Review)
	r.Items = append(r.Items, Item{
		Name: Name{
			Value:        "First",
			PluralSuffix: "",
		},
		Values: nil,
	})

	buffer = bytes.Buffer{}
	r.Fprint(&buffer)
	lines = general.GetLinesFromBuffer(buffer)

	assert.Equal(t, 1, len(lines))
	assert.Equal(t, "First:   -", lines[0])
}
