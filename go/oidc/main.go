package main

import (
	"context"
	"net/http"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

var oauth2Config oauth2.Config

var (
	clientID     = "demo-client"
	clientSecret = "cbfd6e04-a51c-4982-a25b-7aaba4f30c81"

	redirectURL = "http://localhost:8181/demo/callback"
	state = "somestate"
)

func handleRedirect(w http.ResponseWriter, r *http.Request) {
	http.Redirect(w, r, oauth2Config.AuthCodeURL(state), http.StatusFound)
}

func main() {
	provider, err := oidc.NewProvider(context.Background(), "http://localhost:8181/demo/callback")
	if err != nil {
		// handle error
	}

	// Configure an OpenID Connect aware OAuth2 client.
	oauth2Config = oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,

		// Discovery returns the OAuth2 endpoints.
		Endpoint: provider.Endpoint(),

		// "openid" is a required scope for OpenID Connect flows.
		Scopes: []string{oidc.ScopeOpenID, "profile", "email"},
	}
}
