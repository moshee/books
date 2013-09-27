package books

import (
	"github.com/moshee/gas"
)

type AJAXResponse struct {
	Ok      bool   `json:"ok"`
	Message string `json:"msg"`
}

func Login(g *gas.Gas) {
	if err := g.SignIn(); err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		// TODO: gas.Log(gas.Warning, "books: Login: %v", err)
		// TODO: g.JSON(&AJAXResponse{false, "There was an error creating your session. This error has been logged. Please try again later or complain about it."}
		return
	}

	g.Render("books", "login-pane", g.User.(*User))
}

func Logout(g *gas.Gas) {
	if err := g.SignOut(); err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "login-pane", nil)
}
