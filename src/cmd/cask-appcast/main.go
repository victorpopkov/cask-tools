package main

import (
	"fmt"
	"os"

	"github.com/gosuri/uilive"
	"github.com/gosuri/uitable"
	"github.com/victorpopkov/go-appcast"
	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	version          = "1.0.0-beta"
	defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10) http://caskroom.io"

	userAgent          = kingpin.Flag("user-agent", "Set 'User-Agent' header value.").Short('u').PlaceHolder("USER-AGENT").Default(defaultUserAgent).String()
	timeout            = kingpin.Flag("timeout", "Set custom request timeout (default is 10s).").Short('t').Default("10s").Duration()
	checksum           = kingpin.Flag("checksum", "Output appcast SHA256 checksum.").Short('c').Bool()
	provider           = kingpin.Flag("provider", "Output appcast provider.").Short('p').Bool()
	appVersion         = kingpin.Flag("app-version", "Output app version and build (if available).").Short('V').Bool()
	downloads          = kingpin.Flag("downloads", "Output download URL(s).").Short('d').Bool()
	insecureSkipVerify = kingpin.Flag("insecure-skip-verify", "Skip server certificate verification.").Short('i').Bool()

	url = kingpin.Arg("url", "Appcast URL.").Required().URL()
)

func init() {
	kingpin.UsageTemplate(kingpin.CompactUsageTemplate).Version(version)
	kingpin.CommandLine.Help = "Get some useful information from remote appcast URL."
	kingpin.CommandLine.VersionFlag.Short('v')
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()
}

func main() {
	w := uilive.New()
	w.Start()

	fmt.Fprintln(w, "Loading...")

	a := appcast.New()

	// preparing the DefaultClient
	appcast.DefaultClient.Timeout = *timeout
	if *insecureSkipVerify == true {
		appcast.DefaultClient.InsecureSkipVerify()
	}

	// preparing the Request
	req, _ := appcast.NewRequest((*url).String())
	req.AddHeader("User-Agent", *userAgent)

	// loading data (the URL was specified in the Request earlier)
	a.LoadFromURL(req)
	a.GenerateChecksum(appcast.SHA256)
	a.ExtractReleases()

	fmt.Fprintf(w, "%c[2K", 27) // clear previous line
	w.Stop()

	// display only checksum
	if *checksum {
		fmt.Println(a.GetChecksum())
		os.Exit(0)
	}

	// display only provider
	if *provider {
		fmt.Println(a.GetProvider())
		os.Exit(0)
	}

	// display only version and build (if available)
	if *appVersion {
		first := a.GetFirstRelease()
		if first.GetBuildString() != "" && first.GetVersionString() != first.GetBuildString() {
			fmt.Printf("%s %s\n", first.GetVersionString(), first.GetBuildString())
		} else {
			fmt.Println(first.GetVersionString())
		}
		os.Exit(0)
	}

	// display only downloads
	if *downloads {
		for _, download := range a.GetFirstRelease().GetDownloads() {
			fmt.Println(download.URL)
		}
		os.Exit(0)
	}

	reviewAppcast(a)

	os.Exit(0)
}

// reviewAppcast reviews the provided appcast and prints the result on the
// screen.
func reviewAppcast(a *appcast.BaseAppcast) {
	t := uitable.New()
	t.Wrap = true

	t.AddRow("Appcast:", a.GetURL())
	t.AddRow("Checksum (SHA256):", a.GetChecksum())
	t.AddRow("Provider:", a.GetProvider().String())
	t.AddRow("User-Agent:", *userAgent)

	switch a.GetProvider() {
	default:
		reviewDefault(a, t)
	}

	fmt.Println(t)
}

// reviewDefault adds the default rows to the provided uitable.Table which
// should fit most providers.
func reviewDefault(a *appcast.BaseAppcast, t *uitable.Table) {
	if a.GetReleasesLength() > 0 {
		first := a.GetFirstRelease()

		if first.GetBuildString() != "" && first.GetVersionString() != first.GetBuildString() {
			// both version and build are available
			t.AddRow("Latest version:", first.GetVersionString())
			t.AddRow("Latest build:", first.GetBuildString())
		} else {
			// only version or build is available
			t.AddRow("Latest version:", first.GetVersionOrBuildString())
		}

		// downloads
		for _, download := range a.GetFirstRelease().GetDownloads() {
			t.AddRow("Latest download URL:", download.URL)
		}
	} else {
		// no releases
		t.AddRow("Latest version:", "-")
		t.AddRow("Latest download URL:", "-")
	}
}
