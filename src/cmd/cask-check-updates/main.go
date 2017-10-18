package main

import (
	"bufio"
	"errors"
	"fmt"
	"io/ioutil"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"brew"

	"github.com/fatih/color"
	"github.com/victorpopkov/go-appcast"
	"github.com/victorpopkov/go-cask"
	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	version = "1.0.0-beta"
	// defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10) http://caskroom.io"

	// userAgent = kingpin.Flag("user-agent", "Set 'User-Agent' header value.").Short('u').PlaceHolder("USER-AGENT").Default(defaultUserAgent).String()

	// casknames = kingpin.Arg("casks", "Cask names.").Strings()
)

func init() {
	kingpin.UsageTemplate(kingpin.CompactUsageTemplate).Version(version)
	kingpin.CommandLine.Help = "Find the latest available versions for casks in Homebrew-Cask taps."
	kingpin.CommandLine.VersionFlag.Short('v')
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()
}

func main() {
	tapsKeys := []string{}

	// Homebrew
	fmt.Print("Looking for Homebrew executable... ")
	_, err := brew.LookForExecutable()
	if err == nil {
		// Homebrew executable is available
		fmt.Println("Found")

		// update Homebrew
		fmt.Print("Running Homebrew update... ")
		out, err := brew.Update()
		if err == nil {
			scanner := bufio.NewScanner(out)
			scanner.Scan()
			fmt.Printf("%s\n", scanner.Text())
		}
	} else {
		// Homebrew executable is not available
		fmt.Println("Not found")
		fmt.Println("Skipping Homebrew update...")
	}

	// choose available Caskroom taps
	taps, _ := brew.ChooseCaskroomTaps("Choose in which taps to look updates for:")
	for k := range taps {
		tapsKeys = append(tapsKeys, k)
	}
	sort.Strings(tapsKeys)

	// iterate over each chosen tap
	if len(tapsKeys) > 0 {
		for _, tapName := range tapsKeys {
			// search for casks with appcast
			fmt.Printf("Searching for casks with appcast in \"%s\" tap... ", color.CyanString(tapName))
			pathCasks := path.Join(taps[tapName], "Casks")
			casksTotal, casksWithAppcast := findCasks(pathCasks)
			lengthCasksWithAppcast := len(casksWithAppcast)

			fmt.Printf("Found %d out of %d\n", lengthCasksWithAppcast, len(casksTotal))

			if lengthCasksWithAppcast == 0 {
				fmt.Print("Skipping...\n\n")
				continue
			}

			// get the longest cask name length for pretty printing
			lengthLongestCaskname := 0
			for _, caskname := range casksWithAppcast {
				if lengthLongestCaskname < len(caskname) {
					lengthLongestCaskname = len(caskname)
				}
			}

			casknameIndent := 3

			// parse found casks with appcast
			fmt.Print("Parsing casks... ")
			casknames, versions, appcasts, checkpoints, errors := parseCasks(pathCasks, casksWithAppcast)

			// count parseCasks errors
			lengthErrors := 0
			for _, err := range errors {
				if err != nil {
					lengthErrors++
				}
			}

			fmt.Printf("Parsed successfully %d out of %d\n", (lengthCasksWithAppcast - lengthErrors), lengthCasksWithAppcast)
			fmt.Print("Checking for updates...\n\n")

			for i, caskname := range casknames {
				currentVersion := versions[i]
				currentAppcast := appcasts[i]
				currentCheckpoint := checkpoints[i]
				err := errors[i]

				if err == nil {
					// check appcast for updates
					a := appcast.New()
					a.LoadFromURL(currentAppcast)
					a.GenerateChecksum(appcast.SHA256HomebrewCask)

					if a.GetChecksum() != currentCheckpoint {
						// outdated
						a.ExtractReleases()

						if len(a.Releases) > 0 {
							newVersion := a.Releases[0].GetVersionOrBuildString()

							if len(newVersion) > 0 && currentVersion != newVersion {
								// outdated (current and new versions doesn't match)
								fmt.Printf("%-"+strconv.Itoa(lengthLongestCaskname+casknameIndent)+"s", caskname)
								fmt.Printf("%s \u2192 %s\n", currentVersion, color.GreenString(newVersion))
							}
						}
					}
				} else {
					// error
					fmt.Printf("%-"+strconv.Itoa(lengthLongestCaskname+casknameIndent)+"s", caskname)
					fmt.Printf("%s\n", color.RedString("error: "+err.Error()))
				}
			}

			if tapsKeys[len(tapsKeys)-1] != tapName {
				fmt.Print("\n")
			}
		}
	}
}

// findCasks finds all casks with appcast in the provided path. Returns two
// slices as a result: the list of all casks and the list of casks with
// appcast.
func findCasks(p string) (t []string, a []string) {
	files, _ := ioutil.ReadDir(p)
	for _, file := range files {
		filename := file.Name()

		// verify that this is the cask file
		re := regexp.MustCompile(`.*\.rb$`)
		if re.MatchString(filename) {
			caskname := strings.TrimSuffix(filename, filepath.Ext(filename)) // remove file extension

			// add to
			t = append(t, caskname)

			// check if cask has an appcast
			hasAppcast, err := caskHasAppcast(p, filename)
			if hasAppcast && err == nil {
				a = append(a, caskname) // add to found
			}
		}
	}

	return t, a
}

// caskHasAppcast checks whether a cask has an appcast. Returns an error if the
// cask hasn't been found.
func caskHasAppcast(p string, cask string) (bool, error) {
	caskname := strings.TrimSuffix(cask, filepath.Ext(cask))
	content, err := getCaskContent(p, caskname)
	if err != nil {
		return false, errors.New("cask not found")
	}

	// check if appcast is available
	re := regexp.MustCompile(`appcast [\'\"]`)
	if re.MatchString(content) {
		return true, nil
	}

	return false, nil
}

// parseCasks parses the casks by using the provided path and casknames. Returns
// multiple slices: casknames, versions, checkpoints, appcasts and errors. All
// returned slices have equal size.
func parseCasks(casksPath string, casknames []string) (c []string, versions []string, appcasts []string, checkpoints []string, errs []error) {
	for _, caskname := range casknames {
		content, err := getCaskContent(casksPath, caskname)
		if err == nil {
			// parse the content
			cask := cask.NewCask(content)
			err = cask.Parse()

			if err == nil {
				for _, v := range cask.Variants {
					c = append(c, caskname)
					versions = append(versions, v.GetVersion().String())
					appcasts = append(appcasts, v.GetAppcast().URL)
					checkpoints = append(checkpoints, v.GetAppcast().Checkpoint)
					errs = append(errs, nil)
				}
			} else {
				// error: parsing failed
				err = errors.New("parsing failed")
			}
		} else {
			// error: cask not found
			err = errors.New("cask not found")
		}

		// error
		c = append(c, caskname)
		versions = append(versions, "")
		appcasts = append(appcasts, "")
		checkpoints = append(checkpoints, "")
		errs = append(errs, err)
	}

	return c, versions, appcasts, checkpoints, errs
}

// getCaskContent returns the cask content string by its path and name.
func getCaskContent(p string, caskname string) (string, error) {
	content, err := ioutil.ReadFile(path.Join(p, fmt.Sprintf("%s.rb", caskname)))
	if err != nil {
		return "", err
	}

	return string(content), nil
}
