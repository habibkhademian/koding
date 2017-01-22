package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"

	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/helper"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

var testKloudHook = nop

func nop(*kloud.Client) {}

func AuthLogin(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kodingURL, err := url.Parse(c.String("baseurl"))
	if err != nil {
		return 1, fmt.Errorf("%q is not a valid URL value: %s\n", c.String("koding"), err)
	}

	f := auth.NewFacade(&auth.FacadeOpts{
		Base: kodingURL,
		Log:  log,
	})

	testKloudHook(f.Kloud)

	// If we already own a valid kite.key, it means we were already
	// authenticated and we just call kloud using kite.key authentication.
	err = f.Kloud.Transport.(stack.Validator).Valid()

	log.Debug("auth: transport test: %s", err)

	opts := &auth.LoginOptions{
		Team:  c.String("team"),
		Token: c.String("token"),
	}

	if err != nil && opts.Token == "" {
		opts.Username, err = helper.Ask("Username [%s]: ", config.CurrentUser.Username)
		if err != nil {
			return 1, err
		}

		if opts.Username == "" {
			opts.Username = config.CurrentUser.Username
		}

		for {
			opts.Password, err = helper.AskSecret("Password [***]: ")
			if err != nil {
				return 1, err
			}
			if opts.Password != "" {
				break
			}
		}
	}

	fmt.Fprintln(os.Stderr, "Logging to", kodingURL, "...")

	resp, err := f.Login(opts)
	if err != nil {
		return 1, fmt.Errorf("error logging into your Koding account: %v", err)
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)
	} else if resp.GroupName != "" {
		fmt.Fprintln(os.Stdout, "Successfully logged in to the following team:", resp.GroupName)
	} else {
		fmt.Fprintf(os.Stdout, "Successfully authenticated to Koding.\n\nPlease run \"kd auth login "+
			"[--team myteam]\" in order to login to your team.\n")
	}

	return 0, nil
}
