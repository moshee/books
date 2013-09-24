package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"sort"
	"time"
)

func Index(g *gas.Gas) {
	const releaseCount = 20
	releases := make([]Release, releaseCount)
	rows, err := gas.DB.Query("SELECT * FROM books.recent_releases LIMIT 20")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}
	defer rows.Close()

	n := 0

	for ; rows.Next(); n++ {
		r := &releases[n]
		s := new(BookSeries)
		var cs Chapters
		var gs TranslationGroups

		err = rows.Scan(&r.Id, &r.Language, &r.ReleaseDate, &r.IsLastRelease, &r.Extra, &cs.Volumes, &cs.Nums, &s.Id, &s.Title, &gs.Ids, &gs.Names)
		if err != nil {
			g.Render("books", "index-error", err)
			return
		}

		r.BookSeries = s
		r.Chapters = cs
		sort.Sort(gs)
		r.TranslationGroups = gs
	}

	if n < releaseCount {
		releases = releases[:n]
	}

	series := make([]BookSeries, 10)
	rows, err = gas.DB.Query("SELECT * FROM books.latest_series LIMIT 10")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}
	defer rows.Close()

	for n = 0; rows.Next(); n++ {
		s := &series[n]
		err := rows.Scan(&s.Id, &s.Title, &s.SeriesKind, &s.Vintage, &s.DateAdded, &s.NSFW, &s.AvgRating, &s.Demographic, &s.Tags)
		if err != nil {
			g.Render("books", "index-error", err)
			return
		}
	}

	if n < 10 {
		series = series[:n]
	}

	news := new(NewsPost)
	u := new(User)

	row := gas.DB.QueryRow("SELECT * FROM books.latest_news LIMIT 1")

	if err := row.Scan(&news.Id, &u.Id, &u.Name, &news.Category, &news.DatePosted, &news.Title, &news.Body); err != nil {
		g.Render("books", "index-error", err)
		return
	}

	news.User = u

	g.Render("books", "index", &struct {
		Releases []Release
		Series   []BookSeries
		News     *NewsPost
		Now      time.Time
	}{
		releases,
		series,
		news,
		time.Now(),
	})
}
