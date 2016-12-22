// Package review implements project specific reviewing features.
package review

import (
	"fmt"
	"io"
	"os"
	"strconv"
)

type Review struct {
	Items   []Item
	Spacing int
}

// New returns a new Review instance. By default the spacing between is "0".
func New(a ...interface{}) *Review {
	spacing := 0
	if len(a) > 0 {
		spacing = a[0].(int)
	}

	r := new(Review)
	r.Spacing = spacing

	return r
}

// dashify returns a dash ("-") if the passed value is empty.
func dashify(value string) string {
	if value == "" {
		value = "-"
	}

	return value
}

// getValuesMaxLength returns the maximum length of a strings in the string
// array.
func getValuesMaxLength(values []string) int {
	length := 0
	for _, value := range values {
		if len(value) > length {
			length = len(value)
		}
	}

	return length
}

// getNameSpacing returns the maximum length of the names + additional spacing.
// If the spacing value in the Review is specified, then it is used instead.
func (self Review) getNameSpacing() (result int) {
	nameLength := 0
	suffixLength := 0

	if self.Spacing == 0 {
		extra := 3 // additional spacing after ":" in review

		for _, item := range self.Items {
			if len(item.Name.Value) > nameLength {
				nameLength = len(item.Name.Value)
			}
			if len(item.Name.PluralSuffix) > suffixLength {
				suffixLength = len(item.Name.PluralSuffix)
			}
		}

		result = nameLength + suffixLength + extra
	} else {
		result = self.Spacing
	}

	return result
}

// AddItem adds a single new item to the Review with the provided name and
// value.
func (self *Review) AddItem(name string, value string) {
	item := NewItem(name)
	item.AddValue(value)
	self.Items = append(self.Items, item)
}

// AddItems adds multiple new items to the Review with the provided name and
// values array. The plural suffix is "s" by default.
func (self *Review) AddItems(name string, values []string, a ...interface{}) {
	// add suffix for pluralization
	suffix := "s"
	if len(a) > 0 {
		suffix = a[0].(string)
	}

	// remove suffix if only one value
	if len(values) <= 1 {
		suffix = ""
	}

	item := NewItem(name, suffix)
	item.Values = values

	self.Items = append(self.Items, item)
}

// AddPipeItems adds multiple new items to the Review with the provided name,
// plural suffix and value group arrays that will be shown in the review as
// values separated by the pipe ("|") character. All the values will be aligned.
//
// Supports multiple groups but each should have the same number of values.
func (self *Review) AddPipeItems(name string, pluralSuffix string, groups ...interface{}) {
	// verify that passed groups have equal number of values
	groupsSize := 0
	for _, g := range groups {
		group := g.([]string)
		if groupsSize == 0 {
			groupsSize = len(group)
		}
	}

	result := []string{}

	for y, _ := range groups[0].([]string) {
		line := ""
		for x := 0; x < len(groups); x++ {
			group := groups[x].([]string)
			current := dashify(group[y])

			if (x + 1) == len(groups) {
				line = line + current
				break
			}

			line = fmt.Sprintf("%s%-"+strconv.Itoa(getValuesMaxLength(group))+"s | ", line, current)
		}

		result = append(result, line)
	}

	self.AddItems(name, result, pluralSuffix)
}

// Fprint prints the Review to the provided Writer.
func (self Review) Fprint(w io.Writer) {
	spacing := strconv.Itoa(self.getNameSpacing())

	for _, item := range self.Items {
		fmt.Fprintf(w, "%-"+spacing+"s ", item.Name.String()+":")
		if len(item.Values) > 0 {
			for i, value := range item.Values {
				if i == 0 {
					if value == "" {
						value = dashify(value)
					}
					fmt.Fprintln(w, value)
				} else {
					if value == "" {
						value = dashify(value)
					}
					fmt.Fprintf(w, "%-"+spacing+"s %s\n", "", value)
				}
			}
		} else {
			fmt.Fprintf(w, dashify(""))
		}
	}
}

// Print prints the Review to the os.Stdout.
func (self Review) Print() {
	self.Fprint(os.Stdout)
}
