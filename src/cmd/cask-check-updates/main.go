package main

import (
	"encoding/base64"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"cask"
	"general"
	"output"
	"review"

	"github.com/fatih/color"
	"github.com/gosuri/uilive"
	gitconfig "github.com/tcnksm/go-gitconfig"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	version          = "1.0.0-alpha.7"
	defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
	nameSpacing      = 11
	githubUser       = ""
	out              = output.Output{}

	userAgent    = kingpin.Flag("user-agent", "Set 'User-Agent' header value.").Short('u').PlaceHolder("USER-AGENT").Default(defaultUserAgent).String()
	timeout      = kingpin.Flag("timeout", "Set custom request timeout (default is 10s).").Short('t').Default("10s").Duration()
	githubAuth   = kingpin.Flag("github-auth", "GitHub username and personal token.").PlaceHolder("USER:TOKEN").String()
	githubLatest = kingpin.Flag("github-latest", "Try to get only stable GitHub releases.").Bool()
	outputPath   = kingpin.Flag("output-path", "Output the results as CSV into a file.").Short('o').PlaceHolder("FILEPATH").String()
	// configPath         = kingpin.Flag("config-path", "Custom configuration file location.").Short('c').PlaceHolder("FILEPATH").File()
	// configAudit        = kingpin.Flag("config-audit", "Audit configuration file.").Bool()
	all                = kingpin.Flag("all", "Show and output all casks even updated ones.").Short('a').Bool()
	insecureSkipVerify = kingpin.Flag("insecure-skip-verify", "Skip server certificate verification.").Short('i').Bool()

	casknames = kingpin.Arg("casks", "Cask names.").Strings()
)

func init() {
	kingpin.UsageTemplate(kingpin.CompactUsageTemplate).Version(version)
	kingpin.CommandLine.Help = "Scan casks with appcasts for outdated ones and get the latest available version(s)."
	kingpin.CommandLine.VersionFlag.Short('v')
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()

	// if output is specified try to create a file or exit with error
	if *outputPath != "" {
		_, err := os.Create(*outputPath)
		if err != nil {
			general.Error(err.Error())
			os.Exit(1)
		}
		out = *output.New()
	}

	// check if inside of the 'homebrew-*/Casks' directory
	if !general.IsCasksDir() {
		general.Error("You need to be inside a '/homebrew-*/Casks' directory")
	}
}

func main() {
	var found = []string{}

	w := uilive.New()
	w.Start()

	if len(*casknames) > 0 {
		// cask names were provided in arguments
		for _, caskname := range *casknames {
			caskname = strings.TrimSuffix(caskname, filepath.Ext(caskname)) // remove file extension

			// check if file exists
			if _, err := os.Stat(fmt.Sprintf("./%s.rb", caskname)); err == nil {
				if hasAppcast(caskname) {
					found = append(found, caskname) // add to found
				}
			}
		}

		fmt.Fprintf(w, "Checking %d of %d casks for updates...\n", len(found), len(*casknames))
	} else {
		// find casks with appcasts
		fmt.Fprintln(w, "Searching...")
		files, _ := ioutil.ReadDir("./")
		casks := []string{}
		for _, file := range files {
			filename := file.Name()

			// verify that this is the cask file
			re := regexp.MustCompile(`.*\.rb$`)
			if re.MatchString(filename) {
				caskname := strings.TrimSuffix(filename, filepath.Ext(filename)) // remove file extension
				casks = append(casks, caskname)                                  // add to casks

				// check if cask has an appcast
				if hasAppcast(caskname) {
					found = append(found, caskname) // add to found
				}
			}
		}

		fmt.Fprintf(w, "Checking %d of %d casks for updates...\n", len(found), len(casks))
	}

	w.Stop()
	general.TerminalPrintHr('-')

	// check each found cask for updates
	for _, caskname := range found {
		w = uilive.New()
		w.Start()

		// prepare new review and create cask
		r := review.New(nameSpacing)
		c := cask.New(caskname)

		reviewCaskLoading(c, r, w) // show cask data without loaded appcasts

		// set parameters for each appcast, if specified in arguments
		for i, version := range c.Versions {
			version.Appcast.Request.AddHeader("User-Agent", *userAgent)
			version.Appcast.Request.InsecureSkipVerify = *insecureSkipVerify
			version.Appcast.Request.Timeout = *timeout

			if *githubAuth != "" {
				// githubAuth has beed passed as arguments
				githubUser, _ = version.Appcast.Request.AddGitHubAuth(*githubAuth)
			} else {
				// check if `git config` has required parameters set
				gu, guErr := gitconfig.Global("github.user")
				gt, gtErr := gitconfig.Global("github.token")

				if guErr == nil && gtErr == nil {
					// "github.user" and "github.token" are set
					githubUser = gu
					encoded := base64.URLEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", gu, gt)))
					version.Appcast.Request.AddHeader("Authorization", fmt.Sprintf("Basic %s", encoded))
				}
			}

			c.Versions[i] = version
		}

		c.LoadAppcasts() // check for updates

		// override the previous review
		r = review.New(nameSpacing)

		reviewCask(c, r, w) // show data with loaded appcasts

		w.Stop()
	}
}

// hasAppcast checks if cask with provided caskname has an appcast.
func hasAppcast(caskname string) bool {
	content := string(general.GetFileContent(fmt.Sprintf("./%s.rb", caskname))) // read file

	// check if appcast is available
	re := regexp.MustCompile(`appcast [\'\"]`)
	if re.MatchString(content) {
		return true
	}

	return false
}

// reviewCaskLoading reviews provided cask without loaded appcasts.
func reviewCaskLoading(c *cask.Cask, r *review.Review, a ...interface{}) {
	current, _, _ := prepareVersions(c)
	latest := make([]string, len(current))
	for i := range current {
		latest[i] = "Loading..."
	}

	appcasts, _, _ := prepareAppcasts(c.Versions)
	providers := make([]string, len(appcasts))
	for i := range appcasts {
		providers[i] = "Loading..."
	}

	r.AddItem("Name", color.WhiteString(c.Name))
	r.AddItems("Version", current)
	r.AddItem("Status", color.WhiteString("checking..."))
	r.AddItems("Appcast", appcasts)

	if len(a) > 0 {
		r.Fprint(a[0].(io.Writer))
	}
}

// reviewCask reviews provided cask with loaded and checked appcasts.
func reviewCask(c *cask.Cask, r *review.Review, a ...interface{}) {
	status := "error"
	current, latest, statuses := prepareVersions(c)
	appcasts, providers, _ := prepareAppcasts(c.Versions)

	r.AddItem("Name", color.WhiteString(c.Name))
	r.AddPipeItems("Version", "s", current, latest)

	// check if one of the versions has an "outdated" status
	hasOutdatedVersion := false
	hasUnknownVersion := false
	hasErrorVersion := false
	for _, status := range statuses {
		switch status {
		case "outdated":
			hasOutdatedVersion = true
			break
		case "unknown":
			hasUnknownVersion = true
			break
		case "error":
			hasErrorVersion = true
			break
		}
	}

	if len(c.Versions) > 0 && (hasOutdatedVersion || hasUnknownVersion || hasErrorVersion) {
		if hasErrorVersion {
			status = "error"
			r.AddItem("Status", color.RedString(status))
		} else if c.IsOutdated() {
			status = "outdated"
			r.AddItem("Status", color.YellowString(status))
		}

		r.AddPipeItems("Appcast", "s", appcasts, providers)

		if len(a) > 0 {
			r.Fprint(a[0].(io.Writer))
			general.TerminalPrintHr('-')
		}
	} else {
		status = "updated"
		r.AddItem("Status", color.GreenString(status))
		r.AddPipeItems("Appcast", "s", appcasts, providers)

		if len(a) > 0 && *all == false {
			fmt.Fprint(a[0].(io.Writer), "\r\r")
		} else if len(a) > 0 {
			r.Fprint(a[0].(io.Writer))
			general.TerminalPrintHr('-')
		}
	}

	// output the result to CSV file if enabled
	if *outputPath != "" {
		for _, v := range c.Versions {
			if status != "updated" || *all {
				out.AddOutdated(c.Name, status, v)
			}
		}
		out.SaveOutdatedAsCSVToFile(*outputPath)
	}
}

// prepareVersions prepares cask versions to be consumed by review. It separates
// version specific data into 3 equal arrays for Review AddPipeItems(): current,
// latest and statuses.
func prepareVersions(c *cask.Cask) (current []string, latest []string, statuses []string) {
	if *githubLatest {
		c.RemoveAllPrereleases()
	}

	for _, v := range c.Versions {
		var (
			statusCode       = v.Appcast.Request.StatusCode.Code
			currentVersion   = v.Current
			latestVersion    = v.Latest.Version // by default the latest version is without build
			suggestedVersion = v.Latest.Suggested
			status           = "unknown" // by default the status is unknown
		)

		// should return error status for any condition
		if statusCode == 0 || statusCode >= 400 || cask.StringHasInterpolation(v.Appcast.Request.Url) {
			status = "error"
		}

		if v.Latest.Version != "" && v.Latest.Build != "" && v.Latest.Version != v.Latest.Build {
			// when both latest version and build available
			latestVersion = fmt.Sprintf("%s,%s", v.Latest.Version, v.Latest.Build)
		} else if v.Latest.Version == "" && v.Latest.Build != "" {
			// when only build available
			latestVersion = v.Latest.Build
		}

		if latestVersion != "" && v.Appcast.Checkpoint.Current != v.Appcast.Checkpoint.Latest && currentVersion != suggestedVersion {
			// when latest version is available and checkpoints mismatch
			status = "outdated"
			if latestVersion != suggestedVersion {
				latestVersion = fmt.Sprintf("%s \u2192 %s", color.GreenString(latestVersion), color.WhiteString(suggestedVersion))
			} else {
				latestVersion = color.GreenString(latestVersion)
			}
		} else {
			status = "updated"
			if latestVersion != suggestedVersion {
				latestVersion = fmt.Sprintf("%s \u2192 %s", latestVersion, color.WhiteString(suggestedVersion))
			}
		}

		current = append(current, currentVersion)
		latest = append(latest, latestVersion)
		statuses = append(statuses, status)
	}

	return current, latest, statuses
}

// prepareAppcasts prepares versions to be consumed by review. It separates
// appcast specific data into 3 equal arrays for Review AddPipeItems():
// appcasts, providers and codes.
func prepareAppcasts(versions []cask.Version) (appcasts []string, providers []string, codes []string) {
	var encountered = map[string]bool{}

	for _, v := range versions {
		url := v.Appcast.Url
		statusCode := v.Appcast.Request.StatusCode

		if url != "" && encountered[url] != true {
			encountered[url] = true

			if statusCode.Code == 0 || statusCode.Code == 200 {
				// don't show status code for timed out and successful requests
				appcasts = append(appcasts, url)
			} else {
				// show for others
				appcasts = append(appcasts, fmt.Sprintf("%s [%s]", url, statusCode.Colorized()))
			}

			providers = append(providers, v.Appcast.Provider.String())
			codes = append(codes, statusCode.String())
		}
	}

	return appcasts, providers, codes
}
