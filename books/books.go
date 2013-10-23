package books

import (
	//"fmt"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"strconv"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 0, 15)
	g.Populate(&releases, "SELECT * FROM books.recent_releases LIMIT 15")

	releaseFeed := &Feed{
		OutputKind: ReleaseOutput,
		Title:      "Latest Releases",
		Items:      releases,
	}

	series := make([]BookSeries, 0, 15)
	g.Populate(&series, "SELECT * FROM books.latest_series LIMIT 15")

	seriesFeed := &Feed{
		OutputKind: SeriesOutput,
		Title:      "New Titles",
		Items:      series,
	}

	var banner *Banner

	if rr := g.RerouteInfo; rr != nil {
		banner = new(Banner)
		if err := rr.Recover(banner); err != nil {
			banner = nil
			gas.Log(gas.Warning, "books index reroute: %v", err)
		}
	}

	g.Render("books", "index", &struct {
		Feeds  []*Feed
		User   *User
		Banner *Banner
	}{
		[]*Feed{releaseFeed, seriesFeed},
		g.User().(*User),
		banner,
	})
}

func Signup(g *gas.Gas) {
	if user := g.User().(*User); user != nil {
		g.Reroute("/", 302, newBanner("friendly", "You already have an account!", "We're flattered that you like the site so much that you need <strong>another</strong> account, but just one will be enough."))
		return
	}
	g.Render("books", "signup", nil)
}

func Login(g *gas.Gas) {
	if user := g.User().(*User); user != nil {
		g.Reroute("/", 302, newBanner("friendly", "You're already logged in!", ""))
		return
	}

	var data map[string]string

	if rr := g.RerouteInfo; rr != nil {
		if err := rr.Recover(&data); err != nil {
			gas.Log(gas.Warning, "books login reroute: %v", err)
		}
	}

	g.Render("books", "login", data["location"])
}

func UserProfile(g *gas.Gas) {
	id, err := strconv.Atoi(g.Args["id"])
	if err != nil {
		g.Error(400, err)
		return
	}

	me := g.User().(*User)

	them := new(User)
	g.Populate(them, "SELECT * FROM books.users WHERE id = $1", id)

	reviews := make([]BookRating, 0, 3)

	g.Populate(&reviews, `
		SELECT
			r.id,
			r.user_id,
			r.series_id,
			s.title,
			r.rating,
			r.review,
			r.rate_date
		FROM
			books.book_ratings r,
			books.book_series s
		WHERE r.user_id = $1
		  AND s.id = r.series_id
		  AND r.review IS NOT NULL
		ORDER BY r.rate_date DESC
		LIMIT 3
		`, them.Id)

	g.Render("books", "user-profile", &struct {
		User    *User
		Them    *User
		Reviews []BookRating
	}{
		me,
		them,
		reviews,
	})
}

func SettingsProfile(g *gas.Gas) {
	g.Render("books", "user-settings-profile", &struct {
		User *User
	}{
		g.User().(*User),
	})
}

func SettingsFeeds(g *gas.Gas) {
	g.Render("books", "user-settings-feeds", &struct {
		User *User
	}{
		g.User().(*User),
	})
}

func SettingsAccount(g *gas.Gas) {
	g.Render("books", "user-settings-account", &struct {
		User *User
	}{
		g.User().(*User),
	})
}

func SeriesIndex(g *gas.Gas) {

}

func SeriesPage(g *gas.Gas) {
	id, err := strconv.Atoi(g.Args["id"])
	if err != nil {
		g.Error(404, err)
	}

	series := new(BookSeries)
	g.Populate(series, "SELECT * FROM books.series_page WHERE id = $1", id)

	g.Render("books", "series", &struct {
		Series *BookSeries
		User   *User
	}{
		series,
		g.User().(*User),
	})
}

func AuthorsIndex(g *gas.Gas) {

}

func AuthorPage(g *gas.Gas) {

}
