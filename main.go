package main

import (
	"fmt"
	"github.com/moshee/books/books"
	"github.com/moshee/gas"
	"net/http"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"
)

func main() {
	gas.TemplateFunc("books", "slugify", slugify)
	gas.TemplateFunc("books", "ago", ago)
	gas.TemplateFunc("books", "collapse_range", collapse_range)
	gas.TemplateFunc("books", "add", add)
	gas.TemplateFunc("books", "datetime", func(t time.Time) string {
		return t.Format("2006-02-01T15:04:05Z0700")
	})

	gas.New().
		Get("/static/{path}", StaticHandler).
		Get("/img/u/t/{img}", placeholdit(48, 48)).
		Get("/img/c/{img}", placeholdit(256, 384)).
		Get("/img/char/t/{img}", placeholdit(64, 64)).
		Get("/series/{id}", books.SeriesPage).
		Post("/login", books.Login).
		Get("/login", goHome).
		Post("/logout", books.Logout).
		Get("/logout", goHome).
		Post("/ajax/tag/info", books.TagInfo).
		Post("/ajax/tag/vote", books.TagVote).
		Get("/", books.Index)

	gas.InitDB("postgres", "user=postgres dbname=postgres sslmode=disable")

	// set to 9 because the apple tv is a piece of shit
	// don't forget to remove this line in production
	gas.HashCost = 9
	gas.UseCookies(books.DBStore{})

	gas.Ignition()
}

func StaticHandler(g *gas.Gas) {
	name := filepath.Join("./static", g.Args["path"])
	http.ServeFile(g.ResponseWriter, g.Request, name)
}

func goHome(g *gas.Gas) {
	g.Redirect("/", 303)
}

func slugify(in string) string {
	if len(in) == 0 {
		return in
	}
	in = strings.ToLower(in)

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
	unit := ""
	var amt time.Duration

	switch {
	case dur > time_Year:
		unit = "year"
		amt = dur / time_Year
	case dur > time_Day:
		unit = "day"
		amt = (dur % time_Year) / time_Day
	case dur > time.Hour:
		unit = "hour"
		amt = (dur % time_Day) / time.Hour
	case dur > time.Minute:
		unit = "min"
		amt = (dur % time.Hour) / time.Minute
	default:
		return "Just now"
	}

	if amt != 1 {
		unit += "s"
	}
	return fmt.Sprintf("%d %s ago", amt, unit)
}

func collapse_range(a []int) string {
	switch len(a) {
	case 0:
		return ""
	case 1:
		return strconv.Itoa(a[0])
	}
	sort.Ints(a)

	var (
		this  = a[1]
		last  = a[0]
		lower = last
		upper = last
		out   = make([]string, 0)
	)
	for _, this = range a[1:] {
		switch this - last {
		case 0:
			continue
		case 1:
			upper = this
			last = this
			continue
		}
		// not consecutive
		s := strconv.Itoa(lower)
		if lower != upper {
			s += "-" + strconv.Itoa(upper)
		}
		out = append(out, s)
		upper = this
		lower = this
		last = this
	}
	s := strconv.Itoa(lower)
	if lower != upper {
		s += "-" + strconv.Itoa(upper)
	}
	out = append(out, s)

	return strings.Join(out, ", ")
}

func add(n ...int) (sum int) {
	for _, i := range n {
		sum += i
	}
	return
}

func placeholdit(w, h int) func(*gas.Gas) {
	return func(g *gas.Gas) {
		g.Redirect(fmt.Sprintf("http://placehold.it/%dx%d", w, h), 303)
	}
}
