package books

import (
	//"database/sql"
	"github.com/moshee/gas"
)

type Model interface {
	Populate(row SqlScanner, scheme string)
}

type SqlScanner interface {
	Scan(...interface{}) error
}

func Index(g *gas.Gas) {
	g.Render("books", "index", nil)
}
