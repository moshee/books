package main

import (
	"github.com/moshee/books/books"
	"github.com/moshee/gas"
	"net/http"
	"path/filepath"
)

func StaticHandler(g *gas.Gas) {
	name := filepath.Join("./static", g.Args["path"])
	http.ServeFile(g.ResponseWriter, g.Request, name)
}

func main() {
	gas.New().
		Get("/static/{path}", StaticHandler).
		Get("/", books.Index)

	gas.Ignition()
}
