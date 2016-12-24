package cask

import (
	"errors"
	"fmt"
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
func (self Version) Major() (string, error) {
	re := regexp.MustCompile(`^\d`)
	if re.MatchString(self.Current) {
		return re.FindAllString(self.Current, -1)[0], nil
	}
	return "", errors.New(fmt.Sprintf(`No Major() match in version "%s"`, self.Current))
}

// Minor extracts the minor semantic version part.
func (self Version) Minor() (string, error) {
	re := regexp.MustCompile(`^(?:\d)\.(\d)`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No Minor() match in version "%s"`, self.Current))
}

// Patch extracts the patch semantic version part.
func (self Version) Patch() (string, error) {
	re := regexp.MustCompile(`^(?:\d)\.(?:\d)\.(\d)`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No Patch() match in version "%s"`, self.Current))
}

// MajorMinor extracts the major and minor semantic version parts.
func (self Version) MajorMinor() (string, error) {
	re := regexp.MustCompile(`^((?:\d)\.(?:\d))`)
	if re.MatchString(self.Current) {
		return re.FindAllString(self.Current, -1)[0], nil
	}
	return "", errors.New(fmt.Sprintf(`No MajorMinor() match in version "%s"`, self.Current))
}

// MajorMinorPatch extracts the major, minor and patch semantic version parts.
func (self Version) MajorMinorPatch() (string, error) {
	re := regexp.MustCompile(`^((?:\d)\.(?:\d)\.(?:\d))`)
	if re.MatchString(self.Current) {
		return re.FindAllString(self.Current, -1)[0], nil
	}
	return "", errors.New(fmt.Sprintf(`No MajorMinorPatch() match in version "%s"`, self.Current))
}

// BeforeComma extract the part before comma.
func (self Version) BeforeComma() (string, error) {
	re := regexp.MustCompile(`(^.*)\,`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No BeforeComma() match in version "%s"`, self.Current))
}

// AfterComma extract the part after comma.
func (self Version) AfterComma() (string, error) {
	re := regexp.MustCompile(`\,(.*$)`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No AfterComma() match in version "%s"`, self.Current))
}

// BeforeColon extract the part before colon.
func (self Version) BeforeColon() (string, error) {
	re := regexp.MustCompile(`(^.*)\:`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No BeforeColon() match in version "%s"`, self.Current))
}

// AfterColon extract the part after colon.
func (self Version) AfterColon() (string, error) {
	re := regexp.MustCompile(`\:(.*$)`)
	if re.MatchString(self.Current) {
		return re.FindAllStringSubmatch(self.Current, -1)[0][1], nil
	}
	return "", errors.New(fmt.Sprintf(`No AfterColon() match in version "%s"`, self.Current))
}

// NoDots removes all dots from version.
func (self Version) NoDots() (string, error) {
	re := regexp.MustCompile(`\.`)
	if re.MatchString(self.Current) {
		return re.ReplaceAllString(self.Current, ""), nil
	}
	return "", errors.New(fmt.Sprintf(`No NoDots() match in version "%s"`, self.Current))
}

// DotsToUnderscores convert all dots to underscores.
func (self Version) DotsToUnderscores() (string, error) {
	re := regexp.MustCompile(`\.`)
	if re.MatchString(self.Current) {
		return re.ReplaceAllString(self.Current, "_"), nil
	}
	return "", errors.New(fmt.Sprintf(`No DotsToUnderscores() match in version "%s"`, self.Current))
}

// DotsToHyphens convert all dots to hyphens.
func (self Version) DotsToHyphens() (string, error) {
	re := regexp.MustCompile(`\.`)
	if re.MatchString(self.Current) {
		return re.ReplaceAllString(self.Current, "-"), nil
	}
	return "", errors.New(fmt.Sprintf(`No DotsToHyphens() match in version "%s"`, self.Current))
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
				r, err := NewVersion(part).Major()
				if err == nil {
					part = r
				}
				break
			case "minor":
				r, err := NewVersion(part).Minor()
				if err == nil {
					part = r
				}
				break
			case "patch":
				r, err := NewVersion(part).Patch()
				if err == nil {
					part = r
				}
				break
			case "major_minor":
				r, err := NewVersion(part).MajorMinor()
				if err == nil {
					part = r
				}
				break
			case "major_minor_patch":
				r, err := NewVersion(part).MajorMinorPatch()
				if err == nil {
					part = r
				}
				break
			case "before_comma":
				r, err := NewVersion(part).BeforeComma()
				if err == nil {
					part = r
				}
				break
			case "after_comma":
				r, err := NewVersion(part).AfterComma()
				if err == nil {
					part = r
				}
				break
			case "before_colon":
				r, err := NewVersion(part).BeforeColon()
				if err == nil {
					part = r
				}
				break
			case "after_colon":
				r, err := NewVersion(part).AfterColon()
				if err == nil {
					part = r
				}
				break
			case "no_dots":
				r, err := NewVersion(part).NoDots()
				if err == nil {
					part = r
				}
				break
			case "dots_to_underscores":
				r, err := NewVersion(part).DotsToUnderscores()
				if err == nil {
					part = r
				}
				break
			case "dots_to_hyphens":
				r, err := NewVersion(part).DotsToHyphens()
				if err == nil {
					part = r
				}
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
