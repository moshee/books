package main

import (
	"fmt"
	"github.com/moshee/books/books"
	"github.com/moshee/gas"
	"net/http"
	"path/filepath"
	"strings"
	"time"
	"unicode"
)

func main() {
	gas.TemplateFunc("books", "slugify", slugify)
	gas.TemplateFunc("books", "ago", ago)

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
		} else if sym || ch == '\'' || ch == '’' {
			// skip apostrophes
			continue
		} else {
			out = append(out, '-')
			sym = true
		}
	}
	return strings.Trim(string(out), "-")
}

const (
	time_Day  = time.Hour * 24
	time_Year = time_Day * 365
)

func ago(t time.Time) string {
	dur := time.Since(t)

	switch {
	case dur > time_Year:
		return fmt.Sprintf("%dy%dd ago",
			dur/time_Year,
			(dur%time_Year)/time_Day)
	case dur > time_Day:
		return fmt.Sprintf("%d days ago", (dur%time_Year)/time_Day)
	case dur > time.Hour:
		return fmt.Sprintf("%dh%dm ago",
			(dur%time_Day)/time.Hour,
			(dur%time.Hour)/time.Minute)
	case dur > time.Minute:
		return fmt.Sprintf("%d mins ago", (dur%time.Hour)/time.Minute)
	default:
		return "Just now"
	}
}
