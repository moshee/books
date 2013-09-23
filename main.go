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

	switch {
	case dur > time_Year:
		return fmt.Sprintf("%dyrs, %dd ago",
			dur/time_Year,
			(dur%time_Year)/time_Day)
	case dur > time_Day:
		return fmt.Sprintf("%d days ago", (dur%time_Year)/time_Day)
	case dur > time.Hour:
		return fmt.Sprintf("%d hours ago", (dur%time_Day)/time.Hour)
	case dur > time.Minute:
		return fmt.Sprintf("%d mins ago", (dur%time.Hour)/time.Minute)
	default:
		return "Just now"
	}
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
