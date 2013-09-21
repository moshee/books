package main

import (
	"github.com/moshee/books/books"
	"github.com/moshee/gas"
	"net/http"
	"path/filepath"
	"strings"
	"unicode"
)

func main() {
	gas.TemplateFunc("books", "slugify", slugify)

	gas.New().
		Get("/static/{path}", StaticHandler).
		Get("/", books.Index)

	gas.Ignition()
}

func StaticHandler(g *gas.Gas) {
	name := filepath.Join("./static", g.Args["path"])
	http.ServeFile(g.ResponseWriter, g.Request, name)
}

func slugify(in string) string {
	if len(in) == 0 {
		return in
	}

	var (
		out = make([]rune, 0, len(in))
		sym = false
	)

	for _, ch := range in {
		if unicode.IsLetter(ch) || unicode.IsNumber(ch) {
			sym = false
			out = append(out, ch)
		} else if sym {
			continue
		} else {
			out = append(out, '-')
			sym = true
		}
	}
	return strings.Trim(string(out), "-")
}
