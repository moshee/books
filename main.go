package main

import (
	"encoding/json"
	"fmt"
	"github.com/moshee/books/books"
	"github.com/moshee/gas"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"
)

func main() {
	config := make(map[string]string)

	configFile, err := os.Open("config.json")
	if err != nil {
		gas.Log(gas.Fatal, "read config: %v", err)
	}

	configContents, err := ioutil.ReadAll(configFile)
	if err != nil {
		gas.Log(gas.Fatal, "read config: %v", err)
	}

	if err = json.Unmarshal(configContents, &config); err != nil {
		gas.Log(gas.Fatal, "read config: %v", err)
	}

	gas.TemplateFunc("books", "slugify", slugify)
	gas.TemplateFunc("books", "ago", ago)
	gas.TemplateFunc("books", "collapse_range", collapse_range)
	gas.TemplateFunc("books", "add", add)
	gas.TemplateFunc("books", "datetime", func(t time.Time) string {
		return t.Format("2006-02-01T15:04:05Z0700")
	})

	r := gas.New()

	// assets
	r.Get("/static/{path}", StaticHandler)
	r.Get("/img/u/t/{img}", placeholdit(48, 48))
	r.Get("/img/c/{img}", placeholdit(256, 384))
	r.Get("/img/char/t/{img}", placeholdit(64, 64))
	r.Get("/robots.txt", robots)

	// system
	r.Post("/login", books.PostLogin)
	r.Get("/login", books.Login)
	r.Post("/logout", books.Logout)
	r.Get("/logout", redirect("/", 303))
	r.Get("/signup", books.Signup)
	r.Post("/signup", books.PostSignup)

	r.Post("/ajax/tag/info", books.TagInfo)
	r.Post("/ajax/tag/vote", books.TagVote)
	r.Post("/ajax/validate/username", books.ValidateUsername)

	// User
	r.Get("/settings", redirect("/settings/profile", 303))
	r.Get("/settings/profile", requireLogin, books.SettingsProfile)
	r.Get("/settings/feeds", requireLogin, books.SettingsFeeds)
	r.Get("/settings/account", requireLogin, books.SettingsAccount)
	r.Get("/user/{id}", books.UserProfile)

	// Series
	r.Get("/series/{id}", books.SeriesPage)

	r.Get("/", books.Index)

	gas.InitDB("postgres", buildPgArgs(config))

	// set to 9 because the apple tv is a piece of shit
	// don't forget to remove this line in production
	gas.HashCost = 9
	gas.UseCookies(books.DBStore{})

	gas.Ignition()
}

func buildPgArgs(config map[string]string) string {
	keys := []string{"user", "dbname", "sslmode"}
	for i, key := range keys {
		keys[i] += "=" + config[key]
	}

	return strings.Join(keys, " ")
}

func StaticHandler(g *gas.Gas) {
	name := filepath.Join("./static", g.Arg("path"))
	http.ServeFile(g.ResponseWriter, g.Request, name)
}

func robots(g *gas.Gas) {
	http.ServeFile(g.ResponseWriter, g.Request, "./static/robots.txt")
}

func redirect(path string, code int) gas.Handler {
	return func(g *gas.Gas) {
		g.Redirect(path, code)
	}
}

func requireLogin(g *gas.Gas) {
	if g.User().(*books.User) == nil {
		g.Reroute("/login", 302, map[string]string{"location": g.URL.Path})
	}
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
