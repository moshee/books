package books

import (
	"github.com/moshee/gas"
)

func Index(g *gas.Gas) {
	g.Render("books", "index", nil)
}
