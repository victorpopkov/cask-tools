package cask

import (
	"regexp"
	"strings"

	"appcast"
)

type Version struct {
	Current string
	Latest  Latest
	Appcast appcast.BaseAppcast
}

type Latest struct {
	Version string
	Build   string
}

// NewVersion returns a new Version instance with provided current value and
// returns its pointer. By default the appcast is not specified.
func NewVersion(current string, a ...interface{}) *Version {
	v := new(Version)
	v.Current = current

	if len(a) > 0 {
		v.Appcast = *(a[0]).(*appcast.BaseAppcast)
		v.interpolateVersionIntoAppcast()
	}

	return v
}

// interpolateVersionIntoAppcast interpolates an existing current version value
// into the appcast and then tries to guess the provider by URL again.
func (self *Version) interpolateVersionIntoAppcast() {
	url := NewVersion(self.Current).InterpolateIntoString(self.Appcast.Url)
	self.Appcast.Url = url
	self.Appcast.GuessProviderByUrl()
}

// LoadAppcast loads appcast content and extracts releases into its Items array.
func (self *Version) LoadAppcast() {
	self.Appcast = *self.Appcast.LoadContent()

	if len(self.Appcast.Items) > 0 {
		self.Latest.Version = self.Appcast.Items[0].Version.Value
		self.Latest.Build = self.Appcast.Items[0].Build.Value
	}
}

// Major extracts the major semantic version part.
func (self Version) Major() string {
	re := regexp.MustCompile(`^\d`)
	return re.FindAllString(self.Current, -1)[0]
}

// Minor extracts the minor semantic version part.
func (self Version) Minor() string {
	re := regexp.MustCompile(`^(?:\d)\.(\d)`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// Patch extracts the patch semantic version part.
func (self Version) Patch() string {
	re := regexp.MustCompile(`^(?:\d)\.(?:\d)\.(\d)`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// MajorMinor extracts the major and minor semantic version parts.
func (self Version) MajorMinor() string {
	re := regexp.MustCompile(`^((?:\d)\.(?:\d))`)
	return re.FindAllString(self.Current, -1)[0]
}

// MajorMinorPatch extracts the major, minor and patch semantic version parts.
func (self Version) MajorMinorPatch() string {
	re := regexp.MustCompile(`^((?:\d)\.(?:\d)\.(?:\d))`)
	return re.FindAllString(self.Current, -1)[0]
}

// BeforeComma extract the part before comma.
func (self Version) BeforeComma() string {
	re := regexp.MustCompile(`(^.*)\,`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// AfterComma extract the part after comma.
func (self Version) AfterComma() string {
	re := regexp.MustCompile(`\,(.*$)`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// BeforeColon extract the part before colon.
func (self Version) BeforeColon() string {
	re := regexp.MustCompile(`(^.*)\:`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// AfterColon extract the part after colon.
func (self Version) AfterColon() string {
	re := regexp.MustCompile(`\:(.*$)`)
	return re.FindAllStringSubmatch(self.Current, -1)[0][1]
}

// NoDots removes all dots from version.
func (self Version) NoDots() string {
	re := regexp.MustCompile(`\.`)
	return re.ReplaceAllString(self.Current, "")
}

// DotsToUnderscores convert all dots to underscores.
func (self Version) DotsToUnderscores() string {
	re := regexp.MustCompile(`\.`)
	return re.ReplaceAllString(self.Current, "_")
}

// DotsToHyphens convert all dots to hyphens.
func (self Version) DotsToHyphens() string {
	re := regexp.MustCompile(`\.`)
	return re.ReplaceAllString(self.Current, "-")
}

// InterpolateIntoString interpolates existing version into the provided string
// with Ruby interpolation syntax.
func (self Version) InterpolateIntoString(content string) (result string) {
	result = content

	regexInterpolations := regexp.MustCompile(`(#{version})|(#{version\.[^}]*.[^{]*})`)
	regexAllMethods := regexp.MustCompile(`(?:^#{version\.)(.*)}`)

	// find all version interpolations
	matches := regexInterpolations.FindAllStringSubmatch(content, -1)

	// for every version interpolation
	for _, m := range matches {
		match := m[0]

		// extract all methods
		methodsAll := regexAllMethods.FindAllStringSubmatch(match, -1)
		if len(methodsAll) < 1 {
			// when no methods, then it's just a version replace
			re := regexp.MustCompile(match)
			result = re.ReplaceAllString(result, self.Current)
			continue
		}

		methods := strings.Split(methodsAll[0][1], ".")

		// for every method
		part := self.Current
		for _, method := range methods {
			switch method {
			case "major":
				part = NewVersion(part).Major()
				break
			case "minor":
				part = NewVersion(part).Minor()
				break
			case "patch":
				part = NewVersion(part).Patch()
				break
			case "major_minor":
				part = NewVersion(part).MajorMinor()
				break
			case "major_minor_patch":
				part = NewVersion(part).MajorMinorPatch()
				break
			case "before_comma":
				part = NewVersion(part).BeforeComma()
				break
			case "after_comma":
				part = NewVersion(part).AfterComma()
				break
			case "before_colon":
				part = NewVersion(part).BeforeColon()
				break
			case "after_colon":
				part = NewVersion(part).AfterColon()
				break
			case "no_dots":
				part = NewVersion(part).NoDots()
				break
			case "dots_to_underscores":
				part = NewVersion(part).DotsToUnderscores()
				break
			case "dots_to_hyphens":
				part = NewVersion(part).DotsToHyphens()
				break
			default:
				// if one of the methods is unknown, then return full string without any replacements
				return result
			}
		}

		re := regexp.MustCompile(match)
		result = re.ReplaceAllString(result, part)
	}

	return result
}
