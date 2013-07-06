package main

import (
	"./books"
	"github.com/moshee/gas"
)

func StaticHandler(g *gas.Gas) {
	path := g.Args["path"]
	f, err := os.Open(filepath.Join("./static", path))
	if err != nil {
		return
	}
	defer f.Close()
	io.Copy(g.ResponseWriter, f)
}

func main() {
	gas.New().
		Get("/static/{path}", StaticHandler).
		Get("/", books.Index)

	gas.Ignition()
}
