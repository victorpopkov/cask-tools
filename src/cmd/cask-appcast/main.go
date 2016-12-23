package main

import (
	"encoding/base64"
	"fmt"
	"os"
	"strconv"

	"appcast"
	"review"

	"github.com/fatih/color"
	"github.com/gosuri/uilive"
	gitconfig "github.com/tcnksm/go-gitconfig"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	version          = "1.0.0-alpha.3"
	defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
	githubUser       = ""

	userAgent          = kingpin.Flag("user-agent", "Set 'User-Agent' header value.").Short('u').PlaceHolder("USER-AGENT").Default(defaultUserAgent).String()
	timeout            = kingpin.Flag("timeout", "Set custom request timeout (default is 10s).").Short('t').Default("10s").Duration()
	githubAuth         = kingpin.Flag("github-auth", "GitHub username and personal token.").PlaceHolder("USER:TOKEN").String()
	githubLatest       = kingpin.Flag("github-latest", "Try to get only stable GitHub releases.").Bool()
	filter             = kingpin.Flag("filter", "Filter releases using RegExp.").Short('f').PlaceHolder("REGEXP").Regexp()
	checkpoint         = kingpin.Flag("checkpoint", "Output appcast checkpoint.").Short('c').Bool()
	provider           = kingpin.Flag("provider", "Output appcast provider.").Short('p').Bool()
	appVersion         = kingpin.Flag("app-version", "Output app version and build (if available).").Short('V').Bool()
	downloads          = kingpin.Flag("downloads", "Output download URL(s).").Short('d').Bool()
	insecureSkipVerify = kingpin.Flag("insecure-skip-verify", "Skip server certificate verification.").Short('i').Bool()

	url = kingpin.Arg("url", "Appcast URL.").Required().URL()
)

func init() {
	kingpin.UsageTemplate(kingpin.CompactUsageTemplate).Version(version)
	kingpin.CommandLine.Help = "Get the latest available version, checkpoint and download URL(s) from appcast."
	kingpin.CommandLine.VersionFlag.Short('v')
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()
}

func main() {
	w := uilive.New()
	w.Start()

	fmt.Fprintln(w, "Loading...")

	a := appcast.New((*url).String())
	a.Request.AddHeader("User-Agent", *userAgent)
	a.Request.InsecureSkipVerify = *insecureSkipVerify
	a.Request.Timeout = *timeout
	a.Filter = *filter

	if *githubAuth != "" {
		// githubAuth has beed passed as arguments
		githubUser, _ = a.Request.AddGitHubAuth(*githubAuth)
	} else {
		// check if `git config` has required parameters set
		gu, guErr := gitconfig.Global("github.user")
		gt, gtErr := gitconfig.Global("github.token")

		if guErr == nil && gtErr == nil {
			// "github.user" and "github.token" are set
			githubUser = gu
			encoded := base64.URLEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", gu, gt)))
			a.Request.AddHeader("Authorization", fmt.Sprintf("Basic %s", encoded))
		}
	}

	a = a.LoadContent()

	fmt.Fprint(w, "\r")
	w.Stop()

	if !(*checkpoint) && !(*provider) && !(*appVersion) && !(*downloads) {
		reviewAppcast(a, review.New())
	}

	if *checkpoint {
		fmt.Println(a.Checkpoint.Latest)
	}

	if *provider {
		fmt.Println(a.Provider)
	}

	if *appVersion {
		a.FprintSingleVersionAndBuild(os.Stdout)
	}

	if *downloads {
		a.FprintSingleDownloads(os.Stdout)
	}

	os.Exit(0)
}

// reviewAppcast reviews the provided appcast into the Review struct.
func reviewAppcast(a *appcast.BaseAppcast, r *review.Review) {
	if a.Request.StatusCode.Int == 0 {
		r.AddItem("Appcast", a.Url)
	} else {
		r.AddItem("Appcast", fmt.Sprintf("%s [%s]", a.Url, a.Request.StatusCode.Colorized()))
	}

	r.AddItem("Checkpoint", a.Checkpoint.Latest)
	r.AddItem("Provider", a.Provider.Colorized())

	if a.Request.StatusCode.Int == 0 {
		r.AddItem("Status", a.Request.Error.Colorized())
		r.Print()

		if a.Request.Error.Code == 4 {
			fmt.Println("\nYou can disable certificate authority verification using `-i/--insecure-skip-verify` flag.")
		}

		os.Exit(a.Request.Error.Code)
	}

	switch a.Provider {
	case appcast.GitHubAtom:
		reviewGitHubAtom(a, r)
		break
	case appcast.SourceForge:
		reviewSourceForge(a, r)
		break
	case appcast.Sparkle:
		reviewSparkle(a, r)
		break
	case appcast.Unknown:
		r.Print()
		break
	}
}

// reviewGitHubAtom reviews only GitHub Atom provider.
func reviewGitHubAtom(a *appcast.BaseAppcast, r *review.Review) {
	authorized := false
	for _, header := range a.Request.Headers {
		if header.Name == "Authorization" {
			if a.Request.StatusCode.Int != 401 {
				authorized = true
				break
			}
		}
	}

	if authorized {
		r.AddItem("Authorization", fmt.Sprintf("%s | %s", color.GreenString("authorized"), githubUser))
	} else {
		r.AddItem("Authorization", fmt.Sprintf("%s | %s", color.RedString("unauthorized"), "-"))
	}

	if *filter != nil {
		spacing := 21
		if authorized {
			spacing = 19
		}

		r.AddItem("Filtering", fmt.Sprintf("%-"+strconv.Itoa(spacing)+"s | %s", color.GreenString("enabled"), (*filter).String()))
	}

	// r.AddPipeItems("Options", "", optionsStatuses, optionsValues)

	if a.Request.StatusCode.Int == 403 {
		r.AddItem("Status", color.RedString("GitHub API rate limit exceeded."))
		r.Print()

		fmt.Println("\nYou can use authenticated requests to get a higher rate limit using `--github-auth=USER:TOKEN` flag")
		fmt.Println("or you can set 'github.user' and 'github.token' values in `git config`:")
		fmt.Println("\n  git config --global --add 'github.user' <USER>")
		fmt.Println("  git config --global --add 'github.token' <TOKEN>")

		os.Exit(2)
	}

	if len(a.Items) > 0 {
		release, _ := a.GetFirstPrerelease()

		// if only latest versions, then skip prereleases
		if *githubLatest == true {
			release, _ = a.GetFirstStable()
		}

		// there are some releases
		v := release.Version.Value
		if release.Version.Prerelease {
			versions := []string{v}
			prereleases := []string{color.YellowString("Pre-release")}
			r.AddPipeItems("Latest version", "s", versions, prereleases)
		} else {
			r.AddItem("Latest version", v)
		}

		r.AddItems("Latest download URL", release.Urls)
	} else {
		// no releases
		r.AddItem("Latest version", "-")
		r.AddItem("Latest download URL", "-")
	}

	r.Print()
}

// reviewSourceForge reviews only SourceForge provider.
func reviewSourceForge(a *appcast.BaseAppcast, r *review.Review) {
	if len(a.Items) > 0 {
		// there are some releases
		r.AddItem("Latest version", a.Items[0].Version.Value)
		r.AddItems("Latest download URL", a.Items[0].Urls)
	} else {
		// no releases
		r.AddItem("Latest version", "-")
		r.AddItem("Latest download URL", "-")
	}

	r.Print()
}

// reviewSparkle reviews only Sparkle provider.
func reviewSparkle(a *appcast.BaseAppcast, r *review.Review) {
	if len(a.Items) > 0 {
		// there are some releases
		if a.Items[0].Version.Value != "" && a.Items[0].Build.Value != "" {
			// both version and build are available
			r.AddItem("Latest version", a.Items[0].Version.Value)
			r.AddItem("Latest build", a.Items[0].Build.Value)
		} else {
			// only version or build is available
			v := a.Items[0].Version.Value
			if v == "" {
				v = a.Items[0].Build.Value
			}

			r.AddItem("Latest version", v)
		}

		r.AddItem("Latest download URL", a.Items[0].Urls[0])
	} else {
		// no releases
		r.AddItem("Latest version", "-")
		r.AddItem("Latest download URL", "-")
	}

	r.Print()
}
