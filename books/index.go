package books

import (
	"github.com/moshee/gas"
)

func Index(g *gas.Gas) {
	// latest releases
	release := make([]*Release, 0, 25)
	rows, err := gas.DB.Query(`
	SELECT r.
	g.Render("books", "index", nil)
}
