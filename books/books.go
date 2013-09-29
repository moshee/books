package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	//	"path"
	"sort"
	"strconv"
	"time"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 20)
	if err := gas.Query(&releases, "SELECT * FROM books.recent_releases LIMIT 20"); err != nil {
		g.Error(500, err)
		return
	}
	for _, r := range releases {
		sort.Sort(r.TranslationGroups)
	}

	series := make([]BookSeries, 10)
	if err := gas.Query(&series, "SELECT * FROM books.latest_series LIMIT 10"); err != nil {
		g.Error(500, err)
		return
	}

	news := new(NewsPost)
	if err := gas.QueryRow(news, "SELECT * FROM books.latest_news LIMIT 1"); err != nil {
		g.Error(500, err)
		return
	}

	g.Render("books", "index", &struct {
		Releases []Release
		Series   []BookSeries
		News     *NewsPost
		Now      time.Time
		User     *User
	}{
		releases,
		series,
		news,
		time.Now(),
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
	if err = gas.QueryRow(series, "SELECT * FROM books.series_page WHERE id = $1", id); err != nil {
		g.Error(500, err)
		return
	}

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
